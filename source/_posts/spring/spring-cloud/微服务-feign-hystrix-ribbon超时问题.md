---

title: 微服务-feign-hystrix-ribbon超时问题

date: 2019-03-20 20:36:00

categories: [spring,springcloud]

tags: [spring,springcloud]

---


本节介绍 feign-hystrix-ribbon 的超时问题


<!--more-->


## Hystrix 和 Ribbon 超时配置

hystrix的超时时间 和 ribbon的超时时间 正确关系:

```basic
hystrixTimeout > (ribbonReadTimeout + ribbonConnectTimeout) * (maxAutoRetries + 1) * (maxAutoRetriesNextServer + 1)
```

##Ribbon 的 ConnectTimeout 和 ReadTimeout 生效位置

```java
public class FeignLoadBalancer extends
		AbstractLoadBalancerAwareClient<FeignLoadBalancer.RibbonRequest, FeignLoadBalancer.RibbonResponse> {
  // 忽略
  
  /**
  * 1. 到达该方法时，服务名已经被翻译为具体的ip地址。
  * 2. 通过 HttpURLConnection 请求 服务提供的Api
  * 3. ConnectTimeout 代表 HttpURLConnection 的连接超时时间
  * 4. ReadTimeout 代表 HttpURLConnection 的读取时间
  */
	@Override
	public RibbonResponse execute(RibbonRequest request, IClientConfig configOverride)
			throws IOException {
		Request.Options options;
		if (configOverride != null) {
			RibbonProperties override = RibbonProperties.from(configOverride);
      // 设置请求的 连接超时时间 和 读超时时间 
			options = new Request.Options(
					override.connectTimeout(this.connectTimeout),
					override.readTimeout(this.readTimeout));
		}
		else {
			options = new Request.Options(this.connectTimeout, this.readTimeout);
		}
		Response response = request.client().execute(request.toRequest(), options);
		return new RibbonResponse(request.getUri(), response);
	}
  // 忽略
}
```



## Hystrix 超时生效

Hystrix 任务的执行 分为 两个部分: 业务线程和超时检测线程。这两个部分是并发执行的。
谁先更改任务执行的状态，就会主动停止另一方的执行。如下图:

![](微服务-feign-hystrix-ribbon超时问题/51462a15.png)


### AbstractCommand.executeCommandAndObserve()

1. 并行执行业务代码和超时检测代码。
2. 设置服务降级
3. 等等

```java
abstract class AbstractCommand<R> implements HystrixInvokableInfo<R>, HystrixObservable<R> {
    // 忽略

    private Observable<R> executeCommandAndObserve(final AbstractCommand<R> _cmd) {
        // 忽略
        
        //命令执行过程中抛出异常时触发，实现降级
        final Func1<Throwable, Observable<R>> handleFallback = new Func1<Throwable, Observable<R>>() {
            @Override
            public Observable<R> call(Throwable t) {
                circuitBreaker.markNonSuccess();
                Exception e = getExceptionFromThrowable(t);
                executionResult = executionResult.setExecutionException(e);
                if (e instanceof RejectedExecutionException) {
                    return handleThreadPoolRejectionViaFallback(e);
                } else if (t instanceof HystrixTimeoutException) {
                    // 若为 超时异常，调用 超时fallBack
                    return handleTimeoutViaFallback();
                } else if (t instanceof HystrixBadRequestException) {
                    return handleBadRequestByEmittingError(e);
                } else {
                    // 忽略
                }
            }
        };
    
        // 忽略
       
        Observable<R> execution;
        //根据是否开启超时监测 来 创建被观察者
        if (properties.executionTimeoutEnabled().get()) {
            execution = executeCommandWithSpecifiedIsolation(_cmd)
                    .lift(new HystrixObservableTimeoutOperator<R>(_cmd));
        } else {
            execution = executeCommandWithSpecifiedIsolation(_cmd);
        }

        return execution.doOnNext(markEmits)
                .doOnCompleted(markOnCompleted)
                .onErrorResumeNext(handleFallback)
                .doOnEach(setRequestContext);
    }  
  
}
```

### HystrixObservableTimeoutOperator

1. 启动一个定时任务: 以 executionTimeoutInMilliseconds 为周期、延迟 executionTimeoutInMilliseconds 来执行。
一旦 tick() 进入 if 语句，则抛出 超时异常。
2. 添加一个观察者，当原任务执行完成后，取消 定时器。 

```java
private static class HystrixObservableTimeoutOperator<R> implements Operator<R, R> {
  // 忽略
  @Override
  public Subscriber<? super R> call(final Subscriber<? super R> child) {
    final CompositeSubscription s = new CompositeSubscription();
    child.add(s);
    final HystrixRequestContext hystrixRequestContext = HystrixRequestContext.getContextForCurrentThread();

    TimerListener listener = new TimerListener() {
      // 在延迟 executionTimeoutInMilliseconds 时间后，以executionTimeoutInMilliseconds为周期会执行 tick()
      @Override
      public void tick() {
		// 若设置成功，则取消原任务的执行 并 抛出 超时异常。
        if (originalCommand.isCommandTimedOut.compareAndSet(TimedOutStatus.NOT_EXECUTED, TimedOutStatus.TIMED_OUT)) {
          originalCommand.eventNotifier.markEvent(HystrixEventType.TIMEOUT, originalCommand.commandKey);

          //停止原来任务的执行
          s.unsubscribe();

          final HystrixContextRunnable timeoutRunnable = 
            new HystrixContextRunnable(
            		originalCommand.concurrencyStrategy, 
                hystrixRequestContext, 
                new Runnable() {

            @Override
            public void run() {
              //抛出超时异常，交由外围的onErrorResumeNext捕获触发fallback
              child.onError(new HystrixTimeoutException());
            }
          });

          timeoutRunnable.run();
        }
      }

      // 获取 外部配置的 Hystrix 调用超时间
      // 用来 作为 定时器的频率时间
      @Override
      public int getIntervalTimeInMilliseconds() {
        return originalCommand.properties.executionTimeoutInMilliseconds().get();
      }
    };

    // 以 executionTimeoutInMilliseconds 为频率，定时调用 tick()
    final Reference<TimerListener> tl = HystrixTimer.getInstance().addTimerListener(listener);

    // set externally so execute/queue can see this
    originalCommand.timeoutTimer.set(tl);

    // 在 原任务完成后，清除 定时器。
    Subscriber<R> parent = new Subscriber<R>() {

      @Override
      public void onCompleted() {
        if (isNotTimedOut()) {
          // 任务执行结束后，将TimerListener移除
          tl.clear();
          child.onCompleted();
        }
      }

      @Override
      public void onError(Throwable e) {
        if (isNotTimedOut()) {
          // 任务执行结束后，将TimerListener移除
          tl.clear();
          child.onError(e);
        }
      }

      @Override
      public void onNext(R v) {
        if (isNotTimedOut()) {
          child.onNext(v);
        }
      }

      private boolean isNotTimedOut() {
        // if already marked COMPLETED (by onNext) or succeeds in setting to COMPLETED
        return originalCommand.isCommandTimedOut.get() == TimedOutStatus.COMPLETED ||
          originalCommand.isCommandTimedOut.compareAndSet(TimedOutStatus.NOT_EXECUTED, TimedOutStatus.COMPLETED);
      }
    };

    // if s is unsubscribed we want to unsubscribe the parent
    s.add(parent);

    return parent;
  }

}
```


## 相关文章

https://deanwangpro.com/2018/04/13/zuul-hytrix-ribbon-timeout/
https://www.jianshu.com/p/60074fe1bd86
https://github.com/spring-cloud/spring-cloud-netflix/blob/master/spring-cloud-netflix-zuul/src/main/java/org/springframework/cloud/netflix/zuul/filters/route/support/AbstractRibbonCommand.java

[Hystrix超时处理和异常类型](http://atbug.com/hystrix-exception-handling/)
[Hystrix超时机制实现原理](http://www.ligen.pro/2018/10/14/Hystrix%E8%B6%85%E6%97%B6%E6%9C%BA%E5%88%B6%E5%AE%9E%E7%8E%B0%E5%8E%9F%E7%90%86/)
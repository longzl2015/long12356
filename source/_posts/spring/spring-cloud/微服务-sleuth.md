---

title: 微服务-sleuth

date: 2019-08-05 00:10:08

categories: [spring,springcloud,sleuth]

tags: [spring,springcloud,sleuth]

---

简单介绍 微服务-sleuth

<!--more-->

trace和span的流程如下:

![Trace Info propagation](/images/微服务-sleuth/trace-id.png)

下面介绍 sleuth 如何针对不同的场景，是如何进行 记录的。

##web请求

在程序启动时，TraceWebServletAutoConfiguration 会将 TracingFilter 注入到 spring 容器中。

主要针对web请求进行处理。

```java
public final class TracingFilter implements Filter {
  //..
  @Override
  public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
      throws IOException, ServletException {
    HttpServletRequest httpRequest = (HttpServletRequest) request;
    HttpServletResponse httpResponse = servlet.httpResponse(response);

    // Prevent duplicate spans for the same request
    TraceContext context = (TraceContext) request.getAttribute(TraceContext.class.getName());
    if (context != null) {
      // A forwarded request might end up on another thread, so make sure it is scoped
      Scope scope = currentTraceContext.maybeScope(context);
      try {
        chain.doFilter(request, response);
      } finally {
        scope.close();
      }
      return;
    }

    Span span = handler.handleReceive(extractor, httpRequest);

    // Add attributes for explicit access to customization or span context
    request.setAttribute(SpanCustomizer.class.getName(), span.customizer());
    request.setAttribute(TraceContext.class.getName(), span.context());

    Throwable error = null;
    Scope scope = currentTraceContext.newScope(span.context());
    try {
      // any downstream code can see Tracer.currentSpan() or use Tracer.currentSpanCustomizer()
      chain.doFilter(httpRequest, httpResponse);
    } catch (IOException | ServletException | RuntimeException | Error e) {
      error = e;
      throw e;
    } finally {
      scope.close();
      if (servlet.isAsync(httpRequest)) { // we don't have the actual response, handle later
        servlet.handleAsync(handler, httpRequest, httpResponse, span);
      } else { // we have a synchronous response, so we can finish the span
        handler.handleSend(ADAPTER.adaptResponse(httpRequest, httpResponse), error, span);
      }
    }
  }
  // ..
}
```

## hystrix

通过 SleuthHystrixConcurrencyStrategy 和 TraceCallable 实现。

主要逻辑是: TraceCallable是一个包装类，在执行真正的操作前后分别调用 span.start 和 span.stop

```java
public class TraceCallable<V> implements Callable<V> {
  //.. 忽略
	public TraceCallable(Tracing tracing, SpanNamer spanNamer, Callable<V> delegate, String name) {
		this.tracer = tracing.tracer();
		this.delegate = delegate;
		this.parent = tracing.currentTraceContext().get();
		this.spanName = name != null ? name : spanNamer.name(delegate, DEFAULT_SPAN_NAME);
	}

	@Override public V call() throws Exception {
		ScopedSpan span = this.tracer.startScopedSpanWithParent(this.spanName, this.parent);
		try {
			return this.delegate.call();
		} catch (Exception | Error e) {
			span.error(e);
			throw e;
		} finally {
			span.finish();
		}
	}
}
```

## Async注解

主要通过切面`TraceAsyncAspect`实现

```java
@Aspect
public class TraceAsyncAspect {

	private static final String CLASS_KEY = "class";
	private static final String METHOD_KEY = "method";

	private final Tracer tracer;
	private final SpanNamer spanNamer;

	public TraceAsyncAspect(Tracer tracer, SpanNamer spanNamer) {
		this.tracer = tracer;
		this.spanNamer = spanNamer;
	}

	@Around("execution (@org.springframework.scheduling.annotation.Async  * *.*(..))")
	public Object traceBackgroundThread(final ProceedingJoinPoint pjp) throws Throwable {
		String spanName = name(pjp);
		Span span = this.tracer.currentSpan();
		if (span == null) {
			span = this.tracer.nextSpan();
		}
		span = span.name(spanName);
		try(Tracer.SpanInScope ws = this.tracer.withSpanInScope(span.start())) {
			span.tag(CLASS_KEY, pjp.getTarget().getClass().getSimpleName());
			span.tag(METHOD_KEY, pjp.getSignature().getName());
			return pjp.proceed();
		} finally {
			span.finish();
		}
	}

	String name(ProceedingJoinPoint pjp) {
		return this.spanNamer.name(getMethod(pjp, pjp.getTarget()),
				SpanNameUtil.toLowerHyphen(pjp.getSignature().getName()));
	}

	private Method getMethod(ProceedingJoinPoint pjp, Object object) {
		MethodSignature signature = (MethodSignature) pjp.getSignature();
		Method method = signature.getMethod();
		return ReflectionUtils
				.findMethod(object.getClass(), method.getName(), method.getParameterTypes());
	}
}
```


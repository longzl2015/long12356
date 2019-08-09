---

title: 微服务-gateway

date: 2019-08-06 12:44:00

categories: [spring,springcloud,gateway]

tags: [spring,springcloud,gateway]

---

[TOC]

在使用gateway的过程中，主要介绍 重试机制、重试时均衡负载器是否作用、超时机制。

##重试机制

gateway 若要实现重试机制，可以使用 `RetryGatewayFilterFactory`

### yml配置

```yaml
spring:
  application:
    name: gateway
  cloud:
    gateway:
      discovery:
        locator:
          enabled: true
          lowerCaseServiceId: true
          filters:
            - name: Retry
              args:
                retries: 3
                series:
                  - SERVER_ERROR
                methods:
                  - GET
                  - POST
```

- retries：重试次数，默认值是3次

- series：状态码配置，符合的某段状态码才会进行重试逻辑，默认值是SERVER_ERROR，值是5，也就是5XX(5开头的状态码)，共有5个值：

  ```java
  public enum Series {
    INFORMATIONAL(1),
    SUCCESSFUL(2),
    REDIRECTION(3),
    CLIENT_ERROR(4),
    SERVER_ERROR(5);
  }
  ```

- statuses：状态码配置，和series不同的是，statuses表示的是具体状态码的配置，取值请参考：org.springframework.http.HttpStatus

- methods：指定哪些方法的请求需要进行重试逻辑，默认值是GET方法，取值如下：

  ```java
  public enum HttpMethod {
    GET, HEAD, POST, PUT, PATCH, DELETE, OPTIONS, TRACE;
  }
  ```

- exceptions：指定哪些异常需要进行重试逻辑，默认值是java.io.IOException

### Retry源码

```java
public class RetryGatewayFilterFactory extends AbstractGatewayFilterFactory<RetryGatewayFilterFactory.RetryConfig> {

	public static final String RETRY_ITERATION_KEY = "retry_iteration";
	
	@Override
	public GatewayFilter apply(RetryConfig retryConfig) {
		retryConfig.validate();

		Repeat<ServerWebExchange> statusCodeRepeat = null;
    // Statuses 或者 Series 不为空
		if (!retryConfig.getStatuses().isEmpty() || !retryConfig.getSeries().isEmpty()) {
			Predicate<RepeatContext<ServerWebExchange>> repeatPredicate = context -> {
				ServerWebExchange exchange = context.applicationContext();
        // 判断迭代次数已达到最大设定值
				if (exceedsMaxIterations(exchange, retryConfig)) {
					return false;
				}
				HttpStatus statusCode = exchange.getResponse().getStatusCode();
				HttpMethod httpMethod = exchange.getRequest().getMethod();
				// 判断 状态码是否在 Statuses 中
				boolean retryableStatusCode = retryConfig.getStatuses().contains(statusCode);

				if (!retryableStatusCode && statusCode != null) { 
					// 判断 状态码 是否与 Series 匹配
					retryableStatusCode = retryConfig.getSeries().stream()
							.anyMatch(series -> statusCode.series().equals(series));
				}
					// 判断 请求方法 是否在 Methods 中
				boolean retryableMethod = retryConfig.getMethods().contains(httpMethod);
				return retryableMethod && retryableStatusCode;
			};
      // 若 满足[Series||Statuses] && 满足[Methods] && 小于[MaxIterations]
      // 则 重试
			statusCodeRepeat = Repeat.onlyIf(repeatPredicate)
					.doOnRepeat(context -> reset(context.applicationContext()));
		}

		Retry<ServerWebExchange> exceptionRetry = null;
		if (!retryConfig.getExceptions().isEmpty()) {
			Predicate<RetryContext<ServerWebExchange>> retryContextPredicate = context -> {
				if (exceedsMaxIterations(context.applicationContext(), retryConfig)) {
					return false;
				}

				for (Class<? extends Throwable> clazz : retryConfig.getExceptions()) {
					if (clazz.isInstance(context.exception())) {
						return true;
					}
				}
				return false;
			};
      // 若 满足 小于[MaxIterations] && 满足[Exceptions]
      // 则 重试
			exceptionRetry = Retry.onlyIf(retryContextPredicate)
					.doOnRetry(context -> reset(context.applicationContext()))
					.retryMax(retryConfig.getRetries());
		}
		return apply(statusCodeRepeat, exceptionRetry);
	}
  //...
}
```

从源码得出的重试规则(满意其中一条规则即可)

- 满足[Series||Statuses] && 满足[Methods] && 小于[MaxIterations]
- 满足 小于[MaxIterations] && 满足[Exceptions]

##重试: 是否会调用均衡负载

我们先了解下 gateway的均衡负载过滤器的实现源码。如下

```java
public class LoadBalancerClientFilter implements GlobalFilter, Ordered {

	private static final Log log = LogFactory.getLog(LoadBalancerClientFilter.class);
	public static final int LOAD_BALANCER_CLIENT_FILTER_ORDER = 10100;

	protected final LoadBalancerClient loadBalancer;

	public LoadBalancerClientFilter(LoadBalancerClient loadBalancer) {
		this.loadBalancer = loadBalancer;
	}

	@Override
	public int getOrder() {
		return LOAD_BALANCER_CLIENT_FILTER_ORDER;
	}

	@Override
	public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
    //...
		// 根据 ServiceId 选择 服务实例
		final ServiceInstance instance = choose(exchange);
		// 重写 url
		URI requestUrl = loadBalancer.reconstructURI(new DelegatingServiceInstance(instance, overrideScheme), uri);
    //重写 GATEWAY_REQUEST_URL_ATTR
		exchange.getAttributes().put(GATEWAY_REQUEST_URL_ATTR, requestUrl);
		return chain.filter(exchange);
	}

	protected ServiceInstance choose(ServerWebExchange exchange) {
    // RibbonLoadBalancerClient
		return loadBalancer.choose(((URI) exchange.getAttribute(GATEWAY_REQUEST_URL_ATTR)).getHost());
	}
  // ...
}

```



## 超时机制

gateway的自动配置类为 `org.springframework.cloud.gateway.config.GatewayAutoConfiguration`。

通过该类可以看到 gateway 使用的 HttpClient 是基于 netty 的，HttpClient 支持的相关配置信息可以查看 `org.springframework.cloud.gateway.config.HttpClientProperties`。关于超时的参数有:

- spring.cloud.gateway.httpclient.connectTimeout
- spring.cloud.gateway.httpclient.responseTimeout



## 优质blog

[Spring-Cloud-Gateway 源码解析](http://www.iocoder.cn/categories/Spring-Cloud-Gateway/?vip)
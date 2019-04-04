---

title: 微服务-feign-hystrix-ribbon超时问题

date: 2019-03-20 20:36:00

categories: [spring,springcloud]

tags: [spring,springcloud]

---


本节介绍 feign-hystrix-ribbon 的超时问题


<!--more-->



## Hystrix 和 Ribbon

hystrix的超时时间 和 ribbon的超时时间 正确关系:

```basic
hystrixTimeout > (ribbonReadTimeout + ribbonConnectTimeout) * (maxAutoRetries + 1) * (maxAutoRetriesNextServer + 1)
```



### Ribbon 的 ConnectTimeout 和 ReadTimeout 生效位置

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










## 相关文章

https://deanwangpro.com/2018/04/13/zuul-hytrix-ribbon-timeout/

https://github.com/spring-cloud/spring-cloud-netflix/blob/master/spring-cloud-netflix-zuul/src/main/java/org/springframework/cloud/netflix/zuul/filters/route/support/AbstractRibbonCommand.java
---

title: 微服务-Ribbon-概述

date: 2019-08-05 00:10:08

categories: [spring,springcloud,ribbon]

tags: [spring,springcloud,ribbon]

---


本节介绍 Ribbon: 一个基于 HTTP 请求的客户端负载均衡器

<!--more-->

## 使用例子

开启均衡负载功能

```java
@EnableDiscoveryClient //开启服务发现的能力
@SpringBootApplication
public class EurekaConsumerApplication {

    @Bean //定义 REST 客户端，RestTemplate 实例
    @LoadBalanced //开启负载均衡的能力
    RestTemplate restTemplate() {
        return new RestTemplate();
    }
    public static void main(String[] args) {
        SpringApplication.run(EurekaConsumerApplication.class, args);
    }
}
```

使用均衡负载功能

```java
@RestController
public class ConsumerController {
    @Autowired
    private RestTemplate restTemplate;
    @GetMapping(value = "/add")
    public String add() {
        return restTemplate.getForEntity("http://COMPUTE-SERVICE/add?a=10&b=20", String.class).getBody();
    }
}
```



## 原理概述

1. 获取 `@LoadBalanced` 注解标记的`RestTemplate`。

2. 为上述`RestTemplate` 添加一个拦截器(filter): 当使用 `RestTemplate` 发起http调用时进行拦截。

3. 拦截到请求时，通过服务名获取该次请求的服务集群的全部列表信息。

4. 根据规则从集群中选取一个服务作为此次请求访问的目标。

5. 访问该目标，并获取返回结果。

## 选取服务实例过程

![img](/images/微服务-Ribbon/e9998448e095176c2454fafd66ea57ab1511332.png)

![](/images/微服务-Ribbon/cdd4b059.png)


## 其他

### 立即加载

默认情况下Ribbon是懒加载的——首次请求Ribbon相关类才会初始化，这会导致首次请求过慢的问题，你可以配置饥饿加载，让Ribbon在应用启动时就初始化。

```yaml
ribbon:
  eager-load:
    enabled: true
    # 多个用,分隔
    clients: microservice-provider-user
```

### 默认配置

| Bean Type   | Bean Name | Class Name |
| -------------------------- | ------------------------- | -------------------------------- |
| IClientConfig            | ribbonClientConfig      | DefaultClientConfigImpl        |
| IRule                    | ribbonRule              | ZoneAvoidanceRule              |
| IPing                    | ribbonPing              | DummyPing                      |
| ServerList<Server>       | ribbonServerList        | ConfigurationBasedServerList   |
| ServerListFilter<Server> | ribbonServerListFilter  | ZonePreferenceServerListFilter |
| ILoadBalancer            | ribbonLoadBalancer      | ZoneAwareLoadBalancer          |
| ServerListUpdater        | ribbonServerListUpdater | PollingServerListUpdater       |

### 自定义配置

```java
public class CloudProviderConfiguration {
    @Bean
    public IRule ribbonRule(IClientConfig config) {
        return new BestAvailableRule();
    }
}

@FeignClient(name = "cloud-provider")
@RibbonClient(name = "cloud-provider", configuration = CloudProviderConfiguration.class)
public interface UserFeignClient {
// ..
}
```


## 相关文章

https://blog.csdn.net/luanlouis/article/details/83060310

https://github.com/Netflix/ribbon/wiki/Working-with-load-balancers

http://www.itmuch.com/spring-cloud/finchley-8/

https://my.oschina.net/javamaster/blog/2985895

http://blog.didispace.com/springcloud-sourcecode-ribbon/

[ppt](https://docs.google.com/presentation/d/1bF8PpsQjUCppsjqq70KtECQSPUtPHyG335OSc3vSLog/edit?usp=sharing)

http://www.spring4all.com/article/230
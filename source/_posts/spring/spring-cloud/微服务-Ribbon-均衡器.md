---

title: 微服务-Ribbon-均衡负载器

date: 2019-08-05 00:10:08

categories: [spring,springcloud,ribbon]

tags: [spring,springcloud,ribbon]

---


BaseLoadBalancer 在Ribbon中起着至关重要的作用，在该类中定义了很多关于负载均衡器相关的基础内容。ZoneAwareLoadBalancer和DynamicServerListLoadBalancer都是 BaseLoadBalancer 的子类。

<!--more-->

在一个应用中: 一个服务名 对应 一个 ILoadBalancer.

## 均衡负载器

![](/images/微服务-Ribbon/c5ca7e83.png)





### PingTask

BaseLoadBalancer 在初始化时，会调用一个 setupPingTask().

```java
protected Timer lbTimer = null;

void setupPingTask() {
    if (canSkipPing()) {
        return;
    }
    if (lbTimer != null) {
        lbTimer.cancel();
    }
    lbTimer = new ShutdownEnabledTimer("NFLoadBalancer-PingTimer-" + name,
            true);
    // 定时 使用指定 PingStrategy ，检查 实例 是否为 up 
    lbTimer.schedule(new PingTask(), 0, pingIntervalSeconds * 1000);
    forceQuickPing();
}
```

PingTask 仅仅负责实例的状态信息，没有能力 进行 服务列表的增删。

## BaseLoadBalancer

```java
public class BaseLoadBalancer extends AbstractLoadBalancer implements
        PrimeConnections.PrimeConnectionListener, IClientConfigAware {
  
    private final static IRule DEFAULT_RULE = new RoundRobinRule();
    protected IRule rule = DEFAULT_RULE;
    protected IPingStrategy pingStrategy = DEFAULT_PING_STRATEGY;
    protected IPing ping = null;
    /*
     * Get the alive server dedicated to key
     * 
     * @return the dedicated server
     */
    public Server chooseServer(Object key) {
        if (counter == null) {
            counter = createCounter();
        }
        counter.increment();
        if (rule == null) {
            return null;
        } else {
            try {
                return rule.choose(key);
            } catch (Exception e) {
                logger.warn("LoadBalancer [{}]:  Error choosing server for key {}", name, key, e);
                return null;
            }
        }
    }
}

```

[Spring Cloud Ribbon 源码分析](http://www.iocoder.cn/Ribbon/saleson/spring-cloud-ribbon/)
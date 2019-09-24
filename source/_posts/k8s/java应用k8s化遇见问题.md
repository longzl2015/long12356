---

title: java应用k8s化遇见问题

date: 2019-08-17 16:00:28

categories: [k8s]

tags: [k8s]

---

记录java程序docker化过程中，遇到的问题

<!--more-->

## eureka

将 eureka 进行docker化时，配置如下:

```
spring:
  profiles: docker
eureka:
  instance:
    # prefer-ip-address 必须使用 false
    prefer-ip-address: false
    # hostname 必须与 serviceUrl.defaultZone 中的主机名一致。否则会出现 unavailable-replicas
    hostname: ${HOSTNAME}.eureka
  client:
    serviceUrl:
      # k8s中 pod模版 必须为 eureka，服务名也必须是 eureka
      defaultZone: http://eureka-0.eureka:8761/eureka/,http://eureka-1.eureka:8761/eureka/
```

https://github.com/Netflix/eureka/issues/1008

还有一个需要注意:

必须在 k8s 中将 eureka 服务设置为 StatefulSet。因为 Eureka Client 需要将自己的信息注册到每一个 Eureka Server 中。

## 远程调试的问题

1. 每个 dockerfile 中都添加了 `-agentlib:jdwp=transport=dt_socket,address=5005,server=y,suspend=n`便于远程调试。
2. 在编写k8s的pod模版时，通常需要添加监控检测。

在进行远程调试的过程中，一旦超过`监控检测`的时限，pod容器就会重启。

## jdk 的docker支持

https://blog.softwaremill.com/docker-support-in-new-java-8-finally-fd595df0ca54

https://www.oracle.com/technetwork/java/javase/8u191-relnotes-5032181.html

使用 jdk8_191版本默认启用 UseContainerSupport
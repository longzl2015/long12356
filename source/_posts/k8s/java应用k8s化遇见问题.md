---

title: java应用k8s化遇见问题

date: 2019-07-07 16:00:28

categories: [k8s]

tags: [k8s]

---





## eureka

配置

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
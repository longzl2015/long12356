---

title: 微服务-eureka

date: 2019-08-05 00:10:02

categories: [spring,springcloud,eureka]

tags: [spring,springcloud,eureka]

---



eureka 用于服务发现

<!--more-->

## eureka支持的rest-http 

eureka 支持的rest http:

| Operation                                  | HTTP action                                                  | Description                                                  |
| ------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| Register new application instance          | POST /eureka/apps/appID                                      | Input: JSON/XML payload HTTPCode: 204 on success             |
| De-register application instance           | DELETE /eureka/apps/appID/instanceID                         | HTTP Code: 200 on success                                    |
| Send application instance heartbeat        | PUT /eureka/apps/appID/instanceID                            | HTTP Code:  200 on success ;404 if instanceID doesn’t exist  |
| Query for all instances                    | GET /eureka/apps                                             | HTTP Code: 200 on success Output: JSON/XML                   |
| 请求指定appId的信息                        | GET /eureka/apps/appID                                       | HTTP Code: 200 on success Output: JSON/XML                   |
| 请求指定appId/instanceId                   | GET /eureka/apps/appID/instanceID                            | HTTP Code: 200 on success Output: JSON/XML                   |
| 请求指定instanceID                         | GET /eureka/instances/instanceID                             | HTTP Code: 200 on success Output: JSON/XML                   |
| 将实例标记为`不服务`状态                   | PUT /eureka/apps/appID/instanceID/status?value=OUT_OF_SERVICE | HTTP Code: 200 on success; 500 on failure                    |
| 将实例标记回`服务`状态                     | DELETE /eureka/apps/appID/instanceID/status?value=UP         | HTTP Code:  200 on success; 500 on failure                   |
| 更新 metadata                              | PUT /eureka/apps/appID/instanceID/metadata?key=value         | HTTP Code:  200 on success; 500 on failure                   |
| 获取指定 vip address(虚拟主机名)的实例信息 | GET /eureka/vips/vipAddress                                  | HTTP Code: 200 on success Output: JSON/XML; 404 if the vipAddress does not exist. |
| 获取指定 secure vip address的实例信息      | GET /eureka/svips/svipAddress                                | HTTP Code: 200 on success Output: JSON/XML; 404 if the svipAddress does not exist. |

## eureka 密码访问

http://www.itmuch.com/spring-cloud/finchley-out-1-eureka-security/

1. SpringSecurity 配置http保护
2. defaultZone 的 url 采用如下形式。

```yaml
eureka:
  client:
    service-url:
      defaultZone: http://user:password123@localhost:8761/eureka/
```




## 参考

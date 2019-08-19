---

title: springboot-4-外部配置优先级

date: 2019-08-05 00:00:04

categories: [spring,springboot]

tags: [spring,springboot]

---



https://docs.spring.io/spring-boot/docs/current/reference/html/boot-features-external-config.html



1. 当启用devtools时，当前用户目录下的`~/.spring-boot-devtools.properties` 配置。[Devtools global settings properties](https://docs.spring.io/spring-boot/docs/current/reference/html/using-boot-devtools.html#using-boot-devtools-globalsettings) 
2. 测试时的 [`@TestPropertySource`](https://docs.spring.io/spring/docs/5.1.8.RELEASE/javadoc-api/org/springframework/test/context/TestPropertySource.html) 注解
3. `properties` attribute on your tests. Available on [`@SpringBootTest`](https://docs.spring.io/spring-boot/docs/2.1.6.RELEASE/api/org/springframework/boot/test/context/SpringBootTest.html) and the [test annotations for testing a particular slice of your application](https://docs.spring.io/spring-boot/docs/current/reference/html/boot-features-testing.html#boot-features-testing-spring-boot-applications-testing-autoconfigured-tests).
4. 命令行参数
5. Properties from `SPRING_APPLICATION_JSON` (inline JSON embedded in an environment variable or system property).
6. `ServletConfig` init parameters.
7. `ServletContext` init parameters.
8. JNDI attributes from `java:comp/env`.
9. java系统变量 `System.getProperties()`
10. 操作系统环境变量
11. A `RandomValuePropertySource` that has properties only in `random.*`.
12. jar包外的 `application-{profile}.properties` and  `application-{profile}.yml`。[Profile-specific application properties](https://docs.spring.io/spring-boot/docs/current/reference/html/boot-features-external-config.html#boot-features-external-config-profile-specific-properties)
13. jar包内的 `application-{profile}.properties` and  `application-{profile}.yml`。[Profile-specific application properties](https://docs.spring.io/spring-boot/docs/current/reference/html/boot-features-external-config.html#boot-features-external-config-profile-specific-properties)
14. jar包外的 `application.properties` and  `application.yml`。
15. jar包内的 `application.properties` and  `application.yml`。
16. @Configuration类上的[`@PropertySource`](https://docs.spring.io/spring/docs/5.1.8.RELEASE/javadoc-api/org/springframework/context/annotation/PropertySource.html) 注解
17. 默认属性(specified by setting `SpringApplication.setDefaultProperties`)



若有 spring cloud config，默认情况 以 远端配置为准。


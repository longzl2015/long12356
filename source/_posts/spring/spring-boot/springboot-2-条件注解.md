---

title: springboot-2-条件注解

date: 2019-08-05 00:00:02

categories: [spring,springboot]

tags: [springboot]

---


springboot 的条件注解


<!--more-->

@ConditionalOnBean	配置了某个特定的Bean
@ConditionalOnMissingBean	没有配置特定的Bean
@ConditionalOnClass	Classpath里有指定的类
@ConditionalOnMissingClass	Classpath里没有指定的类
@ConditionalOnExpression	给定的Spring Expression Language (SpEL)表达式计算结果为True
@ConditionalOnJava	Java的版本匹配特定值或者一个范围值
@ConditionalOnJndi	参数值给定的JNDI位置必须存在一个，如果没有参数，则要有JNDI InitialContext
@ConditionalOnProperty	制定的配置属性要有一个明确的值
@ConditionalOnResource	Classpath里有指定的资源
@ConditionalOnWebApplication	这是一个web应用程序
@ConditionalOnNotWebApplication	这不是一个web应用程序

### ConditionalOnProperty

当结果为 yes 时，表示通过 `@ConditionalOnProperty`注解的类可以生效。

| Property Value | havingValue="" | havingValue="true" | havingValue="false" | havingValue="foo" |
| -------------- | -------------- | ------------------ | ------------------- | ----------------- |
| "true"         | yes            | yes                | no                  | no                |
| "false"        | no             | no                 | yes                 | no                |
| "foo"          | yes            | no                 | no                  | yes               |




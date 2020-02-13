---
title: spring-4-事务与AOP的优先级
date: 2019-06-09 11:09:04
tags: [aop,事务管理]
categories: [spring,springmvc]
---

事务与AOP的优先级

<!--more-->

事务的优先级最低

如何定义AOP优先级

- Aspect 类添加注解：org.springframework.core.annotation.Order，使用注解value属性指定优先级。  
- Aspect 类实现接口：org.springframework.core.Ordered，实现 Ordered 接口的 getOrder() 方法。

## 来源

https://docs.spring.io/spring/docs/current/spring-framework-reference/core.html#aop-ataspectj-advice-ordering
https://blog.csdn.net/qq_32331073/article/details/80596084
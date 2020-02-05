---
title: spring-3-AOP-基本概念.md
date: 2019-06-09 11:09:04
tags: [spring,aop]
categories: [spring,springmvc]
---

[TOC]

<!--more-->

# AOP概念

即面向切面编程，横切关注点分离和织入。可以用于日志、事务处理权限控制等。

## AOP相关定义

- 切面（Aspect）
- 连接点（Joinpoint）
- 通知（Advice）
- 切入点（Pointcut）

- 引入（Introduction）
- 目标对象（Target Object）
- AOP代理（AOP Proxy）
- 织入（Weaving）

## JoinPoin 

下面简要介绍JponPoint的方法：

1.java.lang.Object[] getArgs()：获取连接点方法运行时的入参列表；
2.Signature getSignature() ：获取连接点的方法签名对象；
3.java.lang.Object getTarget() ：获取连接点所在的目标对象；
4.java.lang.Object getThis() ：获取代理对象本身；


### AOP 的 同类调用问题

```
启用注解 @EnableAspectJAutoProxy(exposeProxy = true)
  
获取代理对象并执行方法 ((Service) AopContext.currentProxy()).callMethodB();  
```



## 来源

[](http://www.importnew.com/28342.html)
[](http://www.uml.org.cn/j2ee/201301102.asp)

https://www.jianshu.com/p/b95365bb323c

[官方文档](https://docs.spring.io/spring/docs/current/spring-framework-reference/core.html#aop)

[AopContext](https://www.threeperson.com/users/zld406504302/articles/2073)
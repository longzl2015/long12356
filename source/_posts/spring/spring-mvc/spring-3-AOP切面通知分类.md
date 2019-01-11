---
title: spring-3-AOP-切面通知详解
date: 2015-8-11 21:21:44
tags: aop
categories: spring
---

## 前置通知:

```xml
@Before("execution(public int com.atguigu.spring.aop.ArithmeticCalculator.*(int, int))")
```

  @Before 表示在目标方法执行之前执行 @Before 标记的方法的方法体.
  @Before 里面的是切入点表达式:
  在通知中访问连接细节: 可以在通知方法中添加 JoinPoint 类型的参数, 从中可以访问到方法的签名和方法的参数.

实例：

```java
	/**
	 * execution(* org.zttc.itat.spring.dao.*.add*(..))
	 * 第一个*表示任意返回值
	 * 第二个*表示 org.zttc.itat.spring.dao包中的所有类
	 * 第三个*表示以add开头的所有方法
	 * (..)表示任意参数
	 */
	@Before("execution(* org.zttc.itat.spring.dao.*.add*(..))||" +
			"execution(* org.zttc.itat.spring.dao.*.delete*(..))||" +
			"execution(* org.zttc.itat.spring.dao.*.update*(..))")
	public void logStart(JoinPoint jp) {
		//得到执行的对象
		System.out.println(jp.getTarget());
		//得到执行的方法
		System.out.println(jp.getSignature().getName());
		Logger.info("加入日志");
	}
```

## 后置通知:

```xml
@After("execution(public int com.atguigu.spring.aop.ArithmeticCalculator.*(int, int))")
```

  @After 在方法执行之后（无论是否发生异常）执行的代码.在后置通知中不能访问目标方法执行的结果

## 返回通知:
```xml
@AfterReturning(value="execution(public int com.atguigu.spring.aop.ArithmeticCalculator.*(int, int))"，returning="result")
```

  @AfterReturning 在方法**正常**结束后执行。

## 异常通知:
```xml
@AfterThrowing(value="execution(public int com.atguigu.spring.aop.ArithmeticCalculator.*(int, int))"，throwing="result")
```
  @AfterThrowing 在方法**异常**时执行，可以访问到异常对象，而且可以指定特定异常通知。

## 环绕通知:
```xml
@Around("execution(public int com.atguigu.spring.aop.ArithmeticCalculator.*(int, int))")
```
  @Around 环绕通知需要携带ProcessdingJoinPoint类型的参数。

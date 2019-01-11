---
title: spring-3-AOP-创建过程（基于注解和基于xml）
date: 2015-08-11 15:09:28
tags: aop
categories: spring
---

AOP 基于注解和基于xml的写法
<!--more-->

# 0 前期准备

## 加入 jar 包
  com.springsource.net.sf.cglib-2.2.0.jar  
  com.springsource.org.aopalliance-1.0.0.jar  
  com.springsource.org.aspectj.weaver-1.6.8.RELEASE.jar  
  spring-aspects-4.0.0.RELEASE.jar  
  ......
## 在 Spring 的配置文件头部加入 aop 的命名空间。

```xml
  <beans xmlns="http://www.springframework.org/schema/beans"
     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
     xmlns:aop="http://www.springframework.org/schema/aop"
     xmlns:context="http://www.springframework.org/schema/context"
     xsi:schemaLocation="http://www.springframework.org/schema/beans
         http://www.springframework.org/schema/beans/spring-beans-3.0.xsd
         http://www.springframework.org/schema/context
         http://www.springframework.org/schema/context/spring-context-3.0.xsd
         http://www.springframework.org/schema/aop
         http://www.springframework.org/schema/aop/spring-aop-3.0.xsd">
```

# 1 基于注解使用AOP

## 1.1 在配置文件xml中

```xml
//打开注解支持
<context:annotation-config/>
```

```xml
//配置自动扫描的包
<context:component-scan base-package="com.atguigu.spring.aop"></context:component-scan>
```

```xml
//使 AspjectJ 注解起作用，使匹配的类自动生成动态代理对象
<aop:aspectj-autoproxy></aop:aspectj-autoproxy>
```

## 1.2 编写切面aspectj类:

1. 一个一般的 Java 类
1. 在其中添加要额外实现的功能.
1. 切面必须是 IOC 中的 bean:
1. 声明是一个切面: 添加 @Aspect
1. 声明通知: 即额外加入功能对应的方法.

```java
@Component("logAspect")//让这个切面类被Spring所管理
@Aspect//申明这个类是一个切面类
public class LogAspect {
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
	/**
	 * 函数调用完成之后执行
	 * @param jp
	 */
	@After("execution(* org.zttc.itat.spring.dao.*.add*(..))||" +
			"execution(* org.zttc.itat.spring.dao.*.delete*(..))||" +
			"execution(* org.zttc.itat.spring.dao.*.update*(..))")
	public void logEnd(JoinPoint jp) {
		Logger.info("方法调用结束加入日志");
	}

	/**
	 * 函数调用中执行
	 * @param pjp
	 * @throws Throwable
	 */
	@Around("execution(* org.zttc.itat.spring.dao.*.add*(..))||" +
			"execution(* org.zttc.itat.spring.dao.*.delete*(..))||" +
			"execution(* org.zttc.itat.spring.dao.*.update*(..))")
	public void logAround(ProceedingJoinPoint pjp) throws Throwable {
		Logger.info("开始在Around中加入日志");
		pjp.proceed();//执行程序
		Logger.info("结束Around");
	}

}
```

#  2 基于xml使用AOP

## 2.1 在配置文件xml中，基于"xml"的方式来使用 AOP

```xml
//打开注解支持
<context:annotation-config/>
```

```xml
//配置自动扫描的包
<context:component-scan base-package="com.atguigu.spring.aop"></context:component-scan>
```

```xml
   <aop:config>
   <!-- 定义切面 -->
   		<aop:aspect id="myLogAspect" ref="logAspect">
   		<!-- 在哪些位置加入相应的Aspect -->
   			<aop:pointcut id="logPointCut" expression="execution(* org.zttc.itat.spring.dao.*.add*(..))||
   							execution(* org.zttc.itat.spring.dao.*.delete*(..))||
   							execution(* org.zttc.itat.spring.dao.*.update*(..))"/>
   			<aop:before method="logStart" pointcut-ref="logPointCut"/>
   			<aop:after method="logEnd" pointcut-ref="logPointCut"/>
   			<aop:around method="logAround" pointcut-ref="logPointCut"/>
   		</aop:aspect>
   </aop:config>
```

### 2.2 编写切面aspectj类:

```java
@Component("logAspect")//让这个切面类被Spring所管理
public class LogAspect {

	public void logStart(JoinPoint jp) {
		//得到执行的对象
		System.out.println(jp.getTarget());
		//得到执行的方法
		System.out.println(jp.getSignature().getName());
		Logger.info("加入日志");
	}
	public void logEnd(JoinPoint jp) {
		Logger.info("方法调用结束加入日志");
	}

	public void logAround(ProceedingJoinPoint pjp) throws Throwable {
		Logger.info("开始在Around中加入日志");
		pjp.proceed();//执行程序
		Logger.info("结束Around");
	}

}
```


----
[AOP切面通知详解](../AOP切面通知分类)

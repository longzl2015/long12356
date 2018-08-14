---
title: SpringIoC
date: 2016-03-16 20:56:37
tags: [spring,ioc]
---

[TOC]

<!--more-->


# IOC概念

## 传统方法

在每个对象使用他的合作对象时，都需要使用 new object 这类的语句来完成对象的申请工作。

缺点: 对象的耦合度较高。

## IOC方法
IoC容器就是具有依赖注入功能的容器，IoC容器负责实例化、定位、配置应用程序中的对象及建立这些对象间的依赖。

在Spring中 BeanFactory 是IoC容器的实际代表者。

Spring IoC容器利用读取配置文件中的配置元数据，对应用中的各个对象进行实例化及装配。一般使用基于xml配置文件进行配置元数据。

## 依赖注入

spring中依赖注入分为两种：

- 设值注入：使用property参数
- 构造注入：使用constructor-arg参数

# IOC容器详解

## bean

由IoC容器管理的各种对象叫做Bean。spring通过元数据中的相关信息来确定如何实例化Bean、管理Bean之间的依赖关系以及管理Bean。

## spring IOC容器

IOC容器有两个接口： beanFactory 和 applicationContext 。

### beanFactory接口

beanFactory是Spring容器最基本的接口，负责配置、创建、管理bean。

主要有以下方法：

- boolean containsBean(String name)
- <T> T getBean(Class<T> requiredType)
- Object getBean(String name)
- <T> T getBean(String name,Class requiredType)
...

### applicationContext接口

ApplicationContext接口扩展了BeanFactory，还提供了与Spring AOP集成、国际化处理、事件传播及提供不同层次的context实现。

主要方法：

- Object getBean(String name)
- T getBean(String name, Class<T> requiredType)
- T getBean(Class<T> requiredType)
- Map<String, T> getBeansOfType(Class<T> type)

常用实现类：

- FileSystemXmlApplicationContext：从文件系统获取配置文件
- ClassPathXmlApplicationContext：从classpath获取配置文件
- WebXmlApplicationContext

# IOC初始化过程

![springIOC初始化流程](http://7xlgbq.com1.z0.glb.clouddn.com/springIOC初始化流程.jpg "springIOC初始化流程")

__bean-xml文件__

```xml
<bean id="XiaoWang" class="com.springstudy.talentshow.SuperInstrumentalist">
    <property name="instruments">
        <list>
            <ref bean="piano"/>
            <ref bean="saxophone"/>
        </list>
    </property>
</bean>
```

__调用栈过程__

![springioc调用栈过程](http://7xlgbq.com1.z0.glb.clouddn.com/springioc调用栈过程.jpg "springioc调用栈过程")

__依赖注入过程__

![springioc依赖注入过程](http://7xlgbq.com1.z0.glb.clouddn.com/springioc依赖注入过程.jpg "springioc依赖注入过程")

----

[Spring-IOC核心源码学习](http://yikun.github.io/2015/05/29/Spring-IOC%E6%A0%B8%E5%BF%83%E6%BA%90%E7%A0%81%E5%AD%A6%E4%B9%A0/)
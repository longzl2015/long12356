---
title: spring-1-Hello world
date: 2019-06-09 11:09:00
tags: spring
categories: [spring,springmvc]
---

创建一个spring的hello world项目。

<!--more-->

## 第一个spring项目

1、导入spring的dist中的jar包和commons-logging包

2、在src目录下创建相应的beans.xml

3、为beans.xml添加相应的schema

```xml
<beans xmlns="http://www.springframework.org/schema/beans"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.springframework.org/schema/beans
    http://www.springframework.org/schema/beans/spring-beans-3.0.xsd">
</beans>
```

4、新建一个类：为每一个依赖类创建相应的getter和setter方法


5、在beans.xml中创建对象


```xml
    <!-- 创建如下bean等于完成了:HelloWorld helloWorld = new HelloWorld-->
    <bean id="helloWorld" class="org.zttc.itat.spring.model.HelloWorld"/>
```

6、在测试类中使用这个对象

创建Spring的工厂

```java
 private BeanFactory factory = new ClassPathXmlApplicationContext("beans.xml");
```

通过Spring工厂获取相应的对象

```java
  //此处getBean中的helloWorld就是beans.xml配置文件中的id
  HelloWorld hello = factory.getBean("helloWorld",HelloWorld.class);

  HelloWorld hello = (HelloWorld)factory.getBean("helloWorld");
  //此时的hello对象就是被Spring说管理的对象
  System.out.println(hello.hello());
```
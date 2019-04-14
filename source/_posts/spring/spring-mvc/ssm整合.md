---
title: "ssm整合-未写完"
date: 2015-09-04 23:22:58
tag: [mybatis,spring,springmvc]
categories: [spring,springmvc]
---

该文章只讲解整合流程，文章的代码，不是一个完整的例子。
[官网地址](https://mybatis.github.io/spring/zh/getting-started.html)
[SSM框架——详细整合教程（Spring+SpringMVC+MyBatis）](http://blog.csdn.net/zhshulin/article/details/37956105)
<!--more-->


## 1、基本概念

### 1.1、Spring

Spring是一个开源框架，Spring是于2003 年兴起的一个轻量级的Java 开发框架，由Rod Johnson 在其著作Expert One-On-One J2EE Development and Design中阐述的部分理念和原型衍生而来。它是为了解决企业应用开发的复杂性而创建的。Spring使用基本的JavaBean来完成以前只可能由EJB完成的事情。然而，Spring的用途不仅限于服务器端的开发。从简单性、可测试性和松耦合的角度而言，任何Java应用都可以从Spring中受益。 简单来说，Spring是一个轻量级的控制反转（IoC）和面向切面（AOP）的容器框架。

### 1.2、SpringMVC

Spring MVC属于SpringFrameWork的后续产品，已经融合在Spring Web Flow里面。Spring MVC 分离了控制器、模型对象、分派器以及处理程序对象的角色，这种分离让它们更容易进行定制。

### 1.3、MyBatis

MyBatis 本是apache的一个开源项目iBatis, 2010年这个项目由apache software foundation 迁移到了googlecode，并且改名为MyBatis。MyBatis是一个基于Java的持久层框架。iBATIS提供的持久层框架包括SQL Maps和Data Access Objects（DAO）MyBatis 消除了几乎所有的JDBC代码和参数的手工设置以及结果集的检索。MyBatis 使用简单的 XML或注解用于配置和原始映射，将接口和 Java 的POJOs（Plain Old Java Objects，普通的 Java对象）映射成数据库中的记录。

## 2、开发环境搭建


如果需要，参看博文：http://blog.csdn.net/zhshulin/article/details/30779873

## 3、Maven Web项目创建

如果需要，参看博文：http://blog.csdn.net/zhshulin/article/details/37921705

## 4、SSM整合

下面主要介绍三大框架的整合，至于环境的搭建以及项目的创建，参看上面的博文。这次整合，有2个配置文件，包含spring配置文件和spring-mvc的配置文件，此外有2个资源文件：conf.propertis和log4j.properties。完整目录结构如下

![完整目录](/img/ssm整合1.jpg)

使用框架都是较新的版本：
  Spring 4.2.0 RELEASE
  Spring MVC 4.2.0 RELEASE
  MyBatis 3.3.0

### 4.1、Maven引入需要的JAR包(仅加入了spring和mybatis的包)

pom.xml
```xml
	<properties>
		<project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
		<spring-version>4.2.0.RELEASE</spring-version>
	</properties>

	<dependencies>
		<dependency>
			<groupId>junit</groupId>
			<artifactId>junit</artifactId>
			<version>4.10</version>
			<scope>test</scope>
		</dependency>

		<!-- spring -->
		<dependency>
			<groupId>org.springframework</groupId>
			<artifactId>spring-context</artifactId>
			<version>${spring-version}</version>
		</dependency>
		<dependency>
			<groupId>org.springframework</groupId>
			<artifactId>spring-webmvc</artifactId>
			<version>${spring-version}</version>
		</dependency>
		<dependency>
			<groupId>org.springframework</groupId>
			<artifactId>spring-orm</artifactId>
			<version>${spring-version}</version>
		</dependency>
		<dependency>
			<groupId>org.springframework</groupId>
			<artifactId>spring-test</artifactId>
			<version>${spring-version}</version>
		</dependency>

		<!-- mybatis -->
		<dependency>
			<groupId>org.mybatis</groupId>
			<artifactId>mybatis</artifactId>
			<version>3.3.0</version>
		</dependency>

		<dependency>
			<groupId>org.mybatis.generator</groupId>
			<artifactId>mybatis-generator-core</artifactId>
			<version>1.3.2</version>
		</dependency>

		<!-- mybatis和spring -->
		<dependency>
			<groupId>org.mybatis</groupId>
			<artifactId>mybatis-spring</artifactId>
			<version>1.2.3</version>
		</dependency>
		<!-- 数据库 -->
		<dependency>
			<groupId>mysql</groupId>
			<artifactId>mysql-connector-java</artifactId>
			<version>5.1.29</version>
		</dependency>

		<dependency>
			<groupId>c3p0</groupId>
			<artifactId>c3p0</artifactId>
			<version>0.9.1.2</version>
		</dependency>

		<!-- log4j -->
		<dependency>
			<groupId>log4j</groupId>
			<artifactId>log4j</artifactId>
			<version>1.2.17</version>
		</dependency>
	</dependencies>
```


### 4.2、Spring与MyBatis的整合

所有需要的JAR包都引入以后，首先进行Spring与MyBatis的整合，然后再进行JUnit测试。

#### 4.2.1、建立JDBC属性文件

conf.properties（文件编码修改为utf-8）
在这个文件中我添加了mybatis-generator的部分属性。

```
#数据源
driver=com.mysql.jdbc.Driver
url=jdbc:mysql:///mybatis
user=root
password=123456
#定义初始连接数
initialSize=0
#定义最大连接数
maxActive=20
#定义最大连接数
minActive=20
#定义最大空闲
maxIdle=20
#定义最小空闲
minIdle=1
#定义最长等待时间
maxWait=60000

#mybatis
#table在generatorConfig.xml的最下面修改
driverLocation=E:\\repo\\maven\\mysql\\mysql-connector-java\\5.1.29\\mysql-connector-java-5.1.29.jar
javaModelGenerator_targetPackage=com.cst.zju.anime.model
sqlMapGenerator_targetPackage=com.cst.zju.anime.dao
javaClientGenerator_targetPackage=com.cst.zju.anime.dao
```

#### 4.2.2、建立spring.xml配置文件

这个文件就是用来完成spring和mybatis的整合的。这里面也没多少行配置，主要的就是自动扫描，自动注入，配置数据库。注释也很详细，大家看看就明白了。

spring.xml
```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:context="http://www.springframework.org/schema/context"
	xmlns:mybatis-spring="http://mybatis.org/schema/mybatis-spring"
	xmlns:jdbc="http://www.springframework.org/schema/jdbc" xmlns:tx="http://www.springframework.org/schema/tx"
	xsi:schemaLocation="http://www.springframework.org/schema/jdbc http://www.springframework.org/schema/jdbc/spring-jdbc-4.2.xsd
		http://mybatis.org/schema/mybatis-spring http://mybatis.org/schema/mybatis-spring-1.2.xsd
		http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd
		http://www.springframework.org/schema/context http://www.springframework.org/schema/context/spring-context-4.2.xsd
		http://www.springframework.org/schema/tx http://www.springframework.org/schema/tx/spring-tx-4.1.xsd">

	<context:property-placeholder location="classpath:conf.properties" />

	<context:component-scan base-package="com.cst.zju.anime.service" />

	<bean id="dataSource" class="com.mchange.v2.c3p0.ComboPooledDataSource"
		destroy-method="close">

		<property name="driverClass" value="${driver}" />
		<property name="jdbcUrl" value="${url}" />
		<property name="user" value="${user}" />
		<property name="password" value="${password}" />

		<property name="initialPoolSize" value="${initialSize}" />
		<property name="minPoolSize" value="${minActive}" />
		<property name="maxPoolSize" value="${maxActive}" />
		<!--最大空闲时间,60秒内未使用则连接被丢弃。若为0则永不丢弃。Default: 0 -->
		<property name="maxIdleTime" value="${maxIdle}" />
		<!--当连接池中的连接耗尽的时候c3p0一次同时获取的连接数。Default: 3 -->
		<property name="acquireIncrement" value="5" />
		<!--定义在从数据库获取新连接失败后重复尝试的次数。Default: 30 -->
		<property name="acquireRetryAttempts" value="30" />
		<!--JDBC的标准参数，用以控制数据源内加载的PreparedStatements数量。但由于预缓存的statements 属于单个connection而不是整个连接池。所以设置这个参数需要考虑到多方面的因素。
			如果maxStatements与maxStatementsPerConnection均为0，则缓存被关闭。Default: 0 -->
		<property name="maxStatements" value="0" />
		<!--每60秒检查所有连接池中的空闲连接。Default: 0 -->
		<property name="idleConnectionTestPeriod" value="60" />
		<!--获取连接失败将会引起所有等待连接池来获取连接的线程抛出异常。但是数据源仍有效 保留，并在下次调用getConnection()的时候继续尝试获取连接。如果设为true，那么在尝试
			获取连接失败后该数据源将申明已断开并永久关闭。Default: false -->
		<property name="breakAfterAcquireFailure" value="true" />
		<!--因性能消耗大请只在需要的时候使用它。如果设为true那么在每个connection提交的 时候都将校验其有效性。建议使用idleConnectionTestPeriod或automaticTestTable
			等方法来提升连接测试的性能。Default: false -->
		<property name="testConnectionOnCheckout" value="false" />
	</bean>

	<!-- ====== mybatis ===== -->

	<bean id="sqlSessionFactory" class="org.mybatis.spring.SqlSessionFactoryBean">
		<property name="dataSource" ref="dataSource" />
		<property name="typeAliasesPackage" value="com.cst.zju.anime.model" />
		<property name="mapperLocations" value="classpath:mapper/*.xml"/>
	</bean>

	<bean class="org.mybatis.spring.mapper.MapperScannerConfigurer">
		<property name="basePackage" value="com.cst.zju.anime.dao" />
	</bean>

	<!-- 事务管理 -->
	<bean id="transactionManager"
		class="org.springframework.jdbc.datasource.DataSourceTransactionManager">
		<property name="dataSource" ref="dataSource" />
	</bean>

</beans>

```


#### 4.2.3、Log4j的配置

为了方便调试，一般都会使用日志来输出信息，Log4j是Apache的一个开放源代码项目，通过使用Log4j，我们可以控制日志信息输送的目的地是控制台、文件、GUI组件，甚至是套接口服务器、NT的事件记录器、UNIX Syslog守护进程等；我们也可以控制每一条日志的输出格式；通过定义每一条日志信息的级别，我们能够更加细致地控制日志的生成过程。
Log4j的配置很简单，而且也是通用的，下面给出一个基本的配置，换到其他项目中也无需做多大的调整，如果想做调整或者想了解Log4j的各种配置，参看我转载的一篇博文，很详细：
http://blog.csdn.net/zhshulin/article/details/37937365
下面给出配置文件目录：

log4j.properties
```xml
#定义LOG输出级别
log4j.rootLogger=DEBUG,Console,File
#定义日志输出目的地为控制台
log4j.appender.Console=org.apache.log4j.ConsoleAppender
log4j.appender.Console.Target=System.out
#可以灵活地指定日志输出格式，下面一行是指定具体的格式
log4j.appender.Console.layout = org.apache.log4j.PatternLayout
log4j.appender.Console.layout.ConversionPattern=[%c] - %m%n

#文件大小到达指定尺寸的时候产生一个新的文件
log4j.appender.File = org.apache.log4j.RollingFileAppender
#指定输出目录
log4j.appender.File.File = logs/ssm.log
#定义文件最大大小
log4j.appender.File.MaxFileSize = 10MB
# 输出所有日志，如果换成DEBUG表示输出DEBUG以上级别日志
log4j.appender.File.Threshold = ALL
log4j.appender.File.layout = org.apache.log4j.PatternLayout
log4j.appender.File.layout.ConversionPattern =[%p] [%d{yyyy-MM-dd HH\:mm\:ss}][%c]%m%n

#仅输出sql
log4j.logger.java.sql.ResultSet=INFO
log4j.logger.org.apache=INFO
log4j.logger.java.sql.Connection=DEBUG
log4j.logger.java.sql.Statement=DEBUG
log4j.logger.java.sql.PreparedStatement=DEBUG
```


#### 4.2.4、JUnit测试

经过以上步骤（到4.2.2，log4j不配也没影响），我们已经完成了Spring和mybatis的整合，这样我们就可以编写一段测试代码来试试是否成功了。


##### 4.2.4.1、创建测试用表
既然我们需要测试，那么我们就需要建立在数据库中建立一个测试表.

##### 4.2.4.2、利用MyBatis Generator自动创建代码
参考博文：http://blog.csdn.net/zhshulin/article/details/23912615
生成分页博文：http://blog.csdn.net/yuanlaishini2010/article/details/40829417

这个可根据表自动创建实体类、MyBatis映射文件以及DAO接口。由于 intellij 的编译器明确了要将资源文件放到resources中，我们需要将mapper.xml放到resources的mapper文件夹中。这样，intellij运行时就不会出现
`org.apache.ibatis.binding.BindingException: Invalid bound statement (not found): `
自动生成完成后，将文件复制到工程中。如图：
![目录结构](/img/ssm整合2.jpg)

##### 4.2.4.3、建立Service接口和实现类

目录结构：
![目录结构](/img/ssm整合3.jpg)

下面给出具体的内容：

IAnimeService.jave
```java
package com.cst.zju.anime.service;

import java.util.List;

import com.cst.zju.anime.model.Anime;
import com.cst.zju.anime.model.Detail;

public interface IAnimeService {

	public Detail getDetailDyID(int ID);
}

```

UserServiceImpl.java

```java
@Service
public class AnimeServiceImpl implements IAnimeService {

	@SuppressWarnings("restriction")
	@Resource
	private DetailMapper detailMapper;

	public Detail getDetailDyID(int ID) {

		return this.detailMapper.selectByPrimaryKey(ID);
	}

```

##### 4.2.4.4、建立测试类

测试类在src/test/java中建立，下面测试类中注释掉的部分是不使用Spring时，一般情况下的一种测试方法；如果使用了Spring那么就可以使用注解的方式来引入配置文件和类，然后再将service接口对象注入，就可以进行测试了。
如果测试成功，表示Spring和Mybatis已经整合成功了。输出信息使用的是Log4j打印到控制台。

```java
package com.cst.zju.anime.testMybatis;

import javax.annotation.Resource;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.junit4.SpringJUnit4ClassRunner;

import com.cst.zju.anime.service.impl.AnimeServiceImpl;

@RunWith(SpringJUnit4ClassRunner.class)
@ContextConfiguration(locations={"classpath:spring.xml"})
public class TestMybatis {

//	private ApplicationContext ac = null;

	@Resource
	private AnimeServiceImpl animeService = null;

//	@Before
//	public void before() {
//		ac = new ClassPathXmlApplicationContext("spring.xml");
//		animeService = (IAnimeService) ac.getBean("animeServiceImpl");
//	}

	@Test
	public void testNewSerial() {
		System.out.println("=========================================");
		System.out.println(animeService.getNewSerialAnime());

	}
}
```
测试结果：

![结果](/img/ssm整合4.jpg)

至此，完成Spring和mybatis这两大框架的整合，下面在继续进行SpringMVC的整合。

## 4.3、整合SpringMVC

上面已经完成了2大框架的整合，SpringMVC的配置文件单独放，然后在web.xml中配置整合。

### 4.3.1、配置spring-mvc.xml
配置里面的注释也很详细，在此就不说了，主要是自动扫描控制器，视图模式，注解的启动这三个。

```xml
<?xml version="1.0" encoding="UTF-8"?>  
<beans xmlns="http://www.springframework.org/schema/beans"  
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:p="http://www.springframework.org/schema/p"  
    xmlns:context="http://www.springframework.org/schema/context"  
    xmlns:mvc="http://www.springframework.org/schema/mvc"  
    xsi:schemaLocation="http://www.springframework.org/schema/beans
                        http://www.springframework.org/schema/beans/spring-beans-3.1.xsd
                        http://www.springframework.org/schema/context
                        http://www.springframework.org/schema/context/spring-context-3.1.xsd
                        http://www.springframework.org/schema/mvc
                        http://www.springframework.org/schema/mvc/spring-mvc-4.0.xsd">  
    <!-- 自动扫描该包，使SpringMVC认为包下用了@controller注解的类是控制器 -->  
    <context:component-scan base-package="com.cn.hnust.controller" />  
    <!--避免IE执行AJAX时，返回JSON出现下载文件 -->  
    <bean id="mappingJacksonHttpMessageConverter"  
        class="org.springframework.http.converter.json.MappingJacksonHttpMessageConverter">  
        <property name="supportedMediaTypes">  
            <list>  
                <value>text/html;charset=UTF-8</value>  
            </list>  
        </property>  
    </bean>  
    <!-- 启动SpringMVC的注解功能，完成请求和注解POJO的映射 -->  
    <bean  
        class="org.springframework.web.servlet.mvc.annotation.AnnotationMethodHandlerAdapter">  
        <property name="messageConverters">  
            <list>  
                <ref bean="mappingJacksonHttpMessageConverter" /> <!-- JSON转换器 -->  
            </list>  
        </property>  
    </bean>  
    <!-- 定义跳转的文件的前后缀 ，视图模式配置-->  
    <bean class="org.springframework.web.servlet.view.InternalResourceViewResolver">  
        <!-- 这里的配置我的理解是自动给后面action的方法return的字符串加上前缀和后缀，变成一个 可用的url地址 -->  
        <property name="prefix" value="/WEB-INF/jsp/" />  
        <property name="suffix" value=".jsp" />  
    </bean>  

    <!-- 配置文件上传，如果没有使用文件上传可以不用配置，当然如果不配，那么配置文件中也不必引入上传组件包 -->  
    <bean id="multipartResolver"
        class="org.springframework.web.multipart.commons.CommonsMultipartResolver">
        <!-- 默认编码 -->  
        <property name="defaultEncoding" value="utf-8" />
        <!-- 文件大小最大值 -->  
        <property name="maxUploadSize" value="10485760000" />
        <!-- 内存中的最大值 -->  
        <property name="maxInMemorySize" value="40960" />
    </bean>

</beans>  
```

### 4.3.2、配置web.xml文件

这里面对spring-mybatis.xml的引入以及配置的spring-mvc的Servlet就是为了完成SSM整合，之前2框架整合不需要在此处进行任何配置。配置一样有详细注释，不多解释了。

web.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>  
<web-app xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"  
    xmlns="http://java.sun.com/xml/ns/javaee"  
    xsi:schemaLocation="http://java.sun.com/xml/ns/javaee http://java.sun.com/xml/ns/javaee/web-app_3_0.xsd"  
    version="3.0">  
    <display-name>Archetype Created Web Application</display-name>  
    <!-- Spring和mybatis的配置文件 -->  
    <context-param>  
        <param-name>contextConfigLocation</param-name>  
        <param-value>classpath:spring-mybatis.xml</param-value>  
    </context-param>  
    <!-- 编码过滤器 -->  
    <filter>  
        <filter-name>encodingFilter</filter-name>  
        <filter-class>org.springframework.web.filter.CharacterEncodingFilter</filter-class>  
        <async-supported>true</async-supported>  
        <init-param>  
            <param-name>encoding</param-name>  
            <param-value>UTF-8</param-value>  
        </init-param>  
    </filter>  
    <filter-mapping>  
        <filter-name>encodingFilter</filter-name>  
        <url-pattern>/*</url-pattern>  
    </filter-mapping>  
    <!-- Spring监听器 -->  
    <listener>  
        <listener-class>org.springframework.web.context.ContextLoaderListener</listener-class>  
    </listener>  
    <!-- 防止Spring内存溢出监听器 -->  
    <listener>  
        <listener-class>org.springframework.web.util.IntrospectorCleanupListener</listener-class>  
    </listener>  

    <!-- Spring MVC servlet -->  
    <servlet>  
        <servlet-name>SpringMVC</servlet-name>  
        <servlet-class>org.springframework.web.servlet.DispatcherServlet</servlet-class>  
        <init-param>  
            <param-name>contextConfigLocation</param-name>  
            <param-value>classpath:spring-mvc.xml</param-value>  
        </init-param>  
        <load-on-startup>1</load-on-startup>  
        <async-supported>true</async-supported>  
    </servlet>  
    <servlet-mapping>  
        <servlet-name>SpringMVC</servlet-name>  
        <!-- 此处可以可以配置成*.do，对应struts的后缀习惯 -->  
        <url-pattern>/</url-pattern>  
    </servlet-mapping>  
    <welcome-file-list>  
        <welcome-file>/index.jsp</welcome-file>  
    </welcome-file-list>  

</web-app>  
```

#### 4.3.3、测试

至此已经完成了SSM三大框架的整合了，接下来测试一下，如果成功了，那么恭喜你，如果失败了，继续调试吧，作为程序员就是不停的与BUG做斗争！

##### 4.3.3.1、新建jsp页面

showUser.jsp   此页面仅输出一下用户名，完成一个完整的简单流程。
```html
<%@ page language="java" import="java.util.*" pageEncoding="utf-8"%>  
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">  
<html>  
  <head>  
    <title>测试</title>  
  </head>  

  <body>  
    ${user.userName}  
  </body>  
</html>  
```

##### 4.3.3.2、建立UserController类
UserController.java  控制器

```java
package com.cn.hnust.controller;  

import javax.annotation.Resource;  
import javax.servlet.http.HttpServletRequest;  

import org.springframework.stereotype.Controller;  
import org.springframework.ui.Model;  
import org.springframework.web.bind.annotation.RequestMapping;  

import com.cn.hnust.pojo.User;  
import com.cn.hnust.service.IUserService;  

@Controller  
@RequestMapping("/user")  
public class UserController {  
    @Resource  
    private IUserService userService;  

    @RequestMapping("/showUser")  
    public String toIndex(HttpServletRequest request,Model model){  
        int userId = Integer.parseInt(request.getParameter("id"));  
        User user = this.userService.getUserById(userId);  
        model.addAttribute("user", user);  
        return "showUser";  
    }  
}  
```
##### 4.3.3.3、部署项目
输入地址：localhost:8080/项目名称/user/showUser?id=1

至此，SSM三大框架的整合就完成了，在此基础上可再添加其他功能。

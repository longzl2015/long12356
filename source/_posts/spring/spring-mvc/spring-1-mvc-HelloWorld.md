---
title: spring-1-mvc-HelloWorld
date: 2015-08-14 09:09:28
tags: springMVC
categories: springMVC

---

## 导包
springMVC所需要的包如下所示：

![springMVC所需要的包](http://i.imgur.com/vwmQSBl.jpg)

## 配置 web-xml

```xml
	<!-- 配置 DispatcherServlet -->
	<servlet>
		<servlet-name>dispatcherServlet</servlet-name>
		<servlet-class>org.springframework.web.servlet.DispatcherServlet</servlet-class>

		<!-- 配置 DispatcherServlet 的一个初始化参数: 配置 SpringMVC 配置文件的位置和名称 -->
		<!--
			实际上也可以不通过 contextConfigLocation 来配置 SpringMVC 的配置文件, 而使用默认的.
			默认的配置文件为: /WEB-INF/<servlet-name>-servlet.xml
		-->
		<init-param>
			<param-name>contextConfigLocation</param-name>
			<param-value>classpath:springmvc.xml</param-value>
		</init-param>

		<!--在web应用被加载的时候就创建dispatcherServlet-->
		<load-on-startup>1</load-on-startup>
	</servlet>

	<servlet-mapping>
		<servlet-name>dispatcherServlet</servlet-name>
		<!--将所有请求发给servlet-->
		<url-pattern>/</url-pattern>
	</servlet-mapping>
```
## 加入 springMVC.xml

```xml

<beans xmlns="http://www.springframework.org/schema/beans"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xmlns:context="http://www.springframework.org/schema/context"
	xmlns:mvc="http://www.springframework.org/schema/mvc"
	xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd
		http://www.springframework.org/schema/context http://www.springframework.org/schema/context/spring-context-4.0.xsd
		http://www.springframework.org/schema/mvc http://www.springframework.org/schema/mvc/spring-mvc-4.0.xsd">

	<!-- 配置自定扫描的包 -->
	<context:component-scan base-package="com.atguigu.springmvc"></context:component-scan>

	<!-- 配置视图解析器: 如何把 handler 方法返回值解析为实际的物理视图 -->
	<bean class="org.springframework.web.servlet.view.InternalResourceViewResolver">
		<property name="prefix" value="/WEB-INF/views/"></property>
		<property name="suffix" value=".jsp"></property>
	</bean>
</beans>

```

## 编写handler控制器

```java
@Controller
public class HelloWorld {

	/**
	 * 1. 使用 @RequestMapping 注解来映射请求的 URL
	 * 2. 返回值会通过视图解析器解析为实际的物理视图, 对于 InternalResourceViewResolver 视图解析器, 会做如下的解析:
	 * 通过 prefix(前缀) + returnVal + suffix(后缀) 这样的方式得到实际的物理视图, 然会做转发操作
	 *
	 * /WEB-INF/views/success.jsp
	 *
	 * @return
	 */
	@RequestMapping("/helloworld")
	public String hello(){
		System.out.println("hello world");
		return "success";
	}
}
```

## 编写 index.jsp 和 success.jsp

### index.jsp

<img src="http://i.imgur.com/b0abCM8.jpg" width="50%" height="20%">

### success.jsp

<img src="http://i.imgur.com/lZI8ltS.jpg" width="50%" height="20%">

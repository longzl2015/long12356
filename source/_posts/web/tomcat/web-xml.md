---
title: web_xml.md
date: 2016-03-20 23:20:12
tags: []
---

[TOC]

<!--more-->

# 简介

- web.xml加载顺序：`context-param -> listener -> filter -> servlet`
- 区分大小写

# 常用元素介绍

## display-name

定义了WEB应用名称

```xml
<display-name></display-name>
```

## description

声明WEB应用的描述信息

```xml
<description></description>
```

## context-param

```xml
<context-param>
    <param-name>ContextParameter</para-name>
    <param-value>test</param-value>
    <description>It is a test parameter.</description>
</context-param>
```

在servlet里面可以通过getServletContext().getInitParameter("context/param")得到

## filter

过滤器配置

```xml
<filter>
        <filter-name>setCharacterEncoding</filter-name>
        <filter-class>com.myTest.setCharacterEncodingFilter</filter-class>
        <init-param>
            <param-name>encoding</param-name>
            <param-value>utf-8</param-value>
        </init-param>
</filter>
<filter-mapping>
        <filter-name>setCharacterEncoding</filter-name>
        <url-pattern>/*</url-pattern>
</filter-mapping>
```

## listener

监听器配置

```xml
<listener>
      <listerner-class>listener.SessionListener</listener-class>
</listener>
```

## servlet

### servlet元素

```xml
   <servlet>
      <servlet-name>snoop</servlet-name>
      <servlet-class>SnoopServlet</servlet-class>
      <init-param>
         <param-name>foo</param-name>
         <param-value>bar</param-value>
      </init-param>
      <load-on-startup></load-on-startup>
   </servlet>
```

说明：

对于`load-on-startup`

- 指定当Web应用启动时，装载Servlet的次序
- 当值为正数或零时：Servlet容器先加载数值小的servlet，再依次加载其他数值大的servlet.
- 当值为负或未定义：Servlet容器将在Web客户首次访问这个servlet时加载它

对于`init-param `

- 可有多个init-param
- 在servlet类中通过getInitParamenter(String name)方法访问初始化参数

### servlet-mapping元素

```xml
   <servlet-mapping>
      <servlet-name>snoop</servlet-name>
      <url-pattern>/snoop</url-pattern>  //指定servlet所对应的URL
   </servlet-mapping>
```

# 其他元素介绍

## session-config

会话超时配置（单位为分钟）

```xml
   <session-config>
      <session-timeout>120</session-timeout>
   </session-config>
```

## mime-mapping

MIME类型配置

```xml
   <mime-mapping>
      <extension>htm</extension>
      <mime-type>text/html</mime-type>
   </mime-mapping>
```

## welcome-file-list

指定欢迎文件页配置

```xml
   <welcome-file-list>
      <welcome-file>index.jsp</welcome-file>
      <welcome-file>index.html</welcome-file>
      <welcome-file>index.htm</welcome-file>
   </welcome-file-list>
```

## 配置错误页

### 通过错误码来配置

```xml
   <error-page>
      <error-code>404</error-code>
      <location>/NotFound.jsp</location>
   </error-page>
```

### 通过异常的类型配置

```xml
   <error-page>
       <exception-type>java.lang.NullException</exception-type>
       <location>/error.jsp</location>
   </error-page>
```



----
#### 参考：
[web.xml 中的listener、 filter、servlet 加载顺序及其详解](http://www.cnblogs.com/shenliang123/p/3344555.html)
---
title: servlet与tomcat交互.md
date: 2016-03-20 23:06:14
categories: [tomcat]
tags: [servlet,tomcat]
---

[TOC]

<!--more-->

## 概述
Tomcat 是Web应用服务器,是一个Servlet/JSP容器. Tomcat 作为Servlet容器,负责处理客户请求,把请求传送给Servlet,并将Servlet的响应传送回给客户.而Servlet是一种运行在支持Java语言的服务器上的组件.


## servlet与tomcat交互图

![servlet和tomcat交互图](http://7xlgbq.com1.z0.glb.clouddn.com/servlet和tomcat交互图.jpg "servlet和tomcat交互图")

1. 用户向Servlet容器（Tomcat）发出Http请求
2. 容器解析用户的请求
3. 容器创建一个HttpRequest对象，将请求的信息封装进该对象中
4. 容器创建一个HttpResponse对象
5. 容器调用Servlet的service方法，把HttpRequest与HttpResponse作为参数传给Servlet
6. Servlet调用HttpRequest对象的有关方法，获取Http请求信息
7. Servlet调用HttpResponse对象的有关方法，生成响应数据
8. Servlet容器把Servlet的响应结果传给用户
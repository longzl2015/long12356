---
title: servlet与tomcat交互.md
date: 2016-03-20 23:06:14
tags: [servlet,tomcat]
---

[TOC]

<!--more-->

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
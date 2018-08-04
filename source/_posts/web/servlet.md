---
title: servlet.md
date: 2016-03-16 23:22:58
tags: [web]
---

[TOC]

<!--more-->

## servlet生命周期

1. 创建实例：
	- 第一次请求servlet
	- 启动时立即创建，即load-on-startup servlet
2. 初始化：调用init()方法
3. 响应请求：调用service()方法,doGet、doPost
5. 实例销毁：调用destroy()方法,在servlet容器停止或者重新启动时发生

## servlet调用图

![servlet调用图](http://7xlgbq.com1.z0.glb.clouddn.com/servlet调用图.jpg "servlet调用图")

## 类介绍

1. ServletConfig：用于封装servlet的配置信息。
2. ServletContext：一个全局的储存信息的空间。
---
title: 动态代理-cglib
date: 2016-08-05 03:30:09
tags: [动态代理,java]
---

[TOC]

JDK动态代理（proxy）可以在运行时创建一个实现一组给定接口的新类。但是略有限制，即被代理的类必须实现某个接口，否则无法使用JDK自带的动态代理，因此，如果不满足条件，就只能使用另一种更加灵活，功能更加强大的动态代理技术—— CGLIB。Spring里会自动在JDK的代理和CGLIB之间切换，同时我们也可以强制Spring使用CGLIB

<!--more-->


## jdk 动态代理




## 来源

https://blog.csdn.net/mantantan/article/details/51873755
---
title: ThreadLocal.md
date: 2016-03-20 16:59:48
tags: [threadlocal,并发]
---

[TOC]

<!--more-->

## ThreadLocal

ThreadLocal 是 Thread 的内部变量，他是map类型的，key用来存储当前进程的引用，value储存用户数据。

主要用于线程内共享一些数据，避免通过参数来传递

最常见的ThreadLocal使用场景为 用来解决 数据库连接、Session管理等。
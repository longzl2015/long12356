---
title: List集合.md
date: 2019-08-01 10:11:01
tags: [list,集合]
categories: [语言,java,集合]
---

[TOC]

ArrayList and Vector 异同。Vector 已经被弃用。

<!--more-->

## ArrayList Vector 相同点

- 实现了List接口(List接口继承了Collection接口)
- 有序集合, 即存储在这两个集合中的元素的位置都是有顺序的
- 一种动态的数组
- 数据是允许重复的

## ArrayList Vector 不同点

- Vector是线程安全的, ArrayList是线程序不安全
- Vector增长原来的一倍, ArrayList增加原来的0.5倍：vector可以自定义增长幅度。

## CopyOnWriteArrayList

写时复制

- 读：旧的容器
- 写：在添加新的元素时，加锁。复制新的容器，然后在新的容器上添加新元素。将引用改为新创建的元素。

适合场景: 读多，写少。

## 参考

[图解AQS的设计与实现](https://www.lagou.com/lgeduarticle/76788.html)
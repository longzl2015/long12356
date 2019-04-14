---
title: ArrayList and Vector.md
date: 2016-03-16 22:12:26
tags: [list,集合]
categories: [语言,java,集合]
---

[TOC]

ArrayList and Vector 异同。Vector 已经被弃用。

<!--more-->

## ArrayList and Vector

- 实现了List接口(List接口继承了Collection接口)
- 有序集合,即存储在这两个集合中的元素的位置都是有顺序的,
- 一种动态的数组
- 数据是允许重复的

## 两者区别

- Vector是线程安全的, ArrayList是线程序不安全
- Vector增长原来的一倍,ArrayList增加原来的0.5倍：vector可以自定义增长幅度。

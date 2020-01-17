---
title: ConcurrentHashMap.md
date: 2018-08-01 10:11:04
tags: [map,并发,线程安全,集合]
categories: [语言,java,集合]
---

[TOC]

<!--more-->

## 结构

concurrentHashMap是由segment数组结构和 HashEntry 数组结构组成的。
一个segment元素管理一个 HashEntry 数组，HashEntry 是链式结构的。

## 特点

ConcurrentHashMap使用segment来分段和管理锁，segment继承自ReentrantLock，因此ConcurrentHashMap使用 ReentrantLock 来保证线程安全。

采用锁分段技术：将数据分为一段一段的存储，然后为每一个数据配一把锁，当线程用锁访问一个段数据时，其他段数据可以被其他数据访问。
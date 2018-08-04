---
title: ConcurrentHashMap.md
date: 2016-03-28 16:31:44
tags: [map,并发,线程安全]
---

[TOC]

<!--more-->

## 结构

concurrentHashmap是由segment数组结构和Hashentry数组结构组成的。
一个segment元素管理一个hashentry数组，hashentry是链式结构的。

# 特点
ConcurrentHashMap使用segment来分段和管理锁，segment继承自ReentrantLock，因此ConcurrentHashMap使用 ReentrantLock 来保证线程安全。
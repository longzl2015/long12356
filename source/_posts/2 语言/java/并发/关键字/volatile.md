---
title: volatile.md
date: 2016-03-20 17:07:34
tags: [volatile]
---

[TOC]

<!--more-->

## volatile关键字的作用

1. 变量可见性，即一个线程修改数据时，其他线程是立即得知的。
2. 禁止语义重排序。

需要注意的是volatile并不具备原子性。
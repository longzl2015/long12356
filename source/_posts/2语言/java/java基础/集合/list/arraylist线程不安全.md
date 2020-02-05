---
title: ArrayList线程不安全.md
date: 2019-08-01 10:11:01
tags: [ArrayList,集合]
categories: [语言,java,集合]
---

[TOC]

分析 ArrayList 线程不安全的原因。

<!--more-->

## ArrayList 

大多数文章中，都是以 add() 方法举例，我们也以此为例。

```java
public boolean add(E e) {
    ensureCapacityInternal(size + 1);  // Increments modCount!!
    elementData[size++] = e;
    return true;
}
```

// todo 
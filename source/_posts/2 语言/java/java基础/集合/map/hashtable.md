---
title: hashtable.md
date: 2016-03-19 22:27:09
tags: [hashtable,集合]
---

[TOC]

<!--more-->

## hashtable结构

![hashtable](http://7xlgbq.com1.z0.glb.clouddn.com/hashtable.jpg "hashtable")

结构与 hashmap 一样：一个数组 + 链表

## put方法

1. 判断value是否为空，为空则抛出异常；
2. 计算key的hash值，并根据hash值获得key在table数组中的位置index，如果table[index]元素不为空，则进行迭代，如果遇到相同的key，则直接替换，并返回旧value；
3. 否则，我们可以将其插入到table[index]位置。

## get方法

1. 通过hash()方法求得key的哈希值
2. 根据hash值得到index索引
3. 然后迭代链表，返回匹配的key的对应的value；
4. 如果找不到，则返回null。

----

[Java集合学习3：Hashtable的实现原理](http://tracylihui.github.io/2015/07/01/Java%E9%9B%86%E5%90%88%E5%AD%A6%E4%B9%A03%EF%BC%9AHashtable%E7%9A%84%E5%AE%9E%E7%8E%B0%E5%8E%9F%E7%90%86/)
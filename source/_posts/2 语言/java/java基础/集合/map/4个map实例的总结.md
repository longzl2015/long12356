---
title: 4个map实例的总结.md
date: 2019-08-01 10:11:02
tags: [map,集合]
categories: [语言,java,集合]
---

[TOC]

Java为数据结构中的映射定义了一个接口java.util.Map，它有四个实现类，分别是HashMap、HashTable、LinkedHashMap和TreeMap。本节实例主要介绍这4中实例的用法和区别。

<!--more-->

## HashMap

最常用的map类，根据key的hashcode存储；可以根据key获得对应的value；允许key，value为null；排序是无序。不支持线程同步。若要实现同步可以使用Collections.synchronizedMap(HashMap map)方法使HashMap具有同步的能力。

- HashMap的key和value支持null。遇到key为null的时候，调用putForNullKey方法，将该键值对放入table[0]。
- HashMap的默认容量是2的幂次方


## hashtable

与HashMap类似，不同的是：基于Dictionary类；支持线程同步；不支持key，value为null；由于线程锁的原因，速度比HashMap慢。

- hashtable不支持null（如有null的key或者value：运行期间会报错），遇到null，直接返回NullPointerException。
- hashtable的默认容量是old*2+1


## linkedHashMap

LinkedHashMap也是一个HashMap,但是内部维持了一个双向链表，保存了记录的插入顺序。

## treeMap

TreeMap以红-黑树结构为基础，键值按顺序排列，可以按自然排序也可以自定义排序。需要注意的是key的对象需要实现Comparable接口（重写public int compareTo()方法），使key能够相互比较。

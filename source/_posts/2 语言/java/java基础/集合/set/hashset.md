---
title: hashset.md
date: 2016-03-22 15:58:06
tags: [hashset,集合]
categories: [语言,java,集合]
---

[TOC]

<!--more-->

## 底层实现

基于 HashMap 实现，HashSet 底层使用 HashMap 来保存所有元素。默认情况下初始容量为16，负载因子为0.75。

## hashset的add()

```java
/**
 * @param e 将添加到此set中的元素。
 * @return 如果此set尚未包含指定元素，则返回true。
 */
public boolean add(E e) {
    return map.put(e, PRESENT)==null;
}
```

这里的代码就一句 map.put(k,v)。下面简单介绍一下：

由于 HashMap 的 put() 方法添加 key-value 对时，当新放入 HashMap 的 Entry 中 key 与集合中原有 Entry 的 key 相同（hashCode()和equal()都相等），新添加的 Entry 的 value 会将覆盖原来 Entry 的 value（HashSet 中的 value 都是PRESENT），但 key 不会有任何改变，因此如果向 HashSet 中添加一个已经存在的元素时，新添加的集合元素将不会被放入 HashMap中，原来的元素也不会有任何改变，这也就满足了 Set 中元素不重复的特性。

需要注意的是hashmap的put方法

- 在添加key不重复的键值对时，返回的是null。
- 在添加key重复的键值对时，返回的是原先的旧value。

## equals 和 hashCode 

由于hashset的不可重复性依赖于equals和hashcode方法，因此使用hashset的时候，需要重写equals和hashcode方法。

----

[hashset实现原理](http://wiki.jikexueyuan.com/project/java-collection/hashset.html)
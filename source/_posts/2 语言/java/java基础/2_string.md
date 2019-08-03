---
title: 2_string
date: 2016-09-08 03:30:09
tags: [string]
categories: [语言,java,java基础]
---

[TOC]

本文主要介绍 String、StringBuffer与 StringBuilder 

<!--more-->

## String

String使用字符数组来保存字符串， 由于String类的字符数组属性使用 `final` 修饰，因此 String 是不可变的。
通常对字符串的操作都是新建一个字符串。

string是final类，不能被继承。

- jdk1.7之前，substring 返回的是 源字符串的引用。
- Jdk1.7及以后，substring 会拷贝一份新的字符串。



## StringBuffer
StringBuffer 继承自AbstractStringBuilder类 该类使用 char[] 保存字符串，没有使用 final 关键字，因此是可变的。

StringBuffer 对方法加了同步锁或者对调用的方法加了同步锁，所以是线程安全的。

```java
 public final class StringBuffer
    extends AbstractStringBuilder
    implements java.io.Serializable, CharSequence
{

    private transient char[] toStringCache;

    static final long serialVersionUID = 3388685877147921107L;

    //..

    @Override
    public synchronized int length() {
        return count;
    }

    @Override
    public synchronized StringBuffer append(String str) {
        toStringCache = null;
        super.append(str);
        return this;
    }


    @Override
    public synchronized StringBuffer delete(int start, int end) {
        toStringCache = null;
        super.delete(start, end);
        return this;
    }


    @Override
    public synchronized String substring(int start) {
        return substring(start, count);
    }

    //..
}

```

## StringBuilder

StringBuilder与StringBuffer基本相同: 继承自AbstractStringBuilder类 ，字符数组可变，但是方法没有使用同步锁，所以是线程不安全的。

由于不执行同步操作，速度比StringBuffer快。在不影响程序运行的情况下，优先使用StringBuilder。

## 总结

在字符串需要频繁变动的情况使用 StringBuffer 或者 StringBuilder 。
执行效率: StringBuilder > StringBuffer > String

从 https://ideone.com/OpUDPU 显示，执行同一段代码，stringBuffer vs  StringBuilder 耗时比对

```
stringBuffer  2798ms
StringBuilder 1673ms
```

一般情况下最好选择 StringBuilder 因为其没有同步，执行效率会快很多。如果实在需要 同步操作，可以在方法外，自己添加 synchronized。



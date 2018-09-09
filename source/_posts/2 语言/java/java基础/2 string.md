---
title: string
date: 2016-08-05 03:30:09
tags: [string]
---

<!-- MarkdownTOC -->

- [String、StringBuffer与 StringBuilder](#string、stringbuffer与-stringbuilder)
	- [String](#string)
	- [StringBuffer](#stringbuffer)
	- [StringBuilder](#stringbuilder)
- [string能否被继承](#string能否被继承)
- [string的substring和spilt](#string的substring和spilt)

<!-- /MarkdownTOC -->

<!--more-->


## String、StringBuffer与 StringBuilder

### String

string使用字符数组来保存字符串， 由于String类的字符数组属性使用 `final` 修饰，因此 String 是不可变的。
通常对字符串的操作都是新建一个字符串。

### StringBuffer
StringBuffer 继承自AbstractStringBuilder类 该类使用 char[] 保存字符串，但是没有使用 final 关键字，应该其是可变的。

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

### StringBuilder

StringBuilder 同样继承自AbstractStringBuilder类 该类使用 char[] 保存字符串，但是没有使用 final 关键字，应该其是可变的。

由于不执行同步操作，速度比StringBuffer快。在不影响程序运行的情况下，优先使用StringBuilder。

### String vs StringBuffer vs StringBuilder

在字符串需要频繁变动的情况使用 StringBuffer 或者 StringBuilder 。
执行效率: StringBuilder > StringBuffer > String

从 https://ideone.com/OpUDPU 显示，执行同一段代码，stringBuffer vs  StringBuilder 耗时比对

```
stringBuffer  2798ms
StringBuilder 1673ms
```

一般情况下最好选择 StringBuilder 因为其没有同步，执行效率会快很多。如果实在需要 同步操作，可以在方法外，自己添加 synchronized。

## string能否被继承

string是final类，不能被继承。

## string的substring和spilt

这两个方法是在原有的字符串上进行操作（添加一个位移量和长度），并不重新创建对象。

若使用不当会造成内存泄漏。

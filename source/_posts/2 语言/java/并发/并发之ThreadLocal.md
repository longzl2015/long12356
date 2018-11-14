---
title: 并发之ThreadLocal.md
date: 2016-03-20 16:59:48
tags: [threadlocal,并发]
categories: [并发]
---

[TOC]

ThreadLocal 主要用于**线程内**共享一些数据，而不是**线程间**共享数据。

<!--more-->

## ThreadLocal

ThreadLocal 是 Thread 的内部变量，他是map类型的，key用来存储当前进程的引用，value储存用户数据。

主要用于同一线程内共享一些数据，避免通过参数来传递

最常见的ThreadLocal使用场景为 用来解决 数据库连接、Session管理等。

## 源码 主要方法

```java
public class ThreadLocal<T> {
    public T get() { }
    public void set(T value) { }
    public void remove() { }
    protected T initialValue() { }
}

```

get: 获取当前线程的副本
set：设置当前线程副本
remove: 移除当前线程中变量的副本
initialValue: 当 get() 获取不到ThreadLocalMap时，返回该值


### ThreadLocalMap

ThreadLocal 中包含着一个静态内部类 ThreadLocalMap . ThreadLocalMap 是一个 自定义的hashMap，用来存储 

```
key: ThreadLocal<T>对象的hashCode)
value: T的值
```

为什么是map呢： 因为一个线程类中，可能会申明多个 ThreadLocal 变量。

### 部分源码
```java
public class ThreadLocal<T> {
    
    public T get() {
        Thread t = Thread.currentThread();
        ThreadLocalMap map = getMap(t);
        if (map != null) {
            ThreadLocalMap.Entry e = map.getEntry(this);
            if (e != null) {
                @SuppressWarnings("unchecked")
                T result = (T)e.value;
                return result;
            }
        }
        return setInitialValue();
    }
    
    public void set(T value) {
        Thread t = Thread.currentThread();
        ThreadLocalMap map = getMap(t);
        if (map != null)
            map.set(this, value);
        else
            createMap(t, value);
    }
    
    ThreadLocalMap getMap(Thread t) {
        return t.threadLocals;
    }
}
```
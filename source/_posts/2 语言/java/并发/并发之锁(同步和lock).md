---
title: 并发之锁(同步和lock).md
date: 2016-03-19 10:50:42
tags: [synchronized,lock]
categories: [并发]
---

[TOC]

<!--more-->

## synchronized和ReentrantLock的区别

synchronized是关键字，ReentrantLock是类。

（1）ReentrantLock可以对获取锁的等待时间进行设置，这样就避免了死锁

（2）ReentrantLock可以获取各种锁的信息

（3）ReentrantLock:使用condition类唤醒指定种类的线程。

ReentrantLock底层调用的是Unsafe的park方法加锁，synchronized操作的应该是对象头中mark word。

## ReentrantLock的缺点 -> ReadWriteLock

ReentrantLock局限：如果线程C在读数据、线程D也在读数据，读数据是不会改变数据的，没有必要加锁，但是还是加锁了，降低了程序的性能。

读写锁接口ReadWriteLock。ReadWriteLock是一个读写锁接口，ReentrantReadWriteLock是

### 读写锁的特点：
实现了读写的分离，读锁是共享的，写锁是独占的：读和读之间不会互斥，读和写、写和读、写和写之间才会互斥，提升了读写的性能。

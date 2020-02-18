---
title: 并发之锁-同步和lock.md
date: 2019-03-01 10:10:15
tags: [synchronized,lock]
categories: [语言,java,并发]
---

[TOC]

<!--more-->

## AQS

AbstractQueuedSynchronizer，抽象队列同步器。

java并发包下很多API都是基于AQS来实现的加锁和释放锁等功能的，AQS是java并发包的基础类。

详细介绍看 https://zhuanlan.zhihu.com/p/86072774

## 公平锁非公平锁

公平锁（Fair）：加锁前检查是否有排队等待的线程，优先排队等待的线程，先来先得
非公平锁（Nonfair）：加锁时不考虑排队等待问题，直接尝试获取锁，获取不到自动到队尾等待

synchronized和ReentrantLock都是非公平锁

##synchronized

![img](/images/并发之锁_同步和lock/2615789-08f16aeac7e0977d-20190810144050197.png)

## synchronized和ReentrantLock的区别

synchronized是关键字，ReentrantLock是类。

（1）ReentrantLock可以对获取锁的等待时间进行设置，这样就避免了死锁

（2）ReentrantLock可以获取各种锁的信息

（3）ReentrantLock:使用condition类唤醒指定种类的线程。

ReentrantLock底层调用的是Unsafe的park方法加锁，synchronized操作的应该是对象头中mark word。

## ReadWriteLock

ReentrantLock局限：如果线程C在读数据、线程D也在读数据，读数据是不会改变数据的，没有必要加锁，但是还是加锁了，降低了程序的性能。

读写锁接口ReadWriteLock。ReadWriteLock是一个读写锁接口，ReentrantReadWriteLock是可重如读写锁，是ReadWriteLock的一个实现。

```java
public interface ReadWriteLock {
    Lock readLock();
    Lock writeLock();
}
```

### 读写锁的特点：

实现了读写的分离，读锁是共享的，写锁是独占的：读和读之间不会互斥，读和写、写和读、写和写之间才会互斥，提升了读写的性能。

ReentrantLock 实现原理 https://www.cnblogs.com/xrq730/p/4979021.html

### ReentrantLock源码中的重要概念:

- FairSync公平锁
- NonfairSync非公平锁
- LockSupport.park() 实际是调用 Unsafe.unpark()
- LockSupport.unpark() 实际是调用 Unsafe.park()
- Unsafe.unpark() 该方法为native方法
- Unsafe.park() 该方法为native方法


## CountDownLatch

CountDownLatch类只提供了一个构造器：

```java
public CountDownLatch(int count) {};//参数count为计数值
```

然后下面的方法是CountDownLatch类中最重要的方法：

```java
//调用await()方法的线程会被挂起，它会等待直到count值为0才继续执行
public void await() throws InterruptedException { };
//将count值减1
public void countDown() {};
```

## CyclicBarrier

通过它可以实现让一组线程等待至某个状态之后再全部同时执行。叫做回环是因为当所有等待线程都被释放以后，CyclicBarrier可以被重用。

CyclicBarrier有两个构造器:

```java
//参数parties指让多少个线程或者任务等待至barrier状态
public CyclicBarrier(int parties) {
}
//如果想在指定数量的线程都达到barrier状态时，执行特定的任务。可以使用该构造方法。
public CyclicBarrier(int parties, Runnable barrierAction) {
}
```

然后CyclicBarrier中最重要的方法就是await方法，它有2个重载版本：

```java
//用来挂起当前线程，进入barrier状态。 直至所有线程都到达barrier状态再同时执行后续任务
public int await() throws InterruptedException, BrokenBarrierException { };
public int await(long timeout, TimeUnit unit) throws InterruptedException,BrokenBarrierException,TimeoutException { };
```

## Semaphore

提供了2个构造器：

```java
//参数permits表示许可数目，即同时可以允许多少线程进行访问
public Semaphore(int permits) {     
  sync = new NonfairSync(permits);
}
//这个多了一个参数fair表示是否是公平的，即等待时间越久的越先获取许可
public Semaphore(int permits, boolean fair) {  
  sync = (fair)? new FairSync(permits) : new NonfairSync(permits);
}
```

比较重要的方法:

```java
public void acquire() throws InterruptedException { }   //获取一个许可
public void acquire(int permits) throws InterruptedException { }  //获取permits个许可
public void release() { }     //释放一个许可
public void release(int permits) { }  //释放permits个许可
```

## 小节

上面说的三个辅助类进行一个总结：

1. CountDownLatch 一般用于某个线程A等待若干个其他线程执行完任务之后，它才执行。不能重用
2. CyclicBarrier 一般用于一组线程互相等待至某个状态，然后这一组线程再同时执行。可以重用
3. Semaphore其实和锁有点类似，它一般用于控制对某组资源的访问权限。
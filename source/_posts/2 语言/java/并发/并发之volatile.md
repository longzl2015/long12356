---
title: 并发之volatile.md
date: 2019-03-01 10:10:22
tags: [volatile]
categories: [语言,java,并发]
---

[TOC]

变量可见性，禁止语义重排序，不具备原子性。


<!--more-->

## volatile 关键字的作用


### 变量可见性

被 volatile 修饰的变量在生成汇编代码时，会在被修饰变量进行写操作时生成一个lock前缀的指令。lock指令的作用:

1. 将当前处理器缓存的数据写回主内存
2. 同时，将其他CPU中缓存的该数据的内存地址设为无效

这样就能保证，每个线程能够获取变量的最新值。

但是需要注意，volatile 仅仅只是保证了可见性，其并不具备 原子性。

### 禁止语义重排序。

“Happens-before”规则 ?  https://blog.csdn.net/qqqqq1993qqqqq/article/details/75285899


需要注意的是volatile并不具备原子性。

## 不具备原子性例子

```java
public class Test {
    public volatile int inc = 0;
     
    public void increase() {
        inc++;
    }
     
    public static void main(String[] args) {
        final Test test = new Test();
        for(int i=0;i<10;i++){
            new Thread(){
                public void run() {
                    for(int j=0;j<1000;j++)
                        test.increase();
                };
            }.start();
        }
         
        while(Thread.activeCount()>1)  //保证前面的线程都执行完
            Thread.yield();
        System.out.println(test.inc);
    }
}
```

大家想一下这段程序的输出结果是多少？也许有些朋友认为是10000。但是事实上运行它会发现每次运行结果都不一致，都是一个小于10000的数字。

可能有的朋友就会有疑问，不对啊，上面是对变量inc进行自增操作，由于volatile保证了可见性，那么在每个线程中对inc自增完之后，在其他线程中都能看到修改后的值啊，所以有10个线程分别进行了1000次操作，那么最终inc的值应该是1000*10=10000。

这里面就有一个误区了，volatile关键字能保证可见性没有错，但是上面的程序错在没能保证原子性。可见性只能保证每次读取的是最新的值，但是volatile没办法保证对变量的操作的原子性。

在前面已经提到过，自增操作是不具备原子性的，它包括读取变量的原始值、进行加1操作、写入工作内存。那么就是说自增操作的三个子操作可能会分割开执行，就有可能导致下面这种情况出现：

假如某个时刻变量inc的值为10，

线程1对变量进行自增操作，线程1先读取了变量inc的原始值，然后线程1被阻塞了；

然后线程2对变量进行自增操作，线程2也去读取变量inc的原始值，由于线程1只是对变量inc进行读取操作，而没有对变量进行修改操作，所以不会导致线程2的工作内存中缓存变量inc的缓存行无效，所以线程2会直接去主存读取inc的值，发现inc的值时10，然后进行加1操作，并把11写入工作内存，最后写入主存。

然后线程1接着进行加1操作，由于已经读取了inc的值，注意此时在线程1的工作内存中inc的值仍然为10，所以线程1对inc进行加1操作后inc的值为11，然后将11写入工作内存，最后写入主存。

那么两个线程分别进行了一次自增操作后，inc只增加了1。

解释到这里，可能有朋友会有疑问，不对啊，前面不是保证一个变量在修改volatile变量时，会让缓存行无效吗？然后其他线程去读就会读到新的值，对，这个没错。这个就是上面的happens-before规则中的volatile变量规则，但是要注意，线程1对变量进行读取操作之后，被阻塞了的话，并没有对inc值进行修改。然后虽然volatile能保证线程2对变量inc的值读取是从内存中读取的，但是线程1没有进行修改，所以线程2根本就不会看到修改的值。

根源就在这里，自增操作不是原子性操作，而且volatile也无法保证对变量的任何操作都是原子性的。

## 使用条件

- 对变量的写操作不依赖于当前值。
- 该变量没有包含在具有其他变量的不变式中。

第一个条件的限制使 volatile 变量不能用作线程安全计数器。虽然增量操作（x++）看上去类似一个单独操作，实际上它是一个由（读取－修改－写入）操作序列组成的组合操作，必须以原子方式执行，而 volatile 不能提供必须的原子特性。实现正确的操作需要使x 的值在操作期间保持不变，而 volatile 变量无法实现这点


## 使用案例
很多并发性专家事实上往往引导用户远离 volatile 变量，因为使用它们要比使用锁更加容易出错。然而，如果谨慎地遵循一些良好定义的模式，就能够在很多场合内安全地使用 volatile 变量

### 状态标志
很多应用程序包含了一种控制结构，形式为 “在还没有准备好停止程序时再执行一些工作”，如清单 2 所示：

将 volatile 变量作为状态标志使用:  如 完成初始化或请求停机。

```java

class ShutDown{
  volatile boolean shutdownRequested;
   
  //...
   
  public void shutdown() { shutdownRequested = true; }
   
  public void doWork() { 
      while (!shutdownRequested) { 
          // do stuff
      }
  }  
}

```

另外还有其他几种使用模式。

- 一次性安全发布（one-time safe publication）
- 独立观察（independent observation）
- “volatile bean” 模式
- 开销较低的读－写锁策略


## 其他资料

[Java并发编程：volatile关键字解析](https://www.cnblogs.com/dolphin0520/p/3920373.html)
[Java线程 volatile的适用场景](https://blog.csdn.net/vking_wang/article/details/9982709)
[IBM-正确使用 Volatile 变量](https://www.ibm.com/developerworks/cn/java/j-jtp06197.html)


---
title: JVM参数.md
date: 2016-03-17 18:37:18
tags: [java,监控]
categories: [语言,java,jvm]
---

[TOC]

<!--more-->

# 参数介绍


- -Xms :设置Java堆栈的初始化大小
- -Xmx :设置最大的java堆大小
- -Xmn :设置年轻代大小
- -Xss :设置java线程堆栈大小

- -XX:NewRatio :设置老年代和年轻代的比值 默认为2
- -XX:NewSize :设置年轻代的大小
- -XX:SurvivorRatio=N :设置年轻代中 Eden 与俩个 Survivor 的比值

- -XX:MetaspaceSize : 

> Sets the size of the allocated class metadata space that will trigger a garbage collection the first time it is exceeded. This threshold for a garbage collection is increased or decreased depending on the amount of metadata used. The default size depends on the platform.

- -XX:+MinMetaspaceFreeRatio=N : 当进行过Metaspace GC之后，会计算当前Metaspace的空闲空间比，如果空闲比小于这个参数，那么虚拟机将增长Metaspace的大小
- -XX:+MaxMetaspaceFreeRatio=N : 当进行过Metaspace GC之后，会计算当前Metaspace的空闲空间比，如果空闲比大于这个参数，那么虚拟机会释放Metaspace的部分空间

- -XX:+HeapDumpBeforeFullGC 
- -XX:+HeapDumpAfterFullGC 

- -XX:+UseAdaptiveSizePolicy



例子: [SurvivorRatio](https://docs.oracle.com/cd/E19159-01/819-3681/abeil/index.html)

> -XX:SurvivorRatio=6 表示 一个Eden与一个Survivor的比值。 即 一个Survivor 在 年轻代 的占比为1/8



## 注意事项

###AdaptiveSizePolicy

JDK 1.8 默认使用 UseParallelGC 垃圾回收器，该垃圾回收器默认启动了 AdaptiveSizePolicy。

如果开启 AdaptiveSizePolicy，则每次 GC 后会重新计算 Eden、From 和 To 区的大小。因此会造成`-XX:SurvivorRatio` 配置无效。

**在设置`-XX:SurvivorRatio`的时候，需要关闭 `-XX:-UseAdaptiveSizePolicy` 选项。**







详细参数介绍:

https://www.cnblogs.com/redcreen/archive/2011/05/04/2037057.html

Visual GC 插件使用

https://www.jianshu.com/p/9e4ccd705709

oracle 官方参数手册

https://docs.oracle.com/javase/8/docs/technotes/tools/unix/java.html#BABFAFAE
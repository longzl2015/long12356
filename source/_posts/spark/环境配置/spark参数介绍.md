---
title: spark参数介绍
date: 2017-06-04 23:22:58
tags: 
  - spark
categories:
  - spark
---

# spark参数介绍

[TOC]

### 1 spark.driver.memory

设置分配给spark driver程序的内存，driver端会运行DAGScheduler、Backend等等进程。

### 2 spark.executor.cores 

单个Executor使用的CPU核数。这个参数决定了每个Executor进程并行执行task线程的能力。因为每个CPU core同一时间只能执行一个task线程，因此每个Executor进程的CPU core数量越多，越能够快速地执行完分配给自己的所有task线程。

### 3 spark.executor.memory

设置每个Executor进程的内存。Executor内存的大小，很多时候直接决定了Spark作业的性能，而且跟常见的JVM OOM异常，也有直接的关联。

### 4 spark.executor.instances

该参数对于静态分配，表示Executor的数量。

如果启用了`spark.dynamicAllocation.enabled`，则表示Executors的初始大小。


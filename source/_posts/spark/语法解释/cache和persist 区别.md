---
title: 缓存方法
date: 2017-06-04 23:22:58
tags:
  - spark
categories: [spark,语法解释]
---

# 缓存方法

[TOC]

来源: [spark中cache和persist的区别](http://blog.csdn.net/houmou/article/details/52491419)

## 相同点

在spark中，cache和persist都是用于将一个RDD进行缓存的，这样在之后的使用过程中就不需要重新进行计算了，可以大大节省程序运行的时间。

## 区别

两者的区别在于：cache 其实是调用了 persist 方法，缓存策略为 MEMORY_ONLY。而 persist 可以通过设置参数有多种缓存策略。

## persist12种策略

```scala
  val NONE = new StorageLevel(false, false, false, false)
  val DISK_ONLY = new StorageLevel(true, false, false, false)
  val DISK_ONLY_2 = new StorageLevel(true, false, false, false, 2)
  val MEMORY_ONLY = new StorageLevel(false, true, false, true)
  val MEMORY_ONLY_2 = new StorageLevel(false, true, false, true, 2)
  val MEMORY_ONLY_SER = new StorageLevel(false, true, false, false)
  val MEMORY_ONLY_SER_2 = new StorageLevel(false, true, false, false, 2)
  val MEMORY_AND_DISK = new StorageLevel(true, true, false, true)
  val MEMORY_AND_DISK_2 = new StorageLevel(true, true, false, true, 2)
  val MEMORY_AND_DISK_SER = new StorageLevel(true, true, false, false)
  val MEMORY_AND_DISK_SER_2 = new StorageLevel(true, true, false, false, 2)
  val OFF_HEAP = new StorageLevel(false, false, true, false)
```

这12种策略都是由5个参数决定的。StorageLevel 构造函数源码如下:

```scala
class StorageLevel private(
    private var _useDisk: Boolean,
    private var _useMemory: Boolean,
    private var _useOffHeap: Boolean,
    private var _deserialized: Boolean,
    private var _replication: Int = 1)
  extends Externalizable {
  ......
  def useDisk: Boolean = _useDisk
  def useMemory: Boolean = _useMemory
  def useOffHeap: Boolean = _useOffHeap
  def deserialized: Boolean = _deserialized
  def replication: Int = _replication
  ......
}
```



可以看到StorageLevel类的主构造器包含了5个参数：

- useDisk：使用硬盘（外存）
- useMemory：使用内存
- useOffHeap：使用堆外内存，这是Java虚拟机里面的概念，堆外内存意味着把内存对象分配在Java虚拟机的堆以外的内存，这些内存直接受操作系统管理（而不是虚拟机）。这样做的结果就是能保持一个较小的堆，以减少垃圾收集对应用的影响。
- deserialized：反序列化，其逆过程序列化（Serialization）是java提供的一种机制，将对象表示成一连串的字节；而反序列化就表示将字节恢复为对象的过程。序列化是对象永久化的一种机制，可以将对象及其属性保存起来，并能在反序列化后直接恢复这个对象
- replication：备份数（在多个节点上备份）



另外还注意到`OFF_HEAP`这种策略

```
val OFF_HEAP = new StorageLevel(false, false, true, false)
```

使用了堆外内存，它不能和其它几个参数共存。

```scala
if (useOffHeap) {
  require(!useDisk, "Off-heap storage level does not support using disk")
  require(!useMemory, "Off-heap storage level does not support using heap memory")
  require(!deserialized, "Off-heap storage level does not support deserialized storage")
  require(replication == 1, "Off-heap storage level does not support multiple replication")
}
```
---
title: spark问题-rdd分区2GB限制
date: 2017-06-04 23:22:58
tags: 
  - spark
  - todo
categories: [spark,数据处理实践]
---



spark在处理较大数据时，会遇到 Shuffle block 小于 2GB 的限制。一旦 Shuffle block 大于2GB，就会出现`Size exceeds Integer.MAX_VALUE`异常

<!--more-->

示例如下:

```text
java.lang.IllegalArgumentException: Size exceeds Integer.MAX_VALUE
    at sun.nio.ch.FileChannelImpl.map(FileChannelImpl.java:860)
    at org.apache.spark.storage.DiskStore$$anonfun$getBytes$2.apply(DiskStore.scala:127)
    at org.apache.spark.storage.DiskStore$$anonfun$getBytes$2.apply(DiskStore.scala:115)
    at org.apache.spark.util.Utils$.tryWithSafeFinally(Utils.scala:1250)
    at org.apache.spark.storage.DiskStore.getBytes(DiskStore.scala:129)
    at org.apache.spark.storage.DiskStore.getBytes(DiskStore.scala:136)
    at org.apache.spark.storage.BlockManager.doGetLocal(BlockManager.scala:503)
    at org.apache.spark.storage.BlockManager.getLocal(BlockManager.scala:420)
    at org.apache.spark.storage.BlockManager.get(BlockManager.scala:625)
    at org.apache.spark.CacheManager.getOrCompute(CacheManager.scala:44)
    at org.apache.spark.rdd.RDD.iterator(RDD.scala:268)
    at org.apache.spark.rdd.MapPartitionsRDD.compute(MapPartitionsRDD.scala:38)
    at org.apache.spark.rdd.RDD.computeOrReadCheckpoint(RDD.scala:306)
    at org.apache.spark.rdd.RDD.iterator(RDD.scala:270)
```

## 解决方案

1. 调大rdd分区数.

> spark.read.format("parquet").option("inferSchema", "true").load(app.inputDataPath).repartition(300)

2. spark.default.parallelism

> 该参数只对 raw rdd有效。无法对 dataFrame 产生作用。

3. spark.sql.shuffle.partitions 

> 执行 join或者 aggregations 方法后，shuffle过程中的分区数 

## 原因

Spark 使用 ByteBuffer 来存储 shuffle blocks。

然而，ByteBuffer 被限制为 Integer.MAX_SIZE (2GB)。

> ByteBuffer.allocate(int capacity)



## 参考

[rdd分区2GB限制](https://www.cnblogs.com/bourneli/p/4456109.html)
[top 5 mistakes to avoid when writing spark](https://www.slideshare.net/cloudera/top-5-mistakes-to-avoid-when-writing-apache-spark-applications/25)
[SparkSQL shuffle异常](https://www.jianshu.com/p/edd3ccc46980)
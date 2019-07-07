---
title: rdd dataframe dataset介绍
date: 2017-06-04 23:22:58
tags: 
  - spark
categories: [spark,语法解释]
---

# rdd dataframe dataset介绍

[TOC]

## 一、综述 

### 1.1 RDD和DataFrame内部结构

![rdd_dataframe](/images/RDD_DataFrame_DataSet/rdd_dataframe.png)

左侧的RDD[Person]虽然以Person为类型参数，但Spark框架本身不了解Person类的内部结构。而右侧的DataFrame却提供了详细的结构信息，使得Spark SQL可以清楚地知道该数据集中包含哪些列，每列的名称和类型各是什么。DataFrame多了数据的结构信息，即schema。

RDD是分布式的Java对象的集合。DataFrame是分布式的Row对象的集合。DataFrame除了提供了比RDD更丰富的算子以外，更重要的特点是提升执行效率、减少数据读取以及执行计划的优化，比如filter下推、裁剪等。

Dataset可以认为是DataFrame的一个特例，主要区别是Dataset每一个record存储的是一个强类型值而不是一个Row。

### 1.2 类型安全 

考虑静态类型和运行时类型安全，SQL有很少的限制而Dataset限制很多。例如，Spark SQL查询语句，你直到运行时才能发现语法错误(syntax error)，代价较大。然后DataFrame和Dataset在编译时就可捕捉到错误，节约开发时间和成本。

Dataset API都是lambda函数和JVM typed object，任何typed-parameters不匹配即会在编译阶段报错。因此使用Dataset节约开发时间。

![spark类型安全](/images/RDD_DataFrame_DataSet/spark类型安全.png)

## 二、RDD

RDD是Spark建立之初的核心API。RDD是`不可变` `分布式`弹性数据集，在Spark集群中可跨节点分区，并提供分布式low-level API来操作RDD，包括transformation和action。

### 2.1 优缺点

**优点:**

1. 编译时类型安全 
   编译时就能检查出类型错误
2. 面向对象的编程风格 
   直接通过类名点的方式来操作数据

**缺点:**

1. 序列化和反序列化的性能开销 
   无论是集群间的通信, 还是IO操作都需要对对象的结构和数据进行序列化和反序列化.
2. GC的性能开销 
   频繁的创建和销毁对象, 势必会增加GC

## 三、DataFrame

DataFrame与RDD类似，也是数据的不可变分布式集合，不同的是，数据被组织成了带名字的列，类似于关系型数据库中的表。

DataFrame引入了`schema`和`off-heap`

- schema : RDD每一行的数据, 结构都是一样的，这个结构就存储在schema中。 [Spark](http://lib.csdn.net/base/spark)通过schema就能够读懂数据, 因此在通信和IO时就只需要序列化和反序列化数据, 而结构的部分就可以省略了。
- off-heap : 意味着JVM堆以外的内存, 这些内存直接受[操作系统](http://lib.csdn.net/base/operatingsystem)管理（而不是JVM）。Spark能够以二进制的形式序列化数据(不包括结构)到off-heap中， 当要操作数据时，就直接操作off-heap内存。由于Spark理解schema，所以知道该如何操作。
- off-heap就像地盘，schema就像地图，Spark有地图又有自己地盘了，就可以自己说了算了，不再受JVM的限制，也就不再收GC的困扰了。

通过schema和off-heap，DataFrame解决了RDD的缺点，但是却丢了RDD的优点。DataFrame不是类型安全的，API也不是面向对象风格的。

**注：在Spark2.1中 DataFrame 的概念已经弱化了，将它视为 DataSet 的一种实现**

## 四、DataSet

从spark 2.0开始，两种独立的API特点：strongly-typed API 和untyped API。从概念上来说，将DataFrame作为 一般对象`Dataset[Row]`的集合的别名，而DataSet是strongly-typed JVM对象的集合，即java和scala中的类。 

DataSet结合了RDD和DataFrame的优点，并带来的一个新的概念Encoder。

当序列化数据时，Encoder产生字节码与off-heap进行交互，能够达到按需访问数据的效果，而不用反序列化整个对象。Spark还没有提供自定义Encoder的API，但是未来会加入。

### 4.1 DataSet与RDD 相比

- DataSet以Catalyst逻辑执行计划表示，并且数据以编码的二进制形式被存储，不需要反序列化就可以执行sorting、shuffle等操作。
- DataSet创立需要一个显式的Encoder，把对象序列化为二进制，可以把对象的scheme映射为Spark SQL类型，然而RDD依赖于运行时反射机制。

DataSet比RDD性能要好很多。

### 4.2 DataSet与DataFrame相比

Dataset可以认为是DataFrame的一个特例，主要区别是Dataset每一个record存储的是一个强类型值而不是一个Row。因此具有如下特点：

- DataSet可以在编译时检查类型
- DataSet是面向对象的编程接口。

DataFrame和DataSet可以相互转化，`df.as[ElementType]`这样可以把DataFrame转化为DataSet，`ds.toDF()`这样可以把DataSet转化为DataFrame。

## 五、3种类型转换

**在使用一些特殊的操作时，一定要加上 import spark.implicits._ 不然toDF、toDS无法使用**

### 5.1 DataFrame转DataSet

```scala
val dataFrame;
case class Persion(name:String,age:Long)
val dataSet = dataFrame.as[Persion]
```

### 5.2 RDD 转 DataFrame 

```Scala
case class Persion(name:String,age:Long)
val rdd;
val dataFrame = rdd.map(_.split(",")).map(attributes => Persion(attributes(0),attributes(1).trim.toLong)).toDF()
```

```scala
import org.apache.spark.sql.types._

val peopleRDD = spark.sparkContext.textFile("examples/src/main/resources/people.txt")
val schemaString = "name age"

val fields = schemaString.split(" ")
  .map(fieldName => StructField(fieldName, StringType, nullable = true))
val schema = StructType(fields)

val rowRDD = peopleRDD
  .map(_.split(","))
  .map(attributes => Row(attributes(0), attributes(1).trim))

val peopleDF = spark.createDataFrame(rowRDD, schema)
```

### 5.3  DataFrame 转 RDD

```Scala
val rdd1=testDF.rdd
val rdd2=testDS.rdd
```

### 5.4 RDD 转 DataSet

```Scala
import spark.implicits._
case class Coltest(col1:String,col2:Int)extends Serializable //定义字段名和类型
val testDS = rdd.map {line=>
      Coltest(line._1,line._2)
    }.toDS
```

### 5.5 DataSet 转 DataFrame 

```Scala
import spark.implicits._
val testDF = testDS.toDF
```


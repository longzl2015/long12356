---
title: DataFrame函数
date: 2017-06-04 00:00:01
tags: 
  - spark
categories: [spark,语法解释]
---

# DataFrame函数

[TOC]

## 一、Action 操作

### 1.1 collect() 

返回值是一个数组，返回dataframe集合所有的行

### 1.2 collectAsList() 

返回值是一个java类型的数组，返回dataframe集合所有的行

### 1.3  count() 

返回一个number类型的，返回dataframe集合的行数

### 1.4 describe(cols: String*) 

描述某些列的count, mean, stddev, min, max。这个可以传多个参数，中间用逗号分隔，如果有字段为空，那么不参与运算。

```scala
df.describe("age", "height").show()
```

### 1.5 first() 

返回第一行 ，类型是row类型

### 1.6 head() 

返回第一行 ，类型是row类型

### 1.7 head(n:Int)

返回n行  ，类型是row 类型

### 1.8 show()

返回dataframe集合的值 默认是20行，返回类型是unit

### 1.9  show(n:Int)

返回n行，返回值类型是unit

### 1.10 table(n:Int) 

返回n行  ，类型是row 类型

## 二、 dataframe的基本操作

### 2.1 cache()

将DataFrame缓存到内存中，以便之后加速运算

### 2.2 columns 

返回一个string类型的数组，返回值是所有列的名字

### 2.3 dtypes

返回一个string类型的二维数组，返回值是所有列的名字以及类型

### 2.4 explan()

打印物理执行计划  

### 2.5 explain(n:Boolean) 

输入值为 false 或者true ，返回值是unit  默认是false ，如果输入true 将会打印 逻辑的和物理的

### 2.6 isLocal 

返回值是Boolean类型，如果允许模式是local返回true 否则返回false

### 2.7 persist(newlevel:StorageLevel) 

与cache类似。不同的是：cache只有一个默认的缓存级别MEMORY_ONLY ，而persist可以根据情况设置其它的缓存级别。

### 2.8 printSchema() 

打印出字段名称和类型 按照树状结构来打印

### 2.9 registerTempTable(tablename:String) 

返回Unit ，将df的对象只放在一张表里面，这个表随着对象的删除而删除了

### 2.10 schema 

返回structType 类型，将字段名称和类型按照结构体类型返回

### 2.11 toDF()

返回一个新的dataframe类型的

### 2.12 toDF(colnames：String*)

将参数中的几个字段返回一个新的dataframe类型的，

### 2.13 unpersist() 

返回dataframe.this.type 类型，去除模式中的数据

### 2.14 unpersist(blocking:Boolean)

返回dataframe.this.type类型 true 和unpersist是一样的作用false 是去除RDD

##三、集成查询：

### 3.1 数据说明

```scala
import org.apache.spark.sql.SparkSession
val spark = SparkSession.builder().appName("Spark SQL basic example").config("spark.some.config.option", "some-value").getOrCreate()
import spark.implicits._
val df = spark.read.format("csv").option("header", true).load("/user/hadoop/csvdata/csvdata")
df.show()
scala >
scala> df.show()
+---+----+-------+-----+
| id|name|subject|score|
+---+----+-------+-----+
|  1|  n1|     s1|   10|
|  2|  n2|     s2|   20|
|  3|  n3|     s3|   30|
|  3|  n3|     s1|   20|
|  4|  n4|     s2|   40|
|  5|  n5|     s3|   50|
|  6|  n6|     s1|   60|
|  7|  n6|     s2|   40|
|  8|  n8|     s3|   90|
|  8|  n9|     s1|   30|
|  9|  n9|     s1|   20|
|  9|  n9|     s2|   70|
+---+----+-------+-----+
```

### 3.2 agg 

在整个数据集范围类进行聚合操作。该函数相当于：`ds.groupBy().agg(…)`

- 函数原型

1、 agg(expers:column*) 

```scala
df.agg(max("age"), avg("salary"))
df.groupBy().agg(max("age"), avg("salary"))
```

2、 agg(exprs: Map[String, String])  

```scala
df.agg(Map("age" -> "max", "salary" -> "avg"))
df.groupBy().agg(Map("age" -> "max", "salary" -> "avg"))
```

3、 agg(aggExpr: (String, String), aggExprs: (String, String)*)  

```scala
df.agg(Map("age" -> "max", "salary" -> "avg"))
df.groupBy().agg(Map("age" -> "max", "salary" -> "avg"))
```

- 例子：

```scala
scala> df.agg("score"->"avg", "score"->"max", "score"->"min", "score"->"count").show()
+----------+----------+----------+------------+
|avg(score)|max(score)|min(score)|count(score)|
+----------+----------+----------+------------+
|      40.0|        90|        10|          12|
+----------+----------+----------+------------+
```

### 3.3  groupBy

使用指定的列对数据集进行分组，以便我们可以对其进行聚合。请参阅RelationalGroupedDataset获取所有可用的聚合函数。 
这是groupBy的一个变体，它只能使用列名称对现有列进行分组（即不能构造表达式）。

- 函数原型

1、def groupBy(col1: String, cols: String*): RelationalGroupedDataset 
2、def groupBy(cols: Column*): RelationalGroupedDataset 

```scala
df.groupBy("age").agg(Map("age" ->"count")).show();
df.groupBy("age").avg().show();
```

- 例子1 

在使用groupBy函数时，一般都是先分组，在使用agg等聚合函数对数据进行聚合。 
按name字段进行聚合，然后再使用agg聚合函数进行聚合。

```scala
scala> df.groupBy("name").agg("score"->"avg").sort("name").show()
+----+----------+
|name|avg(score)|
+----+----------+
|  n1|      10.0|
|  n2|      20.0|
|  n3|      25.0|
|  n4|      40.0|
|  n5|      50.0|
|  n6|      50.0|
|  n8|      90.0|
|  n9|      40.0|
+----+----------+
```

- 例子2 

按id和name两个字段对数据集进行分组，然后求score列的平均值。

```scala
scala> df.groupBy("id","name").agg("score"->"avg").sort("name").show()
+---+----+----------+
| id|name|avg(score)|
+---+----+----------+
|  1|  n1|      10.0|
|  2|  n2|      20.0|
|  3|  n3|      25.0|
|  4|  n4|      40.0|
|  5|  n5|      50.0|
|  7|  n6|      40.0|
|  6|  n6|      60.0|
|  8|  n8|      90.0|
|  9|  n9|      45.0|
|  8|  n9|      30.0|
+---+----+----------+
```

- 例子3 

计算每个subject的平均分数：

```scala
scala> df.groupBy("subject").agg("score"->"avg").sort("subject").show()
+-------+------------------+
|subject|        avg(score)|
+-------+------------------+
|     s1|              28.0|
|     s2|              42.5|
|     s3|56.666666666666664|
+-------+------------------+
```

- 例子4 

同时计算多个列值的平均值，最小值，最大值。 
（注：我这里用的是同一列，完全可以是不同列）

```scala
scala> df.groupBy("subject").agg("score"->"avg", "score"->"max", "score"->"min", "score"->"count").sort("subject").show()
+-------+------------------+----------+----------+------------+
|subject|        avg(score)|max(score)|min(score)|count(score)|
+-------+------------------+----------+----------+------------+
|     s1|              28.0|        60|        10|           5|
|     s2|              42.5|        70|        20|           4|
|     s3|56.666666666666664|        90|        30|           3|
+-------+------------------+----------+----------+------------+
```

### 3.4 apply 和 col

根据列名选择列并将其作为列返回。

- 函数原型

```scala
def apply(colName: String): Column 
def col(colName: String): Column 
```

- 例子1

```scala
scala> df.apply("name")
res11: org.apache.spark.sql.Column = name

scala> df.col("name")
res16: org.apache.spark.sql.Column = name
```

### 3.7 cube

使用指定的列为当前数据集创建一个多维数据集，因此我们可以对它们运行聚合。请参阅RelationalGroupedDataset获取所有可用的聚合函数。 
这是立方体的变体，只能使用列名称对现有列进行分组（即不能构造表达式）。

- 原型

```scala
def cube(col1: String, cols: String*): RelationalGroupedDataset 
def cube(cols: Column*): RelationalGroupedDataset 
```

- 例子1

```scala
scala> df.cube("name", "score")
res18: org.apache.spark.sql.RelationalGroupedDataset = org.apache.spark.sql.RelationalGroupedDataset@3f88db17
```

### 3.8 drop

删除数据集中的某个列。

- 函数原型

```scala
def drop(col: Column): DataFrame 
def drop(colNames: String*): DataFrame 
def drop(colName: String): DataFrame 
```

- 例子1

```scala
scala> df.drop("id").show()
+----+-------+-----+
|name|subject|score|
+----+-------+-----+
|  n1|     s1|   10|
|  n2|     s2|   20|
|  n3|     s3|   30|
|  n3|     s1|   20|
|  n4|     s2|   40|
|  n5|     s3|   50|
|  n6|     s1|   60|
|  n6|     s2|   40|
|  n8|     s3|   90|
|  n9|     s1|   30|
|  n9|     s1|   20|
|  n9|     s2|   70|
+----+-------+-----+
```

### 3.9 join

- join类型的说明 
  内连接 : 只连接匹配的行 
  左外连接 : 包含左边表的全部行（不管右边的表中是否存在与它们匹配的行），以及右边表中全部匹配的行 
  右外连接 : 包含右边表的全部行（不管左边的表中是否存在与它们匹配的行），以及左边表中全部匹配的行 
  全外连接 : 包含左、右两个表的全部行，不管另外一边的表中是否存在与它们匹配的行。
- 功能说明 
  使用给定的连接表达式连接另一个DataFrame。以下执行df1和df2之间的完整外部联接。 
  使用给定的连接表达式与另一个DataFrame进行内部连接。 
  使用给定的列与另一个DataFrame进行设置连接。 
  加入另一个DataFrame。
- 函数原型

```scala
def join(right: Dataset[_], joinExprs: Column, joinType: String): DataFrame 
def join(right: Dataset[_], joinExprs: Column): DataFrame 
def join(right: Dataset[_], usingColumns: Seq[String], joinType: String): DataFrame 

def join(right: Dataset[_], usingColumns: Seq[String]): DataFrame 
// 内部使用给定的列与另一个DataFrame进行同等连接。
def join(right: Dataset[_], usingColumn: String): DataFrame 
def join(right: Dataset[_]): DataFrame 
```

注意：这里的joinType必须是这几个中的一个：`inner`, `outer`, `left_outer`, `right_outer`, `leftsemi`.

- 例子1 
  该例子演示inner join。

```scala
scala> df.show()
+---+----+-------+-----+
| id|name|subject|score|
+---+----+-------+-----+
|  1|  n1|     s1|   10|
|  2|  n2|     s2|   20|
|  3|  n3|     s3|   30|
|  3|  n3|     s1|   20|
|  4|  n4|     s2|   40|
|  5|  n5|     s3|   50|
|  6|  n6|     s1|   60|
|  7|  n6|     s2|   40|
|  8|  n8|     s3|   90|
|  8|  n9|     s1|   30|
|  9|  n9|     s1|   20|
|  9|  n9|     s2|   70|
+---+----+-------+-----+

scala> val df2 = df.select("id", "subject","score")
df2: org.apache.spark.sql.DataFrame = [id: string, subject: string ... 1 more field]

scala> df2.show()
+---+-------+-----+
| id|subject|score|
+---+-------+-----+
|  1|     s1|   10|
|  2|     s2|   20|
|  3|     s3|   30|
|  3|     s1|   20|
|  4|     s2|   40|
|  5|     s3|   50|
|  6|     s1|   60|
|  7|     s2|   40|
|  8|     s3|   90|
|  8|     s1|   30|
|  9|     s1|   20|
|  9|     s2|   70|
+---+-------+-----+

scala> val df3 = df.join(df2, df("id")===df2("id"))
17/12/03 21:40:59 WARN Column: Constructing trivially true equals predicate, 'id#0 = id#0'. Perhaps you need to use aliases.
df3: org.apache.spark.sql.DataFrame = [id: string, name: string ... 5 more fields]

scala> df3.show()
+---+----+-------+-----+---+-------+-----+
| id|name|subject|score| id|subject|score|
+---+----+-------+-----+---+-------+-----+
|  1|  n1|     s1|   10|  1|     s1|   10|
|  2|  n2|     s2|   20|  2|     s2|   20|
|  3|  n3|     s3|   30|  3|     s1|   20|
|  3|  n3|     s3|   30|  3|     s3|   30|
|  3|  n3|     s1|   20|  3|     s1|   20|
|  3|  n3|     s1|   20|  3|     s3|   30|
|  4|  n4|     s2|   40|  4|     s2|   40|
|  5|  n5|     s3|   50|  5|     s3|   50|
|  6|  n6|     s1|   60|  6|     s1|   60|
|  7|  n6|     s2|   40|  7|     s2|   40|
|  8|  n8|     s3|   90|  8|     s1|   30|
|  8|  n8|     s3|   90|  8|     s3|   90|
|  8|  n9|     s1|   30|  8|     s1|   30|
|  8|  n9|     s1|   30|  8|     s3|   90|
|  9|  n9|     s1|   20|  9|     s2|   70|
|  9|  n9|     s1|   20|  9|     s1|   20|
|  9|  n9|     s2|   70|  9|     s2|   70|
|  9|  n9|     s2|   70|  9|     s1|   20|
+---+----+-------+-----+---+-------+-----+

scala> val df4 = df2.limit(6)
df4: org.apache.spark.sql.Dataset[org.apache.spark.sql.Row] = [id: string, subject: string ... 1 more field]

scala> df4.show()
+---+-------+-----+
| id|subject|score|
+---+-------+-----+
|  1|     s1|   10|
|  2|     s2|   20|
|  3|     s3|   30|
|  3|     s1|   20|
|  4|     s2|   40|
|  5|     s3|   50|
+---+-------+-----+

scala> df.show()
+---+----+-------+-----+
| id|name|subject|score|
+---+----+-------+-----+
|  1|  n1|     s1|   10|
|  2|  n2|     s2|   20|
|  3|  n3|     s3|   30|
|  3|  n3|     s1|   20|
|  4|  n4|     s2|   40|
|  5|  n5|     s3|   50|
|  6|  n6|     s1|   60|
|  7|  n6|     s2|   40|
|  8|  n8|     s3|   90|
|  8|  n9|     s1|   30|
|  9|  n9|     s1|   20|
|  9|  n9|     s2|   70|
+---+----+-------+-----+

scala> val df6 = df.join(df4, "id")
df6: org.apache.spark.sql.DataFrame = [id: string, name: string ... 4 more fields]

scala> df6.show()
+---+----+-------+-----+-------+-----+
| id|name|subject|score|subject|score|
+---+----+-------+-----+-------+-----+
|  1|  n1|     s1|   10|     s1|   10|
|  2|  n2|     s2|   20|     s2|   20|
|  3|  n3|     s3|   30|     s1|   20|
|  3|  n3|     s3|   30|     s3|   30|
|  3|  n3|     s1|   20|     s1|   20|
|  3|  n3|     s1|   20|     s3|   30|
|  4|  n4|     s2|   40|     s2|   40|
|  5|  n5|     s3|   50|     s3|   50|
+---+----+-------+-----+-------+-----+
```

- 例子2 
  本例说明left_outer的使用和结果。 
  注意：数据集df4和df与上例的相同。 
  小结：通过例子可以看到，left_outer的效果是，保留左边表格的所有id，即使右边的表没有这些id（关联字段的值）

```scala
scala> df4.show()
+---+-------+-----+
| id|subject|score|
+---+-------+-----+
|  1|     s1|   10|
|  2|     s2|   20|
|  3|     s3|   30|
|  3|     s1|   20|
|  4|     s2|   40|
|  5|     s3|   50|
+---+-------+-----+

scala> df.show()
+---+----+-------+-----+
| id|name|subject|score|
+---+----+-------+-----+
|  1|  n1|     s1|   10|
|  2|  n2|     s2|   20|
|  3|  n3|     s3|   30|
|  3|  n3|     s1|   20|
|  4|  n4|     s2|   40|
|  5|  n5|     s3|   50|
|  6|  n6|     s1|   60|
|  7|  n6|     s2|   40|
|  8|  n8|     s3|   90|
|  8|  n9|     s1|   30|
|  9|  n9|     s1|   20|
|  9|  n9|     s2|   70|
+---+----+-------+-----+

scala> val df7 = df.join(df4, df("id")===df4("id"), "left_outer")
17/12/03 21:53:40 WARN Column: Constructing trivially true equals predicate, 'id#0 = id#0'. Perhaps you need to use aliases.
df7: org.apache.spark.sql.DataFrame = [id: string, name: string ... 5 more fields]

scala> df7.show()
+---+----+-------+-----+----+-------+-----+
| id|name|subject|score|  id|subject|score|
+---+----+-------+-----+----+-------+-----+
|  1|  n1|     s1|   10|   1|     s1|   10|
|  2|  n2|     s2|   20|   2|     s2|   20|
|  3|  n3|     s3|   30|   3|     s1|   20|
|  3|  n3|     s3|   30|   3|     s3|   30|
|  3|  n3|     s1|   20|   3|     s1|   20|
|  3|  n3|     s1|   20|   3|     s3|   30|
|  4|  n4|     s2|   40|   4|     s2|   40|
|  5|  n5|     s3|   50|   5|     s3|   50|
|  6|  n6|     s1|   60|null|   null| null|
|  7|  n6|     s2|   40|null|   null| null|
|  8|  n8|     s3|   90|null|   null| null|
|  8|  n9|     s1|   30|null|   null| null|
|  9|  n9|     s1|   20|null|   null| null|
|  9|  n9|     s2|   70|null|   null| null|
+---+----+-------+-----+----+-------+-----+
```

### 3.10 na

返回一个DataFrameNaFunctions以处理丢失的数据。

- 函数原型

```scala
def na: DataFrameNaFunctions 
```

注意：该函数会返回一个类型的类，该类包含了各种操作空列的函数。 
这些函数包括：drop(),fill(),replace(),fillCol(),replaceCol()

- 例子1

```scala
// 删除包含任何空值的行
scala> df.na.drop()
```

- 例子2

```scala
// 使用常量值填充空值
scala> df.na.fill("null")
```

### 3.11 select

选择一组列。注意：该函数返回的是一个DataFrame类。

- 函数原型

```scala
// 这是select的一个变体，只能使用列名选择现有的列（即不能构造表达式）。
def select(col: String, cols: String*): DataFrame 

// 选择一组基于列的表达式。
def select(cols: Column*): DataFrame 

// 选择一组SQL表达式。这是接受SQL表达式的select的一个变体。
def selectExpr(exprs: String*): DataFrame 
```

- 例子1

```scala
scala> df.select("id", "score").show()
+---+-----+
| id|score|
+---+-----+
|  1|   10|
|  2|   20|
|  3|   30|
|  3|   20|
|  4|   40|
|  5|   50|
|  6|   60|
|  7|   40|
|  8|   90|
|  8|   30|
|  9|   20|
|  9|   70|
+---+-----+
```

- 例子2：对select的列值进行操作

```scala
scala> df.select($"id", $"score"*10).show()
+---+------------+
| id|(score * 10)|
+---+------------+
|  1|       100.0|
|  2|       200.0|
|  3|       300.0|
|  3|       200.0|
|  4|       400.0|
|  5|       500.0|
|  6|       600.0|
|  7|       400.0|
|  8|       900.0|
|  8|       300.0|
|  9|       200.0|
|  9|       700.0|
+---+------------+
```

- 例子3：selectExpr的使用(select表达式)

```scala
ds.selectExpr("colA", "colB as newName", "abs(colC)")
或
ds.select(expr("colA"), expr("colB as newName"), expr("abs(colC)"))

scala> df.selectExpr("id", "score * 10").show()
+---+------------+
| id|(score * 10)|
+---+------------+
|  1|       100.0|
|  2|       200.0|
|  3|       300.0|
|  3|       200.0|
|  4|       400.0|
|  5|       500.0|
|  6|       600.0|
|  7|       400.0|
|  8|       900.0|
|  8|       300.0|
|  9|       200.0|
|  9|       700.0|
+---+------------+

或
scala> df.selectExpr("id", "score as points").show()
+---+------+
| id|points|
+---+------+
|  1|    10|
|  2|    20|
|  3|    30|
... ...
```

### 3.12 withColumn 和 withColumnRenamed

通过添加一列或替换具有相同名称的现有列来返回新的数据集。 
withColumnRenamed只是重命名列。 

- 函数原型

```scala
def withColumn(colName: String, col: Column): DataFrame 
def withColumnRenamed(existingName: String, newName: String): DataFrame 12
```

- 例子1：通过重命名现有列来添加新列

```scala
scala> val df8 = df.withColumn("subs", df("subject"))
df8: org.apache.spark.sql.DataFrame = [id: string, name: string ... 3 more fields]

scala> df8.show()
+---+----+-------+-----+----+
| id|name|subject|score|subs|
+---+----+-------+-----+----+
|  1|  n1|     s1|   10|  s1|
|  2|  n2|     s2|   20|  s2|
|  3|  n3|     s3|   30|  s3|
|  3|  n3|     s1|   20|  s1|
|  4|  n4|     s2|   40|  s2|
|  5|  n5|     s3|   50|  s3|
|  6|  n6|     s1|   60|  s1|
|  7|  n6|     s2|   40|  s2|
|  8|  n8|     s3|   90|  s3|
|  8|  n9|     s1|   30|  s1|
|  9|  n9|     s1|   20|  s1|
|  9|  n9|     s2|   70|  s2|
+---+----+-------+-----+----+
```

- 例子2：重命名现有列，但不添加新列

从下面的例子中可以看出，把score列的值替换了，但并没有添加新的列。

```scala
scala> val df9 = df.withColumn("score", df("score")/100)
df9: org.apache.spark.sql.DataFrame = [id: string, name: string ... 2 more fields]

scala> df9.show()
+---+----+-------+-----+
| id|name|subject|score|
+---+----+-------+-----+
|  1|  n1|     s1|  0.1|
|  2|  n2|     s2|  0.2|
|  3|  n3|     s3|  0.3|
|  3|  n3|     s1|  0.2|
|  4|  n4|     s2|  0.4|
|  5|  n5|     s3|  0.5|
|  6|  n6|     s1|  0.6|
|  7|  n6|     s2|  0.4|
|  8|  n8|     s3|  0.9|
|  8|  n9|     s1|  0.3|
|  9|  n9|     s1|  0.2|
|  9|  n9|     s2|  0.7|
+---+----+-------+-----+


// 也可以直接通过withColumnRenamed进行重命名
scala> val df9 = df.withColumnRenamed("score","score2") 
df9: org.apache.spark.sql.DataFrame = [id: string, name: string ... 2 more fields]

scala> df9.show()
+---+----+-------+------+
| id|name|subject|score2|
+---+----+-------+------+
|  1|  n1|     s1|    10|
|  2|  n2|     s2|    20|
|  3|  n3|     s3|    30|
|  3|  n3|     s1|    20|
|  4|  n4|     s2|    40|
|  5|  n5|     s3|    50|
|  6|  n6|     s1|    60|
|  7|  n6|     s2|    40|
|  8|  n8|     s3|    90|
|  8|  n9|     s1|    30|
|  9|  n9|     s1|    20|
|  9|  n9|     s2|    70|
+---+----+-------+-----
```

### 3.13 stat

为工作统计功能支持返回一个DataFrameStatFunctions。 
该类的函数包括：approxQuantile,corr,cov,freqItems,sampleBy,countMinSketch,bloomFilter,buildBloomFilter等

- 函数原型

```scala
def stat: DataFrameStatFunctions 
```

- 例子1

```scala
scala> val cols = Array("score")
cols: Array[String] = Array(score)

scala> df.stat.freqItems(cols)
res56: org.apache.spark.sql.DataFrame = [score_freqItems: array<string>]

scala> df.stat.freqItems(cols).show()
+--------------------+
|     score_freqItems|
+--------------------+
|[90, 30, 60, 50, ...|
+--------------------+
```

### 3.14 其他

 - as(alias: String) 返回一个新的dataframe类型，就是原来的一个别名
 -  distinct 去重 返回一个dataframe类型
 - dropDuplicates(colNames: Array[String]) 删除相同的列 返回一个dataframe
 - except(other: DataFrame) 返回一个dataframe，返回在当前集合存在的在其他集合不存在的
 - explode[A, B](inputColumn: String, outputColumn: String)(f: (A) ⇒ TraversableOnce[B])(implicit arg0: scala.reflect.api.JavaUniverse.TypeTag[B]) 返回值是dataframe类型，这个 将一个字段进行更多行的拆分

  ```scala
  df.explode("name","names") {name :String=> name.split(" ")}.show();
  将name字段根据空格来拆分，拆分的字段放在names里面
  ```

 - filter(conditionExpr: String): 刷选部分数据，返回dataframe类型 

  ```scala
  df.filter("age>10").show();   
  df.filter(df("age")>10).show();   
  df.where(df("age")>10).show();
  ```

- intersect(other: DataFrame) 返回一个dataframe，在2个dataframe都存在的元素
- limit(n: Int) 返回dataframe类型  去n 条数据出来
- orderBy(sortExprs: Column*)  做alise排序
- sort(sortExprs: Column*)    排序 df.sort(df("age").desc).show(); 默认是asc
- unionAll(other:Dataframe) 合并 df.unionAll(ds).show();


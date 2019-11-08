---
title: RDD函数
date: 2017-06-04 00:00:02
tags: 
  - spark
categories: [spark,语法解释]
---

# RDD函数

[TOC]

RDD提供了两种类型的操作：transformation和action

所有的transformation都是采用的懒策略，如果只是将transformation提交是不会执行计算的，计算只有在action被提交的时候才被触发。

## 一、基本RDD

抽象类`RDD`包含了各种数据类型的RDD都适用的通用操作。

### 1.1 transformation操作 
针对各个元素的转化操作
#### 1.1.1 map(func) 
对各个元素进行映射操作

#### 1.1.2 flatMap(func)

对各个元素进行映射操作，并将最后结果展平。

#### 1.1.3 filter(func) 
过滤不满足条件的元素。filter操作可能会引起数据倾斜，甚至可能导致空分区，新形成的RDD将会包含这些可能生成的空分区。所有这些都可能会导致问题，要想解决它们，最好在filter之后重新分区。

### 1.2 伪集合操作

尽管RDD不是严格意义上的集合，但它支持许多数学上的集合操作。注意：这些操作都要求操作的RDD是相同的数据类型的。

#### 1.2.1 distinct(func) 

对RDD中的元素进行去重处理。需要注意的是，distinct操作开销很大，因为它需要shuffle所有数据，以确保每一个元素都只有一份。

#### 1.2.2 union(otherDataset)

返回一个包含两个或多个RDD中所有元素的RDD。spark的union并不会去重，这点与数学上的不同。

#### 1.2.3 intersection

返回两个RDD中都有的元素。intersection会在运行时除去所有重复的元素，因此它也需要shuffle，性能要差一些。

#### 1.2.4 subtract

返回一个由只存在于第一个RDD中而不存在于第二个RDD中的所有元素组成的RDD。它也需要shuffle

#### 1.2.5 cartesian(otherDataset)

笛卡尔积。但在数据集T和U上调用时，返回一个(T，U）对的数据集，所有元素交互进行笛卡尔积。

#### 1.2.6 sample(withReplacement, frac, seed)

根据给定的随机种子seed，随机抽样出数量为frac的数据

### 1.3 基于分区的转化操作

#### 1.3.1 glom
将每个分区中的所有元素都形成一个数组。如果在处理当前元素时需要使用前后的元素，该操作将会非常有用，不过有时我们可能还需要将分区边界的数据收集起来并广播到各节点以备使用。

#### 1.3.2 mapPartitions
基于分区的map，spark对每个分区的迭代器进行操作。

普通的map算子对RDD中的每一个元素进行操作，而 mapPartitions 算子对RDD中每一个分区进行操作。

- 如果是普通的map算子，假设一个partition有1万条数据，那么map算子中的function要执行1万次，也就是对每个元素进行操作。
- 如果是mapPartition算子，由于一个task处理一个RDD的partition，那么一个task只会执行一次function，function一次接收所有的partition数据，效率比较高。

#### 1.3.3 mapPartitionsWithIndex
与mapPartitions不同之处在于带有分区的序号。

### 1.4 管道(pipe)操作

spark在RDD上提供了`pipe()`方法。通过pipe()，你可以使用任意语言将RDD中的各元素从标准输入流中以字符串形式读出，并将这些元素执行任何你需要的操作，然后把结果以字符串形式写入标准输出，这个过程就是RDD的转化操作过程。

使用pipe()的方法很简单，假如我们有一个用其他语言写成的从标准输入接收数据并将处理结果写入标准输出的可执行脚本，我们只需要将该脚本分发到各个节点相同路径下，并将其路径作为pipe()的参数传入即可。

### 1.5 action操作

#### 1.5.1 foreach(func)
对每个元素进行操作，并不会返回结果。这通常用于更新一个累加器变量，或者和外部存储系统做交互

#### 1.5.2 foreachPartition
基于分区的foreach操作，操作分区元素的迭代器，并不会返回结果。

#### 1.5.3 reduce(func) 
通过函数func聚集数据集中的所有元素。Func函数接受2个参数，返回一个值。这个函数必须是关联性的，确保可以被正确的并发执行

#### 1.5.4 fold
与reduce类似，不同的是，它接受一个“初始值”来作为每个分区第一次调用时的结果。fold同样要求规约函数返回值类型与RDD元素类型相同。

#### 1.5.5 aggregate
与reduce和fold类似，但它把我们从返回值类型必须与所操作的RDD元素类型相同的限制中解放出来。

该函数签名如下:

```scala
 def aggregate[U: ClassTag](zeroValue: U)(seqOp: (U, T) => U, combOp: (U, U) => U): U = withScope {...}
```

zeroValue
 
> 需要注意的是，**zeroValue 会被每一个分区计算一次**.
> 计算过程中的初始值，同时也确定了最终结果的类型

seqOp 函数 : 对分区中的元素进行迭代计算，将一个分区中的所有元素聚合为一个 U 类型的结果。

> 参数U 的来源 : 1 zeroValue ; 2 seqOp 的输出结果。即当前的聚合结果。
> 参数T 的来源 : 原始数据分区中的元素

combOp 函数 : 对 seqOp 函数 产生的结果进行聚合。

> 参数U 的来源 : seqOp 进行聚合后，产生的结果。

https://stackoverflow.com/questions/28240706/explain-the-aggregate-functionality-in-spark/38949457

#### 1.5.6 count() 
返回数据集的元素个数

#### 1.5.7 collect() 
以数组的形式，返回数据集的所有元素到Driver节点。collect()函数通常在使用filter或者其它操作减少数据量的函数后再使用。因为如果返回的数据量很大，很可能会让Driver程序OOM

#### 1.5.8 take(n) 
返回指定数量的元素到driver节点。它会尝试只访问尽量少的分区，因此该操作会得到一个不均衡的集合。需要注意的是，该操作返回元素的顺序与你预期的可能不一样。

#### 1.5.9  top
如果为元素定义了顺序，就可以使用top返回前几个元素。

#### 1.5.10  takeSample
返回采样数据。

## 二、键值对RDD

`PairRDDFunctions`封装了用于操作键值对RDD的一些功能函数。一些文件读取操作(`sc.sequenceFile()`等)会直接返回RDD[(K, V)]类型。在RDD上使用map操作也可以将一个RDD转换为RDD[(K, V)]类型。在用Scala书写的Spark程序中，RDD[(K, V)]类型到PairRDDFunctions类型的转换一般由隐式转换函数完成。

### 2.1  transformation操作
针对各个元素的转化操作
#### 2.1.1 mapValues
对各个键值对的值进行映射。该操作会保留RDD的分区信息。
#### 2.1.2 flatMapValues
对各个键值对的值进行映射，并将最后结果展平。该操作会保留RDD的分区信息。

### 2.2 聚合操作
#### 2.2.1 reduceByKey(func, [numTasks]) 
与reduce相当类似，它们都接收一个函数，并使用该函数对值进行合并。不同的是，reduceByKey是transformation操作，reduceByKey只是对键相同的值进行规约，并最终形成RDD[(K, V)]，而不像reduce那样返回单独一个“值”。
#### 2.2.2 foldByKey
与fold类似，就像reduceByKey之于reduce那样。熟悉MapReduce中的合并器(combiner)概念的你可能已经注意到，reduceByKey和foldByKey会在为每个键计算全局的总结果之前先自动在每台机器上进行本地合并。用户不需要指定合并器。更泛化的combineByKey可以让你自定义合并的行为。
#### 2.2.3 combineByKey
是最常用的基于键进行聚合的函数，大多数基于键聚合的函数都是用它实现的。与aggregate一样，combineByKey可以让用户返回与输入数据的类型不同的返回值。combineByKey的内部实现分为三步来完成：首先根据是否需要在map端进行combine操作决定是否对RDD先进行一次mapPartitions操作(利用createCombiner、mergeValue、mergeCombiners三个函数)来达到减少shuffle数据量的作用。第二步根据partitioner对MapPartitionsRDD进行shuffle操作。最后在reduce端对shuffle的结果再进行一次combine操作。
### 2.3 分组操作
#### 2.3.1 groupBy
根据自定义的东东进行分组。groupBy是基本RDD就有的操作。
#### 2.3.2 groupByKey
根据键对数据进行分组。虽然groupByKey+reduce也可以实现reduceByKey一样的效果，但是请你记住：groupByKey是低效的，而reduceByKey会在本地先进行聚合，然后再通过网络传输求得最终结果。
在执行聚合或分组操作时，可以指定分区数以对并行度进行调优。

### 2.4 连接操作
#### 2.4.1 cogroup
可以对多个RDD进行连接、分组、甚至求键的交集。其他的连接操作都是基于cogroup实现的。
#### 2.4.2 join
对数据进行内连接，也即当两个键值对RDD中都存在对应键时才输出。当一个输入对应的某个键有多个值时，生成的键值对RDD会包含来自两个输入RDD的每一组相对应的记录，也即笛卡尔积。
#### 2.4.3 leftOuterJoin
即左外连接，源RDD的每一个键都有对应的记录，第二个RDD的值可能缺失，因此用Option表示。
#### 2.4.4 rightOuterJoin
即右外连接，与左外连接相反。
#### 2.4.5 fullOuterJoin
即全外连接，它是是左右外连接的并集。

如果一个RDD需要在多次连接操作中使用，对该RDD分区并持久化分区后的RDD是有益的，它可以避免不必要的shuffle。

### 2.5 数据排序：

在基本类型RDD中，`sortBy()`可以用来排序，`max()`和`min()`则可以用来方便地获取最大值和最小值。另外，在OrderedRDDFunctions中，存在一个sortByKey()可以方便地对键值对RDD进行排序，通过spark提供的隐式转换函数可以将RDD自动地转换为OrderedRDDFunctions，并随意地使用它的排序功能。

### 2.6行动操作：

键值对RDD提供了一些额外的行动操作供我们随意使用。如下：

#### 2.6.1 countByKey
对每个键对应的元素分别计数。
#### 2.6.2 collectAsMap
将结果以Map的形式返回，以便查询。
#### 2.6.3 lookup:
返回给定键对应的所有值。

## 三、数值Rdd

DoubleRDDFunctions为包含数值数据的RDD提供了一些描述性的统计操作，RDD可以通过隐式转换方便地使用这些方便的功能。

这些数值操作是通过流式算法实现的，允许以每次一个元素的方式构建出模型。这些统计数据都会在调用stats()时通过一次遍历数据计算出来，并以StatCounter对象返回。如果你只想计算这些统计数据中的一个，也可以直接对RDD调用对应的方法。更多信息参见Spark API。

## 参考

[spark使用总结](http://smallx.me/2016/06/07/spark%E4%BD%BF%E7%94%A8%E6%80%BB%E7%BB%93/)
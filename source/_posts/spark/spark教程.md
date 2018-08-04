
---
title: spark使用教程
tags: 
  - spark
categories:
  - spark
---

# spark使用教程

文章来源：[spark使用教程](http://smallx.me/2016/06/07/spark%E4%BD%BF%E7%94%A8%E6%80%BB%E7%BB%93/)

> 本文是spark的使用教程，文中主要用scala来讲解spark，并且会尽量覆盖较新版本的spark的内容。这篇文章主要记录了一些我平时学到的spark知识，虽然较长，但它并没有包含spark的方方面面，更多更全的spark教程和信息请在[spark官网](http://spark.apache.org/)观看。

# 第一个Spark程序

```
/**
 * 功能：用spark实现的单词计数程序
 * 环境：spark 1.6.1, scala 2.10.4
 */

// 导入相关类库
import org.apache.spark._

object WordCount {
  def main(args: Array[String]) {
    // 建立spark运行上下文
    val sc = new SparkContext("local[3]", "WordCount", new SparkConf())

    // 加载数据，创建RDD
    val inRDD = sc.textFile("words.txt", 3)

    // 对RDD进行转换，得到最终结果
    val res = inRDD.flatMap(_.split(' ')).map((_, 1)).reduceByKey(_ + _)

    // 将计算结果collect到driver节点，并打印
    res.collect.foreach(println)

    // 停止spark运行上下文
    sc.stop()
  }
}

```

# 关于RDD

弹性分布式数据集(RDD)是分布式处理的一个数据集的抽象，**RDD是只读的，在RDD之上的操作都是并行的**。实际上，RDD只是一个逻辑实体，其中存储了分布式数据集的一些信息，并没有包含所谓的“物理数据”，“物理数据”只有在RDD被计算并持久化之后才存在于内存或磁盘中。RDD的重要内部属性有：

- 计算RDD分区的函数。
- 所依赖的直接父RDD列表。
- RDD分区及其地址列表。
- RDD分区器。
- RDD分区优先位置。

RDD操作起来与Scala集合类型没有太大差别，这就是Spark追求的目标：像编写单机程序一样编写分布式程序，但它们的数据和运行模型有很大的不同，用户需要具备更强的系统把控能力和分布式系统知识。

## Transformation与Action

RDD提供了两种类型的操作：**transformation操作**(转化操作)和**action操作**(行动操作)。transformation操作是得到一个新的**RDD**，方式很多，比如从数据源生成一个新的RDD，从RDD生成一个新的RDD。action操作则是得到**其他数据类型**的结果。

所有的transformation都是采用的懒策略，就是如果只是将transformation提交是不会执行计算的，spark在内部只是用新的RDD记录这些transformation操作并形成RDD对象的有向无环图(DAG)，计算只有在action被提交的时候才被触发。实际上，我们不应该把RDD看作存放着特定数据的数据集，而最好把每个RDD当作我们通过transformation操作构建出来的、记录如何计算数据的指令列表。

RDD的action算子会触发一个新的job，spark会在DAG中寻找是否有cached或者persisted的中间结果，如果没有找到，那么就会重新执行这些中间过程以重新计算该RDD。因此，如果想在多个action操作中重用同一个RDD，那么最好使用 `cache()`/`persist()`将RDD缓存在内存中，但如果RDD过大，那么最好使用 `persist(StorageLevel.MEMORY_AND_DISK)` 代替。注意cache/persist仅仅是设置RDD的存储等级，因此你应该在第一次调用action之前调用cache/persist。cache/persist使得中间计算结果存在内存中，这个才是说为啥Spark是内存计算引擎的地方。在MR里，你是要放到HDFS里的，但Spark允许你把中间结果放内存里。

**在spark程序中打印日志时，尤其需要注意打印日志的代码很有可能使用到了action算子，如果没有缓存中间RDD就可能导致程序的效率大大降低。另外，如果一个RDD的计算过程中有抽样、随机值或者其他形式的变化，那么一定要缓存中间结果，否则程序执行结果可能都是不准确的！**

> 参考链接及进一步阅读：
>
> - [Spark会把数据都载入到内存么？](http://www.jianshu.com/p/b70fe63a77a8)
>
>
> - [Using Spark’s cache for correctness, not just performance](http://www.spark.tc/using-sparks-cache-for-correctness-not-just-performance/)

## RDD持久化(缓存)

正如在转化和行动操作部分所说的一样，为了避免在一个RDD上多次调用action操作从而可能导致的重新计算，我们应该将该RDD在第一次调用action之前进行持久化。对RDD进行持久化对于迭代式和交互式应用非常有好处，好处大大滴有。

持久化可以使用`cache()`或者`persist()`。默认情况下的缓存级别为`MEMORY_ONLY`，spark会将对象直接缓存在JVM的堆空间中，而不经过序列化处理。我们可以给persist()传递持久化级别参数以指定的方式持久化RDD。`MEMORY_AND_DISK`持久化级别尽量将RDD缓存在内存中，如果内存缓存不下了，就将剩余分区缓存在磁盘中。`MEMORY_ONLY_SER`将RDD进行序列化处理(每个分区序列化为一个字节数组)然后缓存在内存中。还有`MEMORY_AND_DISK_SER`等等很多选项。选择持久化级别的原则是：尽量选择缓存在内存中，如果内存不够，则首选序列化内存方式，除非RDD分区重算开销比缓存到磁盘来的更大(很多时候，重算RDD分区会比从磁盘中读取要快)或者序列化之后内存还是不够用，否则不推荐缓存到磁盘上。

如果要缓存的数据太多，内存中放不下，spark会自动利用最近最少使用(LRU)策略把最老的分区从内存中移除。对于仅放在内存中的缓存级别，下次要用到已被移除的分区时，这些分区就需要重新计算。对于使用内存与磁盘的缓存级别，被移除的分区都会被写入磁盘。

另外，RDD还有一个`unpersist()`方法，用于手动把持久化的RDD从缓存中移除。

环境变量`SPARK_LOCAL_DIRS`用来设置RDD持久化到磁盘的目录，它同时也是shuffle的缓存目录。

## 各种RDD与RDD操作

### 基本RDD

抽象类`RDD`包含了各种数据类型的RDD都适用的通用操作。下面对基本类型RDD的操作进行分门别类地介绍。

**针对各个元素的转化操作：**

- **map**: 对各个元素进行映射操作。
- **flatMap**: 对各个元素进行映射操作，并将最后结果展平。


- **filter**: 过滤不满足条件的元素。filter操作可能会引起数据倾斜，甚至可能导致空分区，新形成的RDD将会包含这些可能生成的空分区。所有这些都可能会导致问题，要想解决它们，最好在filter之后重新分区。

**伪集合操作：**

尽管RDD不是严格意义上的集合，但它支持许多数学上的集合操作。注意：这些操作都要求操作的RDD是相同的数据类型的。

- **distinct**: 对RDD中的元素进行去重处理。需要注意的是，distinct操作开销很大，因为它需要shuffle所有数据，以确保每一个元素都只有一份。
- **union**: 返回一个包含两个或多个RDD中所有元素的RDD。spark的union并不会去重，这点与数学上的不同。
- **intersection**: 返回两个RDD中都有的元素。intersection会在运行时除去所有重复的元素，因此它也需要shuffle，性能要差一些。
- **subtract**: 返回一个由只存在于第一个RDD中而不存在于第二个RDD中的所有元素组成的RDD。它也需要shuffle。
- **cartesian**: 计算两个RDD的笛卡尔积。需要注意的是，求大规模RDD的笛卡尔积开销巨大。
- **sample**: 对RDD进行采样，返回一个采样RDD。

**基于分区的转化操作：**

- **glom**: 将每个分区中的所有元素都形成一个数组。如果在处理当前元素时需要使用前后的元素，该操作将会非常有用，不过有时我们可能还需要将分区边界的数据收集起来并广播到各节点以备使用。


- **mapPartitions**: 基于分区的map，spark会为操作分区的函数该分区的元素的迭代器。
- **mapPartitionsWithIndex**: 与mapPartitions不同之处在于带有分区的序号。

**管道(pipe)操作：**

spark在RDD上提供了`pipe()`方法。通过pipe()，你可以使用任意语言将RDD中的各元素从标准输入流中以字符串形式读出，并将这些元素执行任何你需要的操作，然后把结果以字符串形式写入标准输出，这个过程就是RDD的转化操作过程。

使用pipe()的方法很简单，假如我们有一个用其他语言写成的从标准输入接收数据并将处理结果写入标准输出的可执行脚本，我们只需要将该脚本分发到各个节点相同路径下，并将其路径作为pipe()的参数传入即可。

**行动操作：**

- **foreach**: 对每个元素进行操作，并不会返回结果。
- **foreachPartition**: 基于分区的foreach操作，操作分区元素的迭代器，并不会返回结果。
- **reduce**: 对RDD中所有元素进行规约，最终得到一个规约结果。reduce接收的规约函数要求其返回值类型与RDD中元素类型相同。
- **fold**: 与reduce类似，不同的是，它接受一个“初始值”来作为每个分区第一次调用时的结果。fold同样要求规约函数返回值类型与RDD元素类型相同。
- **aggregate**: 与reduce和fold类似，但它把我们从返回值类型必须与所操作的RDD元素类型相同的限制中解放出来。
- **count**: 返回RDD元素个数。
- **collect**: 收集RDD的元素到driver节点，如果数据有序，那么collect得到的数据也会是有序的。大数据量最好不要使用RDD的collect，因为它会在本机上生成一个新的Array，以存储来自各个节点的所有数据，此时更好的办法是将数据存储在HDFS等分布式持久化层上。
- **take**: 返回指定数量的元素到driver节点。它会尝试只访问尽量少的分区，因此该操作会得到一个不均衡的集合。需要注意的是，该操作返回元素的顺序与你预期的可能不一样。
- **top**: 如果为元素定义了顺序，就可以使用top返回前几个元素。
- **takeSample**: 返回采样数据。

### 键值对RDD

`PairRDDFunctions`封装了用于操作键值对RDD的一些功能函数。一些文件读取操作(`sc.sequenceFile()`等)会直接返回RDD[(K, V)]类型。在RDD上使用map操作也可以将一个RDD转换为RDD[(K, V)]类型。在用Scala书写的Spark程序中，RDD[(K, V)]类型到PairRDDFunctions类型的转换一般由隐式转换函数完成。

基本类型RDD的操作同样适用于键值对RDD。下面对键值对类型RDD特有的操作进行分门别类地介绍。

**针对各个元素的转化操作：**

- **mapValues**: 对各个键值对的值进行映射。该操作会保留RDD的分区信息。
- **flatMapValues**: 对各个键值对的值进行映射，并将最后结果展平。该操作会保留RDD的分区信息。

**聚合操作：**

- **reduceByKey**: 与reduce相当类似，它们都接收一个函数，并使用该函数对值进行合并。不同的是，reduceByKey是transformation操作，reduceByKey只是对键相同的值进行规约，并最终形成RDD[(K, V)]，而不像reduce那样返回单独一个“值”。
- **foldByKey**: 与fold类似，就像reduceByKey之于reduce那样。熟悉MapReduce中的合并器(combiner)概念的你可能已经注意到，reduceByKey和foldByKey会在为每个键计算全局的总结果之前先自动在每台机器上进行本地合并。用户不需要指定合并器。更泛化的combineByKey可以让你自定义合并的行为。
- **combineByKey**: 是最常用的基于键进行聚合的函数，大多数基于键聚合的函数都是用它实现的。与aggregate一样，combineByKey可以让用户返回与输入数据的类型不同的返回值。combineByKey的内部实现分为三步来完成：首先根据是否需要在map端进行combine操作决定是否对RDD先进行一次mapPartitions操作(利用createCombiner、mergeValue、mergeCombiners三个函数)来达到减少shuffle数据量的作用。第二步根据partitioner对MapPartitionsRDD进行shuffle操作。最后在reduce端对shuffle的结果再进行一次combine操作。

**数据分组：**

- **groupBy**: 根据自定义的东东进行分组。groupBy是基本RDD就有的操作。
- **groupByKey**: 根据键对数据进行分组。虽然`groupByKey`+`reduce`也可以实现`reduceByKey`一样的效果，但是请你记住：groupByKey是低效的，而reduceByKey会在本地先进行聚合，然后再通过网络传输求得最终结果。

> 在执行聚合或分组操作时，可以指定分区数以对并行度进行调优。

**连接：**

- **cogroup**: 可以对多个RDD进行连接、分组、甚至求键的交集。其他的连接操作都是基于cogroup实现的。
- **join**: 对数据进行内连接，也即当两个键值对RDD中都存在对应键时才输出。当一个输入对应的某个键有多个值时，生成的键值对RDD会包含来自两个输入RDD的每一组相对应的记录，也即笛卡尔积。
- **leftOuterJoin**: 即左外连接，源RDD的每一个键都有对应的记录，第二个RDD的值可能缺失，因此用Option表示。
- **rightOuterJoin**: 即右外连接，与左外连接相反。
- **fullOuterJoin**: 即全外连接，它是是左右外连接的并集。

> 如果一个RDD需要在多次连接操作中使用，对该RDD分区并持久化分区后的RDD是有益的，它可以避免不必要的shuffle。

**数据排序：**

在基本类型RDD中，`sortBy()`可以用来排序，`max()`和`min()`则可以用来方便地获取最大值和最小值。另外，在OrderedRDDFunctions中，存在一个`sortByKey()`可以方便地对键值对RDD进行排序，通过spark提供的隐式转换函数可以将RDD自动地转换为OrderedRDDFunctions，并随意地使用它的排序功能。

**行动操作：**

键值对RDD提供了一些额外的行动操作供我们随意使用。如下：

- **countByKey**: 对每个键对应的元素分别计数。
- **collectAsMap**: 将结果以Map的形式返回，以便查询。
- **lookup**: 返回给定键对应的所有值。

### 数值RDD

`DoubleRDDFunctions`为包含数值数据的RDD提供了一些描述性的统计操作，RDD可以通过隐式转换方便地使用这些方便的功能。

这些数值操作是通过流式算法实现的，允许以每次一个元素的方式构建出模型。这些统计数据都会在调用`stats()`时通过一次遍历数据计算出来，并以`StatCounter`对象返回。如果你只想计算这些统计数据中的一个，也可以直接对RDD调用对应的方法。更多信息参见Spark API。

## RDD依赖、窄宽依赖

### RDD依赖与DAG

一系列转化操作形成RDD的有向无环图(DAG)，行动操作触发作业的提交与执行。每个RDD维护了其对**直接父RDD**(一个或多个)的依赖，其中包含了父RDD的引用和依赖类型信息，通过`dependencies()`我们可以获取对应RDD的依赖，其返回一个依赖列表。

通过RDD的父RDD引用就可以从DAG上向前回溯找到其所有的祖先RDD。spark提供了`toDebugString`方法来查看RDD的谱系。对于如下一段简单的代码：

```
val input = sc.parallelize(1 to 10)
val repartitioned = input.repartition(2)
val sum = repartitioned.sum

```

我们就可以通过在RDD上调用toDebugString来查看其依赖以及转化关系，结果如下：

```
// input.toDebugString
res0: String = (4) ParallelCollectionRDD[0] at parallelize at <console>:21 []

// repartitioned.toDebugString
res1: String =
(2) MapPartitionsRDD[4] at repartition at <console>:23 []
 |  CoalescedRDD[3] at repartition at <console>:23 []
 |  ShuffledRDD[2] at repartition at <console>:23 []
 +-(4) MapPartitionsRDD[1] at repartition at <console>:23 []
    |  ParallelCollectionRDD[0] at parallelize at <console>:21 []

```

上述`repartitioned`的依赖链存在两个缩进等级。同一缩进等级的转化操作构成一个Stage(阶段)，它们不需要混洗(shuffle)数据，并可以流水线执行(pipelining)。

### 窄依赖和宽依赖

spark中RDD之间的依赖分为**窄(Narrow)依赖**和**宽(Wide)依赖**两种。我们先放出一张示意图：

[![窄依赖和宽依赖](http://smallx.me/2016/06/07/spark%E4%BD%BF%E7%94%A8%E6%80%BB%E7%BB%93/%E7%AA%84%E4%BE%9D%E8%B5%96%E5%92%8C%E5%AE%BD%E4%BE%9D%E8%B5%96.jpg)](http://smallx.me/2016/06/07/spark%E4%BD%BF%E7%94%A8%E6%80%BB%E7%BB%93/%E7%AA%84%E4%BE%9D%E8%B5%96%E5%92%8C%E5%AE%BD%E4%BE%9D%E8%B5%96.jpg)

**窄依赖**指父RDD的每一个分区最多被一个子RDD的分区所用，表现为一个父RDD的分区对应于一个子RDD的分区，或多个父RDD的分区对应于一个子RDD的分区。图中，map/filter和union属于第一类，对输入进行协同划分(co-partitioned)的join属于第二类。

**宽依赖**指子RDD的分区依赖于父RDD的多个或所有分区，这是因为**shuffle**类操作，如图中的groupByKey和未经协同划分的join。

窄依赖对优化很有利。逻辑上，每个RDD的算子都是一个fork/join(此join非上文的join算子，而是指同步多个并行任务的barrier(路障))： 把计算fork到每个分区，算完后join，然后fork/join下一个RDD的算子。如果直接翻译到物理实现，是很不经济的：一是每一个RDD(即使 是中间结果)都需要物化到内存或存储中，费时费空间；二是join作为全局的barrier，是很昂贵的，会被最慢的那个节点拖死。如果子RDD的分区到父RDD的分区是窄依赖，就可以实施经典的fusion优化，把两个fork/join合为一个；如果连续的变换算子序列都是窄依赖，就可以把很多个fork/join并为一个，不但减少了大量的全局barrier，而且无需物化很多中间结果RDD，这将极大地提升性能。Spark把这个叫做流水线(pipeline)优化。关于流水线优化，从MapPartitionsRDD中compute()的实现就可以看出端倪，该compute方法只是对迭代器进行复合，复合就是嵌套，因此数据处理过程就是对每条记录进行同样的嵌套处理直接得出所需结果，而没有中间计算结果，同时也要注意：依赖过长将导致嵌套过深，从而可能导致栈溢出。

转换算子序列一碰上shuffle类操作，宽依赖就发生了，流水线优化终止。在具体实现 中，DAGScheduler从当前算子往前回溯依赖图，一碰到宽依赖，就生成一个stage来容纳已遍历的算子序列。在这个stage里，可以安全地实施流水线优化。然后，又从那个宽依赖开始继续回溯，生成下一个stage。

另外，宽窄依赖的划分对spark的容错也具有重要作用，参见本文容错机制部分。

### DAG到任务的划分

用户代码定义RDD的有向无环图，行动操作把DAG转译为执行计划，进一步生成任务在集群中调度执行。

具体地说，RDD的一系列转化操作形成RDD的DAG，在RDD上调用行动操作将触发一个Job(作业)的运行，Job根据DAG中RDD之间的依赖关系(宽依赖/窄依赖，也即是否发生shuffle)的不同将DAG划分为多个Stage(阶段)，一个Stage对应DAG中的一个或多个RDD，一个Stage对应多个RDD是因为发生了流水线执行(pipelining)，一旦Stage划分出来，Task(任务)就会被创建出来并发给内部的调度器，进而分发到各个executor执行，一个Stage会启动很多Task，每个Task都是在不同的数据分区上做同样的事情(即执行同样的代码段)，Stage是按照依赖顺序处理的，而Task则是独立地启动来计算出RDD的一部分，一旦Job的最后一个Stage结束，一个行动操作也就执行完毕了。

Stage分为两种：**ShuffleMapStage**和**ResultStage**。**ShuffleMapStage**是非最终stage，后面还有其他的stage，所以它的输出一定是需要shuffle并作为后续stage的输入。ShuffleMapStage的最后Task就是**ShuffleMapTask**。**ResultStage**是一个Job的最后一个Stage，直接生成结果或存储。ResultStage的最后Task就是**ResultTask**。一个Job含有一个或多个Stage，最后一个为ResultTask，其他都为ShuffleMapStage。

## RDD不能嵌套

RDD嵌套是不被支持的，也即不能在一个RDD操作的内部再使用RDD。如果在一个RDD的操作中，需要访问另一个RDD的内容，你可以尝试join操作，或者将数据量较小的那个RDD广播(broadcast)出去。

你同时也应该注意到：join操作可能是低效的，将其中一个较小的RDD广播出去然后再join可以避免不必要的shuffle，俗称“小表广播”。

## 使用其他分区数据

由于RDD不能嵌套，这使得“在计算一个分区时，访问另一个分区的数据”成为一件困难的事情。那么有什么好的解决办法吗？请继续看。

spark依赖于RDD这种抽象模型进行粗粒度的并行计算，一般情况下每个节点的每次计算都是针对单一记录，当然也可以使用 RDD.mapPartition 来对分区进行处理，但都限制在一个分区内(当然更是一个节点内)。

spark的worker节点相互之间不能直接进行通信，如果在一个节点的计算中需要使用到另一个分区的数据，那么还是有一定的困难的。

你可以将整个RDD的数据全部广播(如果数据集很大，这可不是好办法)，或者广播一些其他辅助信息；也可以从所有节点均可以访问到的文件(hdfs文件)或者数据库(关系型数据库或者hbase)中读取；更进一步或许你应该修改你的并行方案，使之满足“可针对拆分得到的小数据块进行并行的独立的计算，然后归并得到大数据块的计算结果”的MapReduce准则，在“划分大的数据，并行独立计算，归并得到结果”的过程中可能存在数据冗余之类的，但它可以解决一次性没法计算的大数据，并最终提高计算效率，hadoop和spark都依赖于MapReduce准则。

## 对RDD进行分区

### 何时进行分区？

spark程序可以通过控制RDD分区方式来减少通信开销。分区并不是对所有应用都是有好处的，如果给定RDD只需要被扫描一次，我们完全没有必要对其预先进行分区处理。只有当数据集多次在诸如连接这种基于键的操作中使用时，分区才会有帮助，同时记得将分区得到的新RDD持久化哦。

更多的分区意味着更多的并行任务(Task)数。对于shuffle过程，如果分区中数据量过大可能会引起OOM，这时可以将RDD划分为更多的分区，这同时也将导致更多的并行任务。spark通过线程池的方式复用executor JVM进程，每个Task作为一个线程存在于线程池中，这样就减少了线程的启动开销，可以高效地支持单个executor内的多任务执行，这样你就可以放心地将任务数量设置成比该应用分配到的CPU cores还要多的数量了。

### 如何分区与分区信息

在创建RDD的时候，可以指定分区的个数，如果没有指定，则分区个数是系统默认值，即该程序所分配到的CPU核心数。在Java/Scala中，你可以使用`rdd.getNumPartitions`(1.6.0+)或`rdd.partitions.size()`来获取分区个数。

对基本类型RDD进行重新分区，可以通过`repartition()`函数，只需要指定重分区的分区数即可。repartition操作会引起shuffle，因此spark提供了一个优化版的repartition，叫做`coalesce()`，它允许你指定是否需要shuffle。在使用coalesce时，需要注意以下几个问题：

- coalesce默认shuffle为false，这将形成窄依赖，例如我们将1000个分区重新分到100个中时，并不会引起shuffle，而是原来的10个分区合并形成1个分区。


- 但是对于从很多个(比如1000个)分区重新分到很少的(比如1个)分区这种极端情况，数据将会分布到很少节点(对于从1000到1的重新分区，则是1个节点)上运行，完全无法开掘集群的并行能力，为了规避这个问题，可以设置shuffle为true。由于shuffle可以分隔stage，这就保证了上一阶段stage中的任务仍是很多个分区在并行计算，不这样设置的话，则两个上下游的任务将合并成一个stage进行计算，这个stage便会在很少的分区中进行计算。


- 如果当前每个分区的数据量过大，需要将分区数量增加，以利于充分利用并行，这时我们可以设置shuffle为true。对于数据分布不均而需要重分区的情况也是如此。spark默认使用hash分区器将数据重新分区。

对RDD进行预置的hash分区，需将RDD转换为RDD[(key,value)]类型，然后就可以通过隐式转换为PairRDDFunctions，进而可以通过如下形式将RDD哈希分区，`HashPartitioner`会根据RDD中每个(key,value)中的key得出该记录对应的新的分区号：

```
PairRDDFunctions.partitionBy(new HashPartitioner(n))

```

另外，spark还提供了一个范围分区器，叫做`RangePartitioner`。范围分区器争取将所有的分区尽可能分配得到相同多的数据，并且所有分区内数据的上界是有序的。

一个RDD可能存在分区器也可能没有，我们可以通过RDD的`partitioner`属性来获取其分区器，它返回一个Option对象。

### 如何进行自定义分区

spark允许你通过提供一个自定义的Partitioner对象来控制RDD的分区方式，这可以让你利用领域知识进一步减少通信开销。

要实现自定义的分区器，你需要继承`Partitioner`类，并实现下面三个方法即可：

- **numPartitions**: 返回创建出来的分区数。
- **getPartition**: 返回给定键的分区编号(0到numPartitions-1)。
- **equals**: Java判断相等性的标准方法。这个方法的实现非常重要，spark需要用这个方法来检查你的分区器对象是否和其他分区器实例相同，这样spark才可以判断两个RDD的分区方式是否相同。

### 影响分区方式的操作

spark内部知道各操作会如何影响分区方式，并将会对数据进行分区的操作的结果RDD自动设置为对应的分区器。

不过转化操作的结果并不一定会按照已知的分区方式分区，这时输出的RDD可能就会丢失分区信息。例如，由于`map()`或`flatMap()`函数理论上可以改变元素的键，因此当你对一个哈希分区的键值对RDD调用map/flatMap时，结果RDD就不会再有分区方式信息。不过，spark提供了另外两个操作`mapValues()`和`flatMapValues()`作为替代方法，它们可以保证每个二元组的键保持不变。

这里列出了所有会为生成的结果RDD设好分区方式的操作：`cogroup()`、 `join()`、 `leftOuterJoin()`、 `rightOuterJoin()`、 `fullOuterJoin()`、`groupWith()`、 `groupByKey()`、 `reduceByKey()`、 `combineByKey()`、 `partitionBy()`、 `sortBy()`、 `sortByKey()`、 `mapValues()`(如果父RDD有分区方式的话)、 `flatMapValues()`(如果父RDD有分区方式的话)、 `filter()`(如果父RDD有分区方式的话) 等。其他所有操作生成的结果都不会存在特定的分区方式。

最后，对于二元操作，输出数据的分区方式取决于父RDD的分区方式。默认情况下，结果会采用哈希分区，分区的数量和操作的并行度一样。不过，如果其中一个父RDD已经设置过分区方式，那么结果就会采用那种分区方式；如果两个父RDD都设置过分区方式，结果RDD会采用第一个父RDD的分区方式。

### 从分区中获益的操作

spark的许多操作都引入了将数据根据键跨节点进行shuffle的过程。所有这些操作都会从数据分区中获益。这些操作主要有：`cogroup()`、 `join()`、 `leftOuterJoin()`、 `rightOuterJoin()`、 `fullOuterJoin()`、 `groupWith()`、 `groupByKey()`、 `reduceByKey()`、 `combineByKey()`、 `lookup()` 等。

## RDD分区优先位置

RDD分区优先位置与spark的调度有关，在spark进行任务调度的时候，会尽可能将任务分配到数据块所存储的节点。我们可以通过RDD的`preferredLocations()`来获取指定分区的优先位置，返回值是该分区的优先位置列表。

# 数据加载与保存

## 从程序中的集合生成

`sc.parallelize()`可用于从程序中的集合产生RDD。`sc.makeRDD()`也是在程序中生成RDD，不过其还允许指定每一个RDD分区的优先位置。

以上这些方式一般用于原型开发和测试，因为它们需要把你的整个数据集先放在一台机器(driver节点)的内存中，从而限制了只能用较小的数据量。

## 从文本文件加载数据

`sc.textFile()`默认从hdfs中读取文件，在路径前面加上`hdfs://`可显式表示从hdfs中读取文件，在路径前面加上`file://`表示从本地文件系统读。给sc.textFile()传递的文件路径可以是如下几种情形：

- 一个文件路径，这时候只装载指定的文件。
- 一个目录路径，这时候只装载指定目录下面的所有文件(不包括子目录下面的文件)。
- 通过通配符的形式加载多个文件或者加载多个目录下面的所有文件。

如果想一次性读取一个目录下面的多个文件并想知道数据来自哪个文件，可以使用`sc.wholeTextFiles`。它会返回一个键值对RDD，其中键是输入文件的文件名。由于该函数会将一个文件作为RDD的一个元素进行读取，因此所读取的文件不能太大，以便其可以在一个机器上装得下。

同其他transform算子一样，文本读取操作也是惰性的并由action算子触发，如果发生重新计算，那么读取数据的操作也可能会被再次执行。另外，在spark中超出内存大小的文件同样是可以被处理的，因为spark并不是将数据一次性全部装入内存，而是边装入边计算。

## 从数据库加载数据

spark中可以使用`JdbcRDD`从数据库中加载数据。spark会将数据从数据库中拷贝到集群各个节点，因此使用JdbcRDD会有初始的拷贝数据的开销。也可以考虑使用sqoop将数据从数据库中迁移到hdfs中，然后从hdfs中读取数据。

## 将结果写入文本文件

`rdd.saveAsTextFile()`用于将RDD写入文本文件。spark会将传入该函数的路径参数作为目录对待，默认情况下会在对应目录输出多个文件，这取决于并行度。如果要将结果写入hdfs的**一个**文件中，可以这样：

```
rdd.coalesce(1).saveAsTextFile("filename")

```

而不要使用repartition，因为repartition会引起shuffle，而coalesce在默认情况下会避免shuffle。

## 关于文件系统

spark支持读写很多文件系统，包括本地文件系统、HDFS、Amazon S3等等很多。

spark在本地文件系统中读取文件时，它要求文件在集群中所有节点的相同路径下都可以找到。我们可以通过`sc.addFile()`来将文件弄到所有节点同路径下面，并在各计算节点中通过`SparkFiles.get()`来获取对应文件在该节点上的绝对路径。

> `sc.addFile()`的输入文件路径不仅可以是本地文件系统的，还可以是HDFS等spark所支持的所有文件系统，甚至还可以是来自网络的，如HTTP、HTTPS、FTP。

# 关于并行

## 慎用可变数据

当可变数据用于并发/并行/分布式程序时，都有可能出现问题，因此对于会并发执行的代码段不要使用可变数据。

尤其要注意不要在scala的object中使用var变量！其实scala的object单例对象只是对java中静态的一种封装而已，在class文件层面，object单例对象就是用java中静态(static)来实现的，而java静态成员变量不会被序列化！在编写并行计算程序时，不要在scala的object中使用var变量，如果确实需要使用var变量，请写在class中。

另外，在分布式执行的spark代码段中使用可变的闭包变量也可能会出现不同步问题，因此请谨慎使用。

## 闭包 vs 广播变量

有两种方式将你的数据从driver节点发送到worker节点：通过**闭包**和通过**广播变量**。闭包是随着task的组装和分发自动进行的，而广播变量则是需要程序猿手动操作的，具体地可以通过如下方式操作广播变量(假设`sc`为`SparkContext`类型的对象，`bc`为`Broadcast`类型的对象)：

- 可通过`sc.broadcast(xxx)`创建广播变量。
- 可在各计算节点中(闭包代码中)通过`bc.value`来引用广播的数据。
- `bc.unpersist()`可将各executor中缓存的广播变量删除，后续再使用时数据将被重新发送。
- `bc.destroy()`可将广播变量的数据和元数据一同销毁，销毁之后就不能再使用了。

任务闭包包含了任务所需要的代码和数据，如果一个executor数量小于RDD partition的数量，那么每个executor就会得到多个同样的任务闭包，这通常是低效的。而广播变量则只会将数据发送到每个executor一次，并且可以在多个计算操作中共享该广播变量，而且广播变量使用了类似于p2p形式的非常高效的广播算法，大大提高了效率。另外，广播变量由spark存储管理模块进行管理，并以MEMORY_AND_DISK级别进行持久化存储。

**什么时候用闭包自动分发数据？**情况有几种：

- 数据比较小的时候。
- 数据已在driver程序中可用。典型用例是常量或者配置参数。

**什么时候用广播变量分发数据？**情况有几种：

- 数据比较大的时候(实际上，spark支持非常大的广播变量，甚至广播变量中的元素数超过java/scala中Array的最大长度限制(2G，约21.5亿)都是可以的)。
- 数据是某种分布式计算结果。典型用例是训练模型等中间计算结果。

当数据或者变量很小的时候，我们可以在Spark程序中直接使用它们，而无需使用广播变量。

对于大的广播变量，序列化优化可以大大提高网络传输效率，参见本文序列化优化部分。

## 巧用累加器

累加器提供了将工作节点中的值聚合到驱动器程序中的简单语法。累加器的一个常见用途是在调试时对作业执行过程中的事件进行计数。可以通过`sc.accumulator(xxx)`来创建一个累加器，并在各计算节点中(闭包代码中)直接写该累加器。

累加器只能在驱动程序中被读取，对于计算节点(闭包代码)是只写的，这大大精简了累加器的设计。

使用累加器时，我们要注意的是：对于在RDD转化操作中使用的累加器，如果发生了重新计算(这可能在很多种情况下发生)，那么累加器就会被重复更新，这会导致问题。而在行动操作(如foreach)中使用累加器却不会出现这种情况。因此，在转化操作中，累加器通常只用于调试目的。尽管将来版本的spark可能会改善这一问题，但在spark 1.2.0中确实存在这个问题。

## 关于shuffle

在经典的MapReduce中，shuffle(混洗)是连接map阶段和reduce阶段的桥梁(注意这里的术语跟spark的map和reduce操作没有直接关系)，它是将各个map的输出结果重新组合作为下阶段各个reduce的输入这样的一个过程，由于这一过程涉及各个节点相互之间的数据传输，故此而名“混洗”。下面这幅图清晰地描述了MapReduce算法的整个流程，其中shuffle阶段是介于map阶段和reduce阶段之间。[![mapreduce过程](http://smallx.me/2016/06/07/spark%E4%BD%BF%E7%94%A8%E6%80%BB%E7%BB%93/mapreduce%E8%BF%87%E7%A8%8B.jpg)](http://smallx.me/2016/06/07/spark%E4%BD%BF%E7%94%A8%E6%80%BB%E7%BB%93/mapreduce%E8%BF%87%E7%A8%8B.jpg)

Spark的shuffle过程类似于经典的MapReduce，但是有所改进。spark中的shuffle在实现上主要分为**shuffle write**和**shuffle fetch**这两个大的阶段。如下图所示，shuffle过程大致可以描述为：

[![spark-shuffle过程](http://smallx.me/2016/06/07/spark%E4%BD%BF%E7%94%A8%E6%80%BB%E7%BB%93/spark-shuffle%E8%BF%87%E7%A8%8B.png)](http://smallx.me/2016/06/07/spark%E4%BD%BF%E7%94%A8%E6%80%BB%E7%BB%93/spark-shuffle%E8%BF%87%E7%A8%8B.png)

- 首先每一个Mapper会根据Reducer的数量创建出相应的bucket，bucket的数量是M×R，其中M是Map的个数，R是Reduce的个数。
- 其次Mapper产生的结果会根据设置的partition算法填充到每个bucket中去。这里的partition算法是可以自定义的，当然默认的算法是根据key哈希到不同的bucket中去。
- 当Reducer启动时，它会根据自己task的id和所依赖的Mapper的id从远端或是本地的block manager中取得相应的bucket作为Reducer的输入进行处理。

spark的shuffle实现随着spark版本的迭代正在逐步完善和成熟，这中间曾出现过多种优化实现，关于spark shuffle的演进过程和具体实现参见后面的参考链接。

shuffle(具体地是shuffle write阶段)会引起数据缓存到本地磁盘文件，从spark 1.3开始，这些缓存的shuffle文件只有在相应RDD不再被使用时才会被清除，这样在lineage重算的时候shuffle文件就不需要重新创建了，从而加快了重算效率(请注意这里的缓存并保留shuffle数据这一行为与RDD持久化和检查点机制是不同的，缓存并保留shuffle数据只是省去了重算时重建shuffle文件的开销，因此我们才有理由在shuffle(宽依赖)之后对形成的RDD进行持久化)。在standalone模式下，我们可以在`spark-env.sh`中通过环境变量`SPARK_LOCAL_DIRS`来设置shuffle数据的本地磁盘缓存目录。为了优化效率，本地shuffle缓存目录的设置都应该使用由单个逗号隔开的目录列表，并且这些目录分布在不同的磁盘上，写操作会被均衡地分配到所有提供的目录中，磁盘越多，可以提供的总吞吐量就越高。另外，`SPARK_LOCAL_DIRS`也是RDD持久化到磁盘的目录。

> 参考链接及进一步阅读：
>
> - [详细探究Spark的shuffle实现](http://jerryshao.me/architecture/2014/01/04/spark-shuffle-detail-investigation/)
> - [Spark Shuffle operations](http://spark.apache.org/docs/latest/programming-guide.html#shuffle-operations)

## 序列化优化

在spark中，序列化通常出现在跨节点的数据传输(如广播变量、shuffle等)和数据持久化过程中。序列化和反序列化的速度、序列化之后数据大小等都影响着集群的计算效率。

spark默认使用Java序列化库，它对于除基本类型的数组以外的任何对象都比较低效。为了优化序列化效率，你可以在spark配置文件中通过`spark.serializer`属性来设置你想使用的序列化库，一般情况下，你可以使用这个序列化库：`org.apache.spark.serializer.KryoSerializer`。

为了获得最佳性能，你还应该向Kryo注册你想要序列化的类，注册类可以让Kryo避免把每个对象的完整类名写下来，成千上万条记录累计节省的空间相当可观。如果你想强制要求这种注册，可以把`spark.kryo.registrationRequired`设置为true，这样Kryo会在遇到未注册的类时抛出错误。使用Kryo序列化库并注册所需类的示例如下：

```
val conf = new SparkConf()
conf.set("spark.serializer", "org.apache.spark.serializer.KryoSerializer")
conf.set("spark.kryo.registrationRequired", "true")
conf.registerKryoClasses(Array(classOf[MyClass], classOf[MyOtherClass]))

```

# Spark调度

## 应用调度

应用是指用户提交的spark应用程序。spark应用程序之间的调度关系，不一定由spark所管理。

在YARN和Mesos模式下，底层资源的调度策略由YARN和Mesos集群资源管理器所决定。

只有在standalone模式下，spark master按照当前集群资源是否满足等待列表中的spark应用对资源的需求，而决定是否创建一个SparkContext对应的driver，进而完成spark应用的启动过程，这个过程可以粗略地认为是一种粗颗粒度的有条件的**FIFO**(先进先出)调度策略。

## 作业调度

作业是指spark应用程序内部的由action算子触发并提交的Job。在给定的spark应用中，不同线程的多个job可以并发执行，并且这个调度是线程安全的，这使得一个spark应用可以处理多个请求。

默认地，spark作业调度是**FIFO**的，在多线程的情况下，某些线程提交的job可能被大大推迟执行。

不过我们可以通过配置**FAIR**(公平)调度器来使spark在作业之间轮询调度，这样所有的作业都能得到一个大致公平的共享的集群资源。这就意味着即使有一个很长的作业在运行，较短的作业在提交之后也能够得到不错的响应。要启用一个FAIR作业调度，需在创建SparkContext之前配置一下`spark.scheduler.mode`为`FAIR`：

```
// 假设conf是你的SparkConf变量
conf.set("spark.scheduler.mode", "FAIR")

```

公平调度还支持在池中将工作分组(这样就形成两级调度池)，而不同的池可以设置不同的调度选项(如权重)。这种方式允许更重要的job配置在高优先级池中优先调度。如果没有设置，新提交的job将进入**默认池**中，我们可以通过在对应线程中给SparkContext设置本地属性`spark.scheduler.pool`来设置该线程对应的pool：

```
// 假设sc是你的SparkContext变量
sc.setLocalProperty("spark.scheduler.pool", "pool1")

```

在设置了本地属性之后，所有在这个线程中提交的job都将会使用这个调度池的名字。如果你想清除该线程相关的pool，只需调用如下代码：

```
sc.setLocalProperty("spark.scheduler.pool", null)

```

在默认情况下，每个调度池拥有相同的优先级来共享整个应用所分得的集群资源。同样的，**默认池中的每个job也拥有同样的调度优先级，但是在用户创建的每个池中，job是通过FIFO方式进行调度的**。

关于公平调度池的详细配置，请参见官方文档：[Spark Job Scheduling](http://spark.apache.org/docs/latest/job-scheduling.html)。

如果你想阅读相关实现代码，可以观看`Schedulable.scala`、`SchedulingAlgorithm.scala`以及`SchedulableBuilder.scala`等相关文件。

> 参考链接及进一步阅读：
>
> - [Spark Job Scheduling](http://spark.apache.org/docs/latest/job-scheduling.html)
> - [Spark 作业调度–job执行方式介绍](http://www.aboutyun.com/thread-7600-1-1.html)
> - [spark internal - 作业调度](http://blog.csdn.net/colorant/article/details/24010035)

# 容错机制与检查点

spark容错机制是粗粒度并且是轻量级的，主要依赖于RDD的依赖链(**lineage**)。spark能够通过lineage获取足够的信息来重新计算和恢复丢失的数据分区。这样的基于lineage的容错机制可以理解为粗粒度的重做日志(redo log)。

鉴于spark的基于lineage的容错机制，RDD DAG中宽窄依赖的划分对容错也有很重要的作用。如果一个节点宕机了，而且运算是窄依赖，那只要把丢失的父RDD分区重算即可，跟其他节点没有依赖。而宽依赖需要父RDD的所有分区都存在，重算代价就很高了。可以这样理解为什么窄依赖开销小而宽依赖开销大：在窄依赖中，在子RDD分区丢失、重算父RDD分区时，父RDD相应分区的所有数据都是子RDD分区的数据，并不存在冗余计算；而在宽依赖中，丢失一个子RDD分区将导致其每个父RDD的多个甚至所有分区的重算，而重算的结果并不都是给当前丢失的子RDD分区用的，这样就存在了冗余计算。

不过我们可以通过**检查点**(**checkpoint**)机制解决上述问题，通过在RDD上做检查点可以将物理RDD数据存储到持久层(HDFS、S3等)中。在RDD上做检查点的方法是在调用action算子之前调用`checkpoint()`，并且RDD最好是缓存在内存中的，否则可能导致重算(参见API注释)。示例如下：

```
// 假设rdd是你的RDD变量
rdd.persist(StorageLevel.MEMORY_AND_DISK_SER)
rdd.checkpoint()
val count = rdd.count()

```

在RDD上做检查点会切断RDD依赖，具体地spark会清空该RDD的父RDD依赖列表。并且由于检查点机制是将RDD存储在外部存储系统上，所以它可以被其他应用重用。

过长的lineage(如在pagerank、spark streaming等中)也将导致过大的重算代价，而且还会占用很多系统资源。因此，**在遇到宽依赖或者lineage足够长时，我们都应该考虑做检查点**。

# 集群监控与运行日志

spark在应用执行时记录详细的进度信息和性能指标。这些内容可以在两个地方找到：spark的网页用户界面以及driver进程和executor进程生成的日志文件中。

## 网页用户界面

在浏览器中打开 [http://master:8080](http://master:8080/) 页面，你可以看到集群概况，包括：集群节点、可用的和已用的资源、已运行的和正在运行的应用等。

[http://master:4040](http://master:4040/) 页面用来监控正在运行的应用(默认端口为4040，如果有多个应用在运行，那么端口顺延，如4041、4042)，包括其执行进度、构成Job的Stage的执行情况、Stage详情、已缓存RDD的信息、各executor的信息、spark配置项以及应用依赖信息等，该页面经常用来发现应用的效率瓶颈并辅助优化，不过该页面只有在有spark应用运行时才可以被访问到。

上述404x端口可用于查看正在运行的应用的执行详情，但是应用运行结束之后该页面就不可以访问了。要想查看已经执行结束的应用的执行详情，则需开启事件日志机制，具体地设置如下两个选项：

- spark.eventLog.enabled: 设置为true时开启事件日志机制。这样已完成的spark作业就可以通过历史服务器查看。

- spark.eventLog.dir: 开启事件日志机制时的事件日志文件存储位置。如果要在历史服务器中查看事件日志，需要将该值设置为一个全局可见的文件系统路径，比如HDFS中。最后，请确保目录以 ‘/‘ 结束，否则可能会出现如下错误：

  ```
  Application history not found ... No event logs found for application ...
  Did you specify the correct logging directory?

  ```

在配置好上述选项之后，我们就可以查看新提交的应用的详细执行信息了。在不同的部署模式中，查看的方式不同。在standalone模式中，可以直接在master节点的UI界面(上述8080端口对应的页面)中直接单击已完成应用以查看详细执行信息。在YARN/Mesos模式中，就要开启历史服务器了，此处略去。

## Metrics系统

spark在其内部拥有一个可配置的度量系统(Metrics)，它能够将spark的内部状态通过HTTP、JMX、CSV等多种不同形式呈现给用户。同时，用户也可以定义自己的数据源(Metrics Source)和数据输出方式(Metrics Sink)，从而获取自己所需的数据。此处略去详情，可参考下面的链接进一步阅读。

> 参考链接及进一步阅读：
>
> - [Spark Monitoring and Instrumentation: Metrics](http://spark.apache.org/docs/latest/monitoring.html#metrics)

## 查看日志文件

spark日志文件的具体位置取决于具体的部署模式。在standalone模式中，日志默认存储于各个工作节点的spark目录下的`work`目录中，此时所有日志还可以直接通过主节点的网页用户界面进行查看。

默认情况下，spark输出的日志包含的信息量比较合适。我们可以自定义日志行为，改变日志等级或存储位置。spark日志系统使用`log4j`实现，我们只需将conf目录下的log4j.properties.template复制一个并命名为log4j.properties，然后自定义修改即可。

# SparkConf与配置

spark中最主要的配置机制是通过`SparkConf`类对spark进行配置。当创建出一个SparkContext时，就需要创建出一个SparkConf的实例作为参数。

SparkConf实例包含用户要重载的配置选项的键值对，spark中的每个配置选项都是基于字符串形式的键值对。你可以调用SparkConf的`set()`或者`setXxx()`来设置对应选项。

另外，spark-submit脚本可以动态设置配置项。当应用被spark-submit脚本启动时，脚本会把这些配置项设置到运行环境中。当一个新的SparkConf被创建出来时，这些环境变量会被检测出来并且自动配到SparkConf中。这样在使用spark-submit时，用户应用通常只需创建一个“空”的SparkConf，并直接传递给SparkContext的构造方法即可。

spark-submit为常用的spark配置选项提供了专用的标记，还有一个通用标记`--conf`来接收任意spark配置项的值，形如`--conf 属性名=属性值`。

spark-submit也支持从文件中读取配置项的值。默认情况下，spark-submit会在spark安装目录中找到`conf/spark-defaults.conf`文件，读取该文件中以空格隔开的键值对数据。你也可以通过spark-submit的`--properties-File`选项来自定义该文件的路径。

> spark-defaults.conf的作用范围要搞清楚，编辑driver所在机器上的spark-defaults.conf，该文件会影响到driver所提交运行的application，及专门为该application提供计算资源的executor的启动参数。

spark有特定的优先级顺序来选择实际配置。优先级最高的是在用户代码中显式调用set()方法设置的选项。其次是通过spark-submit传递的参数。再次是写在配置文件中的值。最后是系统默认值。如果你想知道应用中实际生效的配置，可以在应用的网页用户界面中查看。

下面列出一些常用的配置项，完整的配置项列表可以参见[官方配置文档](http://spark.apache.org/docs/latest/configuration.html)。

| 选项                            | 默认值                   | 描述                                                         |
| ------------------------------- | ------------------------ | ------------------------------------------------------------ |
| spark.master                    | (none)                   | 表示要连接的集群管理器。                                     |
| spark.app.name                  | (none)                   | 应用名，将出现在UI和日志中。                                 |
| spark.driver.memory             | 1g                       | 为driver进程分配的内存。注意：在客户端模式中，不能在SparkConf中直接配置该项，因为driver JVM进程已经启动了。 |
| spark.executor.memory           | 1g                       | 为每个executor进程分配的内存。                               |
| spark.executor.cores            | all/1                    | 每个executor可用的核心数。针对standalone和YARN模式。更多参见官方文档。 |
| spark.cores.max                 | (not set)                | 设置standalone和Mesos模式下应用程序的核心数上限。            |
| spark.speculation               | false                    | 设置为true时开启任务预测执行机制。当出现比较慢的任务时，这种机制会在另外的节点上也尝试执行该任务的一个副本。打开此选项会帮助减少大规模集群中个别较慢的任务带来的影响。 |
| spark.driver.extraJavaOptions   | (none)                   | 设置driver节点的JVM启动参数。                                |
| spark.executor.extraJavaOptions | (none)                   | 设置executor节点的JVM启动参数。                              |
| spark.serializer                | JavaSerializer           | 指定用来进行序列化的类库，包括通过网络传输数据或缓存数据时的序列化。为了速度，推荐使用KryoSerializer。 |
| spark.eventLog.enabled          | false                    | 设置为true时开启事件日志机制。这样已完成的spark作业就可以通过历史服务器查看。 |
| spark.eventLog.dir              | file:///tmp/spark-events | 开启事件日志机制时的事件日志文件存储位置。如果要在历史服务器中查看事件日志，需要将该值设置为一个全局可见的文件系统路径，比如HDFS中。最后，请确保目录以 ‘/‘ 结束，否则可能会出现错误，参见本文集群监控部分。 |

# 一些问题的解决办法

## /tmp目录写满

由于Spark在计算的时候会将中间结果存储到/tmp目录，而目前linux又都支持tmpfs，其实说白了就是将/tmp目录挂载到内存当中。那么这里就存在一个问题，中间结果过多导致/tmp目录写满而出现如下错误：

```
No Space Left on the device

```

解决办法就是针对tmp目录不启用tmpfs，修改/etc/fstab。

## 无法创建进程

有时可能会遇到如下错误，即无法创建进程：

```
java.lang.OutOfMemory, unable to create new native thread

```

导致这种错误的原因比较多。有一种情况并非真的是内存不足引起的，而是由于超出了允许的最大文件句柄数或最大进程数。

排查的步骤就是查看一下允许打开的文件句柄数和最大进程数，如果数值过低，使用ulimit将其调高之后，再试试问题是否已经解决。

## 不可序列化

```
Task not serializable: java.io.NotSerializableException

```

作为RDD操作算子参数的匿名函数使用外部变量从而形成闭包。为了效率，spark并不是将所有东东都序列化以分发到各个executor。spark会先对该匿名函数进行ClosureCleaner.clean()处理(将该匿名函数涉及到的$outer中的与闭包无关的变量移除)，然后将该匿名函数对象及闭包涉及到的对象序列化并包装成task分发到各个executor。

看到这里，你或许就发现了一个问题，那就是不管怎样，spark需要序列化的对象必须都可以被序列化！`Task not serializable: java.io.NotSerializableException`错误就是由于相应的对象不能被序列化造成的！

为了解决这个问题，首先你可以使用 `-Dsun.io.serialization.extendedDebugInfo=true` java选项来让jvm打印出更多的关于序列化的信息，以便了解哪些对象不可以被序列化。然后就是使这些对象对应的类可序列化，或者将这些对象定义在RDD操作算子的参数(匿名函数)中以取消闭包。

## 缺少winutils.exe

在windows上进行spark程序测试时，你可能会碰到如下几个问题：

```
java.io.IOException: Could not locate executable null\bin\winutils.exe in the Hadoop binaries.

```

```
java.lang.NullPointerException
	at java.lang.ProcessBuilder.start(ProcessBuilder.java:1010)

```

原因就是缺少 hadoop 的 `winutils.exe` 这个文件。解决方法是：下载一个(注意是32位还是64位)，新建一个文件夹 D:\hadoop\bin\ 并将 winutils.exe 放入其中，并保证winutils.exe双击运行没有报*.dll缺失的错误，然后在程序中设置一下hadoop目录即可，如下：

```
System.setProperty("hadoop.home.dir", "D:\hadoop\")

```
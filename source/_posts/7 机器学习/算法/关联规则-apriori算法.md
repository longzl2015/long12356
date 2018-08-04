---
title: 关联规则-Apriori算法
date: 2018-04-02 16:03:07
tags: 
  - 关联规则
  - Apriori算法
categories:
  - 算法
---



**引文：** 学习一个算法，我们最关心的并不是算法本身，而是一个算法能够干什么，能应用到什么地方。很多的时候，我们都需要从大量数据中提取出有用的信息，从大规模数据中寻找物品间的隐含关系叫做关联分析(association analysis)或者关联规则学习(association rule learning)。比如在平时的购物中，那些商品一起捆绑购买销量会比较好，又比如购物商城中的那些推荐信息，都是根据用户平时的搜索或者是购买情况来生成的。如果是蛮力搜索的话代价太高了，所以Apriori就出现了，就是为了解决这类问题的。

**内容纲要**

- 关联分析
- Apriori算法理论
- Apriori实现
  - 频繁项集生成
  - 关联规则生成
- reference

**Apriori算法**

- 优点：易编码实现
- 缺点：在大数据集上可能较慢
- 适合数据类型：数值型或者标称型数据

### **1 关联分析**

说到关联分析，顾名思义的就可以联想到，所谓关联就是两个东西之间存在的某种联系。关联分析最有名的例子是“尿布和啤酒”，以前在美国西部的一家连锁店，店家发现男人们在周四购买尿布后还会购买啤酒。于是他便得出一个推理，尿布和啤酒存在某种关联。但是具体怎么来评判呢？

那么，这里用的是**支持度**和**可信度**来评判!

一个项集的支持度（support）被定义为数据集中包含该数据集的记录所占的比例。可信度或置信度（confidence）是正对一条关联规则来定义的，比如{尿布}->{啤酒}，这条规则的可信度定义为“支持度{尿布，啤酒}/支持度{尿布}”

比如有规则 X=>Y，它的**支持度**可以计算为包含XUY所有商品的交易量相对所有交易量的比例（也就是X和Y同时出现一次交易的概率）。**可信度**定义为包含XUY所有物品的交易量相对仅包含X的交易量的比值，也就是说可信度对应给定X时的条件概率。关联规则挖掘，其目的是自动发起这样的规则，同时计算这些规则的质量。

**计算公式如下：**
$$
支持度 = \frac{交易量包含XUY}{交易量}
$$

$$
可信度 = \frac{交易量包含XUY}{交易量包含X}
$$

支持度和可信度是用来量化关联分析是否成功的方法。关联分析的目的包括两个：发现频繁项集和发现关联规则。首先我们要找到频繁项集，然后根据频繁项集找出关联规则。下面使用apriori算法来发现频繁项集。

### **2 Apriori理论**

**算法的一般过程：**

- 收集数据：使用任何方法
- 准备数据：任意数据类型都可以，因为我们只保存集合
- 分析数据：使用任何方法
- 训练算法：使用Apriori算法来找到频繁项集
- 测试算法：不需要测试过程
- 使用算法：用于发现频繁项集以及物品之间的关联规则

**使用Apriori算法，首先计算出单个元素的支持度，然后选出单个元素置信度大于我们要求的数值，比如0.5或是0.7等。然后增加单个元素组合的个数，只要组合项的支持度大于我们要求的数值就把它加到我们的频繁项集中，依次递归。**

然后根据计算的支持度选出来的频繁项集来生成关联规则。

### **3 Apriori实现**

首先定义一些算法的辅助函数
加载数据集的

```python
from numpy import *

def loadDataSet():
    list = [[1, 3, 4], [2, 3, 5], [1, 2, 3, 5], [2, 5]]
    return list

```

根据数据集构建集合C1，该集合是大小为1的所有候选集的集合。

```python
def createC1(dataSet):
    C1 = [] #C1是大小为1的所有候选项集的集合
    for transaction in dataSet:
        for item in transaction:
            if not [item] in C1:
                C1.append([item])             
    C1.sort()
    return map(frozenset, C1)#use frozen set so we can use it as a key in a dict

```

根据构建出来的频繁项集，选出满足我们需要的大于我们给定的支持度的项集

```python
#D表示数据集，CK表示候选项集，minSupport表示最小的支持度，自己设定
def scanD(D, Ck, minSupport):
    ssCnt = {}
    for tid in D:  # 统计 候选项出现次数
        for can in Ck:
            if can.issubset(tid):
                if not ssCnt.has_key(can): ssCnt[can]=1
                else: ssCnt[can] += 1
    numItems = float(len(D))
    retList = [] #存储满足最小支持度要求的项集
    supportData = {} #每个项集的支持度字典
    for key in ssCnt:  #计算所有项集的支持度
        support = ssCnt[key]/numItems
        if support >= minSupport:
            retList.insert(0,key)
        supportData[key] = support
    return retList, supportData

```

#### **3.1 频繁项集**

关于频繁项集的产生，我们单独的抽取出来
首先需要一个生成合并项集的函数，将两个子集合并的函数

```python
#LK是频繁项集列表，K表示接下来合并的项集中的单个想的个数{1,2,3}表示k=3
def aprioriGen(Lk, k): #creates Ck
    retList = []
    lenLk = len(Lk)
    for i in range(lenLk):
        for j in range(i+1, lenLk): 
            L1 = list(Lk[i])[:k-2]; L2 = list(Lk[j])[:k-2] #前k-2个项相同时，将两个集合合并
            L1.sort(); L2.sort()
            if L1==L2: #if first k-2 elements are equal
                retList.append(Lk[i] | Lk[j]) #set union
    return retList

```

接着定义生成频繁项集的函数

```python
#只需要输入数据集和支持度即可
def apriori(dataSet, minSupport = 0.5):
    C1 = createC1(dataSet) 
    D = map(set, dataSet)
    L1, supportData = scanD(D, C1, minSupport)
    L = [L1]
    k = 2
    while (len(L[k-2]) > 0):
        Ck = aprioriGen(L[k-2], k)
        Lk, supK = scanD(D, Ck, minSupport)#scan DB to get Lk
        supportData.update(supK)
        L.append(Lk)
        k += 1
    return L, supportData#返回频繁项集和每个项集的支持度值

```

#### **3.2 关联规则生成**

通过频繁项集，我们可以得到相应的规则，但是具体规则怎么得出来的呢？下面给出一个规则生成函数，具体原理参考注释

```python
#输入的参数分别为：频繁项集、支持度数据字典、自定义的最小支持度，返回的是可信度规则列表
def generateRules(L, supportData, minConf=0.7):  #支持度是通过scanD得到的字典
    bigRuleList = []
    for i in range(1, len(L)):#只去频繁项集中元素个数大于2的子集，如{1,2}{1,2,3}，不取{2}{3},etc...
        for freqSet in L[i]:
            H1 = [frozenset([item]) for item in freqSet]
            if (i > 1):
                rulesFromConseq(freqSet, H1, supportData, bigRuleList, minConf)
            else:
                calcConf(freqSet, H1, supportData, bigRuleList, minConf)
    return bigRuleList

```

下面定义一个用来计算置信度的函数，通过该函数抽取出符合我们要求的规则，如freqSet为{1,2}，H为{1}，{2}，可以计算出{1}—>{2}和{2}—>{1}的质心度，即下面的conf变量，然后用if语句判断是否符合我们的要求。代码如下：

```python
#计算可信度，找到满足最小可信度的要求规则
def calcConf(freqSet, H, supportData, brl, minConf=0.7):
    prunedH = [] #create new list to return
    for conseq in H:
        conf = supportData[freqSet]/supportData[freqSet-conseq] #calc confidence
        if conf >= minConf: 
            print freqSet-conseq,'-->',conseq,'conf:',conf
            brl.append((freqSet-conseq, conseq, conf))
            prunedH.append(conseq)
    return prunedH

```

下面的函数是用来合并子集的，比如我现在的频繁项集是{2,3,5},它的构造元素是{2},{3},{5}，所以需要将{2},{3},{5}两两合并然后再根据上面的calcConf函数计算置信度。代码如下：

```python
#从最初的项集中生成更多的规则
def rulesFromConseq(freqSet, H, supportData, brl, minConf=0.7):
    m = len(H[0])
    if (len(freqSet) > (m + 1)): #进一步合并项集
        Hmp1 = aprioriGen(H, m+1)#create Hm+1 new candidates
        Hmp1 = calcConf(freqSet, Hmp1, supportData, brl, minConf)
        if (len(Hmp1) > 1):    #need at least two sets to merge
            rulesFromConseq(freqSet, Hmp1, supportData, brl, minConf)

```
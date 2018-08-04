
---
title: hadoop balancer 的使用经验
date: 2016-04-02 22:46:48
tags: 
  - balancer
categories:
  - hadoop
---

由于历史原因，hadoop集群中的机器的磁盘空间的大小各不相同，而HDFS在进行写入操作时，并没有考虑到这种情况，所以随着数据量的逐渐增加，磁盘较小的datanode机器上的磁盘空间很快将被写满，从而触发了报警。
此时，不得不手工执行start-balancer.sh来进行balance操作，即使将dfs.balance.bandwidthPerSec  参数设置为10M/s，整个集群达到平衡也需要很长的时间，所以写了个`crontab`来每天凌晨来执行start-balancer.sh，由于此时集群不平衡的状态还没有那么严重，所以start-balancer.sh很快执行结束了。
### 不要在namenode中执行banlance指令
由于HDFS需要启动单独的Rebalance Server来执行Rebalance操作，所以尽量不要在NameNode上执行start-balancer.sh，而是找一台比较空闲的机器。
###  hadoop balance工具的用法：
开始：  `bin/start-balancer.sh [-threshold <threshold>]`  

停止：  `bin/stop-balancer.sh`

### 影响hadoop balance工具的几个参数：

- threshold 
  默认设置：10，参数取值范围：0-100，参数含义：判断集群是否平衡的目标参数，每一个 datanode 存储使用率和集群总存储使用率的差值都应该小于这个阀值 ，理论上，该参数设置的越小，整个集群就越平衡，但是在线上环境中，hadoop集群在进行balance时，还在并发的进行数据的写入和删除，所以有可能无法到达设定的平衡参数值。

- setBalancerBandwidth
  可以使用如下命令修改 balancer宽带参数
  `hdfs dfsadmin -setBalancerBandwidth 67108864`
  默认设置：1048576（1 M/S），参数含义：设置balance工具在运行中所能占用的带宽，设置的过大可能会造成mapred运行缓慢

### 命令 (未验证)

```
hdfs balancer -Dfs.defaultFS=hdfs://<NN_HOSTNAME>:8020 -Ddfs.balancer.movedWinWidth=5400000 -Ddfs.balancer.moverThreads=1000 -Ddfs.balancer.dispatcherThreads=200 -Ddfs.datanode.balance.max.concurrent.moves=5 -Ddfs.balance.bandwidthPerSec=100000000 -Ddfs.balancer.max-size-to-move=10737418240 -threshold 5 
```

### 参考资料
[hadoop command guide](https://hadoop.apache.org/docs/r2.7.3/hadoop-project-dist/hadoop-hdfs/HDFSCommands.html#balancer)
[Hadoop集群datanode磁盘不均衡的解决方案](http://forum.huawei.com/enterprise/thread-363899-1-1.html)
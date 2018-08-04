---
title: hadoop 2.6版本 添加节点
date: 2016-04-02 22:46:48
tags: 
  - hadoop
categories:
  - hadoop
---

本文主要从基础准备，添加DataNode和添加NodeManager三个部分详细说明在Hadoop2.6.0环境下，如何动态新增节点到集群中。

### 基础准备

在基础准备部分，主要是设置hadoop运行的系统环境

- 修改系统hostname（通过hostname和/etc/sysconfig/network进行修改）

- 修改hosts文件，将集群所有节点hosts配置进去（集群所有节点保持hosts文件统一）

- 设置NameNode（两台HA均需要）到DataNode的免密码登录（ssh-copy-id命令实现，可以免去cp *.pub文件后的权限修改）

- 修改主节点slave文件，添加新增节点的ip信息（集群重启时使用）

- 将hadoop的配置文件scp到新的节点上

### 添加DataNode

对于新添加的DataNode节点，需要启动datanode进程，从而将其添加入集群

- 在新增的节点上，运行`sbin/hadoop-daemon.sh start datanode`即可

- 然后在namenode通过`hdfs dfsadmin -report`查看集群情况

- 最后还需要对hdfs负载设置均衡，因为默认的数据传输不允许占用太大网络宽带，因此需要设置，如下命令设置的是64M，即`hdfs dfsadmin -setBalancerBandwidth 67108864`即可

- 然后启动Balancer，`sbin/start-balancer.sh -threshold 5`，等待集群自均衡完成即可。（默认balancer的threshold为10%，即各个节点与集群总的存储使用率相差不超过10%，我们可将其设置为5%），

### 添加Nodemanager

由于Hadoop 2.X引入了YARN框架，所以对于每个计算节点都可以通过NodeManager进行管理，同理启动NodeManager进程后，即可将其加入集群

- 在新增节点，运行`sbin/yarn-daemon.sh start nodemanager`即可

- 在ResourceManager，通过yarn node -list查看集群情况


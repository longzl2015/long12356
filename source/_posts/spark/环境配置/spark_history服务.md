---
title: spark_history服务
date: 2017-06-04 23:22:58
tags: 
  - spark
categories: [spark,环境配置]
---

在运行Spark应用程序的时候，driver会提供一个webUI给出应用程序的运行信息，但是该webUI随着应用程序的完成而关闭端口，也就是说，Spark应用程序运行完后，将无法查看应用程序的历史记录。Spark history server就是为了应对这种情况而产生的，通过配置，Spark应用程序在运行完应用程序之后，将应用程序的运行信息写入指定目录，而Spark history server可以将这些运行信息装载并以web的方式供用户浏览。

要使用history server，对于提交应用程序的客户端需要配置以下参数（在conf/spark-defaults.conf中配置）：

```
spark.eventLog.enabled  true 
spark.eventLog.dir      hdfs://hadoop1:8000/sparklogs   
```

进入$SPARK_HOME/sbin路径

```
./start-all.sh
./start-history-server.sh 
```

注意：会启动失败，控制台显示

```
hadoop@Node4:/usr/local/SPARK/spark-1.1.0-bin-hadoop2.4/sbin$ ./start-history-server.sh 
starting org.apache.spark.deploy.history.HistoryServer, logging to /usr/local/SPARK/spark-1.1.0-bin-hadoop2.4/sbin/../logs/spark-hadoop-org.apache.spark.deploy.history.HistoryServer-1-Node4.out
failed to launch org.apache.spark.deploy.history.HistoryServer:
      at org.apache.spark.deploy.history.FsHistoryProvider.<init>(FsHistoryProvider.scala:41)
      ... 6 more
full log in /usr/local/SPARK/spark-1.1.0-bin-hadoop2.4/sbin/../logs/spark-hadoop-org.apache.spark.deploy.history.HistoryServer-1-Node4.out
```

找到日志文件，发现报错 Logging directory must be specified
**解决**：在启动historyserver的时候需要加上参数，指明log的存放位置，例如，我们在spark-default.conf中配置的存放路径为hdfs://hadoop1:8000/sparklogs 
有下面两种方法解决问题
**1. 将启动命令改成**

```
start-history-server.sh hdfs://node4:9000/directory
```

**2. 启动命令不变，在conf/spark-env.sh中添加**

```
export SPARK_HISTORY_OPTS="-Dspark.history.ui.port=18080 -Dspark.history.retainedApplications=3 -Dspark.history.fs.logDirectory=hdfs://node4:9000/directory"
```

这样，在启动HistoryServer之后，在浏览器中打开`http://node4:18080`就可以看到web页面了

 

**附：在conf/spark-defaults.conf中配置参数**

**history server相关的配置参数描述**

**1） spark.history.updateInterval**
　　默认值：10
　　以秒为单位，更新日志相关信息的时间间隔

**2）spark.history.retainedApplications**
　　默认值：50
　　在内存中保存Application历史记录的个数，如果超过这个值，旧的应用程序信息将被删除，当再次访问已被删除的应用信息时需要重新构建页面。

**3）spark.history.ui.port**
　　默认值：18080
　　HistoryServer的web端口

**4）spark.history.kerberos.enabled**
　　默认值：false
　　是否使用kerberos方式登录访问HistoryServer，对于持久层位于安全集群的HDFS上是有用的，如果设置为true，就要配置下面的两个属性

**5）spark.history.kerberos.principal**
　　默认值：用于HistoryServer的kerberos主体名称

**6）spark.history.kerberos.keytab**
　　用于HistoryServer的kerberos keytab文件位置

**7）spark.history.ui.acls.enable**
　　默认值：false
　　授权用户查看应用程序信息的时候是否检查acl。如果启用，只有应用程序所有者和spark.ui.view.acls指定的用户可以查看应用程序信息;否则，不做任何检查

**8）spark.eventLog.enabled**
　　默认值：false 
　　是否记录Spark事件，用于应用程序在完成后重构webUI

**9）spark.eventLog.dir**
　　默认值：file:///tmp/spark-events
　　保存日志相关信息的路径，可以是hdfs://开头的HDFS路径，也可以是file://开头的本地路径，都需要提前创建

10）**spark.eventLog.compress **
　　默认值：false 
　　是否压缩记录Spark事件，前提spark.eventLog.enabled为true，默认使用的是snappy

**以spark.history开头的需要配置在spark-env.sh中的SPARK_HISTORY_OPTS，以spark.eventLog开头的配置在spark-defaults.conf**
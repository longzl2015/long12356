---
title: spark 提交任务后，Linux中java 进程说明
date: 2017-06-04 23:22:58
tags: 
  - spark
categories:
  - spark
---

# spark 提交任务后，Linux中java 进程说明

[TOC]

## 一、简述

当使用 spark 提交任务后，可在hadoop集群中的一台Linux里 使用 `ps -ef | grep jdk1.8` 可查看到对应的任务进程信息。

注、本例中使用的是单机模式

## 二、进程分析

```
hadoop   110334 110332  0 13:40 ?        00:00:00 /bin/bash -c ./jdk-8u161-linux-x64.tar.gz/jdk1.8.0_161/bin/java -server -Xmx1024m -Djava.io.tmpdir=/home/hadoop/tmp/nm-local-dir/usercache/xxxxx/appcache/application_1519271509270_0745/container_1519271509270_0745_01_000001/tmp '-XX:MaxPermSize=2048m' '-XX:PermSize=512m' -Dspark.yarn.app.container.log.dir=/home/hadoop/hadoop-2.7.3/logs/userlogs/application_1519271509270_0745/container_1519271509270_0745_01_000001 org.apache.spark.deploy.yarn.ApplicationMaster --class 'org.apache.spark.ml.alogrithm.SmartRules' --jar hdfs://slave131:9000/user/mls_zl/lib2/cmpt/xxxxx-workflow-component-0.3.2-20180320-1101.jar --arg 'hdfs://slave131:9000/user/mls_3.5/proc/1/11/92/submit_SmartRules_37Client.json' --properties-file /home/hadoop/tmp/nm-local-dir/usercache/xxxxx/appcache/application_1519271509270_0745/container_1519271509270_0745_01_000001/__spark_conf__/__spark_conf__.properties 1> /home/hadoop/hadoop-2.7.3/logs/userlogs/application_1519271509270_0745/container_1519271509270_0745_01_000001/stdout 2> /home/hadoop/hadoop-2.7.3/logs/userlogs/application_1519271509270_0745/container_1519271509270_0745_01_000001/stderr
hadoop   110891 110334 99 13:40 ?        00:00:34 ./jdk-8u161-linux-x64.tar.gz/jdk1.8.0_161/bin/java -server -Xmx1024m -Djava.io.tmpdir=/home/hadoop/tmp/nm-local-dir/usercache/xxxxx/appcache/application_1519271509270_0745/container_1519271509270_0745_01_000001/tmp -XX:MaxPermSize=2048m -XX:PermSize=512m -Dspark.yarn.app.container.log.dir=/home/hadoop/hadoop-2.7.3/logs/userlogs/application_1519271509270_0745/container_1519271509270_0745_01_000001 org.apache.spark.deploy.yarn.ApplicationMaster --class org.apache.spark.ml.alogrithm.SmartRules --jar hdfs://slave131:9000/user/mls_zl/lib2/cmpt/xxxxx-workflow-component-0.3.2-20180320-1101.jar --arg hdfs://slave131:9000/user/mls_3.5/proc/1/11/92/submit_SmartRules_37Client.json --properties-file /home/hadoop/tmp/nm-local-dir/usercache/xxxxx/appcache/application_1519271509270_0745/container_1519271509270_0745_01_000001/__spark_conf__/__spark_conf__.properties
hadoop   111013 111010  0 13:40 ?        00:00:00 /bin/bash -c ./jdk-8u161-linux-x64.tar.gz/jdk1.8.0_161/bin/java -server -Xmx4096m -Djava.io.tmpdir=/home/hadoop/tmp/nm-local-dir/usercache/xxxxx/appcache/application_1519271509270_0745/container_1519271509270_0745_01_000002/tmp '-Dspark.ui.port=0' '-Dspark.driver.port=37011' -Dspark.yarn.app.container.log.dir=/home/hadoop/hadoop-2.7.3/logs/userlogs/application_1519271509270_0745/container_1519271509270_0745_01_000002 -XX:OnOutOfMemoryError='kill %p' org.apache.spark.executor.CoarseGrainedExecutorBackend --driver-url spark://CoarseGrainedScheduler@10.100.1.131:37011 --executor-id 1 --hostname slave131 --cores 8 --app-id application_1519271509270_0745 --user-class-path file:/home/hadoop/tmp/nm-local-dir/usercache/xxxxx/appcache/application_1519271509270_0745/container_1519271509270_0745_01_000002/__app__.jar 1>/home/hadoop/hadoop-2.7.3/logs/userlogs/application_1519271509270_0745/container_1519271509270_0745_01_000002/stdout 2>/home/hadoop/hadoop-2.7.3/logs/userlogs/application_1519271509270_0745/container_1519271509270_0745_01_000002/stderr
hadoop   111567 111013 99 13:40 ?        00:00:32 ./jdk-8u161-linux-x64.tar.gz/jdk1.8.0_161/bin/java -server -Xmx4096m -Djava.io.tmpdir=/home/hadoop/tmp/nm-local-dir/usercache/xxxxx/appcache/application_1519271509270_0745/container_1519271509270_0745_01_000002/tmp -Dspark.ui.port=0 -Dspark.driver.port=37011 -Dspark.yarn.app.container.log.dir=/home/hadoop/hadoop-2.7.3/logs/userlogs/application_1519271509270_0745/container_1519271509270_0745_01_000002 -XX:OnOutOfMemoryError=kill %p org.apache.spark.executor.CoarseGrainedExecutorBackend --driver-url spark://CoarseGrainedScheduler@10.100.1.131:37011 --executor-id 1 --hostname slave131 --cores 8 --app-id application_1519271509270_0745 --user-class-path file:/home/hadoop/tmp/nm-local-dir/usercache/xxxxx/appcache/application_1519271509270_0745/container_1519271509270_0745_01_000002/__app__.jar
hadoop   111619 111616  0 13:40 ?        00:00:00 /bin/bash -c ./jdk-8u161-linux-x64.tar.gz/jdk1.8.0_161/bin/java -server -Xmx4096m -Djava.io.tmpdir=/home/hadoop/tmp/nm-local-dir/usercache/xxxxx/appcache/application_1519271509270_0745/container_1519271509270_0745_01_000003/tmp '-Dspark.ui.port=0' '-Dspark.driver.port=37011' -Dspark.yarn.app.container.log.dir=/home/hadoop/hadoop-2.7.3/logs/userlogs/application_1519271509270_0745/container_1519271509270_0745_01_000003 -XX:OnOutOfMemoryError='kill %p' org.apache.spark.executor.CoarseGrainedExecutorBackend --driver-url spark://CoarseGrainedScheduler@10.100.1.131:37011 --executor-id 2 --hostname slave131 --cores 8 --app-id application_1519271509270_0745 --user-class-path file:/home/hadoop/tmp/nm-local-dir/usercache/xxxxx/appcache/application_1519271509270_0745/container_1519271509270_0745_01_000003/__app__.jar 1>/home/hadoop/hadoop-2.7.3/logs/userlogs/application_1519271509270_0745/container_1519271509270_0745_01_000003/stdout 2>/home/hadoop/hadoop-2.7.3/logs/userlogs/application_1519271509270_0745/container_1519271509270_0745_01_000003/stderr
hadoop   112178 111619 99 13:40 ?        00:00:50 ./jdk-8u161-linux-x64.tar.gz/jdk1.8.0_161/bin/java -server -Xmx4096m -Djava.io.tmpdir=/home/hadoop/tmp/nm-local-dir/usercache/xxxxx/appcache/application_1519271509270_0745/container_1519271509270_0745_01_000003/tmp -Dspark.ui.port=0 -Dspark.driver.port=37011 -Dspark.yarn.app.container.log.dir=/home/hadoop/hadoop-2.7.3/logs/userlogs/application_1519271509270_0745/container_1519271509270_0745_01_000003 -XX:OnOutOfMemoryError=kill %p org.apache.spark.executor.CoarseGrainedExecutorBackend --driver-url spark://CoarseGrainedScheduler@10.100.1.131:37011 --executor-id 2 --hostname slave131 --cores 8 --app-id application_1519271509270_0745 --user-class-path file:/home/hadoop/tmp/nm-local-dir/usercache/xxxxx/appcache/application_1519271509270_0745/container_1519271509270_0745_01_000003/__app__.jar
```



下面逐条解释上面java进程： 

### 2.1 进程一

进程一表示使用bash -c 启动进程二，并将进程二的信息重定向到指定位置。这里直接说重定向命令参数，其他参数见进程二说明

```
hadoop   110334 110332  0 13:40 ?        00:00:00 /bin/bash -c ./jdk-8u161-linux-x64.tar.gz/jdk1.8.0_161/bin/java -server -Xmx1024m -Djava.io.tmpdir=/home/hadoop/tmp/nm-local-dir/usercache/xxxxx/appcache/application_1519271509270_0745/container_1519271509270_0745_01_000001/tmp '-XX:MaxPermSize=2048m' '-XX:PermSize=512m' -Dspark.yarn.app.container.log.dir=/home/hadoop/hadoop-2.7.3/logs/userlogs/application_1519271509270_0745/container_1519271509270_0745_01_000001 org.apache.spark.deploy.yarn.ApplicationMaster --class 'org.apache.spark.ml.alogrithm.SmartRules' --jar hdfs://slave131:9000/user/mls_zl/lib2/cmpt/xxxxx-workflow-component-0.3.2-20180320-1101.jar --arg 'hdfs://slave131:9000/user/mls_3.5/proc/1/11/92/submit_SmartRules_37Client.json' --properties-file /home/hadoop/tmp/nm-local-dir/usercache/xxxxx/appcache/application_1519271509270_0745/container_1519271509270_0745_01_000001/__spark_conf__/__spark_conf__.properties 1> /home/hadoop/hadoop-2.7.3/logs/userlogs/application_1519271509270_0745/container_1519271509270_0745_01_000001/stdout 2> /home/hadoop/hadoop-2.7.3/logs/userlogs/application_1519271509270_0745/container_1519271509270_0745_01_000001/stderr
```

#### 信息重定向命令

> 1> /home/hadoop/hadoop-2.7.3/logs/userlogs/application_1519271509270_0745/container_1519271509270_0745_01_000001/stdout
>
>  2> /home/hadoop/hadoop-2.7.3/logs/userlogs/application_1519271509270_0745/container_1519271509270_0745_01_000001/stderr



### 2.2 进程二： ApplicationMaster

```
hadoop   110891 110334 99 13:40 ?        00:00:34 ./jdk-8u161-linux-x64.tar.gz/jdk1.8.0_161/bin/java -server -Xmx1024m -Djava.io.tmpdir=/home/hadoop/tmp/nm-local-dir/usercache/xxxxx/appcache/application_1519271509270_0745/container_1519271509270_0745_01_000001/tmp -XX:MaxPermSize=2048m -XX:PermSize=512m -Dspark.yarn.app.container.log.dir=/home/hadoop/hadoop-2.7.3/logs/userlogs/application_1519271509270_0745/container_1519271509270_0745_01_000001 org.apache.spark.deploy.yarn.ApplicationMaster --class org.apache.spark.ml.alogrithm.SmartRules --jar hdfs://slave131:9000/user/mls_zl/lib2/cmpt/xxxxx-workflow-component-0.3.2-20180320-1101.jar --arg hdfs://slave131:9000/user/mls_3.5/proc/1/11/92/submit_SmartRules_37Client.json --properties-file /home/hadoop/tmp/nm-local-dir/usercache/xxxxx/appcache/application_1519271509270_0745/container_1519271509270_0745_01_000001/__spark_conf__/__spark_conf__.properties
```

该进程有 进程一 产生，参数配置和一近乎相当

#### 1. ./jdk-8u161-linux-x64.tar.gz/jdk1.8.0_161/bin/java

使用 jdk1.8 运行

#### 2. -server

 java 有2种启动方式 client 和 server 启动方式 ，client模式启动比较快，但运行时性能和内存管理效率不如server模式，通常用于客户端应用程序。相反，server模式启动比client慢，但可获得更高的运行性能。
在 windows上，缺省的虚拟机类型为client模式，如果要使用 server模式，就需要在启动虚拟机时加-server参数，以获得更高性能，对服务器端应用，推荐采用server模式，尤其是多个CPU的系统。在 Linux，Solaris上缺省采用server模式。 

#### 3. -Xmx1024m

设置虚拟机内存堆的最大可用大小

#### 4. -Djava.io.tmpdir

设置java 临时目录 为 `/home/hadoop/tmp/nm-local-dir/usercache/xxxxx/appcache/application_1519271509270_0745/container_1519271509270_0745_01_000001/tmp`

#### 5. -XX:MaxPermSize=2048m -XX:PermSize=512m

-XX:PermSize=64M JVM初始分配的非堆内存

-XX:MaxPermSize=128M JVM最大允许分配的非堆内存，按需分配

#### 6. -Dspark.yarn.app.container.log.dir

设置容器 日志目录 为 `/home/hadoop/hadoop-2.7.3/logs/userlogs/application_1519271509270_0745/container_1519271509270_0745_01_000001 `

#### 7. org.apache.spark.deploy.yarn.ApplicationMaster

Java 程序入口类

#### 8. --class

指定spark任务需要执行任务主类 `org.apache.spark.ml.alogrithm.SmartRules`

#### 9. --jar

指定spark需要的jar包路径  `hdfs://slave131:9000/user/mls_zl/lib2/cmpt/xxxxx-workflow-component-0.3.2-20180320-1101.jar`

#### 10. --arg

指定spark任务（客户端编写的代码）所需的参数

`'hdfs://slave131:9000/user/mls_3.5/proc/1/11/92/submit_SmartRules_37Client.json'` 

#### 11. --properties-file

 `/home/hadoop/tmp/nm-local-dir/usercache/xxxxx/appcache/application_1519271509270_0745/container_1519271509270_0745_01_000001/__spark_conf__/__spark_conf__.properties` 

### 2.3 进程三

使用 bash -c 启动 executor 守护进程 即进程四

[spark executor内幕](http://blog.sina.com.cn/s/blog_9ca9623b0102w7p9.html)

```
hadoop   111013 111010  0 13:40 ?        00:00:00 /bin/bash -c ./jdk-8u161-linux-x64.tar.gz/jdk1.8.0_161/bin/java -server -Xmx4096m -Djava.io.tmpdir=/home/hadoop/tmp/nm-local-dir/usercache/xxxxx/appcache/application_1519271509270_0745/container_1519271509270_0745_01_000002/tmp '-Dspark.ui.port=0' '-Dspark.driver.port=37011' -Dspark.yarn.app.container.log.dir=/home/hadoop/hadoop-2.7.3/logs/userlogs/application_1519271509270_0745/container_1519271509270_0745_01_000002 -XX:OnOutOfMemoryError='kill %p' org.apache.spark.executor.CoarseGrainedExecutorBackend --driver-url spark://CoarseGrainedScheduler@10.100.1.131:37011 --executor-id 1 --hostname slave131 --cores 8 --app-id application_1519271509270_0745 --user-class-path file:/home/hadoop/tmp/nm-local-dir/usercache/xxxxx/appcache/application_1519271509270_0745/container_1519271509270_0745_01_000002/__app__.jar 1>/home/hadoop/hadoop-2.7.3/logs/userlogs/application_1519271509270_0745/container_1519271509270_0745_01_000002/stdout 2>/home/hadoop/hadoop-2.7.3/logs/userlogs/application_1519271509270_0745/container_1519271509270_0745_01_000002/stderr
```

### 2.4 进程四：CoarseGrainedExecutorBackend

在spark中，executor是负责计算任务的，而CoarseGrainedExecutorBackend 则是负责Executor对象的创建和维护的

```
hadoop   111567 111013 99 13:40 ?        00:00:32 ./jdk-8u161-linux-x64.tar.gz/jdk1.8.0_161/bin/java -server -Xmx4096m -Djava.io.tmpdir=/home/hadoop/tmp/nm-local-dir/usercache/xxxxx/appcache/application_1519271509270_0745/container_1519271509270_0745_01_000002/tmp -Dspark.ui.port=0 -Dspark.driver.port=37011 -Dspark.yarn.app.container.log.dir=/home/hadoop/hadoop-2.7.3/logs/userlogs/application_1519271509270_0745/container_1519271509270_0745_01_000002 -XX:OnOutOfMemoryError=kill %p org.apache.spark.executor.CoarseGrainedExecutorBackend --driver-url spark://CoarseGrainedScheduler@10.100.1.131:37011 --executor-id 1 --hostname slave131 --cores 8 --app-id application_1519271509270_0745 --user-class-path file:/home/hadoop/tmp/nm-local-dir/usercache/xxxxx/appcache/application_1519271509270_0745/container_1519271509270_0745_01_000002/__app__.jar
```

#### 1. -Dspark.ui.port 

0 代表随机选择一个可用的端口

#### 2. -Dspark.driver.port 

驱动器监听端口号 37011 

#### 3. -Dspark.yarn.app.container.log.dir 

指定app.container 的日志位置：`/home/hadoop/hadoop-2.7.3/logs/userlogs/application_1519271509270_0745/container_1519271509270_0745_01_000002`

#### 4. -XX:OnOutOfMemoryError=kill %p 

出现OutOfMemoryError 时，启动 运行kill命令

#### 5. org.apache.spark.executor.CoarseGrainedExecutorBackend  

java 命令 主类

#### 6. --driver-url 

 `spark://CoarseGrainedScheduler@10.100.1.131:37011 `

指定CoarseGrainedScheduler对外暴露的url

#### 7. --executor-id  

执行器的id，1

#### 8. --hostname  

主机名 slave131,谁的主机名，待查？

#### 9. --cores 8 

执行核心数

#### 10. --app-id  

应用的id application_1519271509270_0745

由时间戳加id组成。

####  --user-class-path 

`file:/home/hadoop/tmp/nm-local-dir/usercache/xxxxx/appcache/application_1519271509270_0745/container_1519271509270_0745_01_000002/__app__.jar `

### 2.5 进程五

使用 bash -c 启动 进程五

```
hadoop   111619 111616  0 13:40 ?        00:00:00 /bin/bash -c ./jdk-8u161-linux-x64.tar.gz/jdk1.8.0_161/bin/java -server -Xmx4096m -Djava.io.tmpdir=/home/hadoop/tmp/nm-local-dir/usercache/xxxxx/appcache/application_1519271509270_0745/container_1519271509270_0745_01_000003/tmp '-Dspark.ui.port=0' '-Dspark.driver.port=37011' -Dspark.yarn.app.container.log.dir=/home/hadoop/hadoop-2.7.3/logs/userlogs/application_1519271509270_0745/container_1519271509270_0745_01_000003 -XX:OnOutOfMemoryError='kill %p' org.apache.spark.executor.CoarseGrainedExecutorBackend --driver-url spark://CoarseGrainedScheduler@10.100.1.131:37011 --executor-id 2 --hostname slave131 --cores 8 --app-id application_1519271509270_0745 --user-class-path file:/home/hadoop/tmp/nm-local-dir/usercache/xxxxx/appcache/application_1519271509270_0745/container_1519271509270_0745_01_000003/__app__.jar 1>/home/hadoop/hadoop-2.7.3/logs/userlogs/application_1519271509270_0745/container_1519271509270_0745_01_000003/stdout 2>/home/hadoop/hadoop-2.7.3/logs/userlogs/application_1519271509270_0745/container_1519271509270_0745_01_000003/stderr

```

### 2.6 进程六：CoarseGrainedExecutorBackend

```
hadoop   112178 111619 99 13:40 ?        00:00:50 ./jdk-8u161-linux-x64.tar.gz/jdk1.8.0_161/bin/java -server -Xmx4096m -Djava.io.tmpdir=/home/hadoop/tmp/nm-local-dir/usercache/xxxxx/appcache/application_1519271509270_0745/container_1519271509270_0745_01_000003/tmp -Dspark.ui.port=0 -Dspark.driver.port=37011 -Dspark.yarn.app.container.log.dir=/home/hadoop/hadoop-2.7.3/logs/userlogs/application_1519271509270_0745/container_1519271509270_0745_01_000003 -XX:OnOutOfMemoryError=kill %p org.apache.spark.executor.CoarseGrainedExecutorBackend --driver-url spark://CoarseGrainedScheduler@10.100.1.131:37011 --executor-id 2 --hostname slave131 --cores 8 --app-id application_1519271509270_0745 --user-class-path file:/home/hadoop/tmp/nm-local-dir/usercache/xxxxx/appcache/application_1519271509270_0745/container_1519271509270_0745_01_000003/__app__.jar
```

## 三、总结

从上面的结果分析，提交某任务后，spark 启动的3个进程：一个 ApplicationMaster、两个CoarseGrainedExecutorBackend。
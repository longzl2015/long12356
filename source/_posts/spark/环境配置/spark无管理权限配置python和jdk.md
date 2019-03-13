---
title: Spark无管理权限配置Python或JDK
date: 2017-06-04 23:22:58
tags: 
  - spark
categories: [spark,环境配置]
---

# Spark无管理权限配置Python或JDK

[TOC]

## 部署java

将对应的jdk文件夹压缩成tar.gz

> tar -zcf jdk1.8.0_77.tar.gz jdk1.8.0_77

然后在提交任务的时候添加某些参数：

```shell
$SPARK_HOME/bin/spark-submit --master yarn-cluster  \
 --conf "spark.yarn.dist.archives=/home/zzz/jdk1.8.0_77.tar.gz"  \
 --conf "spark.executorEnv.JAVA_HOME=./jdk1.8.0_77.tar.gz/jdk1.8.0_77"\
 --conf "spark.yarn.appMasterEnv.JAVA_HOME=./jdk1.8.0_77.tar.gz/jdk1.8.0_77" \
 xxxxx
```

- spark.yarn.dist.archives：逗号分隔的压缩包。运行时，会将这些压缩包分发到所有的executor节点的工作目录，executor节点会自动解压这些压缩包。路径规则参考上面的命令。

运行结果《在hadoop集群的任一台机器上执行 ps -ef | grep jdk1.8》

```
hadoop   110334 110332  0 13:40 ?        00:00:00 /bin/bash -c ./jdk-8u161-linux-x64.tar.gz/jdk1.8.0_161/bin/java -server -Xmx1024m -Djava.io.tmpdir=/home/hadoop/tmp/nm-local-dir/usercache/zhoulong/appcache/application_1519271509270_0745/container_1519271509270_0745_01_000001/tmp '-XX:MaxPermSize=2048m' '-XX:PermSize=512m' -Dspark.yarn.app.container.log.dir=/home/hadoop/hadoop-2.7.3/logs/userlogs/application_1519271509270_0745/container_1519271509270_0745_01_000001 org.apache.spark.deploy.yarn.ApplicationMaster --class 'org.apache.spark.ml.alogrithm.SmartRules' --jar hdfs://slave131:9000/user/mls_zl/lib2/cmpt/zl-workflow-component-0.3.2-20180320-1101.jar --arg 'hdfs://slave131:9000/user/mls_3.5/proc/1/11/92/submit_SmartRules_37Client.json' --properties-file /home/hadoop/tmp/nm-local-dir/usercache/zhoulong/appcache/application_1519271509270_0745/container_1519271509270_0745_01_000001/__spark_conf__/__spark_conf__.properties 1> /home/hadoop/hadoop-2.7.3/logs/userlogs/application_1519271509270_0745/container_1519271509270_0745_01_000001/stdout 2> /home/hadoop/hadoop-2.7.3/logs/userlogs/application_1519271509270_0745/container_1519271509270_0745_01_000001/stderr
hadoop   110891 110334 99 13:40 ?        00:00:34 ./jdk-8u161-linux-x64.tar.gz/jdk1.8.0_161/bin/java -server -Xmx1024m -Djava.io.tmpdir=/home/hadoop/tmp/nm-local-dir/usercache/zhoulong/appcache/application_1519271509270_0745/container_1519271509270_0745_01_000001/tmp -XX:MaxPermSize=2048m -XX:PermSize=512m -Dspark.yarn.app.container.log.dir=/home/hadoop/hadoop-2.7.3/logs/userlogs/application_1519271509270_0745/container_1519271509270_0745_01_000001 org.apache.spark.deploy.yarn.ApplicationMaster --class org.apache.spark.ml.alogrithm.SmartRules --jar hdfs://slave131:9000/user/mls_zl/lib2/cmpt/zl-workflow-component-0.3.2-20180320-1101.jar --arg hdfs://slave131:9000/user/mls_3.5/proc/1/11/92/submit_SmartRules_37Client.json --properties-file /home/hadoop/tmp/nm-local-dir/usercache/zhoulong/appcache/application_1519271509270_0745/container_1519271509270_0745_01_000001/__spark_conf__/__spark_conf__.properties
hadoop   111013 111010  0 13:40 ?        00:00:00 /bin/bash -c ./jdk-8u161-linux-x64.tar.gz/jdk1.8.0_161/bin/java -server -Xmx4096m -Djava.io.tmpdir=/home/hadoop/tmp/nm-local-dir/usercache/zhoulong/appcache/application_1519271509270_0745/container_1519271509270_0745_01_000002/tmp '-Dspark.ui.port=0' '-Dspark.driver.port=37011' -Dspark.yarn.app.container.log.dir=/home/hadoop/hadoop-2.7.3/logs/userlogs/application_1519271509270_0745/container_1519271509270_0745_01_000002 -XX:OnOutOfMemoryError='kill %p' org.apache.spark.executor.CoarseGrainedExecutorBackend --driver-url spark://CoarseGrainedScheduler@10.100.1.131:37011 --executor-id 1 --hostname slave131 --cores 8 --app-id application_1519271509270_0745 --user-class-path file:/home/hadoop/tmp/nm-local-dir/usercache/zhoulong/appcache/application_1519271509270_0745/container_1519271509270_0745_01_000002/__app__.jar 1>/home/hadoop/hadoop-2.7.3/logs/userlogs/application_1519271509270_0745/container_1519271509270_0745_01_000002/stdout 2>/home/hadoop/hadoop-2.7.3/logs/userlogs/application_1519271509270_0745/container_1519271509270_0745_01_000002/stderr
hadoop   111567 111013 99 13:40 ?        00:00:32 ./jdk-8u161-linux-x64.tar.gz/jdk1.8.0_161/bin/java -server -Xmx4096m -Djava.io.tmpdir=/home/hadoop/tmp/nm-local-dir/usercache/zhoulong/appcache/application_1519271509270_0745/container_1519271509270_0745_01_000002/tmp -Dspark.ui.port=0 -Dspark.driver.port=37011 -Dspark.yarn.app.container.log.dir=/home/hadoop/hadoop-2.7.3/logs/userlogs/application_1519271509270_0745/container_1519271509270_0745_01_000002 -XX:OnOutOfMemoryError=kill %p org.apache.spark.executor.CoarseGrainedExecutorBackend --driver-url spark://CoarseGrainedScheduler@10.100.1.131:37011 --executor-id 1 --hostname slave131 --cores 8 --app-id application_1519271509270_0745 --user-class-path file:/home/hadoop/tmp/nm-local-dir/usercache/zhoulong/appcache/application_1519271509270_0745/container_1519271509270_0745_01_000002/__app__.jar
hadoop   111619 111616  0 13:40 ?        00:00:00 /bin/bash -c ./jdk-8u161-linux-x64.tar.gz/jdk1.8.0_161/bin/java -server -Xmx4096m -Djava.io.tmpdir=/home/hadoop/tmp/nm-local-dir/usercache/zhoulong/appcache/application_1519271509270_0745/container_1519271509270_0745_01_000003/tmp '-Dspark.ui.port=0' '-Dspark.driver.port=37011' -Dspark.yarn.app.container.log.dir=/home/hadoop/hadoop-2.7.3/logs/userlogs/application_1519271509270_0745/container_1519271509270_0745_01_000003 -XX:OnOutOfMemoryError='kill %p' org.apache.spark.executor.CoarseGrainedExecutorBackend --driver-url spark://CoarseGrainedScheduler@10.100.1.131:37011 --executor-id 2 --hostname slave131 --cores 8 --app-id application_1519271509270_0745 --user-class-path file:/home/hadoop/tmp/nm-local-dir/usercache/zhoulong/appcache/application_1519271509270_0745/container_1519271509270_0745_01_000003/__app__.jar 1>/home/hadoop/hadoop-2.7.3/logs/userlogs/application_1519271509270_0745/container_1519271509270_0745_01_000003/stdout 2>/home/hadoop/hadoop-2.7.3/logs/userlogs/application_1519271509270_0745/container_1519271509270_0745_01_000003/stderr
hadoop   112178 111619 99 13:40 ?        00:00:50 ./jdk-8u161-linux-x64.tar.gz/jdk1.8.0_161/bin/java -server -Xmx4096m -Djava.io.tmpdir=/home/hadoop/tmp/nm-local-dir/usercache/zhoulong/appcache/application_1519271509270_0745/container_1519271509270_0745_01_000003/tmp -Dspark.ui.port=0 -Dspark.driver.port=37011 -Dspark.yarn.app.container.log.dir=/home/hadoop/hadoop-2.7.3/logs/userlogs/application_1519271509270_0745/container_1519271509270_0745_01_000003 -XX:OnOutOfMemoryError=kill %p org.apache.spark.executor.CoarseGrainedExecutorBackend --driver-url spark://CoarseGrainedScheduler@10.100.1.131:37011 --executor-id 2 --hostname slave131 --cores 8 --app-id application_1519271509270_0745 --user-class-path file:/home/hadoop/tmp/nm-local-dir/usercache/zhoulong/appcache/application_1519271509270_0745/container_1519271509270_0745_01_000003/__app__.jar

```



## 部署python

将对应的python压缩成tar.gz

> $ tar -zcf anaconda2.tar.gz anaconda2

然后操作如下：
```shell
export PYSPARK_PYTHON=./anaconda2.tar.gz/anaconda2/bin/python
$SPARK_HOME/bin/pyspark 
 --conf "spark.yarn.dist.archives=/home/iteblog/anaconda2.tar.gz" \    
 --conf "spark.executorEnv.PYSPARK_PYTHON=./anaconda2.tar.gz/anaconda2/bin/python"\    
 --master yarn-client
```

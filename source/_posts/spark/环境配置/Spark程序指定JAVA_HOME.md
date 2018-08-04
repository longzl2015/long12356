---
title: 在Spark程序里面指定jdk版本
tags: 
  - spark
categories:
  - spark
---

# 在Spark程序里面指定jdk版本

[TOC]

在使用spark集群时经常会出现一种情况：集群的JDK版本为1.7，但是自己编写并编译的程序是用1.8版本的jdk。这种程序提交到spark中就会出现

> Unsupported major.minor version 52.0

为了解决这种情况，可以通过设置相应参数让spark集群调用对应版本的jdk执行对应的程序。

## 前提条件：

在每一个集群节点上安装好相应的jdk版本，这里的安装是指将jdk压缩包解压到某个目录。

**注**：该方法的缺点是必须在每台节点上安装jdk。为了克服该方法可以查看另一篇文章《Spark无管理权限配置Python或JDK》

## 在命令行显示调用

使用`spark.executorEnv.JAVA_HOME` 和 `spark.yarn.appMasterEnv.JAVA_HOME`为spark的executor和driver执行jdk路径：

```shell
$SPARK_HOME/bin/spark-submit --master yarn-cluster  \
        --executor-memory 8g \
        --num-executors 80 \
        --queue eggzl \
        --conf "spark.yarn.appMasterEnv.JAVA_HOME=/home/user/java/jdk1.8.0_25" \
        --conf "spark.executorEnv.JAVA_HOME=/home/user/java/jdk1.8.0_25" \
        --executor-cores 1 \
        --class com.xx.xx \
        /home/user/spark/app.jar
```

## 使用spark_default.conf

```
spark.yarn.appMasterEnv.JAVA_HOME  /home/user/java/jdk1.8.0_25
spark.executorEnv.JAVA_HOME        /home/user/java/jdk1.8.0_25
```

其他的环境变量也可以通过该配置文件获取，比如 `spark.executorEnv.MY_BLOG=www.zzz.com` 这样我们就可以从程序里面获取 `MY_BLOG` 环境变量的值。
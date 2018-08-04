---
title: kafka 初步使用
tags: 
  - kafka
categories:
  - 消息中间件
---



## 1、安装kafka

```
brew install kafka
```

该命令会自动安装 zookeeper依赖

可通过 `brew info kafka`查看 kafka 的相关安装信息。

## 2、修改server.properties 

执行命令：`vi /usr/local/etc/kafka/server.properties`
增加一行配置如下：

```
#listeners = PLAINTEXT://your.host.name:9092
listeners=PLAINTEXT://localhost:9092
```

## 3、启动 zk

```
zkServer start
```

## 4、启动kafka

```
kafka-server-start /usr/local/etc/kafka/server.properties
```

## 5、 测试kafka

启动生产者：

```
kafka-console-producer --topic [topic-name]  --broker-list localhost:9092(第2步修改的listeners)
```

启动消费者：

```
kafka-console-consumer --bootstrap-server localhost:9092 —topic [topic-name] --from-beginning
```

上述命令参数说明：

- --broker-list 
- --bootstrap-server 
- --from-beginning 获取该主题创建起的所有记录(未验证)

## 注意

若部署的kafka是集群形式，命令行起的消费者必须在kafka集群上起，具体啥原因还不清楚，可能自己的配置有问题。

## 参考

[kafka官网quick start](https://kafka.apache.org/quickstart)
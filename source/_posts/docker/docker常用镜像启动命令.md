---
title: docker常用镜像启动命令
date: 2016-04-02 22:46:48
tags: 
  - docker
categories: [docker]
---

## 启动 mysql

```bash
docker run --name localmysql --restart=always -p 3306:3306  -e MYSQL_ROOT_PASSWORD=root -d mysql:5.6 --lower_case_table_names=1
```

- 若要指定路径放到 宿主机上，添加 `-v e:/docker/data/mysql:/var/lib/mysql` 即可。
- 若需要在 定制 sql-model 直接在 docker 命令的末尾加上 `--sql-mode=""`即可

## 启动 迅雷

```bash
 docker run --name xware -v e:/docker/data/xware:/data/TDDOWNLOAD -d bestwu/xware
```

之后，第一次运行 xware 需要绑定一下你的迅雷账号，执行

```bash
docker logs xware
```

```
initing...
try stopping xunlei service first...
killall: ETMDaemon: no process killed
killall: EmbedThunderManager: no process killed
killall: vod_httpserver: no process killed
setting xunlei runtime env...
port: 9000 is usable.

YOUR CONTROL PORT IS: 9000

starting xunlei service...
Connecting to 127.0.0.1:9000 (127.0.0.1:9000)
setting xunlei runtime env...
port: 9000 is usable.

YOUR CONTROL PORT IS: 9000

starting xunlei service...

getting xunlei service info...

THE ACTIVE CODE IS: vghqnv

go to http://yuancheng.xunlei.com, bind your device with the active code.
finished.
```

把 active code 复制一下，打开 http://yuancheng.xunlei.com 点击 我的下载器 旁边的 添加 把 active code 输入进去

## 启动oracle
### oracle 11g

[oracle参考来源](https://github.com/wnameless/docker-oracle-xe-11g)

```bash
docker run --name localOracle -d -p 49160:22 -p 49161:1521 -e ORACLE_ALLOW_REMOTE=true registry.cn-hangzhou.aliyuncs.com/qida/oracle-xe-11g 
```

1. Connect database

-  hostname: localhost 
-  port: 49161 
-  sid: xe 
-  username: system 
-  password: oracle 

2. Login by SSH

```bash
ssh root@localhost -p 49160
password: admin
```

3. 处理密码7天失效问题

```sql
-- 设置密码不过期
ALTER PROFILE DEFAULT LIMIT PASSWORD_LIFE_TIME UNLIMITED;
-- 查看是否生效
SELECT * FROM dba_profiles WHERE profile='DEFAULT' AND resource_name='PASSWORD_LIFE_TIME';
-- 修改密码
alter user zxx identified by zxx;
```



### oracle 12c

```
docker run -d -p 8080:8080 -p 1521:1521 sath89/oracle-12c
```

1. 连接

```
hostname: localhost
port: 1521
sid: xe
service name: xe
username: system
password: oracle

sqlplus system/oracle@//localhost:1521/xe
```

2. 8080

```
http://localhost:8080/apex
workspace: INTERNAL
user: ADMIN
password: 0Racle$
```



## 启动 kafka

[在Docker环境下部署Kafka](http://blog.csdn.net/snowcity1231/article/details/54946857)

```bash
docker run -d --name zookeeper -p 2181 -t wurstmeister/zookeeper 

docker run --name kafka -e HOST_IP=localhost -e KAFKA_ADVERTISED_PORT=9092 -e KAFKA_BROKER_ID=1 -e ZK=zk -p 9092 --link zookeeper:zk -t wurstmeister/kafka  
```

### 验证

```bash
## 进入 kafka 默认目录
docker exec -it ${CONTAINER ID} /bin/bash 
cd opt/kafka_2.11-0.10.1.1/  
## 创建主题
bin/kafka-topics.sh --create --zookeeper zookeeper:2181 --replication-factor 1 --partitions 1 --topic mykafka  
## 创建生产者
bin/kafka-console-producer.sh --broker-list localhost:9092 --topic mykafka  
## 运行消费者
bin/kafka-console-consumer.sh --zookeeper zookeeper:2181 --topic mykafka --from-beginning  
```

## 启动hive

启动hive

```shell
docker run -d --name hadoop-master -p 50070:50070 -p 10000:10000 -p 8088:8088 -p 19888:19888 -p 8042:8042 -p 10020:10020 -h hadoop-master teradatalabs/cdh5-hive
```

启动hue

```bash
docker run --name hue -d -p 8888:8888 gethue/hue

// 容器中修改 pseudo-distributed.ini，主要是hive端口号和ip信息
docker cp hue:/hue/desktop/conf/pseudo-distributed.ini ./pseudo-distributed.ini
docker cp ./pseudo-distributed.ini hue:/hue/desktop/conf/pseudo-distributed.ini

//重启
docker restart hue
```

## 启动swagger

```bash
docker pull swaggerapi/swagger-editor
docker run -d -p 80:8080 swaggerapi/swagger-editor
```

##  启动 jenkins

```bash
docker run --name jenkins -d -p 8080:8080 -p 50000:50000 -v jenkins_home:/var/jenkins_home jenkins/jenkins:lts
```

##退出自动删除

添加 `--rm` 参数即可


---
title: cdh出错锦集
date: 2016-04-02 22:46:48
tags: 
  - cdh
categories:
  - hadoop
---

## 已验证问题
### hdfs 
####  hdfs fsck : Permission denied
在 `conf/hdfs-site.xml` 中
```
<property>
  <name>dfs.permissions</name>
  <value>false</value>
</property>
```
#### hdfs 出现  副本不足的块
使用 `hdfs fsck /` 命令查出出错的文件，将其删除即可。
删除命令 hadoop dfs -rmr 文件路径

### sqoop
#### sqoop2 启动出错

点击sqoop2界面的操作按钮，创建sqoop数据库，然后重新启动


### hive
#### 创建hive时，出现找不到 jdbc。
第一种情况 ：下载jdbc.jar 。(用于cm识别jdbc)
将其放到`/usr/share/cmf/lib/`下
第二种情况：（用于hive识别jdbc）
查看 `/etc/hive/conf.cloudera.hive/hive-env.sh` 发现 `$(find /usr/share/java/mysql-connector-java.jar`
将 jdbc驱动重命名后 放入 `/usr/share/java/`

#### 启动hive时报错 Specified key was too long 问题
将hive数据库改为
alter database hive character set latin1;
#### 启动hive报错 Caused by: MetaException(message:Versioninformation not found in metastore. )
修改CDH中hive的配置:
```
datanucleus.autoCreateSchema=true
datanucleus.metadata.validate=false
hive.metastore.schema.verification=false
```
### yarn
####  yarn启动报错：YarnRuntimeException: Error creating done directory:
sudo -u hdfs hadoop fs -chmod -R 777 /



## 未验证问题 
### sqoop2 使用mysql

参考 
[配置sqoop2](https://www.cloudera.com/documentation/enterprise/5-5-x/topics/cdh_ig_sqoop2_configure.html)
[网上的相关提问](https://community.cloudera.com/t5/Data-Ingestion-Integration/Sqoop-cannot-load-a-driver-class-SQL-Server-when-creating-a/td-p/13626/page/2)

将 `mysql-connector-java-version-bin.jar`添加到 `/var/lib/sqoop2/`

> sudo cp mysql-connector-java-version/mysql-connector-java-version-bin.jar /var/lib/sqoop2/

配置 /etc/sqoop2/conf/sqoop.properties的jdbc连接
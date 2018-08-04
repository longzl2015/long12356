
---
title: sqoop 常用操作
tags: 
  - sqoop
categories:
  - hadoop
---

## sqoop导入到hdfs命令
### 指定parquet类型

```
sqoop import --connect jdbc:mysql://10.100.1.30:3306/zy-ds --username root --password root --table users --delete-target-dir --target-dir /user/mls/dw_data/2/ --as-parquetfile;
```


## sqoop导入hive命令
### 增量导入
1. 简单的增量导入,需自行确定时间分片

```
sqoop import --connect jdbc:mysql://10.100.1.30:3306/zy-ds2 --username root --password root --table calls --delete-target-dir --hive-import --hive-database zyds --hive-table calls -m 1 --where "split_date='20170101'";
```

2. 使用 `--incremental` 
  incremental 有两种模式：append 和 lastmodified。目前 hive import 暂不支持 append 模式。
  incremental 需要跟随两个参数（以下只针对 lastmodified 说明）：
- check-column 必须是 `timestamp` 和 `date` 类型。（对于 db2 ：check-column的列名必须`大写`）
- last-value 需要大于之前的最大值，一般取 `字段最大值 +1`

```
sqoop import --connect jdbc:mysql://10.100.1.30:3306/zy-ds2 --username root --password root --table calls --delete-target-dir --hive-import --hive-database zyds --hive-table calls -m 1 --incremental lastmodified --check-column crt_date --last-value "2015-11-25 12:41:40"
```

### 全量导入
其实就是将原有覆盖写入

```
sqoop import --connect jdbc:mysql://10.100.1.30:3306/zy-ds2 --username root --password root --table calls --delete-target-dir --hive-import --hive-database zyds --hive-table calls -m 1 --hive-overwrite; 
```

## 取消SSL警告

### 警告如下：
```
Tue Aug 09 10:29:43 CST 2016 WARN: Establishing SSL connection without server's identity verification is not recommended. According to MySQL 5.5.45+, 5.6.26+ and 5.7.6+ requirements SSL connection must be established by default if explicit option isn't set. For compliance with existing applications not using SSL the verifyServerCertificate property is set to 'false'. You need either to explicitly disable SSL by setting useSSL=false, or set useSSL=true and provide truststore for server certificate verification.
```
### 解决方案
 产生报警的原因是因为，我搭建的Hive使用MySql作为metadata的存储，而MySql为5.7.12版本，需要在连接串中指定是否采用SSL连接。

所以我们只需修改Hive的 hive-site.xml，在连接串中加入指定SSL为false即可：

```xml
<property>
    <name>javax.jdo.option.ConnectionURL</name>
    <value>jdbc:mysql://ut07:3306/hive?createDatabaseIfNotExist=true&amp;useUnicode=true&amp;characterEncoding=UTF-8&amp;useSSL=false</value>
</property>
```

## 实践中遇到的问题
### 1. Mysql 导到 hive 命令（单表导入命令）：

进入/sqoop/bin目录下，执行如下语句:

```
./sqoop import --connect jdbc:mysql://10.100.1.30:3306/zy-ds2 --username root --password root --table calls --hive-import --hive-database zyds --hive-table calls -m 1; 
```

```
--connect         jdbc:mysql://10.100.1.30:3306/zy-ds2为数据库url
--username root --password root 为数据库用户名密码
--table calls         导入表
--hive-database  zyds 导入至hive内的数据库名
--hive-table calls    导入至hive内的表名
-m 1                  表示启动几个map任务来读取数据（如果数据库中的表没有主键这个参数是必须设置的而且只能设定为1 ）
```
### db2 导入到 hive 
若要使用DB2可将 db2jcc.jar 和 db2jcc_license_cu.jar加入sqoop的lib目录


#### 1.1 FileAlreadyExistsException

	17/02/17 12:27:02 ERROR tool.ImportTool: Encountered IOException running import job: org.apache.hadoop.mapred.FileAlreadyExistsException: Output directory hdfs://master:9000/user/hadoop/calls already exists

解决方法: 
> hadoop dfs -rm -r 相应目录。

或者
运行 sqoop 时添加 `--delete-target-dir` 参数 （放在hive-import 之前）

#### 1.2 已经存在相应的表
如果hive数据库已经存在相应的表，可以通过添加参数  `--hive-overwrite`（放在hive-import 之后）

### 2. Mysql => hive 命令（多表导入命令）：
使用`sqoop-import-all-tables`命令实现多表导入。

在使用多表导入之前，以下三个条件必须同时满足：
           1、每个表必须都只有一个列作为主键；
           2、必须将每个表中所有的数据导入，而不是部分；
           3、你必须使用默认分隔列，且WHERE子句无任何强加的条件

#### 2.1 例子

```
sqoop import-all-tables --connect jdbc:mysql://10.100.1.30:3306/zy-ds2 --username root --password root --hive-import --hive-database zyds -m 2
```

如需指定 hdfs 目录 可加参数 `--warehouse-dir='/user/zl/'`





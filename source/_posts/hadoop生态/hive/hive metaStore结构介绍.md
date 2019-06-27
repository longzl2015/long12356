---
title: hive metaStore 结构介绍
date: 2016-04-02 22:46:48
tags: 
  - hive
categories: [hadoop生态,hive]
---

## 主要表

| 表名               | 说明                                                       | 关联键               |
| -------------------- | ------------------------------------------------------------ | ---------------------- |
| TBLS               | 所有hive表的基本信息                                       | TBL_ID,SD_ID         |
| TABLE_PARAM        | 表级属性，如是否外部表，表注释等                           | TBL_ID               |
| COLUMNS            | Hive表字段信息(字段注释，字段名，字段类型，字段序号)       | SD_ID                |
| SDS                | 所有hive表、表分区所对应的hdfs数据目录和数据格式           | SD_ID,SERDE_ID       |
| SERDE_PARAM        | 序列化反序列化信息，如行分隔符、列分隔符、NULL的表示字符等 | SERDE_ID             |
| PARTITIONS         | Hive表分区信息                                             | PART_ID,SD_ID,TBL_ID |
| PARTITION_KEYS     | Hive分区表分区键                                           | TBL_ID               |
| PARTITION_KEY_VALS | Hive表分区名(键值)                                         | PART_ID              |


从上面表的内容来看，hive整个创建表的过程已经比较清楚了。
   （1）解析用户提交hive语句，对其进行解析，分解为表、字段、分区等hive对象
   （2）根据解析到的信息构建对应的表、字段、分区等对象，从SEQUENCE_TABLE中获取构建对象的最新ID，与构建对象信息（名称，类型等）一同通过DAO方法写入到元数据表中去，成功后将SEQUENCE_TABLE中对应的最新ID+5。


## 表介绍

### 1、SEQUENCE_TABLE 

 对于db、tbl、sds等的SEQUENCE_id ,每次新增的时候 Next_Val


### 2、DBS

存储hive的DB信息，包括描述信息、存储路径、数据库名、拥有者和角色名

### 3、DATABASE_PARAMS 
db的key-value参数 ，不清楚用途。

###4、SDS

提供文件路径location、InputFormat、OutputFormat、是否压缩、是否是子文件夹存储、SerDe类（对应于SERDES表）。

SerDe类表示各种序列化和反序列化的类。

### 5、SD_PARAMS 

每个SDS的key-value参数

### 6、SERDES 

每个SDS对应的存储的SerDer类，每个SDS记录一个SERDES表的记录

### 7、SERDE_PARAMS

SERDE的一些参数，主要是行分隔符、列分隔符、NULL字符串等等，可以每个SerDer自己定义 

### 8、CDS  

暂时没明白到底是什么，不过其id和tbl_id是一致的，貌似就是tbl_id

### 9、TBLS 

table的具体信息。 

Tabid、创建时间、数据库id、last_access、owner(这个后面会和权限控制有关)、表的存储位置id、表名、TBL_TYPE（外部表、内部表）等

### 10、TABLE_PARAMS 

table级别的key-value参数

主要是总文件个数、总文件大小、comment、last_ddl_time（上次执行ddl的时间）、以及用户自定义的一些参数（orcfile中的参数）



### 11、COLUMNS_V2  

列的信息

CD_ID对应的应该是tbl_id  

### 12、PARTITION_KEYS

每个表的partitions 列 

### 13、PARTITIONS 

Partitions id 、create_time、part_name、sds_id、tbl_id

### 14、PARTITION_KEY_VALS

和上面的表对应，每个partitions对应的具体值 

### 15、PARTITION_PARAMS

分区参数，暂时为找到怎么设置每个分区的key-value参数

### 16、PART_COL_STATS

对于每列的统计信息，在0.11以后增加了 

`ANALYZE table contline_revenue_day PARTITION(pdate='2014-03-09') compute statistics for COLUMNS contract_line_id , st_date ,contract_no ; `

这样的ddl命令来用于统计每个分区的基本统计信息，用于优化 

  

### 17.     未用到的空表

BUCKETING_COLS ：

IDXS

INDEX_PARAMS

SKEWED_COL_NAMES

SKEWED_COL_VALUE_LOC_MAP

SKEWED_STRING_LIST

SKEWED_STRING_LIST_VALUES

SKEWED_VALUES

SORT_COLS

VERSION





---
title: Hive - row_number,rank(),dense_rank()
date: 2016-04-02 22:46:48
tags: 
  - hive
  - sql
categories:
  - hadoop
---

### 1. 准备数据

```
	浙江,杭州,300
	浙江,宁波,150
	浙江,温州,200
	浙江,嘉兴,100
	江苏,南京,270
	江苏,苏州,299
	江苏,某市,200
	江苏,某某市,100
```

### 2. 创建表

``` sql
CREATE table pcp
(province string,city string,people int)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
STORED AS TEXTFILE;
```

### 3. 导入数据

> load data inpath '/tmp/1.txt' into table pcp;

### 4. 普通查询

```sql
select * from pcp order by people desc;
```

```
浙江    杭州    300
浙江    宁波    150
浙江    温州    200
浙江    嘉兴    100
江苏    南京    270
江苏    苏州    299
江苏    某市    200
江苏    某某市    100
```

### 5. 综合查询

``` sql
select province,city,
rank() over(order by people desc) rank,
dense_rank() over(order by people desc) dense_rank,
row_number() over(order by people desc) row_number
from pcp
group by province,city,people;
```

	浙江    杭州    300    1    1    1
	江苏    苏州    299    2    2    2
	江苏    南京    270    3    3    3
	江苏    某市    200    4    4    4
	浙江    温州    200    4    4    5
	浙江    宁波    150    6    5    6
	江苏    某某市    100    7    6    7
	浙江    嘉兴    100    7    6    8

主要注意4,5,6行的:

row_number:顺序下来,
rank:在遇到数据相同项时,会留下空位,(4，5，6 第一列,4,4,6)
dense_rank:在遇到数据相同项时,不会留下空位,(4，5，6第一列,4,4,5)


### 6. 分组统计查询

``` sql
select province,city,
rank() over (partition by province order by people desc) rank,
dense_rank() over (partition by province order by people desc) dense_rank,
row_number() over(partition by province order by people desc) row_number
from pcp
group by province,city,people;
```

	江苏    苏州    299    1    1    1
	江苏    南京    270    2    2    2
	江苏    某市    200    3    3    3
	江苏    某某市    100    4    4    4
	浙江    杭州    300    1    1    1
	浙江    温州    200    2    2    2
	浙江    宁波    150    3    3    3
	浙江    嘉兴    100    4    4    4
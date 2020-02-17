---
title: mysql数据类型
date: 2020-01-05 03:30:09
tags: 
  - mysql
categories: [数据库,rdbms,mysql]
---


## 整型

- TINYINT    8位
- SMALLINT   16位
- MEDIUMINT  24位
- INT        32位
- BIGINT     64位

默认情况下，上述类型可以存储的值范围为 -2^(N-1) 到 2^(N-1)-1。
但若类型设置了UNSIGNED属性，则可以使数据的正值增加一倍

注: 
> 当编写 DDL 时，我们发现可以指定 INT 类型的长度。
> 这个长度只是规定了MySQL的一些交互工具(例如MySQL命令行客户端)用来显示字符的个数。对于存储和计算来说，INT(1)和INT(20)是相同的。

## 实数

- FLOAT  4个字节
- DOUBLE 8个字节
- DECIMAL : DECIMAL(18,9)小数点两边将各存储9个数字

## 字符

- VARCHAR 变长字符

由于行是变长的，在UPDATE时可能使行变得比原来更长，这就导致需要做额外的工作。
如果一个行占用的空间增长，并且在页内没有更多的空间可以存储，在这种情况下，不同的存储引擎的处理方式是不一样的。
例如，MyISAM会将行拆成不同的片段存储，InnoDB则需要分裂页来使行可以放进页内。其他一些存储引擎也许从不在原数据位置更新数据。

- CHAR 定长字符

## 大字段

- TINYTEXT
- SMALLTEXT
- TEXT
- MEDIUMTEXT
- LONGTEXT

- TINYBLOB
- SMALLBLOB
- BLOB
- MEDIUMBLOB
- LONGBLOB

BLOB和TEXT家族之间仅有的不同是: BLOB类型存储的是二进制数据，没有排序规则或字符集; 而TEXT类型有字符集和排序规则。
MySQL对BLOB和TEXT列进行排序与其他类型是不同的: 它只对每个列的最前max_sort_length字节而不是整个字符串做排序。如果只需 要排序前面一小部分字符，则可以减小max_sort_length的配置，或者 使用ORDER BY SUSTRING(column，length)。

## 日期

- TIMESTAMP : 从1970年到2038年 精度为秒 （格林尼治标准时间）
- DATETIME : 从1001年到9999年 精度为秒 时区无关
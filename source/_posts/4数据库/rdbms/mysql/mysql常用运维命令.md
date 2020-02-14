---
title: mysql常用运维命令
date: 2020-02-14 03:30:09
tags: 
  - mysql
categories: [数据库,rdbms,mysql]
---


## 查看 表 的相关信息

> SHOW TABLE STATUS LIKE '表名'

输出信息字段介绍: 

1. Name: 表名。
2. Engine: 表的存储引擎类型。
3. Row_format: 行的格式。
4. Rows: 表中的行数。对于MyISAM和其他一些存储引擎，该值是精确 的，但对于InnoDB，该值是估计值。
5. Avg_row_length: 平均每行包含的字节数。
6. Data_length: 表数据的大小(以字节为单位)。
7. Max_data_length: 表数据的最大容量，该值和存储引擎有关。
8. Index_length: 索引的大小(以字节为单位)。
9. Data_free: 对于MyISAM表，表示已分配但目前没有使用的空间。这部分 空间包括了之前删除的行，以及后续可以被INSERT利用到的空 间。
10. Auto_increment: 下一个AUTO_INCREMENT的值。 
11. Create_time: 表的创建时间。
12. Update_time: 表数据的最后修改时间。
13. Check_time: 使用CKECK TABLE命令或者myisamchk工具最后一次检查表的时 间。
14. Collation: 表的默认字符集和字符列排序规则。
15. Checksum: 如果启用，保存的是整个表的实时校验和。
16. Create_options: 创建表时指定的其他选项。
17. Comment: 该列包含了一些其他的额外信息。对于MyISAM表，保存的是 表在创建时带的注释。对于InnoDB表，则保存的是InnoDB表空间 的剩余空间信息。如果是一个视图，则该列包含“VIEW”的文本字 样。
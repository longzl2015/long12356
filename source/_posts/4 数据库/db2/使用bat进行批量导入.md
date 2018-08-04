---
title: db2 使用bat脚本批量导入
tags: 
  - db2
categories:
  - 数据库
---

运行 bat ，调用sql文件即可。

### 创建bat文件

```
@echo off
echo ###用生成的文件操作DB2数据库###
db2cmd db2 -tvf "importall.sql" -l import.log
pause
```

### 创建sql文件

```sql
connect to zl user test using testtest;
load client from 'E:\zds\czj_data\test-20091029' of del insert into test_tmp;
update CCARD.card set SPLIT_DATE = '20161111' where SPLIT_DATE is null 
connect reset;
```

### db2cmd 部分参数

- -c	   执行 DB2 命令窗口，然后终止。
   -w  	一直等到 DB2 命令窗口终止。
    -i  	   从进行调用的 shell 继承环境。
    -t	   从进行调用的 shell 继承标题。

### db2 部分参数

- -t 指明在缺省情况下用分号（;）终止每条命令 
- -v 指明应将每条命令显示到标准输出 
- -f 指明从输入文件读取命令 
- -l 指明将命令记录到输出文件中 
- -r 指明将结果保存到报告文件中 
- -s stop commands on command error

更多参数请访问 [db2 命令 options](https://www.ibm.com/support/knowledgecenter/SSEPGG_9.7.0/com.ibm.db2.luw.admin.cmd.doc/doc/r0010410.html)




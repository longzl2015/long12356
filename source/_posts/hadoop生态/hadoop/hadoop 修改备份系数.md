
---
title: hadoop 修改备份系数
tags: 
  - hadoop
categories:
  - hadoop
---

### 查看文件备份数

```
[root@VLNX107011 hue]# hdfs dfs -ls /facishare-data/flume/test
Found 2 items
drwxr-xr-x   - fsdevops fsdevops          0 2015-11-18 11:09 /facishare-data/flume/test/2015
-rw-r--r--   2 fsdevops fsdevops         33 2015-11-30 17:49 /facishare-data/flume/test/nohup.out
```

结果行中的第2列是备份系数(注：文件夹信息存储在namenode节点上，没有备份，故文件夹的备份系数是横杠)

### 查看集群平均备份数

通过hadoop fsck /可以方便的看到Average block replication的值，这个值不一定会与Default replication factor相等。

```
[root@VLNX107011 hue]# hdfs fsck /
Connecting to namenode via http://VLNX107011:50070
FSCK started by root (auth:SIMPLE) from /VLNX107011 for path / at Fri Dec 04 19:08:09 CST 2015
...................
 Total size:	11837043630 B (Total open files size: 166 B)
 Total dirs:	3980
 Total files:	3254
 Total symlinks:		0 (Files currently being written: 2)
 Total blocks (validated):	2627 (avg. block size 4505916 B) (Total open file blocks (not validated): 2)
 Minimally replicated blocks:	2627 (100.0 %)
 Over-replicated blocks:	2253 (85.76323 %)
 Under-replicated blocks:	0 (0.0 %)
 Mis-replicated blocks:		0 (0.0 %)
 Default replication factor:	3
 Average block replication:	2.9798248
 Corrupt blocks:		0
 Missing replicas:		0 (0.0 %)
 Number of data-nodes:		10
 Number of racks:		1
FSCK ended at Fri Dec 04 19:08:09 CST 2015 in 100 milliseconds
The filesystem under path '/' is HEALTHY
```

可以看到`Average block replication`, `Corrupt blocks`, `Missing replicas`等信息。

### 修改备份系数

```
[root@VLNX107011 hue]# hdfs dfs -setrep -w 3 -R /
Replication 3 set: /user/oozie/share/lib/lib_20151103160704/hive/jetty-all-7.6.0.v20120127.jar
Replication 3 set: /user/oozie/share/lib/lib_20151103160704/hive/jline-2.11.jar
......
Waiting for /backup/gitlab/1447133001_gitlab_backup.tar ........... done
Waiting for /backup/gitlab/1447133732_gitlab_backup.tar ... done
Waiting for /backup/gitlab/1447180217_gitlab_backup.tar ... done
......
```
可以看到HDFS对所有文件的备份系数进行了刷新。

再次检查刚才文件的备份系数，可以看到从2变为3。

```
[root@VLNX107011 hue]# hdfs dfs -ls /facishare-data/flume/test
Found 2 items
drwxr-xr-x   - fsdevops fsdevops          0 2015-11-18 11:09 /facishare-data/flume/test/2015
-rw-r--r--   3 fsdevops fsdevops         33 2015-11-30 17:49 /facishare-data/flume/test/nohup.out
```

**WARNING** 
将备份系数从低到高比较容易，但从高到低会特别慢，所以在集群搭建初始就要规划好Default replication factor。
通常备份系数不需要太高，可以是服务器总量的1/3左右即可，Hadoop默认的数值是3。

### 参考
[HDFS修改备份系数和动态增删节点](http://wzktravel.github.io/2016/01/19/hdfs-add-nodes-dynamically/)
---

title: oracle session和process试图

date: 2018-08-14 22:46:48

categories: [oracle]

tags: [oracle]

---

v$session    此视图列出当前会话的详细信息-用户进程通过网络连接到服务器进程，即产生一个会话--不论会话是否有操作。
v$process    此视图包含当前系统oracle运行的所有进程信息。

<!--more-->

## session 视图

v$session

### 常用字段及其描述：

SADDR       产生的会话在内存中的位置
PADDR       进程的地址，与V$PROCESS中ADDR对应
TADDR       与V$TRANSACTION中ADDR对应，与V$LOCK中ADDR对应
SID         Session identifier  与select distinct sid from v$mystat;中对应
SERIAL#     同一会话下的多个操作，用序列号SERIAL#来表示
USER#       其中SYS用户为0，与后面的SCHEMA#字段对应
USERNAME    当前进程使用的ORACLE数据库用户名，与后面SCHEMANAME对应
COMMAND     查看进程当前正在执行的操作类型--显示数字，要查找数字对应的操作类型。-有锁定时可查
OWNERID     固定值2147483644。如是其它值，则是迁移会话的用户的标识符。
LOCKWAIT    与V$LOCK中KADDR对应
STATUS      会话ACTIVE 状态：1.SQL正在执行 2.在等待-锁。
SERVER      网络连接模式：(DEDICATED| SHARED| PSEUDO| NONE)

### 客户端主机相关字段描述：
OSUSER      客户端的操作系统用户名：WIN下Administrator，LINUX下oracle
PROCESS     客户端的进程号：LINUX客户端进程号为25819： ps aux|grep 25819|grep -v grep
PORT        客户端端口号
MACHINE     客户端主机名：比如WIN WORKGROUP\BYSORACLE，LINUX bys3.bys.com
TERMINAL    控制台名：比如WIN BYSORACLE，LINUX pts/3
PROGRAM     客户端程序，比如WIN PLSQL:plsqldev.exe,LINUX的SQLPLUS sqlplus@bys3.bys.com (TNS V1-V3)
TYPE        会话类型：分为用户会话与后台进程会话两种
SERVICE_NAME    会话如果是通过网络监听连接，显示的是服务名。如通过IPC，可能是SYS$USERS
SQL_TRACE   SQL TRACE是否开启
LOGON_TIME  客户端登陆时的时间 
RESOURCE_CONSUMER_GROUP  会话当前资源组的名称

### 会话执行的SQL语句的相关字段描述：

SQL_ADDRESS 目前正在执行的SQL语句的SQL标识符
SQL_HASH_VALUE
SQL_ID      为空，执行完毕。不为空，会话ACTIVE。与V$SQL中SQL_ID对应。select sql_text from v$sql where sql_id='9mk1dmrqf9dv8';
SQL_CHILD_NUMBER
SQL_EXEC_START 10G无此字段，11G有，显示SQL语句开始执行的时间
SQL_EXEC_ID     目前正在执行的SQL语句的SQL标识符
PREV_SQL_ADDR
PREV_HASH_VALUE
PREV_SQL_ID
PREV_CHILD_NUMBER   
PREV_EXEC_START  11G新增
PREV_EXEC_ID        11G新增。这6个PREV_开头的字段描述的均是最后一次执行的SQL语句的信息。

### 会话相关的锁、等待事件字段描述

ROW_WAIT_OBJ#   等待的对象；与DBA_OBJECTS中OBJECT_ID对应
ROW_WAIT_FILE#  等待的OBJECTS所在的数据文件编号，与dba_data_files 中 file_id对应。select * from dba_data_files where file_id=4;
ROW_WAIT_BLOCK# 在数据文件 的第N个块上
ROW_WAIT_ROW#   在数据文件 的第N个块上第N行 0指从第一行开始
BLOCKING_SESSION_STATUS 阻塞会话状态，VALID 被阻塞；NO HOLDER 无阻塞；
BLOCKING_SESSION        显示被哪个会话阻塞
BLOCKING_INSTANCE       显示补哪个实例阻塞-RAC时
SEQ#            等待事件的惟一标识，此数字会递增。
EVENT#          事件ID；五V$EVENT_NAME中的EVENT#对应
EVENT           事件描述：如enq: TX - row lock contention 行锁  正常状态：SQL*Net message from client
WAIT_CLASS      等待事件的类型-Application/IDLE；
WAIT_TIME       WAIT_TIME非零值是会话的最后等待时间。零值表示会话正在等待。
SECONDS_IN_WAIT 如果WAIT_TIME=0，则SECONDS_IN_WAIT是在当前等待状态所花费的秒。如果WAIT_TIME> 0，则SECONDS_IN_WAIT是秒自上次等待的开始，SECONDS_IN_WAIT - WAIT_TIME/100自上等待结束的活跃秒。

## PROCESS视图

V$PROCESS

ADDR       与v$session中PADDR对应
PID        Oracle进程标识符，ORACLE的后台进程及用户进程都在内。查select pid,pname from v$process;
SPID       ORACLE中进程ID--ps -ef |grep LOCAL    查出的进程号
PROGRAM    显示所用的程序--如oracle@bys3.bys.com (SMON)  后台进程 oracle@bys3.bys.com (TNS V1-V3) 服务器上直接连接  oracle@bys3.bys.com 通过监听连接的用户进程
BACKGROUND 值为1，是后台进程。NULL表示是普通用户进程
TRACEID     
TRACEFILE  11G中新增字段，显示了当前进程的TRACEFILE的具体位置。
LATCHWAIT  等待的锁的地址; NULL，没有锁
LATCHSPIN  Address of the latch the process is spinning on; NULL if none

## 运维sql

### 查看 进程数

```oraclesqlplus
-- 当前连接数
select count(*)
from v$process;
```

### 查看 当前连接的 主机 用户等信息

process 字段显示 1234 ，该字段就是无效的

```oraclesqlplus
select program, machine,port, process, osuser from v$session order by machine ,osuser;
```

### 查询 当前连接主机的pid

process 字段显示 1234 ，该字段就是无效的

1. 先查询到客户端的端口号

```oraclesqlplus
select program, machine,port, osuser from v$session order by machine ,osuser;
```

2. 登录连接主机，通过 lsof 查询对应的pid

```bash
lsof -i:58993
```


---
title: processlist
date: 2017-01-05 03:30:09
tags: 
  - mysql
categories:
  - 数据库
---

# show processlist 命令

该命令用于展示哪些线程正在运行。你也可以从`INFORMATION_SCHEMA PROCESSLIST` 表中 或者mysqladmin processlist命令获得以上信息。如果你有 process 特权，你可以看到所有的线程信息，否则你仅能看到你自己的线程信息。如果你没有使用 full 关键字，那么你只会获得前100条记录。

进程信息也可以从`performance_schema.threads`表中获得。但是，对`threads`表的访问不需要互斥，并且对服务器性能的影响最小。`information_schema.processlist`和`show processlist`会产生负面的性能影响，因为它们需要互斥体。`threads`表还显示关于后台线程的信息，其中`information_schema.processlist`和`show processlist`不包含这些信息。这意味着可以使用`threads`表来监视其他线程信息源无法进行的活动。

如果你得到`too many connections`的错误信息,`show processlist`语句是非常有用的。mysql会保留一个额外的连接供具有超级特权的帐户使用，以确保管理员始终能够连接并检查系统（假设您没有将此特权授予所有用户）。线程可以用kill语句来杀死。请参见 [Section 13.7.6.4 “KILL Syntax”](https://dev.mysql.com/doc/refman/5.7/en/kill.html).。

这里是`show processlist`输出的一个例子：

```mysql
mysql> SHOW FULL PROCESSLIST\G
*************************** 1. row ***************************
Id: 1
User: system user
Host:
db: NULL
Command: Connect
Time: 1030455
State: Waiting for master to send event
Info: NULL
*************************** 2. row ***************************
Id: 2
User: system user
Host:
db: NULL
Command: Connect
Time: 1004
State: Has read all relay log; waiting for the slave
       I/O thread to update it
Info: NULL
*************************** 3. row ***************************
Id: 3112
User: replikator
Host: artemis:2204
db: NULL
Command: Binlog Dump
Time: 2144
State: Has sent all binlog to slave; waiting for binlog to be updated
Info: NULL
*************************** 4. row ***************************
Id: 3113
User: replikator
Host: iconnect2:45781
db: NULL
Command: Binlog Dump
Time: 2086
State: Has sent all binlog to slave; waiting for binlog to be updated
Info: NULL
*************************** 5. row ***************************
Id: 3123
User: stefan
Host: localhost
db: apollon
Command: Query
Time: 0
State: NULL
Info: SHOW FULL PROCESSLIST
5 rows in set (0.00 sec)
```

- Id

  连接标识符。这与`information_schema.processlist`表的id列、`performance schema threads表的processlist_id列 、由connection_id（）函数返回的值相同。

- User

  发布该声明的mysql用户。如果这是`system user`，则它指由服务器派生、处理内部任务的非client线程。`unauthenticated user`是指客户端已建立关联但客户端用户的身份验证尚未完成的线程。`event_scheduler`是指监视scheduled事件的线程。For system user, there is no host specified in the Host column.

- Host

  发布该声明的主机名（除没有host的`system user`外）。show processlist命令host列的展现格式 host_name:client_port

- Db

  数据库名。

- Command

  线程正在执行的命令的类型。有关线程命令的说明，请参见 [Section 8.14 “Examining Thread Information”](https://dev.mysql.com/doc/refman/5.7/en/thread-information.html)，[Section 5.1.7 “Server Status Variables”](https://dev.mysql.com/doc/refman/5.7/en/server-status-variables.html)

- Time  

  线程处于当前状态的时间（以秒为单位）。对于slave SQL线程，请参见[Section 16.2.2, “Replication Implementation Details”](https://dev.mysql.com/doc/refman/5.7/en/replication-implementation-details.html)

- Status

  表示当前线程正在执行的动作、事件或状态。状态值的描述可以在 [Section 8.14, “Examining Thread Information”](https://dev.mysql.com/doc/refman/5.7/en/thread-information.html)中找到。

  大多数的status停留的时间很短，如果一个线程停留在特定的状态很多秒，可能有一个问题需要调查。

  对于show processlist语句，state的值为null。

- INFO  

  线程正在执行的statement;如果未执行任何statement，则为null。该statement可能是发送给服务器的statement，也可能是一个内嵌statement（如果statement执行了其他的statement）。For example, if a `CALL` statement executes a stored procedure that is executing a[`SELECT`](https://dev.mysql.com/doc/refman/5.7/en/select.html) statement, the `Info` value shows the [`SELECT`](https://dev.mysql.com/doc/refman/5.7/en/select.html) statement.



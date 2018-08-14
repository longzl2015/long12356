---

title: oracle连接数超限

date: 2018-08-14 下午4:55

categories: [oracle]

tags: [oracle]

---


oracle连接数超限,需修改最大连接数


<!--more-->

以oracle用户登录linux服务器，然后执行以下命令

```bash
cmd>sqlplus / as sysdba
sqlplus>alter system set processes=300 scope=spfile;
sqlplus>shut immediate;
sqlplus>startup
```

检查是否生效：

```oraclesqlplus
select value from v$parameter where name = 'processes';
```

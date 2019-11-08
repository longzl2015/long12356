---
title: docker常用数据库
date: 2019-08-10 22:46:48
tags: 
  - docker
categories: [docker]
---

测试人员经常需要切换数据库，安装数据库非常耗时。故编写该文章。

本文的目标用户是测试人员，使其能快速使用docker搭建不同的版本的数据库，然后进行测试。

<!--more-->

## 通用参数

`-p 1111:2222`   将 `本机的1111端口` 映射到 `容器中的2222端口`

`-v /home/data:/var/data` 将 `本机的文件夹/home/data` 映射到 `容器中的/var/data` 

`--restart=always`  容器异常退出后，自动重启

## 通用命令

`docker stop 容器名` 停止容器，不删除容器

`docker start 容器名` 启动容器

`docker logs 容器名` 查看容器的日志

`docker rm 容器名` 删除容器

`docker rmi 镜像名` 删除镜像

`docker ps` 查看正在运行的容器

`docker ps -a` 查看所有的容器

`docker images ` 查看所有的镜像

##  mysql

### 启动 mysql

```bash
docker run --name localmysql --restart=always -p 3306:3306  -e MYSQL_ROOT_PASSWORD=root -d mysql:5.6 --lower_case_table_names=1
```

> 用户名           root
>
> 密码               root
>
> 端口号           -p 的第一个参数

- 若要将mysql的数据保存到本机上，添加 `-v /home/data:/var/lib/mysql` 即可。
- `--lower_case_table_names=1` 表示数据库对大小写不敏感
- 如要改mysql版本，将 5.6 修改为其他版本即可。

### 迁移 mysql

```text
docker exec some-mysql sh -c 'exec mysqldump --all-databases -uroot -p"$MYSQL_ROOT_PASSWORD"' > /some/path/on/your/host/all-databases.sql

docker exec -i another-mysql sh -c 'exec mysql -uroot -p"$MYSQL_ROOT_PASSWORD"' < /some/path/on/your/host/all-databases.sql
```

### 创建用户与授权

```text
use mysql;
CREATE USER 'username'@'localhost' IDENTIFIED BY 'password';
GRANT ALL ON *.* TO 'username'@'localhost';
flush privileges;
```

## 启动oracle
### oracle 11g

```bash
docker run --name oracle11 -d -p 49160:22 -p 49161:1521 -e ORACLE_ALLOW_REMOTE=true registry.cn-hangzhou.aliyuncs.com/qida/oracle-xe-11g 
```

> 数据库sid               xe
>
> 数据库用户名        system
>
> 数据库密码            oracle
>
> 数据库端口号        见 -p 参数

> ssh 用户名       root
>
> ssh 密码          admin
>
> ssh 端口号      见 -p 参数

**新建用户**

先使用管理员账号连上数据库，然后执行如下语句

```sql
create user 用户名 identified by 密码;
grant connect, resource to 用户名;
```

### oracle 12c

```
docker run --name oracle12 -d -p 8080:8080 -p 1521:1521 sath89/oracle-12c
```

1. 连接

```
hostname: localhost
port: 1521
sid: xe
service name: xe
username: system
password: oracle

sqlplus system/oracle@//localhost:1521/xe
```

2. 8080

```
http://localhost:8080/apex
workspace: INTERNAL
user: ADMIN
password: 0Racle$
```



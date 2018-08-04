---
title: cloudera安装cdh5.7
date: 2016-04-02 22:46:48
tags: 
  - cloudera
  - cdh
categories:
  - hadoop
---

详细可参考cloudera的path B安装方法

建议使用root用户安装

## host 配置

1. 修改主机名

> hostname mastter 

2. 配置 /etc/hosts

|           ip | hostname |
| -----------: | :------: |
| 10.100.1.211 |  master  |
| 10.100.1.213 |  slave0  |

3. 将hosts文件从主节点master分发到各个从节点。：
> scp /etc/hosts root@slave1:/etc

## 防火墙与selinux
1. 关闭防火墙(每个节点)
  service iptables stop
  chkconfig iptables off
2. 关闭selinux(重启生效)
  vim /etc/selinux/config
  将`SELINUX`修改为`disabled`

## ssh免密登录

1. 各个节点安装ssh
> ssh-keygen -t rsa  一路回车结束
2. 将公钥加入到authorized_keys(只需master操作)
> cat id_rsa.pub >authorized_keys

3. 修改权限
> chmod 600 authorized_keys

4. 将authorized_keys从master分发到各个slave
> scp authorize_keys root@slave1:~/.ssh/

### jdk 安装
1. 卸载自带java
> rpm -qa |grep java
> yum remove java*(删除自带的java)

2. 将jdk安装到 `/usr/java/jdk-version`目录下

3. 配置java环境变量到 `/etc/profile`

### ntp时间同步

1. 安装NTP（每个节点）
  yum install ntp

2. 配置NTP
  vim /etc/ntp.conf
  master配置：
```
# 中国这边最活跃的时间服务器 : http://www.pool.ntp.org/zone/cn
 server 0.cn.pool.ntp.org
 server 0.asia.pool.ntp.org
 server 3.asia.pool.ntp.org
#
# # allow update time by the upper server
# # 允许上层时间服务器主动修改本机时间
 restrict 0.cn.pool.ntp.org nomodify notrap noquery
 restrict 0.asia.pool.ntp.org nomodify notrap noquery
 restrict 3.asia.pool.ntp.org nomodify notrap noquery
#
# # Undisciplined Local Clock. This is a fake driver intended for backup
# # and when no outside source of synchronized time is available.
# # 外部时间服务器不可用时，以本地时间作为时间服务
 server  127.127.1.0     # local clock
 fudge   127.127.1.0 stratum 10
```
slave配置
在vim /etc/ntp.conf中
将服务器地址改为 server master  prefer

3. 开启NTP服务
  service ntpd start
  chkconfig ntpd off

4. 查看同步效果
  命令：ntpstat
```
synchronised to ntp server(...) at ...
time correct to within 219ms 
```

### 安装mysql
1. 配置远程访问
2. 新建hive、cmf、activity等数据库

### Cloudera Manager安装

1. 下载软件包
> http://archive.cloudera.com/cm5/redhat/6/x86_64/cm/5.7/RPMS/x86_64/

```
cloudera-manager-agent-5.7.6-1.cm576.p0.5.el6.x86_64.rpm	2017-02-21 22:37	8.9M	 
cloudera-manager-daemons-5.7.6-1.cm576.p0.5.el6.x86_64.rpm	2017-02-21 22:37	530M	 
cloudera-manager-server-5.7.6-1.cm576.p0.5.el6.x86_64.rpm	2017-02-21 22:37	8.2K	 
cloudera-manager-server-db-2-5.7.6-1.cm576.p0.5.el6.x86_64.rpm	2017-02-21 22:37	9.9K	 
enterprise-debuginfo-5.7.6-1.cm576.p0.5.el6.x86_64.rpm	2017-02-21 22:37	30M	 
```

2. master节点安装
  将下载好的rpm包放到一个文件夹中，任意命名，进入到这个文件夹手动安装：
  yum localinstall --nogpgcheck *.rpm
  使用yum安装会同时安装相关的依赖，非常方便
  如果要卸载使用
  yum --setopt=tsflags=noscripts remove xxxx

3. slave节点安装
  slave中不需要安装server的包，只需要安装cloudera-manager-agent.rpm和cloudera-manager-daemons.rpm。先将两个rpm包拷贝到slave节点上，剩下安装方法和master一样。

4. 启动cm server和agent 
> service cloudera-manager-server start
> service cloudera-manager-agent start

5. 访问登录7180端口
  默认账号/密码：admin/admin

### CDH服务安装

1. CDH软件包，下载地址：
> http://archive.cloudera.com/cdh5/parcels/5.6/
```
CDH-5.6.1-1.cdh5.6.1.p0.3-el6.parcel	
CDH-5.6.1-1.cdh5.6.1.p0.3-el6.parcel.sha1
manifest.json
```
之前完成CM安装之后master节点会在/opt目录下生成cloudera文件夹，将刚才下载的三个文件移动到parcel-repo文件夹中并将
CDH-5.6.1-1.cdh5.6.1.p0.3-el6.parcel.sha1更名为
CDH-5.6.1-1.cdh5.6.1.p0.3-el6.parcel.sha 如不更名会在线重新下载。

2. 配置软件

登录7180端口:http://master:7180
初始用户名与密码均为admin。 一路 continue

2.1  在搜索主机界面添加各个主机ip
输入集群中各个主机名或者ip，可以用空格分隔，点击search，然后continue
2.2 选择parcel版本
2.3  跳过安装jdk
2.4 设置ssh登录，选择全部主机使用统一ssh密码，输入密码点击continue。
2.5 安装cloudera-manager-agent相关软件
2.6 主机检测
2.7 安装parcel包
选择hadoop、spark、hive等组件
2.8 一路continue完成安装






---
title: docker 远程访问
tags: 
  - docker
categories:
  - docker
---

## 前言

注意关闭防火墙



## 方法一：配置daemon.json文件（centos7中失败，无法成功）

vim /etc/docker/daemon.json
```json
{
  "registry-mirrors": ["https://xxxxxxx.mirror.aliyuncs.com"],
  "hosts": ["tcp://0.0.0.0:2375","unix:///var/run/docker.sock"]
}
```

使用 `sudo service docker start` 启动

docker ps  验证
```
[root@devhost16 ~]# docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
```

注:
 [daemon.json文件详细解释](https://docs.docker.com/engine/reference/commandline/dockerd/)

## 方法二：修改 /etc/sysconfig/docker
首先，centos中Docker的配置不同于ubuntu，在centos中没有/etc/default/docker，另外在centos7中也没有找到/etc/sysconfig/docke这个配置文件。


**在作为docker远程服务的centos7机器中配置如下：**

1、在/usr/lib/systemd/system/docker.service，配置远程访问。主要是在[Service]这个部分，加上下面两个参数


```
# vim /usr/lib/systemd/system/docker.service
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H tcp://0.0.0.0:2375 -H unix://var/run/docker.sock
```

2、docker重新读取配置文件，重新启动docker服务

```
# systemctl daemon-reload
# systemctl restart docker
```

3、查看docker进程，发现docker守护进程在已经监听2375的tcp端口

```
# ps -ef|grep docker
root     26208     1  0 23:51 ?        00:00:00 /usr/bin/dockerd -H tcp://0.0.0.0:2375 -H unix://var/run/docker.sock
```

4、查看系统的网络端口，发现tcp的2375端口，的确是docker的守护进程在监听

```
# netstat -tulp
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
tcp        0      0 0.0.0.0:ssh             0.0.0.0:*               LISTEN      886/sshd
tcp6       0      0 [::]:2375               [::]:*                  LISTEN      26208/dockerd
```

5、这里拿本地的ubuntu做客户端，来访问阿里云上centos7的docker服务，访问成功。139.129.130.123是阿里云上的centos7机器公网ip。

```
$ sudo docker -H tcp://13x.12x.13x.12x:2375 images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
mysql               5.6                 f8fe303bcac2        4 days ago          298MB
```

注意：生产环境最好将这个关掉，或者做好安全的配置


## dockerui 命令

 > sudo docker run -d -p 9000:9000 portainer/portainer -H tcp://13x.12x.13x.12x:2375

##参考文章：

https://forums.docker.com/t/expose-the-docker-remote-api-on-centos-7/26022/2
https://docs.docker.com/engine/security/https/







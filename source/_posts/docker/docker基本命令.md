---
title: docker 基本命令
date: 2016-04-02 22:46:48
tags: 
  - docker
categories: [docker]
---

[TOC]

## 1. 镜像基本操作

### 1.1 搜索镜像:  

 docker search 关键字

### 1.2 下载一个镜像

docker pull 镜像名

###1.3 本地镜像列表

docker images

### 1.4 删除镜像

docker rmi 镜像名

## 2. 容器基本操作
### 2.1 创建并运行一个容器
> docker run --rm --name 容器名 -d 镜像名

	-d表示deamon，以后台启动这个container
	-i表示同步container的stdin
	-t表示同步container的输出
	--rm=true 表示容器运行完后，自动删除

### 2.2 容器列表
docker ps 查看所有正在运行的容器
docker ps -a 查看所有的容器，包括停止运行的

### 2.3 启动和停止容器
docker stop  container-id/container-name
docker start  container-id/container-name

### 2.4 登陆容器
登陆容器能够使我们在容器中像正常访问linux一样操作,访问正在运行的容器
docker exec -it  container-id/container-name bash

### 2.5 端口映射
由于本机和本机的局域网是无法访问docker容器的，所以需要将docker容器的端口映射到当前主机的端口上。
> docker run -d -p (宿主机器端口):(虚拟机端口) --name 容器名 镜像名

### 2.6 删除容器
docker rm  container-id
docker rm $(docker ps -a -q) 删除所有的容器

### 2.7 查看容器日志
docker logs  container-id/container-name

### 2.8 将容器保存为一个镜像
docker commit  container-id/container-name

## 3.自定义一个镜像
### 3.1 commit方式
1. 进入bash交互环境
  docker run -t -i 镜像名 /bin/bash
2. 安装想要的软件( 如 wget )
  docker run -t -i b15 /bin/bash

3. 安装完毕后退出容器
  exit
4. 找到刚刚创建的容器
  docker ps -a
5. 将该容器提交为一个新的镜像
  docker commit 容器名  新的镜像名

### 3.2 dockfile方式
1. 预先编写一个Dockerfile
```
# This is a comment
FROM centos  //基于什么镜像
MAINTAINER doublespout <doublespout@gmail.com>   //作者是
RUN yum install -y wget    //依次执行什么命令
```
2. 安装如下命令创建镜像

```bash
mkdir wget
cd wget
vi Dockerfile #将上面内容复制进去
docker build -t="doublespout/wget" ./
# 也可以直接使用远程文件
docker build -t="dockerfile/nginx" github.com/dockerfile/nginx
#将看到安装脚本的执行输出，安装完成后，执行 docker images 就可以看到我们刚才创建的镜像了
```

## 4.容器和宿主机的资源拷贝

https://docs.docker.com/engine/reference/commandline/cp/

### 从container往host拷贝文件

```Sh
docker cp <container_id>:/root/hello.txt 宿主机路径
```

### 从host往container里拷贝文件
```Sh
docker cp 宿主机路径 <container_id>:/root/hello.txt 
```

## 5.将多个 container 连接起来
`--link` 已不被推荐。

使用 自定义 bridge ，可以使 不同的容器以容器名的方法相互访问。

```bash
docker network create --driver bridge busybox_bridge
docker run -itd --network busybox_bridge --name busybox5 busybox
docker run -itd --network busybox_bridge --name busybox6 busybox
```

busybox5 就可以使用`域名busybox6`访问`容器busybox6`了


## 6.文件卷标加载
比如我们想要一个日志文件保存目录，如果直接写入container，那样image升级之后，日志文件处理就比较麻烦了，所以就需要将主机的文件卷标挂载到container中去，挂载方法如下：
```
$ docker run --rm=true -i -t --name=ls-volume -v /etc/:/opt/etc/ centos ls /opt/etc
boot2docker  hostname     ld.so.conf     passwd-      securetty  sysconfig
default      hosts        mke2fs.conf    pcmcia       services   sysctl.conf
fstab        hosts.allow  modprobe.conf  profile      shadow     udev
group        hosts.deny   motd           profile.d    shadow-    version
group-       init.d       mtab           protocols    shells
gshadow      inittab      netconfig      rc.d         skel
gshadow-     issue        nsswitch.conf  resolv.conf  ssl
host.conf    ld.so.cache  passwd         rpc          sudoers
```
如果想要挂载后的文件是只读，需要在这样挂载：
>-v /etc/:/opt/etc/:ro #read only

## 7.发布到docker hub上去

我们做完镜像，就需要将镜像发布到docker hub上，供服务器下载然后运行，这类似git仓库，将自己开发的东西丢到云服务器上，然后自己在其他机器或者其他开发者可以下载镜像，并且从这个镜像开始运行程序或者再进行2次制作镜像。

我们需要先登录docker帐号，执行：
 ```
$ docker login #输入你在docker官网注册的帐号和密码就可以登录了
$ docker push <用户名>/<镜像名> #将你制作的镜像提交到docker hub上
 ```
非官方不允许直接提交根目录镜像，所以必须以<用户名>/<镜像名>这样的方式提交，比如 doublespout/dev 这样



---
title: dump分析-mat.md
date: 2016-08-05 03:30:09
tags: [jvm,mat]
categories: [语言,java,jvm]
---

Widows 分析dump文件的工具太多了，而且都是傻瓜式的点点就好了。但是生产上分析dump文件的话，还是linux工具比较方便，因为生产上的dump文件一般都至少是GB级别的，这么大的文件拷贝到本机要耗费很长时间，特别是遇到生产事故的时候，时间=金钱。 更不允许我们把宝贵的拍错时间浪费到网络传输上面。
那么linux有什么好的解析dump工具呢? 如何解析 java dump的文件? 这里比较推荐IBM的eclipse的MAT工具。

<!--more-->

## 运行环境要求

- linux操作系统
- JDK8 以上

## 下载MAT的linux版本

Eclipse的MAT工具下载链接
http://www.eclipse.org/mat/downloads.php

MAT支持各种操作系统，找到Linux版本下载下来

```text
# 运行uname -m 看一下linux是 x86_64还是 x86的帮助你选择下载那个版本。
uname -m
#x86_64
wget http://eclipse.stu.edu.tw/mat/1.9.0/rcp/MemoryAnalyzer-1.9.0.20190605-linux.gtk.x86_64.zip
```

## 解压配置MAT基本参数

```text
unzip MemoryAnalyzer-1.8.0.20180604-linux.gtk.x86_64.zip
## 修改MAT的内存大小， 注意这个大小要根据你dump文件大小来的，如果dump文件是5GB那么 这里最好配>5GB 否则会报MAT内存不足的异常
## 修改MemoryAnalyzer.ini 的 -Xmx6024m 
vi MemoryAnalyzer.ini
```

## jmap dump整个堆
想了解更详细的请看这篇博文 望闻问切使用jstack和jmap剖析java进程各种疑难杂症
http://moheqionglin.com/site/blogs/24/detail.html

```text
jmap -dump:format=b,file=jmap.info PID
```

## MAT分析 dump

```text
 ./ParseHeapDump.sh jmap.info  org.eclipse.mat.api:suspects org.eclipse.mat.api:overview org.eclipse.mat.api:top_components
```

## 等待结果....

结果会生产如下三个zip文件，很小可以直接拷贝到本机

- jmap_Leak_Suspects.zip
- jmap_System_Overview.zip
- jmap_Top_Components.zip

## 查看报告结果
有两种查看报告的方法

- 直接把zip下载到本地，然后解压用浏览器查看index.html
- 把zip下载到本地， 用MAT可视化工具解析zip

## 遇到问题
Unable to initialize GTK+

遇到这个问题的话，是因为ParseHeapDump.sh
里面需要调用GTK的一些东西。解决方法：

```text
vi ParseHeapDump.sh
#注释掉 "$(dirname -- "$0")"/MemoryAnalyzer -consolelog -application org.eclipse.mat.api.parse "$@"这一行
#然后加入下面
#注意plugins/org.eclipse.equinox.launcher_1.5.0.v20180512-1130.jar要根据你自己本地的文件名做修改调整
java -Xmx4g -Xms4g \
-jar  plugins/org.eclipse.equinox.launcher_1.5.0.v20180512-1130.jar \
-consoleLog -consolelog -application org.eclipse.mat.api.parse "$@"

```

然后继续运行

```text
 ./ParseHeapDump.sh jmap.info  org.eclipse.mat.api:suspects org.eclipse.mat.api:overview org.eclipse.mat.api:top_components
```

问题解决

## MAC 如何使用 mat工具

下载加压缩以后

```text
#修改内存大小，默认1G不够用
vi mat.app/Contents/Eclipse/MemoryAnalyzer.ini
```

运行

```text
sudo  mat.app/Contents/MacOS/MemoryAnalyzer 
## 1、点击最上面的Overview的 tab
## 2、点击最先面的 Open a Head Dump 就可以选择加载dump文件了

```

原网址 

http://moheqionglin.com/site/blogs/84/detail.html
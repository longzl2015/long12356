---
title: 协议-http
date: 2016-06-04 23:22:58
categories: [web,协议]
tags: [网络,web,http]
---

[TOC]

<!--more-->

## http完整过程

1. 域名解析，定位到IP（浏览器自身DNS缓存、操作系统DNS缓存、host文件、DNS服务器）
2. TCP3次握手，建立TCP连接
3. 发起http请求
4. 服务器响应请求，浏览器获得html代码
5. 浏览器解析html，并解析html中的资源（js，图片等）
6. 浏览器进行页面渲染

## TCP3次握手

1. SYN=1 ACK=0 seq=x
2. SYN=1 ACK=1 seq=y ack=x+1
3. ACK=1 seq=x+1 ack=y+1

一次握手：客户端发送位码 SYN=1 和 seq number=XXX
二次握手：服务器有SYN得知客户端要求联机，因此server发送 SYN=1,ack number = XXX+1,ACK=1,seq number=YYY.
三次握手：客户端检测收到的 ack number 和 ACK。客户端发送ack number =YYY+1,ack=1。server确认seq和ack后建立连接。

## http7步传输过程

1. 建立TCP连接
2. 浏览器发送请求行
3. 浏览器发送请求头（以空行表示结束）
4. 服务器发送响应行（即状态行）
5. 服务器发送响应头（以空行表示结束）
6. 服务器发送响应数据
7. 关闭TCP（若请求头或响应头中有connection:KEEP-alive则不关闭TCP）

## http1.1
- http1.0：浏览器对每个请求建立一次TCP连接；
- http1.1：可以在一次连接中处理多个请求，并且多个请求可以并发进行。

## get和post
- get请求的数据附在url后面，以？为界限，由于浏览器对url长度有限制，get方式传输数据有限。  
- post请求数据位于请求体中，因此数据大小不限

## http请求报文

![http请求报文](http://7xlgbq.com1.z0.glb.clouddn.com/http1.jpg)

- 请求行，请求头，空行，请求体
- 请求行：请求方式，请求url，报文协议
- 报文头属性：Accept，Cookie，Referer，Cache-Control，Accept-Encoding

## http响应报文

![http响应报文](http://7xlgbq.com1.z0.glb.clouddn.com/http2.jpg)

- 响应行，响应头，空行，响应体
- 响应行：报文协议，状态码
- 报文头属性：Set-Cookie

## cookie和session
http是无状态协议，每个请求之间的数据无法通信。

**cookie：** 存储于客户端中
1. 以文件方式存储在硬盘的长期性cookie
2. 存储在内存中的暂时性cookie

**session：** 存储于服务器中





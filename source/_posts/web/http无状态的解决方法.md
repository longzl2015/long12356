---
title: http无状态的解决方法
date: 2019-06-12 13:22:58
tag: [cookie,session,token]
categories: [web]
---



## 简要

### cookie

指的是 浏览器永久存储的一种数据，仅仅是浏览器实现的一种数据存储功能。

### session
一种抽象概念-会话: 表示一个人和你交谈的时候， 你知道这个人是张三还是李四。

session通常需要借助cookie来实现: 
浏览器在cookie存储sessionId，而 服务器在内存中存储所有用户的sessionId。
当浏览器发送请求时会携带 cookie，服务器在处理请求时会取出cookie中的sessionId，验证 sessionId的有效性，继而判断用户的合法性。

session方式 有以下缺点:

- 服务器不好横向扩展，每个服务器需要同步所有的session信息
- 需要存储所有的session信息，占用内存

### token

#### token实现

token 是对session方式的一种改进。

服务器使用**秘钥**对**userId**进行加密计算得到一个token，并把token传给浏览器。浏览器每次请求时，会将token一起发送过来。服务器只需再使用**秘钥**对**userId**进行加密计算得到一个新的token，然后比较新旧token。如果新旧token一致，说明用户是合法的。

特点是 利用cpu计算时间 换取 session存储空间 的方法。

![img](/images/cookie_session_token/1350514-20180504123206667-444188772.png)

![img](/images/cookie_session_token/1350514-20180504123326596-1492094512.png)



#### token过期



## 详细

https://www.cnblogs.com/moyand/p/9047978.html
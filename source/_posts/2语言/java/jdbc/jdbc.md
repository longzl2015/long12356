---
title: 第一个jdbc.md
date: 2016-03-18 22:39:44
tags: [jdbc,数据库]
categories: [语言,java,jdbc]
---

[TOC]

第一个JDBC程序：

<!--more-->

## 第一个JDBC程序

### jdbc操作步骤

DriverManager -> Connection -> Statement -> ResultSet -> rs.next得到结果

### 加载驱动

> Class.forName("com.mysql.jdbc.Drvie()");

### 获取连接

> Connection conn = DriveManager.getConnection(url,user,pwd);

### 获取向数据库发sql语句的statement对象

> Statement st = conn.createStatement();

### 向数据库发送sql，获取数据库的返回结果

> ResultSet rs = st.executeQuery("select * from usertable");

### 从结果获取数据

```java
 while(rs.next){
      system.out.println("id=" + rs.getObject("id"));
      system.out.println("name=" + rs.getObject("name"));
 }
```

### 释放资源

```java
 if(rs!=null){
          try{
          rs.close();
          }catch(Exception e){
          e.SQLException();
          }
     }
     if(st!=null){
          try{
          st.close();
          }catch(Exception e){
          e.SQLException();
          }
     }
     if(conn!=null){
          try{
          conn.close();
          }catch(Exception e){
          e.SQLException();
          }
     }

```

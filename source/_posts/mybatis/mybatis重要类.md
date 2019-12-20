---
title: mybatis重要类
date: 2019-12-04 23:22:58
tags: 
  - mybatis
categories:
  - mybatis
---

## MapperRegistry

Mapper实例的注册中心。

MapperRegistry 拥有一个 knownMappers 变量，所有的 mapper 实例都会注册到 该变量中。

提供 如下方法:

- addMapper
- getMapper
- hasMapper



## MapperScan 扫描注册

该方法主要针对 maper.java 。

## MapperLocations 扫描注册

该方法主要针对 mapper.xml。代码入口为:

> SqlSessionFactoryBean.buildSqlSessionFactory()

在上述方法中，会遍历所有的 mapperLocations，解析 xml 生成Mapper实例，之后将其注册到 MapperRegistry中。
---
title: mybatis与spring整合-mapper.xml映射配置
date: 2015-09-04 23:22:58
tag: [mybatis,spring,mapper.xml映射]
categories: mybatis
---
mybatis使用***mapper.xml的配置方式
[官网地址](https://mybatis.github.io/spring/zh/getting-started.html)
[SSM框架——详细整合教程（Spring+SpringMVC+MyBatis）](http://blog.csdn.net/zhshulin/article/details/37956105)
<!--more-->

## 单独使用 mybatis

单独使用mybatis时，映射mapper.xml,有两种选择。
第一是手动在 MyBatis 的 XML 配置文件中使用 <mappers> 部分来指定类路径。
第二是使用工厂 bean 的 mapperLocations 属 性。

###  <mappers>

```xml
<!-- 加载 映射文件 -->
<mappers>
  <!-- 批量加载mapper 指定mapper接口的包名，mybatis自动扫描包下边所有mapper接口进行加载
  上边规范的前提是：使用的是mapper代理方法
  和spring整合后，使用mapper扫描器，这里不需要配置了 -->
  <package name="com.cst.zju.anime.dao" />
</mappers>
```

### mapperLocations
mapperLocations 属性使用一个资源位置的 list。
这个属性可以用来指定 MyBatis 的 XML 映射器文件的位置。
它的值可以包含 Ant 样式来加载一个目录中所有文件, 或者从基路径下递归搜索所有路径。

比如:

```xml
<bean id="sqlSessionFactory" class="org.mybatis.spring.SqlSessionFactoryBean">
  <property name="dataSource" ref="dataSource" />
  <property name="mapperLocations" value="classpath*:sample/config/mappers/**/*.xml" />
</bean>
```
这会从类路径下加载在 sample.config.mappers 包和它的子包中所有的 MyBatis 映射器 XML 文件。

note：注意点：在classpath后面的*必不可少，缺少型号的话后面的通配符不起作用。
  \**表示可以表示任意多级目录，
  \*表示多个任意字符

  缺少classpath后面的*会报以下的错误：

```
org.mybatis.spring.MyBatisSystemException: nested exception is org.apache.ibatis.exceptions.PersistenceException:
### Error querying database.  Cause: java.lang.IllegalArgumentException: Mapped Statements collection does not contain value for framework.system.dao.UserDao.getNextUserId_MySQL
### Cause: java.lang.IllegalArgumentException: Mapped Statements collection does not contain value for framework.system.dao.UserDao.getNextUserId_MySQL
	at org.mybatis.spring.MyBatisExceptionTranslator.translateExceptionIfPossible(MyBatisExceptionTranslator.java:75)
	at org.mybatis.spring.SqlSessionTemplate$SqlSessionInterceptor.invoke(SqlSessionTemplate.java:371)
	at com.sun.proxy.$Proxy18.selectOne(Unknown Source)
	at org.mybatis.spring.SqlSessionTemplate.selectOne(SqlSessionTemplate.java:163)
	at com.huaxin.framework.core.dao.impl.BaseDaoImpl.selectOne(BaseDaoImpl.java:298)
	at com.huaxin.framework.system.dao.impl.UserDaoImpl.getNextUserId(UserDaoImpl.java:41)
```

## mybatis 和 spring整合

MapperScannerConfigurer: 它将会查找类路径下的映射并自动将它们创建成 MapperFactoryBean。

要创建 MapperScannerConfigurer,可以在 Spring 的配置中添加如下代码:

```xml
<bean class="org.mybatis.spring.mapper.MapperScannerConfigurer">
  <property name="basePackage" value="org.mybatis.spring.sample.mapper" />
</bean>
```

basePackage 属性是让你为映射器接口文件设置基本的包路径。
你可以使用分号或逗号 作为分隔符设置多于一个的包路径。
每个映射器将会在指定的包路径中递归地被搜索到。

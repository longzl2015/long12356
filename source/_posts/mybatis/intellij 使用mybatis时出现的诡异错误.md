---
title: intellij idea 使用mybatis时,出现的诡异错误。
date: 2015-08-31 09:09:28
tags: [intellij, mybatis]
categories: mybatis
---

[TOC]

<!--more-->

## 一、BindingException

>org.apache.ibatis.binding.BindingException: Invalid bound statement (not found):

**原因：**

intellij 的编译器明确了要将资源文件放到resources中。

**解决方法：**

我们需要将mapper.xml放到resources的mapper文件夹中。

相应的 spring.xml 中的 "sqlSessionFactory" 配置：

```xml
   <bean id="sqlSessionFactory" class="org.mybatis.spring.SqlSessionFactoryBean">
      <property name="dataSource" ref="dataSource" />
      <property name="mapperLocations">
         <list>
            <value>classpath*:mybatis/mapper/*Mapper.xml</value>
         </list>
      </property>
   </bean>
```

## 二、No beans of '\*Mapper' type found

>Could not autowire. No beans of 'CorpDepEmpMapper' type found. [less...](about://%23inspection/SpringJavaAutowiringInspection)(Ctrl+F1)
Checks autowiring problems in a bean class.

**原因：**

Intellij会对Spring的bean做检查，如果在xml或者注解里引用了不存在的bean，它会出错误提示，但是实际上我们的bean是runtime生成的(例如iBatis的dao)，这个时候它还会提示`error。`


**解决方法：**

1、安装mybatis plugin插件.

2、在Mapper接口上添加 @Component 或者 @Repository。


```java
@Repository
public interface ApplicationMapper {
 //...
}
```

3、取消 Autowiring for Bean Class 的提示

`Settings - Editor - Inspections - Spring - Spring Core - Code - Autowiring for Bean Class - disable`


## 三、project directory src/main/java does not exist

运行mybatis Generator 时出现以下错误：

>The specified target project directory src/main/java does not exist。


**原因：**

项目工作目录设置错误。

**解决方法：**

进入 “run/debug configuration”界面

修改`configuration`选项卡里的`working directory`成当前项目的路径。


## 四、IDEA资源文件问题

>将IDEA maven项目中src源代码下的xml等资源文件编译进classes文件夹


IDEA的maven项目中，默认源代码目录下的xml等资源文件并不会在编译的时候一块打包进classes文件夹，而是直接舍弃掉。

如果使用的是Eclipse，Eclipse的src目录下的xml等资源文件在编译的时候会自动打包进输出到classes文件夹。Hibernate和Spring有时会将配置文件放置在src目录下，编译后要一块打包进classes文件夹，所以存在着需要将xml等资源文件放置在源代码目录下的需求。

**解决IDEA的这个问题有两种方式。**

第一种
是建立src/main/resources文件夹，将xml等资源文件放置到这个目录中。maven工具默认在编译的时候，会将resources文件夹中的资源文件一块打包进classes目录中。

第二种
解决方式是配置maven的pom文件配置，在pom文件中找到<build>节点，添加下列代码：


```xml
   <build>
   <resources>
   <resource>
   <directory>src/main/java</directory>
   <includes>
   <include>**/*.xml</include>
   </includes>
   </resource>
   </resources>
   </build>
```

其中`<directory>src/main/java</directory>`表明资源文件的路径，`<include>**/*.xml</include>`表明需要编译打包的文件类型是xml文件，如果有其它资源文件也需要打包，可以修改或添加通配符。




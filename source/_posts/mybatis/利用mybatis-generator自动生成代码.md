---
title: 利用mybatis-generator自动生成代码
date: 2015-09-02 13:45:09
tags: [mybatis,mybatis插件]
categories: mybatis
---

mybatis-generator有三种用法：命令行、eclipse插件、maven插件。个人觉得maven插件最方便，可以在eclipse/intellij idea等ide上可以通---
用。
<!--more-->

下面是从官网上的截图：(不过官网www.mybatis.org 最近一段时间,好象已经挂了)

![官网截图](http://7xlgbq.com1.z0.glb.clouddn.com/static/images/mybatis.png)

### 在pom.xml中添加plugin

```xml
 1 <plugin>
 2     <groupId>org.mybatis.generator</groupId>
 3     <artifactId>mybatis-generator-maven-plugin</artifactId>
 4     <version>1.3.2</version>
 5     <configuration>
 6         <configurationFile>src/main/resources/mybatis-generator/generatorConfig.xml</configurationFile>
 7         <verbose>true</verbose>
 8         <overwrite>true</overwrite>
 9     </configuration>
10     <executions>
11         <execution>
12             <id>Generate MyBatis Artifacts</id>
13             <goals>
14                 <goal>generate</goal>
15             </goals>
16         </execution>
17     </executions>
18     <dependencies>
19         <dependency>
20             <groupId>org.mybatis.generator</groupId>
21             <artifactId>mybatis-generator-core</artifactId>
22             <version>1.3.2</version>
23         </dependency>
24     </dependencies>
25 </plugin>
```

其中generatorConfig.xml的位置，大家根据实际情况自行调整

### generatorConfig.xml配置文件

```xml
 1 <?xml version="1.0" encoding="UTF-8"?>
 2 <!DOCTYPE generatorConfiguration
 3         PUBLIC "-//mybatis.org//DTD MyBatis Generator Configuration 1.0//EN"
 4         "http://mybatis.org/dtd/mybatis-generator-config_1_0.dtd">
 5
 6 <generatorConfiguration>
 7     <classPathEntry
 8             location="C:/Oracle/Middleware/wlserver_10.3/server/lib/ojdbc6.jar"/>
 9     <context id="my" targetRuntime="MyBatis3">
10         <commentGenerator>
11             <property name="suppressDate" value="false"/>
12             <property name="suppressAllComments" value="true"/>
13         </commentGenerator>
14
15         <jdbcConnection driverClass="oracle.jdbc.driver.OracleDriver"
16                         connectionURL="jdbc:oracle:thin:@172.20.16.***:1521:CARGO" userId="***"
17                         password="***"/>
18
19         <javaModelGenerator targetPackage="ctas.test.entity"
20                             targetProject="D:/yangjm/Code/CTAS/JAVAEE/CTAS2CCSP/src/main/java">
21             <property name="enableSubPackages" value="true"/>
22             <property name="trimStrings" value="true"/>
23         </javaModelGenerator>
24
25         <sqlMapGenerator targetPackage="ctas.test.entity.xml"
26                          targetProject="D:/yangjm/Code/CTAS/JAVAEE/CTAS2CCSP/src/main/java">
27             <property name="enableSubPackages" value="true"/>
28         </sqlMapGenerator>
29
30         <javaClientGenerator targetPackage="ctas.test.mapper"
31                              targetProject="D:/yangjm/Code/CTAS/JAVAEE/CTAS2CCSP/src/main/java" type="XMLMAPPER">
32             <property name="enableSubPackages" value="true"/>
33         </javaClientGenerator>
34
35         <!--<table tableName="T_FEE_AGTBILL" domainObjectName="FeeAgentBill"
36                enableCountByExample="false" enableUpdateByExample="false"
37                enableDeleteByExample="false" enableSelectByExample="false"
38                selectByExampleQueryId="false"/>-->
39
40         <table tableName="CTAS_FEE_BASE" domainObjectName="FeeBase"
41                enableCountByExample="false" enableUpdateByExample="false"
42                enableDeleteByExample="false" enableSelectByExample="false"
43                selectByExampleQueryId="false">
44             <!--<columnRenamingRule searchString="^D_"
45                                 replaceString=""/>-->
46         </table>
47
48     </context>
49 </generatorConfiguration>
```

几个要点：

1. 因为生成过程中需要连接db，所以第3行指定了驱动jar包的位置

2. 15-17行为连接字符串

3. 19-33行指定生成“entity实体类、mybatis映射xml文件、mapper接口”的具体位置

4. 40-46行为具体要生成的表，如果有多个表，复制这一段，改下表名即可

### 使用方式

mvn mybatis-generator:generate

如果是在intellij 环境，直接鼠标点击即可

![截图1](http://7xlgbq.com1.z0.glb.clouddn.com/static/images/mybatis1.jpg)

最后给出目录结构图：

![截图2](http://7xlgbq.com1.z0.glb.clouddn.com/static/images/mybatis2.jpg)

最后给一些小技巧：

1. 建表时，字段名称建议用"_"分隔多个单词，比如:AWB_NO、REC_ID...，这样生成的entity，属性名称就会变成漂亮的驼峰命名，即：awbNo、recId

2. oracle中，数值形的字段，如果指定精度，比如Number(12,2)，默认生成entity属性是BigDecimal型 ，如果不指定精度，比如:Number(9)，指默认生成的是Long型

3. oracle中的nvarchar/nvarchar2，mybatis-generator会识别成Object型，建议不要用nvarchar2，改用varchar2

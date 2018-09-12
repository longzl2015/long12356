---
title: mybatis生成器
date: 2015-09-02 13:45:09
tags: [mybatis,mybatis插件]
categories: mybatis
---

mybatis 代码生成器

<!--more-->

## 依赖

```xml
    <dependency>
      <groupId>org.mybatis.generator</groupId>
      <artifactId>mybatis-generator-core</artifactId>
      <version>1.3.2</version>
    </dependency>
    <dependency>
      <groupId>org.mybatis</groupId>
      <artifactId>mybatis</artifactId>
      <version>3.3.0</version>
    </dependency>
```

## 主类

MybatisGen.java

```java

package cn.zl;

import org.mybatis.generator.api.ShellRunner;

import java.io.File;

/**
 * 1. 使用该脚本时，须先手动删除要生成的表的 XXXXMapper.xml文件.
 * 2. 注意 generator.properties 的用户民密码是否正确
 *
 * @author zhoul
 * @since 2017-07-13-15:34
 */
public class MybatisGen {
    public static void main(String[] args) {
        String type = args[0];
        boolean isDelete = false;

        if (args.length > 1 && "true".equals(args[1])) {
            isDelete = true;
        }
        gen(type, isDelete);
    }

    public static void gen(String type, Boolean isDelete) {
        // 删除 对应的xml文件
        String sepa = File.separator;
        File xmlPath = new File("." + sepa + "src" + sepa + "main" + sepa + "resources" + sepa + "cn" + sepa + "zl" + sepa + "sqlmap");
        System.out.println(xmlPath.getAbsolutePath());
        if (xmlPath.exists() && isDelete) {
            System.out.println("开始删除xml文件");
            boolean b = deleteDir(xmlPath);
            if (!b) {
                return;
            }
        }
        String config = MybatisGen.class.getClassLoader().getResource(type + "/generatorConfig.xml").getFile();
        String[] arg = {"-configfile", config, "-overwrite"};
        ShellRunner.main(arg);
    }


    private static boolean deleteDir(File dir) {

        if (dir.isDirectory()) {
            String[] children = dir.list();
            if (children == null) {
                return true;
            }
            for (String aChildren : children) {
                boolean success = deleteDir(new File(dir, aChildren));
                if (!success) {
                    return false;
                }
            }
        }
        System.out.println("删除xml：" + dir.getName());
        return dir.delete();
    }

}
```

## 配置文件

1. generatorConfig.xml

```xml

<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE generatorConfiguration
        PUBLIC "-//mybatis.org//DTD MyBatis Generator Configuration 1.0//EN"
        "http://mybatis.org/dtd/mybatis-generator-config_1_0.dtd">

<generatorConfiguration>

    <!-- 配置该配置文件需要的属性, 自动从classpath中搜索, 使用uri可以指定绝对路径  -->
    <properties resource="MybatisConfig.properties"/>


    <!-- 指定数据库驱动程序的绝对地址  -->
    <classPathEntry location="${jdbc.path}"/>

    <!-- 用于指定生成一组对象的环境:
        - id(必选): 唯一标识

        # targetRuntime(可选): 指定生成代码的运行目标环境:
            * MyBatis3: 默认值, 包含Example类, 动态SQL, 支持自定义查询条件, 包含注解和泛型规范
            * MyBatis3Simple: 默认值, 不包含Example类, 只支持少量动态SQL
            * Ibatis2Java2: Java 2.0以上, 包含Example类
            * Ibatis2Java5: Java 5.0以上, 包含Example类
        # defaultModelType(可选): 定义如何生成实体类
            * conditional: 默认值, 生成实体类的规则为 - BLOB类、其他字段类(包括主键字段) <继承关系>
            * flat: 一张表只生成一个实体类, 包含所有字段
            * hierarchical： 生成的实体类还要多一个主键类, 规则为 - BLOB类、其他字段类(不包括主键字段)、主键类 <继承关系>
            * 自定义: 需继承org.mybatis.generator.api.IntrospectedTable
        # introspectedColumnImpl(可选)： 可以自定义拦截器, 改变默认生成列的行为, 需继承org.mybatis.generator.api.IntrospectedColumn
     -->
    <context id="MySQLTables" targetRuntime="MyBatis3" defaultModelType="conditional">

        <plugin type="org.mybatis.generator.plugins.EqualsHashCodePlugin"></plugin>
        <plugin type="org.mybatis.generator.plugins.CaseInsensitiveLikePlugin"></plugin>
        <!-- 配置 mapper 扫描位置 -->
        <plugin type="org.mybatis.generator.plugins.MapperConfigPlugin">
            <property name="fileName" value="sqlMapperConfig.xml"/>
            <property name="targetPackage" value="mybatis"/>
            <property name="targetProject" value="src/main/resources"/>
        </plugin>
        
        <plugin type="org.mybatis.generator.plugins.SerializablePlugin"></plugin>
        <plugin type="org.mybatis.generator.plugins.ToStringPlugin"></plugin>


        <!-- 不生成注释 -->
        <commentGenerator>
             <!-- true 为关闭，反人类的设计-->
            <property name="suppressAllComments" value="true"/>
            <property name="suppressDate" value="true"/>
        </commentGenerator>

        <!-- 定义jdbc连接属性 -->
        <jdbcConnection driverClass="${jdbc.driverClass}" connectionURL="${jdbc.url}" userId="${jdbc.username}"
                        password="${jdbc.password}">
        </jdbcConnection>

        <!-- 定义java到jdbc的类型转换器 -->
        <javaTypeResolver>
            <!-- 指定Decimal类型的转换方式, 如果位数不大, 直接使用对应的位数较少的java类型 , 默认false-->
            <property name="forceBigDecimals" value="false"/>
        </javaTypeResolver>

        <!-- 定义Model类型生成的包位置和工程路径, 以及Model生成的属性:
            - targetPackage(必选): 目标包路径
            - targetProject(必选): 目标工程路径
         -->
        <javaModelGenerator targetPackage="${mdb.javaModelGenerator.targetPackage}"
                            targetProject="${mdb.javaModelGenerator.targetProject}">

            <!-- 指定生成的实体类中是否需要生成含参构造函数, 默认false -->
            <property name="constructorBased" value="false"/>

            <!-- 为每个表对应的实体生成子包, 子包名默认为表名首字母小写, 默认false -->
            <property name="enableSubPackages" value="false"/>

            <!-- 指定生成的实体类是否是不变的, 即不生成setter, 强制生成含参构造函数, 默认false -->
            <property name="immutable" value="false"/>

            <!-- 指定生成实体类的公共父类, 只有主键, 记录对象和属性名、类型不相同的字段会生成, 不生成重复的字段. value需要配置公共父类的全包名 -->
            <!-- <property name="rootClass" value="com.mycompany.MyRootClass" /> -->

            <!-- 为查询出来的字符类型的字段值自动去除首尾空格, 默认false -->
            <property name="trimStrings" value="true"/>
        </javaModelGenerator>

        <!-- 定义映射文件(XML)生成的包位置和工程路径，以及映射文件生成的属性:
            - targetPackage(必选): 目标包路径
            - targetProject(必选): 目标工程路径
         -->
        <sqlMapGenerator targetPackage="${mdb.sqlMapGenerator.targetPackage}"
                         targetProject="${mdb.sqlMapGenerator.targetProject}">
            <!-- 指定生成XML文件的子包包名, 如果配置true, 则最终生成位置为targetPackage.Table表名 包下, 默认false -->
            <property name="enableSubPackages" value="true"/>
        </sqlMapGenerator>

        <!-- 定义Mapper接口生成的包位置和工程路径，以及Mapper接口生成的属性:
            - targetPackage(必选): 目标包路径
            - targetProject(必选): 目标工程路径
            - type(必选): 指定生成的Mapper类的风格:
                * ANNOTATEDMAPPER: context的targetRuntime属性为Mybatis3或Mybatis3Simple, Mapper全部使用注解, 不生成XML文件, 会生成SQLProvider
                * MIXEDMAPPER: context的targetRuntime属性为Mybatis3, Mapper使用XML和注解混合, 不生成SQLProvider
                * XMLMAPPER:　context的targetRuntime属性为Mybatis3或Mybatis3Simple, 全部使用XML

            # implementationPackage(可选): 指定生成接口的包路径(与enableSubPackages有关)
         -->
        <javaClientGenerator type="XMLMAPPER" targetPackage="${mdb.javaClientGenerator.targetPackage}"
                             targetProject="${mdb.javaClientGenerator.targetProject}">
            <!-- 不生成子包 -->
            <property name="enableSubPackages" value="false"/>

            <!-- targetRuntime为Mybatis3时忽略, 指定ByExample方法的可见性(如selectByExample)  -->
            <!-- <property name="exampleMethodVisibility" value="public"/> -->

            <!-- targetRuntime为Mybatis3时忽略, 指定方法名生成策略 -->
            <!-- <property name="methodNameCalculator" value="default" /> -->

            <!-- 指定生辰Mapper接口的父接口 -->
            <!-- <property name="rootInterface" value="com.github.abel533.mapper.Mapper"/> -->

            <!-- 已废弃SQLBuilder, 配置是否使用SQLBuilder生成动态SQL -->
            <!-- <property name="useLegacyBuilder" value="false"/> -->
        </javaClientGenerator>


        <!-- 指定了数据库表的属性:
            - tableName(必选): 数据库表的名称(不包括schema或catalog). 如果需要, 指定的值可以包含SQL通配符

            # schema(可选): 数据库的schema, 用来精确搜索表
            # catalog(可选): 数据库的catalog, 用来精确搜索表
            # alias(可选): 定义表的别名, 通常使用在select语句生成表别名和列别名中
            # domainObjectName(可选): 指定生成实体类的类名, 如果不指定, 默认根据表名生成实体类名. 例如如果该属性配置了foo.Bar, 则foo会添加到包名中, Bar会被当做实体类的类名
            # enableInsert(可选): 默认true, 指定是否生成insert
            # enableSelectByPrimaryKey(可选): 默认true, 指定是否生成根据主键查询. 如果主键不存在，则不会生成该语句
            # enableSelectByExample(可选): 默认true, 指定是否生成根据Example查询, 支持动态查询
            # enableUpdateByPrimaryKey、enableDeleteByPrimaryKey、enableDeleteByExample、enableCountByExample、enableUpdateByExample(可选): 默认true
            # selectByPrimaryKeyQueryId、selectByExampleQueryId(可选): 为每个查询添加QueryId
            # modelType(可选): 重写生成实体类的规则, 覆盖context定义的规则:
                * conditional: 默认值, 生成实体类的规则为 - BLOB类、其他字段类(包括主键字段) <继承关系>
                * flat: 一张表只生成一个实体类, 包含所有字段
                * hierarchical： 生成的实体类还要多一个主键类, 规则为 - BLOB类、其他字段类(不包括主键字段)、主键类 <继承关系>
            # escapeWildcards(可选): 是否对SQL语句中的通配符进行转义, 默认false
            # delimitIdentifiers(可选): 当tableName, Schema, Catalog中包含分隔符时, 是否使用确切的值, 默认为false. 当以上三者中包括空格等, 需要设置true
            # delimitAllColumns(可选): 为每个列名添加分隔符, 默认false
         -->
        <table schema="${jdbc.username}" tableName="pay_order" domainObjectName="PayOrder">
            <!-- 是否采用生成含参构造器的方式, 不生成setter, 默认false -->
            <property name="constructorBased" value="false"/>

            <!-- 是否在运行时忽略schema和catalog,在SQL中不添加这些到表名上, 默认false  -->
            <property name="ignoreQualifiersAtRuntime" value="false"/>

            <!-- 生成的实体类是否是不变的, 即不需要setter方法, 默认false, 覆盖constructorBased配置 -->
            <property name="immutable" value="false"/>

            <!-- 是否只生成实体类, 不生成Mapper接口和XML的Statement, 默认false -->
            <property name="modelOnly" value="false"/>

            <!-- 是否使用数据库中字段的实际名称作为实体类的字段名, false时使用驼峰规则, 默认false -->
            <property name="useActualColumnNames" value="false"/>

            <!-- 实体类的公共父类 -->
            <!-- <property name="rootClass" value="com.mycompany.MyRootClass" /> -->

            <!-- Mapper接口的公共接口 -->
            <!-- <property name="rootInterface" value="com.mycompany.MyRootInterface"/> -->

            <!-- runtimeCatalog、runtimeSchema、runtimeTableName: 指定运行时的相应属性, 用于SQL语句中 -->

            <!-- selectAllOrderByClause: 指定在selectAll查询中需要添加的Order by的属性, 仅适用于MyBatis3Simple环境-->

            <!-- useColumnIndexes: 不支持Mybatis3环境, 使用索引名来区分只有大小写不同的列, 默认false -->

            <!-- useCompoundPropertyNames: 生成实体类的属性名时会将列名和备注连在一起, 默认false-->

            <!-- 指定添加主键自增时的自动返回位置:
                - column: 指定生成列的列名
                - sqlStatement:指定对应生成语句的数据库类型, MySql为SELECT LAST_INSERT_ID()

                # identity: true则在insert之前, false则在insert之后
                # type: 指定selectKey的执行时间, pre表示在insert语句之前执行, post表示在insert语句之后执行
             -->
            <!--<generatedKey column="ID" sqlStatement="MySql" identity="true" type="post"/>-->

            <!-- 可以在生辰实体类属性名是去掉符合searchString条件的字符串，以replaceString内容来代替 -->
            <!-- <columnRenamingRule searchString="^CUST_" replaceString="" /> -->

            <!-- 配置实体类属性和数据库字段之间的映射关系:
                - column: 数据库中的列名

                # property: 实体类属性名
                # javaType: 实体类类型
                # jdbcType: 数据库字段类型
                # typeHandler: 配置类型转换处理器
                # delimitedColumnName: 定义分隔符是否需要重写或分割
             -->
            <!-- <columnOverride column="DATE_FIELD" property="startDate" /> 
            <columnOverride column="LONG_VARCHAR_FIELD" jdbcType="VARCHAR" /> -->

            <!-- 定义需要忽略的列名 -->
            <!-- <ignoreColumn column="FRED" /> -->

        </table>
        <!--<table tableName="C_ITEMS" domainObjectName="Item">-->
            <!--<generatedKey column="ID" sqlStatement="MySql" identity="true" type="post"/>-->
        <!--</table>-->

    </context>
</generatorConfiguration>

```

2. MybatisConfig.properties

```properties
#jdbc.path=E:/maven/repo/com/oracle/ojdbc14/10.2.0.4.0/ojdbc14-10.2.0.4.0.jar
jdbc.path=D:/tools/apache-maven-3.2.5/repo/mysql/mysql-connector-java/5.1.34/mysql-connector-java-5.1.34.jar

jdbc.driverClass=com.mysql.jdbc.Driver

jdbc.url=jdbc:mysql://192.168.174.128:3306/dongwanpoc?useUnicode=true&amp;characterEncoding=UTF-8
#jdbc.url=jdbc:oracle:thin:@192.168.174.128:3306:lakala-base

jdbc.username=root
jdbc.password=123456

mdb.javaModelGenerator.targetPackage=cn.zl.model
mdb.javaModelGenerator.targetProject=src/main/java
mdb.sqlMapGenerator.targetPackage=cn.zl.mapper
mdb.sqlMapGenerator.targetProject=src/main/resources
mdb.javaClientGenerator.type=XMLMAPPER
mdb.javaClientGenerator.targetPackage=cn.zl.mapper
mdb.javaClientGenerator.targetProject=src/main/java
```

## oracle 注意点

1. 类型对照表

Mybatis生成java文件时，数据库表字段类型与java类型对照表

| NUMBER 长度 | JAVA 类型  |
| ----------- | ---------- |
| 1-4         | short      |
| 5-9         | integer    |
| 10-18       | long       |
| 18+         | bigDecimal |

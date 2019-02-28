---

title: dependency scope作用域

date: 2018-08-29 16:09:00

categories: [maven]

tags: [maven,scope]

---



Dependency scope通常被用于限制一个依赖的传递性，同时影响 the classpath used for various build tasks

<!--more-->

Scope 有以下六种:

## compile

默认的**scope**，表示 dependency 都可以在生命周期中使用。而且，这些dependencies 会传递到依赖的项目中。

##provided

跟compile相似，表示依赖由jdk或者容器提供。如: 当构建java web项目时，我们需要将 Servlet API和 Java EE APIs设置为 provided，因为tomcat会提供这些依赖jar。provided 只在 编译和测试环境生效，同时不具备传递性。

##runtime

runtime，表示被依赖项目不会参与整个项目的编译，但项目的测试期和运行时期会参与。与compile相比，跳过了编译这个环节。

- 编译: 对代码做一些简单的语法检测和翻译工作
- 运行: 将代码跑起来


##test
仅在测试环境生效。不具备传递性。

This scope indicates that the dependency is not required for normal use of the application, and is only available for the test compilation and execution phases. This scope is not transitive.

##system
跟provided 相似，但是**在系统中要以外部JAR包的形式提供**，maven不会在repository查找它。 例如：



##import (only available in Maven 2.0.9 or later)
仅作用在 `<dependencyManagement> `中，且仅用于`type=pom`的dependency。

主要作用: 解决pom单继承的问题。

 It indicates the dependency to be replaced with the effective list of dependencies in the specified POM's <dependencyManagement> section. Since they are replaced, dependencies with a scope of import do not actually participate in limiting the transitivity of a dependency.

以下为 import 实例

```xml
<dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>com.alibaba</groupId>
                <artifactId>dubbo-dependencies-bom</artifactId>
                <version>2.6.1</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
        </dependencies>
</dependencyManagement>
```

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
 
    <parent>
        <groupId>org.sonatype.oss</groupId>
        <artifactId>oss-parent</artifactId>
        <version>7</version>
        <relativePath />
    </parent>
 
    <groupId>com.alibaba</groupId>
    <artifactId>dubbo-dependencies-bom</artifactId>
    <version>2.6.1</version>
    <packaging>pom</packaging>
 
    <name>dubbo-dependencies-bom</name>
    <description>Dubbo dependencies BOM</description>
    <url>http://dubbo.io</url>
 
    <inceptionYear>2011</inceptionYear>
    <licenses>
        <license>
            <name>Apache 2</name>
            <url>http://www.apache.org/licenses/LICENSE-2.0.txt</url>
        </license>
    </licenses>
 
    <organization>
        <name>The Dubbo Project</name>
        <url>http://dubbo.io</url>
    </organization>
 
    <issueManagement>
        <system>Github Issues</system>
        <url>https://github.com/alibaba/dubbo/issues</url>
    </issueManagement>
    <scm>
        <url>https://github.com/alibaba/dubbo/tree/master</url>
        <connection>scm:git:git://github.com/alibaba/dubbo.git</connection>
        <developerConnection>scm:git:git@github.com:alibaba/dubbo.git</developerConnection>
    </scm>
    <mailingLists>
        <mailingList>
            <name>Dubbo User Mailling List</name>
            <subscribe>dubbo+subscribe@googlegroups.com</subscribe>
            <unsubscribe>dubbo+unsubscribe@googlegroups.com</unsubscribe>
            <post>dubbo@googlegroups.com</post>
            <archive>http://groups.google.com/group/dubbo</archive>
        </mailingList>
        <mailingList>
            <name>Dubbo Developer Mailling List</name>
            <subscribe>dubbo-developers+subscribe@googlegroups.com</subscribe>
            <unsubscribe>dubbo-developers+unsubscribe@googlegroups.com</unsubscribe>
            <post>dubbo-developers@googlegroups.com</post>
            <archive>http://groups.google.com/group/dubbo-developers</archive>
        </mailingList>
    </mailingLists>
    <developers>
        <developer>
            <id>dubbo.io</id>
            <name>The Dubbo Project Contributors</name>
            <email>dubbo@googlegroups.com</email>
            <url>http://dubbo.io</url>
            <organization>The Dubbo Project</organization>
            <organizationUrl>http://dubbo.io</organizationUrl>
        </developer>
    </developers>
 
    <properties>
        <!-- Common libs -->
        <spring_version>4.3.10.RELEASE</spring_version>
        <javassist_version>3.20.0-GA</javassist_version>
        <netty_version>3.2.5.Final</netty_version>
        <netty4_version>4.0.35.Final</netty4_version>
        ....
    </properties>
 
    <dependencyManagement>
        <dependencies>
            <!-- Common libs -->
            <dependency>
                <groupId>org.springframework</groupId>
                <artifactId>spring-framework-bom</artifactId>
                <version>${spring_version}</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
            <dependency>
                <groupId>org.javassist</groupId>
                <artifactId>javassist</artifactId>
                <version>${javassist_version}</version>
            </dependency>
            <dependency>
                <groupId>org.jboss.netty</groupId>
                <artifactId>netty</artifactId>
                <version>${netty_version}</version>
            </dependency>
       ....
    </dependencyManagement>
 
</project>
```


[import scope 解决单继承问题](https://www.cnblogs.com/huahua035/p/7680607.html)
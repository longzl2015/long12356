---

title: dependency scope作用域

date: 2018-08-29 16:09:00

categories: [maven]

tags: [maven,scope]

---





<!--more-->


Dependency scope is used to limit the transitivity of a dependency, and also to affect the classpath used for various build tasks.

There are 6 scopes available:

## compile

This is the default scope, used if none is specified. Compile dependencies are available in all classpaths of a project. Furthermore, those dependencies are propagated to dependent projects.

##provided

This is much like compile, but indicates you expect the JDK or a container to provide the dependency at runtime. For example, when building a web application for the Java Enterprise Edition, you would set the dependency on the Servlet API and related Java EE APIs to scope provided because the web container provides those classes. This scope is only available on the compilation and test classpath, and is not transitive.

##runtime

This scope indicates that the dependency is not required for compilation, but is for execution. It is in the runtime and test classpaths, but not the compile classpath.

运行域，表示被依赖项目不会参与项目的编译，但项目的测试期和运行时期会参与。与compile相比，跳过了编译这个环节。


##test
This scope indicates that the dependency is not required for normal use of the application, and is only available for the test compilation and execution phases. This scope is not transitive.

##system
This scope is similar to provided except that you have to provide the JAR which contains it explicitly. The artifact is always available and is not looked up in a repository.

##import (only available in Maven 2.0.9 or later)
This scope is only supported on a dependency of type pom in the <dependencyManagement> section. It indicates the dependency to be replaced with the effective list of dependencies in the specified POM's <dependencyManagement> section. Since they are replaced, dependencies with a scope of import do not actually participate in limiting the transitivity of a dependency.

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
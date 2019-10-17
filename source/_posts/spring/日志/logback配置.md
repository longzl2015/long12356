---

title: logback配置

date: 2018-08-21 11:40:00

categories: [log]

tags: [spring,logback]

---


spring boot日志 : logback配置


<!--more-->



## 根节点< configuration >

- scan:当此属性设置为true时，配置文件如果发生改变，将会被重新加载，默认值为true。
- scanPeriod:设置监测配置文件是否有修改的时间间隔，如果没有给出时间单位，默认单位是毫秒。当scan为true时，此属性生效。默认的时间间隔为1分钟。
- debug:当此属性设置为true时，将打印出logback内部日志信息，实时查看logback运行状态。默认值为false。

## 两个属性 contextName 和 property 

### contextName

每个logger都关联到logger上下文，默认上下文名称为“default”。但可以使用< contextName >设置成其他名字，用于区分不同应用程序的记录。一旦设置，不能修改,可以通过%contextName来打印日志上下文名称。 

```xml
<contextName>logback</contextName> 
```

### property

用来定义变量值的标签，< property > 有两个属性，name和value；其中name的值是变量的名称，value的值时变量定义的值。通过< property >定义的值会被插入到logger上下文中。定义变量后，可以使“${}”来使用变量。

```xml
<property name="log.path" value="./logs" />
```

### 子节点一 appender 

appender用来格式化日志输出节点，有俩个属性name和class，class用来指定哪种输出策略，常用就是控制台输出策略和文件输出策略。

#### 控制台输出ConsoleAppender 

```xml
<!--输出到控制台-->
    <appender name="console" class="ch.qos.logback.core.ConsoleAppender">
        <!--过滤掉ERROR级别以下的日志-->
        <filter class="ch.qos.logback.classis.filter.ThresholdFilter" >
            <level>ERROR</level>
        </filter>
        <!--格式化输出：%d表示日期，%thread表示线程名，%-5level：级别从左显示5个字符宽度%msg：日志消息，%n是换行符-->
        <encoder>
            <pattern>%d{HH:mm:ss.SSS} %-5level [%thread] %logger{36} - %msg%n</pattern>
        </encoder>
    </appender>
```

    %d{HH: mm:ss.SSS}——日志输出时间
    %thread——输出日志的进程名字，这在Web应用以及异步任务处理中很有用
    %logger{36}——日志输出者的名字
    %msg——日志消息
    %n——平台的换行符

#### 输出到文件RollingFileAppender

```xml
<appender name="out2File" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <!--日志文件输出的文件名-->
        <file>${LOG_HOME_SERVICE}.log</file>
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <!--归并日志文件输出的文件名-->
            <fileNamePattern>${LOG_HOME_SERVICE}-%d{yyyy-MM-dd}.%i.log</fileNamePattern>
            <!--日志文件保留天数-->
            <MaxHistory>30</MaxHistory>
            <!--文件最大1G-->
            <totalSizeCap>1GB</totalSizeCap>
            <!--归并日志文件最大大小-->
            <TimeBasedFileNamingAndTriggeringPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedFNATP">
                <MaxFileSize>100MB</MaxFileSize>
            </TimeBasedFileNamingAndTriggeringPolicy>
        </rollingPolicy>
        <encoder>
            <pattern>%d{HH:mm:ss.SSS} %-5level [%thread] %logger{36} - %msg%n</pattern>
        </encoder>
        <!--日志文件最大的大小-->
        <triggeringPolicy class="ch.qos.logback.core.rolling.SizeBasedTriggeringPolicy">
            <MaxFileSize>10MB</MaxFileSize>
        </triggeringPolicy>
    </appender>
```


### 子节点二 < root>

root节点是必选节点，用来指定最基础的日志输出级别，只有一个level属性。 
level:用来设置打印级别，大小写无关：TRACE, DEBUG, INFO, WARN, ERROR, ALL 和 OFF，不能设置为INHERITED或者同义词NULL，默认是DEBUG。 


```xml
    <root level="INFO">
        <!-- 生产环境将请stdout去掉 -->
        <appender-ref ref="stdout"/>
        <appender-ref ref="LOG"/>
    </root>
```

### 子节点三< logger >

<logger>用来设置某一个包或者具体的某一个类的日志打印级别、以及指定<appender>。<logger>仅有一个name属性，一个可选的level和一个可选的addtivity属性。

    name:用来指定受此loger约束的某一个包或者具体的某一个类。 l
    evel:用来设置打印级别，大小写无关：TRACE, DEBUG, INFO, WARN, ERROR, ALL和OFF，还有一个特俗值INHERITED或者同义词NULL，代表强制执行上级的级别。如果未设置此属性，那么当前loger将会继承上级的级别。
    addtivity:是否向上级logger传递打印信息。默认是true。

```xml
<logger name="java.sql.Statement" additivity="true" level="DEBUG">
   <appender-ref ref="stdout"></appender-ref>
</logger>
```

### 多环境配置

```xml
<!--生产环境:打印控制台和输出到文件-->
    <springProfile name="prod">
        <root level="info">
            <appender-ref ref="CONSOLE"/>
            <appender-ref ref="asyncFileAppender"/>
        </root>
    </springProfile>

    <!--开发环境:打印控制台-->
    <springProfile name="dev">
        <root level="info">
            <appender-ref ref="CONSOLE"/>
        </root>
    </springProfile>

    <!--测试环境:打印控制台-->
    <springProfile name="test">
        <!-- 打印sql -->
        <logger name="com.yunchuang.dao" level="DEBUG"/>
        <root level="info">
            <appender-ref ref="CONSOLE"/>
        </root>
    </springProfile>

```


## 样例
```xml

<?xml version="1.0" encoding="UTF-8"?>
<configuration>

    <property name="LOG_PATH" value="./log"/>
   
    <appender name="stdout" class="ch.qos.logback.core.ConsoleAppender">
        <Target>System.out</Target>
        <encoder>
            <pattern>%-5p [%d] %C{5}:%L - %m %n</pattern>
            <charset>utf-8</charset>
        </encoder>
    </appender>

    <appender name="LOG"
              class="ch.qos.logback.core.rolling.RollingFileAppender">
        <File>${LOG_PATH}/${LOG_FILE}</File>
        <encoder>
            <pattern>%-5p [%d] %C{5}:%L - %m %n</pattern>
            <charset>utf-8</charset>
        </encoder>
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <fileNamePattern>${LOG_PATH}/${LOG_FILE}.%d{yyyy-MM-dd}</fileNamePattern>
            <maxHistory>1</maxHistory>
        </rollingPolicy>
    </appender>
    
    <root level="INFO">
        <appender-ref ref="stdout"/>
        <appender-ref ref="LOG"/>
    </root>
</configuration>

```
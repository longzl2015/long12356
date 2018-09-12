---

title: mybatis拦截器(原)

date: 2018-09-12 17:28:00

categories: [mybatis]

tags: [mybatis,sql,interceptor]

---

mybatis 提供了一种插件机制，其实就是一个拦截器，用于拦截 mybatis。

使用拦截器可以实现很多功能，比如: 记录执行错误的sql信息

<!--more-->

添加一个拦截器非常简单:
- 实现 Interceptor 接口，
- 将拦截器注册到配置文件的<plugins>即可

## 拦截器接口

```java
/**
 * @author Clinton Begin
 */
public interface Interceptor {

  Object intercept(Invocation invocation) throws Throwable;

  Object plugin(Object target);

  void setProperties(Properties properties);

}

```

## 简单样例

该样例拦截 Executor 接口的 update 方法。

```java
@Intercepts({@Signature(
  type= Executor.class,
  method = "update",
  args = {MappedStatement.class,Object.class})})
public class ExamplePlugin implements Interceptor {
  public Object intercept(Invocation invocation) throws Throwable {
      //可以再该处进行拦截处理。
    return invocation.proceed();
  }
  public Object plugin(Object target) {
    return Plugin.wrap(target, this);
  }
  public void setProperties(Properties properties) {
  }
}
```

```xml
<plugins>
    <plugin interceptor="org.format.mybatis.cache.interceptor.ExamplePlugin"></plugin>
</plugins>
```

## 源码分析

### 将 注册的插件加入 InterceptorChain

先从 XMLConfigBuilder 解析 xml 配置文件开始。

```java
public class XMLConfigBuilder extends BaseBuilder { 
    //...
  
  // 解析 xml 的 plugins 配置
  private void pluginElement(XNode parent) throws Exception {
    if (parent != null) {
      for (XNode child : parent.getChildren()) {
        String interceptor = child.getStringAttribute("interceptor");
        Properties properties = child.getChildrenAsProperties();
        //通过反射实例化 interceptor
        Interceptor interceptorInstance = (Interceptor) resolveClass(interceptor).newInstance();
        //调用接口的 setProperties() 设置 拦截器需要的变量。
        interceptorInstance.setProperties(properties);
        // 将拦截器加入全局配置类Configuration.interceptorChain中
        // InterceptorChain 就是一个连接器链
        configuration.addInterceptor(interceptorInstance);
      }
    }
  } 
  
  //...
}
```

拦截器链具体代码如下

```java
public class InterceptorChain {

  private final List<Interceptor> interceptors = new ArrayList<Interceptor>();

  public Object pluginAll(Object target) {
    for (Interceptor interceptor : interceptors) {
      target = interceptor.plugin(target);
    }
    return target;
  }

  public void addInterceptor(Interceptor interceptor) {
    interceptors.add(interceptor);
  }

  public List<Interceptor> getInterceptors() {
    return Collections.unmodifiableList(interceptors);
  }

}
```


## 应用实例一、执行错误时日志输出sql

```java
package cn.zl.util;

import org.apache.ibatis.executor.Executor;
import org.apache.ibatis.executor.statement.StatementHandler;
import org.apache.ibatis.mapping.BoundSql;
import org.apache.ibatis.mapping.MappedStatement;
import org.apache.ibatis.mapping.ParameterMapping;
import org.apache.ibatis.plugin.*;
import org.apache.ibatis.reflection.MetaObject;
import org.apache.ibatis.session.Configuration;
import org.apache.ibatis.session.ResultHandler;
import org.apache.ibatis.session.RowBounds;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Map;
import java.util.Properties;


@Intercepts({
        @Signature(type = Executor.class, method = "update", args = {MappedStatement.class, Object.class}),
        @Signature(type = Executor.class, method = "query", args = {MappedStatement.class, Object.class, RowBounds
                .class, ResultHandler.class})})
public class SQLInterceptor implements Interceptor {
    private Logger logger = LoggerFactory.getLogger(SQLInterceptor.class);

    @Override
    public Object intercept(Invocation invocation) throws Throwable {

        long startTime = System.currentTimeMillis();
        Object proceed;

        try {
            proceed = invocation.proceed();
        } catch (Exception e) {

            String formatSql = getSql(invocation);
            logger.error("sql: {}", formatSql);
            throw e;
        }

        if (this.logger.isDebugEnabled()) {
            long endTime = System.currentTimeMillis();
            String formatSql = getSql(invocation);
            long cost = endTime - startTime;
            //if (cost > 100) {
            logger.debug("sql: {}, cost: {}ms", formatSql, cost);
            //}
        }
        return proceed;
    }


    @Override
    public Object plugin(Object o) {
        return Plugin.wrap(o, this);
    }

    @Override
    public void setProperties(Properties properties) {

    }


    private String getSql(Invocation invocation) {
        MappedStatement mappedStatement = (MappedStatement) invocation.getArgs()[0];
        Object parameter = null;
        if (invocation.getArgs().length > 1) {
            parameter = invocation.getArgs()[1];
        }
        BoundSql boundSql = mappedStatement.getBoundSql(parameter);
        Configuration configuration = mappedStatement.getConfiguration();
        return formatSql(configuration, boundSql);
    }

    private String formatSql(Configuration configuration, BoundSql boundSql) {
        String sql = boundSql.getSql();
        if (sql == null || sql.length() == 0) {
            return "";
        }
        sql = beautifySql(sql);

        // 定义一个没有替换过占位符的sql，用于出异常时返回
        String sqlWithoutReplacePlaceholder = sql;
        try {
            sql = handleCommonParameter(boundSql, sql, configuration);
        } catch (Exception e) {
            logger.error(e.getMessage(), e);
            return sqlWithoutReplacePlaceholder;
        }

        return sql;
    }

    /**
     * 美化Sql
     */
    private String beautifySql(String sql) {
        sql = sql.replaceAll("[\\s\n ]+", " ");
        return sql;
    }


    /**
     * 处理通用的场景
     */
    private String handleCommonParameter(BoundSql boundSql, String sql, Configuration configuration) {
        Object parameterObject = boundSql.getParameterObject();
        for (ParameterMapping parameterMapping : boundSql.getParameterMappings()) {
            Object propertyValue;
            String propertyName = parameterMapping.getProperty();
            if (boundSql.hasAdditionalParameter(propertyName)) {
                propertyValue = boundSql.getAdditionalParameter(propertyName);
            } else if (parameterObject == null) {
                propertyValue = null;
            } else if (configuration.getTypeHandlerRegistry().hasTypeHandler(parameterObject.getClass())) {
                propertyValue = parameterObject;
            } else {
                MetaObject metaObject = configuration.newMetaObject(parameterObject);
                propertyValue = metaObject.getValue(propertyName);
            }
            if (propertyValue != null) {
                String temp;
                StringBuilder builder = new StringBuilder();
                if (propertyValue instanceof String) {
                    builder.append("\"")
                            .append(propertyValue.toString())
                            .append("\"");
                    temp = builder.toString().replace("[\\n\\r]","  ");
                } else {
                    temp = propertyValue.toString();
                }


                sql = sql.replaceFirst("\\?", temp);
            }
        }

        return sql;
    }

}

```

## 来源

https://www.cnblogs.com/fangjian0423/p/mybatis-interceptor.html
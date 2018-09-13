---

title: mybatis拦截器2

date: 2018-09-12 17:28:00

categories: [mybatis]

tags: [mybatis,sql,interceptor]

---

上一章讲了 mybatis 如何通过代理实现插件功能。本章则讲述插件运行的前后逻辑。

<!--more-->


## 简单介绍四大对象
Mybatis 中 有四类对象 Executor，ParameterHandler，ResultSetHandler，StatementHandler。

- Executor : DefaultSqlSession 是通过 Executor 完成查询的，而 Executor 是依赖 StatementHandler 完成与数据库的交互的。
- StatementHandler : 与数据库对话，会使用 parameterHandler 和 ResultHandler 对象为我们绑定SQL参数和组装最后的结果返回
- ParameterHandler : ParameterHandler 用于处理 sql 的参数，实际作用相当于对sql中所有的参数都执行 preparedStatement.setXXX(value);
- ResultSetHandler : 处理Statement执行后产生的结果集，生成结果列表

## 源码分析

### xml注册插件

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

  //遍历执行每个plugin
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

### 四大对象调用插件

```java
public class Configuration {
  //..
  
  // 初始化 StatementHandler 时调用 newParameterHandler()
  public ParameterHandler newParameterHandler(MappedStatement mappedStatement, Object parameterObject, BoundSql boundSql) {
    ParameterHandler parameterHandler = mappedStatement.getLang().createParameterHandler(mappedStatement, parameterObject, boundSql);
    parameterHandler = (ParameterHandler) interceptorChain.pluginAll(parameterHandler);
    return parameterHandler;
  }

  // 初始化 StatementHandler 时调用 newResultSetHandler()
  public ResultSetHandler newResultSetHandler(Executor executor, MappedStatement mappedStatement, RowBounds rowBounds, ParameterHandler parameterHandler,
      ResultHandler resultHandler, BoundSql boundSql) {
    ResultSetHandler resultSetHandler = new DefaultResultSetHandler(executor, mappedStatement, parameterHandler, resultHandler, boundSql, rowBounds);
    resultSetHandler = (ResultSetHandler) interceptorChain.pluginAll(resultSetHandler);
    return resultSetHandler;
  }

  // Executor 执行请求时调用
  public StatementHandler newStatementHandler(Executor executor, MappedStatement mappedStatement, Object parameterObject, RowBounds rowBounds, ResultHandler resultHandler, BoundSql boundSql) {
    StatementHandler statementHandler = new RoutingStatementHandler(executor, mappedStatement, parameterObject, rowBounds, resultHandler, boundSql);
    statementHandler = (StatementHandler) interceptorChain.pluginAll(statementHandler);
    return statementHandler;
  }


  public Executor newExecutor(Transaction transaction) {
    return newExecutor(transaction, defaultExecutorType);
  }

  // SqlSessionFactory openSession 时调用 
  public Executor newExecutor(Transaction transaction, ExecutorType executorType) {
    executorType = executorType == null ? defaultExecutorType : executorType;
    executorType = executorType == null ? ExecutorType.SIMPLE : executorType;
    Executor executor;
    if (ExecutorType.BATCH == executorType) {
      executor = new BatchExecutor(this, transaction);
    } else if (ExecutorType.REUSE == executorType) {
      executor = new ReuseExecutor(this, transaction);
    } else {
      executor = new SimpleExecutor(this, transaction);
    }
    if (cacheEnabled) {
      executor = new CachingExecutor(executor);
    }
    executor = (Executor) interceptorChain.pluginAll(executor);
    return executor;
  }
  //...
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
https://blog.csdn.net/qq924862077/article/details/53197778
[ResultSetHandler](https://blog.csdn.net/ashan_li/article/details/50379458)
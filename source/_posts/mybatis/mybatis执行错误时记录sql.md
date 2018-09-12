---

title: mybatis执行错误时记录sql

date: 2018-09-12 17:28:00

categories: [mybatis]

tags: [mybatis,sql]

---



记录执行错误的sql信息

<!--more-->



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

    @SuppressWarnings("unchecked")
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
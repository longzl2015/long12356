---
title: mybatis-00-重要的几个类
date: 2018-09-03 10:00:01
tag: ["mybatis"]
categories: mybatis
---

重要的几个类

<!--more-->

## SqlSessionFactory 接口

```java
public interface SqlSessionFactory {
  SqlSession openSession();
  SqlSession openSession(boolean autoCommit);
  SqlSession openSession(Connection connection);
  SqlSession openSession(TransactionIsolationLevel level);
  SqlSession openSession(ExecutorType execType);
  SqlSession openSession(ExecutorType execType, boolean autoCommit);
  SqlSession openSession(ExecutorType execType, TransactionIsolationLevel level);
  SqlSession openSession(ExecutorType execType, Connection connection);
  Configuration getConfiguration();
}
```

### 获取 SqlSessionFactory 流程

![WX20200121-161759](/images/mybatis-00-重要的几个类/WX20200121-161759.png)

### SqlSessionFactoryBean

用于设置 mybatis 的各种配置信息，然后将这些配置信息 全部组装到 Configuration 类中。

主要的配置信息如下

```java
// mapper.xml 文件位置
private Resource[] mapperLocations;
//数据源
private DataSource dataSource;
//事务工厂
private TransactionFactory transactionFactory;
// 拦截器 
private Interceptor[] plugins;

private Resource configLocation;
private Configuration configuration;
private Properties configurationProperties;
private String environment = SqlSessionFactoryBean.class.getSimpleName();
private boolean failFast;
private TypeHandler<?>[] typeHandlers;
private String typeHandlersPackage;
private Class<?>[] typeAliases;
private String typeAliasesPackage;
private Class<?> typeAliasesSuperType;
private DatabaseIdProvider databaseIdProvider;
private Class<? extends VFS> vfs;
private Cache cache;
private ObjectFactory objectFactory;
private ObjectWrapperFactory objectWrapperFactory;
```

### SqlSessionFactoryBuilder

构建 SqlSessionFactory

### DefaultSqlSessionFactory

默认的 SqlSessionFactory 实现类。


## SqlSession 接口

```java
public interface SqlSession extends Closeable {
  <T> T selectOne(String statement);
  <T> T selectOne(String statement, Object parameter);
  <E> List<E> selectList(String statement);
  <E> List<E> selectList(String statement, Object parameter);
  <E> List<E> selectList(String statement, Object parameter, RowBounds rowBounds);
  <K, V> Map<K, V> selectMap(String statement, String mapKey);
  <K, V> Map<K, V> selectMap(String statement, Object parameter, String mapKey);
  <K, V> Map<K, V> selectMap(String statement, Object parameter, String mapKey, RowBounds rowBounds);
  <T> Cursor<T> selectCursor(String statement);
  <T> Cursor<T> selectCursor(String statement, Object parameter);
  <T> Cursor<T> selectCursor(String statement, Object parameter, RowBounds rowBounds);
  void select(String statement, Object parameter, ResultHandler handler);
  void select(String statement, ResultHandler handler);
  void select(String statement, Object parameter, RowBounds rowBounds, ResultHandler handler);
  int insert(String statement);
  int insert(String statement, Object parameter);
  int update(String statement);
  int update(String statement, Object parameter);
  int delete(String statement);
  int delete(String statement, Object parameter);
  void commit();
  void commit(boolean force);
  void rollback();
  void rollback(boolean force);
  List<BatchResult> flushStatements();
  void close();
  void clearCache();
  Configuration getConfiguration();
  <T> T getMapper(Class<T> type);
  Connection getConnection();
}
```

### 获取 SqlSession 流程

上午 已经得到 DefaultSqlSessionFactory 类的实例了，我们可以直接通过 DefaultSqlSessionFactory对象 获取 SqlSession 对象。

```java
public class DefaultSqlSessionFactory implements SqlSessionFactory {

  @Override
  public SqlSession openSession() {
    return openSessionFromDataSource(configuration.getDefaultExecutorType(), null, false);
  }

  private SqlSession openSessionFromDataSource(ExecutorType execType, TransactionIsolationLevel level, boolean autoCommit) {
    Transaction tx = null;
    try {
      final Environment environment = configuration.getEnvironment();
      final TransactionFactory transactionFactory = getTransactionFactoryFromEnvironment(environment);
      tx = transactionFactory.newTransaction(environment.getDataSource(), level, autoCommit);
      final Executor executor = configuration.newExecutor(tx, execType);
      return new DefaultSqlSession(configuration, executor, autoCommit);
    } catch (Exception e) {
      closeTransaction(tx); // may have fetched a connection so lets call close()
      throw ExceptionFactory.wrapException("Error opening session.  Cause: " + e, e);
    } finally {
      ErrorContext.instance().reset();
    }
  }

  private TransactionFactory getTransactionFactoryFromEnvironment(Environment environment) {
    if (environment == null || environment.getTransactionFactory() == null) {
      return new ManagedTransactionFactory();
    }
    return environment.getTransactionFactory();
  }

  private void closeTransaction(Transaction tx) {
    if (tx != null) {
      try {
        tx.close();
      } catch (SQLException ignore) {
        // Intentionally ignore. Prefer previous error.
      }
    }
  }
}
```

## 获取mapper流程

![img](/images/mybatis-00-重要的几个类/041116257808987.png)

### MapperRegistry

Mapper的注册中心

```java
public class MapperRegistry {

  private final Configuration config;
  private final Map<Class<?>, MapperProxyFactory<?>> knownMappers = new HashMap<Class<?>, MapperProxyFactory<?>>();

  public MapperRegistry(Configuration config) {
    this.config = config;
  }

  @SuppressWarnings("unchecked")
  public <T> T getMapper(Class<T> type, SqlSession sqlSession) {
    final MapperProxyFactory<T> mapperProxyFactory = (MapperProxyFactory<T>) knownMappers.get(type);
    if (mapperProxyFactory == null) {
      throw new BindingException("Type " + type + " is not known to the MapperRegistry.");
    }
    try {
      return mapperProxyFactory.newInstance(sqlSession);
    } catch (Exception e) {
      throw new BindingException("Error getting mapper instance. Cause: " + e, e);
    }
  }
 
  public <T> void addMapper(Class<T> type) {
    if (type.isInterface()) {
      if (hasMapper(type)) {
        throw new BindingException("Type " + type + " is already known to the MapperRegistry.");
      }
      boolean loadCompleted = false;
      try {
        knownMappers.put(type, new MapperProxyFactory<T>(type));
        // It's important that the type is added before the parser is run
        // otherwise the binding may automatically be attempted by the
        // mapper parser. If the type is already known, it won't try.
        MapperAnnotationBuilder parser = new MapperAnnotationBuilder(config, type);
        parser.parse();
        loadCompleted = true;
      } finally {
        if (!loadCompleted) {
          knownMappers.remove(type);
        }
      }
    }
  }
}
```



## SqlSessionTemplate

SqlSessionTemplate 是 MyBatis-Spring 的核心。作为 SqlSession 的一个实现，这意味着可以使用它无缝代替你代码中已经在使用的 SqlSession。SqlSessionTemplate 是线程安全的，可以被多个 DAO 或映射器所共享使用


## 参考 

[深入浅出Mybatis系列（十）---SQL执行流程分析（源码篇）](https://www.cnblogs.com/dongying/p/4142476.html)
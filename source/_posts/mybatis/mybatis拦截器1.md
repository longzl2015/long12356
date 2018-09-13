---

title: mybatis拦截器1

date: 2018-09-11 17:28:00

categories: [mybatis]

tags: [mybatis,sql,interceptor]

---

mybatis 提供了一种插件机制，其实就是一个拦截器，用于拦截 mybatis。

使用拦截器可以实现很多功能，比如: 记录执行错误的sql信息

本章简单讲解下 plugin 的运行机制

<!--more-->

## 简单使用 

添加一个拦截器非常简单:

- 实现 Interceptor 接口，
- 将拦截器注册到配置文件的`<plugins>`即可

该样例拦截 Executor 接口的 update 方法。

```java
@Intercepts({@Signature(
  type= Executor.class,
  method = "update",
  args = {MappedStatement.class,Object.class})})
public class ExamplePlugin implements Interceptor {
  public Object intercept(Invocation invocation) throws Throwable {
      //可以再该处进行拦截处理。
      //do something 
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

### 拦截器接口

```java
/**
 * @author Clinton Begin
 */
public interface Interceptor {

  // 实际处理在这里做
  Object intercept(Invocation invocation) throws Throwable;

  // 一般 使用 `return Plugin.wrap(o, this);`即可
  Object plugin(Object target);

  //获取 xml 中配置的参数
  void setProperties(Properties properties);

}

```

### Plugin类

为了方便生成代理对象和绑定方法，MyBATIS为我们提供了一个 Plugin 类。


```java

```

## 来源

https://www.cnblogs.com/fangjian0423/p/mybatis-interceptor.html
https://blog.csdn.net/qq924862077/article/details/53197778
[ResultSetHandler](https://blog.csdn.net/ashan_li/article/details/50379458)
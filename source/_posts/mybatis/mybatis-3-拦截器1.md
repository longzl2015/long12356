---

title: mybatis-3-拦截器1

date: 2018-09-03 10:00:04

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

## 四大对象

Mybatis 中 有四类对象 Executor，ParameterHandler，ResultSetHandler，StatementHandler。

- Executor : DefaultSqlSession 是通过 Executor 完成查询的，而 Executor 是依赖 StatementHandler 完成与数据库的交互的。
- StatementHandler : 与数据库对话，会使用 parameterHandler 和 ResultHandler 对象为我们绑定SQL参数和组装最后的结果返回
- ParameterHandler : ParameterHandler 用于处理 sql 的参数，实际作用相当于对sql中所有的参数都执行 preparedStatement.setXXX(value);
- ResultSetHandler : 处理Statement执行后产生的结果集，生成结果列表

## 插件需要的相关注解

### Intercepts

Intercepts 注解 表示该类为mybatis拦截器。该注解只有一个属性 

> Signature[] value();

表示 拦截其需要拦截的 类 和 方法。

### Signature

Signature 注解。通过该注解可以确定拦截 具体哪一个类的哪个方法。

```java
@Documented
@Retention(RetentionPolicy.RUNTIME)
@Target({})
public @interface Signature {
    // 可选参数 Executor，ParameterHandler，ResultSetHandler，StatementHandler
    Class<?> type();
    
    // 上面选取类型对应的方法
    String method();
     
    // 由于只传方法名无法确定是具体哪一个方法，还需要带上方法的参数列表
    Class<?>[] args();
}
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

  // 返回代理对象
  // 一般 使用 `return Plugin.wrap(o, this);`即可
  Object plugin(Object target);

  //获取 xml 中配置的参数
  void setProperties(Properties properties);

}

```

### Plugin类

为了方便生成代理对象和绑定方法，MyBATIS为我们提供了一个 Plugin 类。

```java
package org.apache.ibatis.plugin;

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

import org.apache.ibatis.reflection.ExceptionUtil;

/**
 * @author Clinton Begin
 */
public class Plugin implements InvocationHandler {

  private Object target;
  private Interceptor interceptor;
  // Class<?> 代表需要拦截的类，Set<Method>代表 需要拦截的对应类的方法
  private Map<Class<?>, Set<Method>> signatureMap;

  private Plugin(Object target, Interceptor interceptor, Map<Class<?>, Set<Method>> signatureMap) {
    this.target = target;
    this.interceptor = interceptor;
    this.signatureMap = signatureMap;
  }

  // 这个 target 可强制转换的类型: ParameterHandler、ResultSetHandler、StatementHandler、Executor
  public static Object wrap(Object target, Interceptor interceptor) {
    // 获取需要拦截的类和方法
    Map<Class<?>, Set<Method>> signatureMap = getSignatureMap(interceptor);
    Class<?> type = target.getClass();
    Class<?>[] interfaces = getAllInterfaces(type, signatureMap);
    
    //若存在符合拦截条件的接口，创建一个代理对象
    if (interfaces.length > 0) {
      return Proxy.newProxyInstance(
          type.getClassLoader(),
          interfaces,
          new Plugin(target, interceptor, signatureMap));
    }
    return target;
  }

  @Override
  public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
    try {
        
      Set<Method> methods = signatureMap.get(method.getDeclaringClass());
      if (methods != null && methods.contains(method)) {
          // 调用接口的处理逻辑的
        return interceptor.intercept(new Invocation(target, method, args));
      }
      return method.invoke(target, args);
    } catch (Exception e) {
      throw ExceptionUtil.unwrapThrowable(e);
    }
  }

  //解析拦截器的注解，将注解解析成 Map<Class<?>, Set<Method>> 
  // Class<?> 代表需要拦截的类，Set<Method>代表 需要拦截的对应类的方法
  private static Map<Class<?>, Set<Method>> getSignatureMap(Interceptor interceptor) {
    
    Intercepts interceptsAnnotation = interceptor.getClass().getAnnotation(Intercepts.class);
    // issue #251
    if (interceptsAnnotation == null) {
      throw new PluginException("No @Intercepts annotation was found in interceptor " + interceptor.getClass().getName());      
    }
    Signature[] sigs = interceptsAnnotation.value();
    Map<Class<?>, Set<Method>> signatureMap = new HashMap<Class<?>, Set<Method>>();
    for (Signature sig : sigs) {
      Set<Method> methods = signatureMap.get(sig.type());
      if (methods == null) {
        methods = new HashSet<Method>();
        signatureMap.put(sig.type(), methods);
      }
      try {
        Method method = sig.type().getMethod(sig.method(), sig.args());
        methods.add(method);
      } catch (NoSuchMethodException e) {
        throw new PluginException("Could not find method on " + sig.type() + " named " + sig.method() + ". Cause: " + e, e);
      }
    }
    return signatureMap;
  }

  //筛选出 target 类实现的接口: 这些接口在 拦截器的拦截列表中
  private static Class<?>[] getAllInterfaces(Class<?> type, Map<Class<?>, Set<Method>> signatureMap) {
    Set<Class<?>> interfaces = new HashSet<Class<?>>();
    while (type != null) {
      for (Class<?> c : type.getInterfaces()) {
        if (signatureMap.containsKey(c)) {
          interfaces.add(c);
        }
      }
      type = type.getSuperclass();
    }
    return interfaces.toArray(new Class<?>[interfaces.size()]);
  }

}

```

### 小结

Plugin 和 Interceptor 的合作流程:

1. 当外界需要新建一个对象时: 会调用 interceptor.plugin(Object target), 该方法会返回一个 target 的代理对象(简称为 proxy )。
2. 当外界需要执行 target 的方法的时候，会委托 proxy 执行对应的方法。
3. proxy 执行时，会根据 拦截器上的注解内容 判断是否进行拦截操作。若是，则调用 interceptor 的 intercept() 方法。
4. intercept() 方法 必须执行 proxy 的 invoke 方法。

## 来源

https://www.cnblogs.com/fangjian0423/p/mybatis-interceptor.html
https://blog.csdn.net/qq924862077/article/details/53197778
https://blog.csdn.net/ykzhen2015/article/details/50349540
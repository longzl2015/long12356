---
title: 动态代理-jdk
date: 2016-08-05 03:30:09
tags: [动态代理,java]
---

[TOC]

JDK动态代理（proxy）可以在运行时创建一个实现一组给定接口的新类。但是略有限制，即被代理的类必须实现某个接口，否则无法使用JDK自带的动态代理，
因此，如果不满足条件，就只能使用另一种更加灵活，功能更加强大的动态代理技术—— CGLIB。Spring里会自动在JDK的代理和CGLIB之间切换，同时我们也可以强制Spring使用CGLIB。

本文介绍jdk原始动态代理。

<!--more-->


JDK动态代理主要有 Proxy类的newProxyInstance()方法 和 InvocationHandler接口 这两个要点。

newProxyInstance()方法用于根据传入的接口类型interfaces返回一个动态创建的代理类的实例，方法中

- 第一个参数loader表示代理类的类加载器，
- 第二个参数interfaces表示被代理类实现的接口列表，
- 第三个参数h表示所指派的调用处理程序类。

## 简单例子

主题接口类：

```java
public interface IHello {
    public void sayHello();
}
```

被代理的真实类：

```java

public class Hello implements IHello{

    public void sayHello() {
        System.out.println("hello!");
    }
}
```

JDK动态代理类必须管理一个 InvocationHandler类。

```java

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;

public class MyInvocationHandler implements InvocationHandler {
    private Object target;//委托类
    public MyInvocationHandler(Object target){
        this.target=target;
    }

    @Override
    public Object invoke(Object o, Method method, Object[] args) throws Throwable {
        /**代理环绕**/
        //执行实际的方法
        Object invoke = method.invoke(target, args);
        return invoke;
    }
}
```


```java
import java.lang.reflect.Proxy;

public class Test {

    public static void main(String[] args){
        //需要代理的对象
        IHello hello = new Hello();
        InvocationHandler handler = new MyInvocationHandler(hello);
        
        /*
         * 通过Proxy的newProxyInstance方法来创建我们的代理对象，我们来看看其三个参数
         * 
         * 第一个参数 类加载器
         * 第二个参数 代理对象对应的接口集
         * 第三个参数 自定义的InvocationHandler
         */
        IHello  ihello = (IHello) Proxy.newProxyInstance(handler.getClass().getClassLoader(),  
                hello.getClass().getInterfaces(),      //一组接口
                handler); //自定义的InvocationHandler
        ihello.sayHello();
    }
}
```

## 源码

```java
public class Proxy implements java.io.Serializable {
    // ...
     public static Object newProxyInstance(ClassLoader loader,
                                              Class<?>[] interfaces,
                                              InvocationHandler h)
        throws IllegalArgumentException {
         
        Objects.requireNonNull(h);
        
        final Class<?>[] intfs = interfaces.clone();
        // 安全管理器，默认是关闭状态
        final SecurityManager sm = System.getSecurityManager();
        if (sm != null) {
            checkProxyAccess(Reflection.getCallerClass(), loader, intfs);
        }

        // 查找或者生产特定的类，
        // todo 具体细节
        Class<?> cl = getProxyClass0(loader, intfs);

        /*
         * Invoke its constructor with the designated invocation handler.
         */
        try {
            if (sm != null) {
                checkNewProxyPermission(Reflection.getCallerClass(), cl);
            }

            // 获取 InvocationHandler 构造器
            final Constructor<?> cons = cl.getConstructor(constructorParams);
            final InvocationHandler ih = h;
            // 如果修饰符不为 public，则 跳过 权限检查。
            if (!Modifier.isPublic(cl.getModifiers())) {
                AccessController.doPrivileged(new PrivilegedAction<Void>() {
                    public Void run() {
                        cons.setAccessible(true);
                        return null;
                    }
                });
            }
            // 根据代理类的构造函数来创建代理对象
            return cons.newInstance(new Object[]{h});
        } catch (IllegalAccessException|InstantiationException e) {
            throw new InternalError(e.toString(), e);
        } catch (InvocationTargetException e) {
            Throwable t = e.getCause();
            if (t instanceof RuntimeException) {
                throw (RuntimeException) t;
            } else {
                throw new InternalError(t.toString(), t);
            }
        } catch (NoSuchMethodException e) {
            throw new InternalError(e.toString(), e);
        }
    }
    
    private static Class<?> getProxyClass0(ClassLoader loader,
                                           Class<?>... interfaces) {
         //接口数不超过65535
        if (interfaces.length > 65535) {
            throw new IllegalArgumentException("interface limit exceeded");
        }

        // If the proxy class defined by the given loader implementing
        // the given interfaces exists, this will simply return the cached copy;
        // otherwise, it will create the proxy class via the ProxyClassFactory
        // 如果该代理类已经存在了，那么他会直接返回缓存拷贝
        // 如果不存在，他会通过 ProxyClassFactory 创建一个。
        return proxyClassCache.get(loader, interfaces);
    }    
}
```

## 来源

https://blog.csdn.net/mantantan/article/details/51873755
https://www.jianshu.com/p/1a87323164f5
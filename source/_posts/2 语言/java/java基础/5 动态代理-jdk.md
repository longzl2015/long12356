---
title: 动态代理-jdk
date: 2016-08-05 03:30:09
tags: [动态代理,java]
---

[TOC]


JDK动态代理可以在`运行期间`创建一个代理类，这个代理类实现了一组给定的接口方法。

当调用这个代理类的接口方法时，这个调用都会被定向到 InvocationHandler.invoke()方法。在这个invoke方法中，我们可以添加任何逻辑，如打印日志、安全检查等等。
之后，invoke方法会调用真实对象的方法。

从上面的描述可以看出，动态代理是基于接口实现代理类的。因此当被代理对象没有继承接口时，JDK动态代理就无法使用，这时可以使用 CGLIB 代理，关于CGLIB 代理在下一章中介绍。

<!--more-->


JDK动态代理主要有 `Proxy类的newProxyInstance(...)方法` 和 `实现InvocationHandler接口` 这两个要点。

newProxyInstance()方法用于根据传入的接口类型interfaces返回一个动态创建的代理类的实例，方法的参数解释

- 第一个参数loader表示代理类的类加载器，
- 第二个参数interfaces表示被代理类实现的接口列表，
- 第三个参数h表示所指派的调用处理程序类。

实现InvocationHandler接口主要是重写 invoke 方法，在invoke 方法中，可以添加任何逻辑，如打印日志、安全检查等等。
如果不进行拦截的话，一定要 调用 `Object invoke = method.invoke(target, args);`来执行真正的方法

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

测试代码

```java
import java.lang.reflect.Proxy;

public class Test {

    public static void main(String[] args){
        //需要代理的对象
        IHello hello = new Hello();
        InvocationHandler handler = new MyInvocationHandler(hello);
        
        IHello  ihello = (IHello) Proxy.newProxyInstance(handler.getClass().getClassLoader(),  
                hello.getClass().getInterfaces(),     
                handler);
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
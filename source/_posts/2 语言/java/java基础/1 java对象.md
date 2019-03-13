---
title: java基础
date: 2016-08-05 03:30:09
tags: [java]
categories: [语言,java,java基础]
---

[TOC]

<!--more-->

# 基础

## static

1. 静态数据全局唯一
2. 引用方便。只需类名.方法或变量名即可

静态方法：只能调用其他静态方法、只能访问静态数据，不能引用this和super。

## final

1. final修饰的类不能被继承，同时其成员方法全部隐式指定为final类。
2. final方法防止继承类修改其含义。
3. final变量：若为基础类型，一旦初始化就无法修改。若为引用类型变量，则不能指向其他对象，但仍可修改引用对象的内容。


# java对象

## 重载

让这个类以相同的方法处理不同的数据类型。

重载的判定：相同的方法名、不同的参数类型和参数数量。仅返回类型不同不能是重载

## 重写

1. 对从父类继承来的方法进行重新编写，（参数列表和返回类型）与被重写的方法完全相同。
2. 访问修饰符一定要高于被重写方法（public>protected>default>private）
3. 重写方法不能抛出新的异常或者被重写方法的父类异常。

## 深复制和浅复制的区别

浅拷贝：复制一个对象，但是新对象中的变量仍然指向原来的引用。

深拷贝：新对象与与对象的值相同，而且新对象中引用的对象是重新创建的。

实现浅拷贝：
1. object 的clone方法能够实现浅拷贝
2. 派生类中重写父类的clone方法
2. 派生类实现 Cloneable 接口
3. 在clone方法中调用super.clone()即可。

```java
public Object clone(){
           Book b = null;
           try{
               b = (Book)super.clone();
           }catch(CloneNotSupportedExceptione){
               e.printStackTrace();
           }
            return b;
         }
```

## 实现深拷贝的实践：序列化

先使对象实现Serializable接口，然后把对象写到一个流里，再从流里读出来，便可以重建对象。
前提需要确定对象和对象内部的引用对象都是可序列化的。

```java
 public Object deepClone() throws Exception
    {
        // 序列化
        ByteArrayOutputStream bos = new ByteArrayOutputStream();
        ObjectOutputStream oos = new ObjectOutputStream(bos);
        oos.writeObject(this);
        // 反序列化
        ByteArrayInputStream bis = new ByteArrayInputStream(bos.toByteArray());
        ObjectInputStream ois = new ObjectInputStream(bis);
        return ois.readObject();
    }
```


## equal

`==` 比较的是对象存储的值，8种基础类型：变量存储的都是真实的值，而其他类型则存储的是引用地址。

object类的 equal 默认情况下和 == 相同

```java
public boolean equals(Object obj) {
        return (this == obj);
}
```

当一个类拥有自己特有的 "逻辑相等" 的概念的时候，可以重写 equal() 方法。

当重写 equal方法是 需要遵循几个原则:

- 自反性: x.equal(x) 必须返回 真
- 对称性: x.equal(y) 和 y.equal(x) 返回的结果相同
- 传递性: x.equal(y) 返回 true, y.equal(z) 返回 true 那么 x.equal(z) 返回 true
- 一致性: x.equal(y) 只要没有改动 x和y，那么无论调用多少次，其结果始终相同。
- 非空与null相 equal 必须放回 false。

**需要注意的是：**
由于 存在 Float.Nan, -0.0f 以及类似的 double 常量

- float  类型的比较需要使用 Float.compare()
- double 类型的比较需要使用 Double.compare()

## hashcode

在重写了equal方法后，必须重写 hashcode(). 如果没有重写hashcode(), 那么就会违反 hashcode 规则: 

> 如果两个对象根据equal方法比较的结果相等，那么调用这两个对象的hashcode()返回的值也需要是相同的结果

举个例子:

> 有两个不同的实例，其在逻辑上是相同的，即 equal方法 返回 true，然而 object 自带的hashcode 会将这两实例当成两个截然不同的对象。

需要注意的是在极少数情况下，两个对象根据 equal 方法 比较返会的是 false，这两个对象的hashcode有可能会相同。


# 抽象类和接口

## 抽象类


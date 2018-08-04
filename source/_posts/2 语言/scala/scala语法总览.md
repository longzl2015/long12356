---
title: scala语法总览
date: 2018-01-05 03:30:09
tags: 
  - scala
categories:
  - scala
---

# Scala

[TOC]

## 简单介绍

Scala语言是一种面向对象语言，结合了命令式（imperative）和函数式（functional）编程风格，其设计理念是创造一种更好地支持组件的语言。

> **Object-Oriented Meets Functional**

**特性**

- 多范式（Multi-Paradigm）编程语言，类似Java、C#；
- 继承面向对象编程和函数式编程的特性；
  - 　　面向对象：[1]. 子类继承，[2]. 混入(**Mixin**)机制；
  - 　　**函数式**：支持高阶函数、嵌套函数，模式匹配，支持柯里化(**Currying**)；
  - 　　**类型推断**（Type Inference）：根据函数体中的具体内容推断方法的返回值类型
- 更高层的并发模型，可伸缩；
- 静态类型，编译时检查；
- 允许与Java互操作（将来会支持与.Net互操作）；

**与Java对比**

- 如果用作服务器端开发，Scala的简洁、灵活性是Java无法比拟的；
- 如果是企业级应用开发、Web开发，Java的强大是Scala无法匹敌的；

**Scala和Groovy**

Groovy的优势在于易用性以及与Java无缝衔接，更注重实效思想，脚本化；

Scala的优势在于性能和一些高级特性，静态类型，更具有学术思想；

**关于Lift**

一个使用了Scala的开源的Web应用框架，可以使用所有的Java库和Web容器。其他框架：Play、Bowler等。



##基础语法问题

Scala程序的执行入口是提供main方法的独立单例对象。每个Scala函数都有返回值，每个Scala表达式都有返回结果。

在Scala中没有静态的概念，所有东西都是面向对象的。其实object单例对象只是对静态的一种封装而已，在.class文件层面，object单例对象就是用静态（static）来实现的。

###一切皆为对象

Scala中所有的操作符都是方法，操作符面向的使用者都是对象

Scala编程的一个基本原则上，能不用var，尽量不用var，能不用mutable变量，尽量不用mutable变量，能避免函数的副作用，尽量不产生副作用。

> - 对于任何对象，如果在其后面使用()，将调用该对象的apply方法，arr(0) == arr.apply(0)
> - 如果对某个使用()的对象赋值，将该对象的update方法，arr(0)=value == arr.update(0,value)
>

###字段 + 方法 + 函数

scalac编译器会为类中的var字段自动添加setter和getter方法，会为类中的val方法自动添加getter方法。 其中，getter方法和字段名相同。

在源码中，所有对字段的显示访问，都会在class中编译成通过getter和setter方法来访问。

方法作用于对象，方法是对象的行为。

方法定义格式：

```
def 方法名称（参数列表）：返回值 = { 方法体 }
```

```
val 函数名称 = { (参数列表) => { 函数体 } }，即 val 函数名称 = { Lambda表达式 }
或 val 函数名称 ： (入参类型 => 出参类型) = { 入参 => 函数体 }
```

**方法名意味着方法调用，函数名只代表函数本身**。

> 关于方法（Method）和函数（Function）
>
> - **函数是一等公民**，使用val语句可以定义函数，def语句定义方法；
> - 函数是一个对象，继承自FuctionN，函数对象有curried,equals,isInstanceOf,toString等方法，而方法不具有；
> - 函数是一个值，可以给val变量赋值，方法不是值、也不可以给val变量赋值；
> - 通过将方法转化为函数的方式 method _ 或 method(_) 实现给val变量赋值；
> - 若 method 有重载的情况，方法转化为函数时必须指定参数和返回值的类型；
> - 某些情况下，编译器可以根据上下文自动将方法转换为函数；
> - 无参数的方法 method 没有参数列表（调用：method），无参数的函数 function 有空列表（调用：function()）；
> - 方法可以使用参数序列，转换为函数后，必须用 Seq 包装参数序列；
> - 方法支持默认参数，函数不支持、会忽略之；

参考：[学习Scala：Scala中的字段和方法](http://www.tuicool.com/articles/yYRBnqI)； [Scala中Method和Function的区别 - 简书](http://www.jianshu.com/p/d5ce4c683703)；

**参数**

> - 按名传参：By-name parameter，def fun(param: => T)。Evaluated every time it's used within the body of the function
> - 按值传参：By-value parameter。Evaluated before entry into the function/method

推荐将按值传参（def fun(msg: String)）改为按名称传参（def fun(msg: =>String)）。这样参数会等到实际使用的时候才会计算，延迟加载计算，可以减少不必要的计算和异常。

###case class

```
case class PubInterfaceLog(interfaceId: Int, busiType: String, respTime: Long, publicId: Long)
```

最重要的特性是支持模式匹配，Scala官方表示：

> It makes only sense to define case classes if pattern matching is used to decompose data structures.

其他特性如下：

- 编译器自动生成对应的伴生对象和 apply() 方法；
- 实例化时，普通类必须 new，而 case class 不需要；
- 主构造函数的参数默认是 public 级别，默认在参数为 val；
- 默认实现了 equals 和 hashCode，默认是可以序列化的，也就是实现了Serializable，toString 更优雅；
- 默认生成一个 `copy` 方法，支持从实例 a 以部分参数生成另一个实例 b；

参考：[Scala case class那些你不知道的知识](http://www.jianshu.com/p/deb8ca125f6c)；

###apply() 方法

apply方法是Scala提供的一个语法糖

对apply方法的简单测试：

```java
class ApplyTest {
    println("class ApplyTest")
    def apply() {
        println("class APPLY method")
    }
}
object ApplyTest {
    println("object ApplyTest")
    def apply() = {
        println("object APPLY method")
        new ApplyTest()
    }
}
 
// 对象名+括号，调用类的apply方法
val a1 = new ApplyTest()
a1() // == a1.apply()
// 输出 class ApplyTest, class APPLY method
 
// 类名+括号，调用对象的apply方法
val a2 = ApplyTest()
// 输出 object ApplyTest, object APPLY method, class ApplyTest
 
val a2 = ApplyTest()
a2()
// 输出 object ApplyTest, object APPLY method, class ApplyTest, class APPLY method
 
val a3 = ApplyTest
// 输出 object ApplyTest
 
val a3 = ApplyTest
a3()
// 输出 object ApplyTest, object APPLY method, class ApplyTest
```

###几个零碎的知识点

> - **Array **长度不可变, 值可变；**Tuple** 亦不可变，但可以包含不同类型的元素；
> - **List **长度不可变, 值也不可变，**::: **连接两个List，**::** 将一个新元素放到List的最前端，空列表对象 **Nil**
> - **_**：通配符，类似Java中的*，[下划线 "_ " 的用法总结](http://blog.csdn.net/silentwolfyh/article/details/51174192)
> - **_=**：自定义setter方法；
> - **_\***：参数序列化，将参数序列 Range 转化为 Seq
> - i **to** j : [i, j]； i **until** j : [i, j)
> - **lazy ****val**表示延迟初始化，无lazy var

###映射 + 对偶 + 元组

映射由对偶组成，映射是对偶的集合。**对偶**即键值对，键->值，（键, 值），是最简单的元组。**元组**是不同类型的值的聚集。

> 映射是否可变表示整个映射是否可变，包括元素值、映射中元素个数、元素次序等：
>
> - **不可变**映射：直接用(scala.collection.mutable.)Map声明，维持元素插入顺序，支持 += 、-=；
> - **可变**映射：用scala.collection.immutable.Map声明，不维持元素插入顺序，支持 +、-；

###构造器

> （**1**）**主构造器**
>
```java
class Student(var ID : String, var Name : String) {
    println("主构造器！")
}
```
>
> - 主构造器直接跟在类名后面，主构造器的参数最后会被编译成字段
> - 主构造器执行时，会执行类中所有的语句
> - 如果主构造器参数声明时不加val或var，相当于声明为private级别
>
> （**2**）**从构造器**
>
```java
class Student(var ID : String, var Name : String) {
    println("主构造器！")
 
    var Age : Int = _
    var Address : String = _
    private val Email : String = Name + ID + "@163.com"
 
    println("从构造器！")
    def this(ID:String, Name:String, Age:Int, Address:String) {
        this(ID, Name)
        this.Age = Age
        this.Address = Address
    }
}
```
>
> - 从构造器定义在类内部，方法名为this
> - 从构造器必须先调用已经存在的主或从构造器

###集合

Scala语言的一个设计目标是可以同时利用**面向对象和面向函数**的方法编码，因此提供的集合类分成了**可以修改的集合类和不可以修改的集合类**两大类型。Scala除了**Array和List**，还提供了**Set和Map**两种集合类。

> - 通过 scala.collection.JavaConversions.**mapAsScalaMap **可将 Java 的 Map 转换为 Scala 类型的 Map；
> - 通过 scala.collection.JavaConversions.**mapAsJavaMap **可将 Scala 的映射转换为 Java 类型的映射；
> - **toMap** 方法将对偶集合转化为映射

###Option**，**None**，**Some

[Option**，**None**，**Some](http://www.jianshu.com/p/95896d06a94d)

> 一致目标：所有皆为对象 + 函数式编程，在变量和函数返回值可能不会引用任何值的时候使用 Option 类型
>
> - 在没有值的时候，使用None；
> - 如果有值可以引用，使用Some来包含这个值；
>
> None 和 Some 均为 Option 的子类，但是 None 被声明为一个对象，而不是一个类.

###伴生对象

当单例对象（object Name，Singleton Object）与类（class Name）同名时，该单例对象称作类的伴生对象（Companion Object），该类称作单例对象的伴生类。没有伴生类的单例对象称为孤立对象（Standalone Object），最常见的就是包含程序入口main()的单例对象。

- 同名且在同一个源文件中定义
- 可以互相访问其私有成员

参考：[Scala学习笔记-伴生对象于孤立对象](http://lib.csdn.net/article/scala/26983)；

- 伴生对象的属性、方法指向全局单例对象 `MODULE$`
- ``伴生类的属性、方法被定义为是对象相关的

单例对象在第一次访问时初始化，不可以new、不能带参数，而类可以new、可以带参数。

- 伴生对象中定义的字段和方法， 对应同名.class类中的静态方法，对应同名$.class虚构类中的成员字段和方法
- 伴生类中定义的字段和方法， 对应同名.class类中的成员字段和成员方法

同名.class类中的静态方法，会访问单例的虚构类的实例化对象， 将相关的逻辑调用转移到虚构类中的成员方法中，即：.class类提供程序的入口，$.class提供程序的逻辑调用。

- 伴生对象中的逻辑，转移到$.class虚构类中去处理
- 伴生类中的逻辑，转移到.class同名类中的成员方法中去处理

通过伴生对象来访问伴生类的实例，提供了控制实例个数的机会。虚构类的单例性，保证了伴生对象中信息的唯一性。

那么：伴生对象如何体现单例呢？

> 因为伴生类不是单例的，如何实现单例模式呢？方法2种：
>
> （**1**）将伴生类中的所有逻辑全部移到单例对象中，去除伴生类， 单例对象成为孤立对象， 该孤立对象天然就是单例的
>
> （**2**）若必须存在伴生类，如何保证伴生类是单例的？ 将伴生类的主构造器私有， 并在伴生对象中创建一个伴生类的对象， 该对象就是唯一的
>
```java
class A private {
}
object A {
  val single = new A()
}
// true
var a1 = A.single
var a2 = A.single;
println("a1 eq a2 : " + (a1 eq a2))
```

参考：[学习Scala：孤立对象的实现原理](http://www.tuicool.com/articles/N3eAVn)； [学习Scala：伴生对象的实现原理](http://www.tuicool.com/articles/qaq6nau)；

###Trait

特质，类似有函数体的 Interface，利用关键字 **with** 混入。

###IO读写

Scala本身提供 Read API，但是 Write API 需要利用Java的API，文件不存在会自动创建。

> （**1**）**Read**
>
```java
import scala.io.Source
val content = Source.fromURL(url).getLines()    // 网络资源
val lines = Source.fromFile(filePath).getLines()  // 文件
```
>
> （**2**）**Write**
>
```java
import java.io.File
import java.io.PrintWriter
import java.io.FileWriter
import java.io.BufferedWriter
 
// 文件首次写入，ok; 不支持追加
val writer = new PrintWriter(new File("sqh.txt"))
writer.println("xxx")
 
// 支持追加；但是有换行问题
val writer = new FileWriter(new File("sqh.txt"), true)
writer.write("xxx")
 
// 支持追加，换行解决方法1
val writer = new BufferedWriter(new FileWriter(new File("sqh.txt"), true))
writer.write("xxx")
writer.newLine()
 
// 支持追加，换行解决方法2
val writer = new PrintWriter(new FileWriter(new File("sqh.txt"), true))
writer.println("xxx")
 
writer.flush()
writer.close
```
> 注意，关闭流前，先刷新。PrintWriter 不支持追加，FileWriter 支持追加，但存在换行问题。可以将 FileWriter 包装成 BufferedWriter 或 PrintWriter 解决换行问题。

##参考

- [Scala官网](http://www.scala-lang.org/)；
- [Scala | 菜鸟教程](http://www.runoob.com/scala/scala-tutorial.html)； [Scala | 易佰教程](http://www.yiibai.com/scala/)；
- [Scala - ZeZhi.net](http://www.zezhi.net/cat/scala2)；
- [A Scala Tutorial for Java Programmers](http://docs.scala-lang.org/tutorials/scala-for-java-programmers.html)；
---
title: apply, update 语法糖
date: 2018-01-05 03:30:09
tags: 
  - scala
categories: [语言,scala]
---

# apply, update 语法糖

[TOC]

语法糖，又称为糖衣语法，指计算机语言中添加的某种语法，这种语法对语言的功能并没有影响，但是更方便程序员使用。通常来说可以增加程序的可读性，从而减少程度代码出错的机会。接下来就会介绍两个 Scala 中的语法糖。

## apply

在 Scala 中，如果我们要频繁调用某个 class 或 object 的方法，我们可以通过定义 apply 方法来避免每次写出该函数的调用，而使用一种更加简洁的方式，来看下面的例子：

**不使用 apply 方法**

```scala
scala> class truck {
     |   def transport( goods: Int ): Unit = {
     |     println( "truck transport " + goods + "t goods" )
     |   }
     | }
defined class truck

scala>     val t = new truck
t: truck = truck@77468bd9

scala>     t.transport( 100 )
truck transport 100t goods

```

**使用 apply 方法**

```scala
scala> class truck {
     |   def apply( goods: Int ): Unit = {
     |     println( "truck transport " + goods + "t goods" )
     |   }
     | }
defined class truck

scala>

scala> val t = new truck
t: truck = truck@68bbe345

scala> t(100)
truck transport 100t goods

```

上面两个例子的效果是完全一样的，下面这个定义了 apply 的类能让我们在频繁调用某个方法的时候更加方便。当然，apply 方法支持任意类型和任意个参数。

另一种 apply 常用的使用场景是用 object 来创建其伴生类的实例。如下例：

```scala
private class truck {
  println( "new truck created!" )
}

object truck {
  def apply(): Unit = {
    new truck
  }
}

object TT {
  def main (args: Array[String]) {
    val t = truck()
  }
}

```

输出：

```scala
new truck created!
```

其实上例中，`truck()`就是调用了`truck.apply()`方法，编译器在编译时将`truck()`编译成`truck.apply()`，如果你对编译后的结果进行反编译就能验证这一点，这留给有兴趣的同学自行实践，这里不展开了。

apply 方法在我们平时写代码时也经常碰到，比如：

```scala
val l = List(1,2,3)
```

中的 `List(1,2,3)` 调用就是调用的 object List 的 apply 方法

```scala
object List extends scala.collection.generic.SeqFactory[scala.collection.immutable.List] with scala.Serializable {
  implicit def canBuildFrom[A] : scala.collection.generic.CanBuildFrom[List.Coll, A, scala.collection.immutable.List[A]] = { /* compiled code */ }
  def newBuilder[A] : scala.collection.mutable.Builder[A, scala.collection.immutable.List[A]] = { /* compiled code */ }
  override def empty[A] : scala.collection.immutable.List[A] = { /* compiled code */ }
  override def apply[A](xs : A*) : scala.collection.immutable.List[A] = { /* compiled code */ }
  private[collection] val partialNotApplied : scala.AnyRef with scala.Function1[scala.Any, scala.Any] = { /* compiled code */ }
}
```

## update

除了 apply 方法，还有一个用于赋值时的 update 方法，

```scala
scala> val a = mutable.Map[ Int, Int ]()
a: scala.collection.mutable.Map[Int,Int] = Map()

scala> a(1) = 1

scala> println( a )
Map(1 -> 1)
```

当我们调用 `a(1) = 1` 的时候其实是在调用 `a.update(1,1)`，当然你也可以在自定义类中实现 update 使调用更方便。就像下面这个例子一样

```scala
scala> class A {
     |   private var a = 0
     |
     |   def update( i: Int ): Unit = {
     |     a = i
     |     println( a )
     |   }
     | }
defined class A

scala> val a = new A
a: A = A@27e47833

scala> a() = 2
2
```
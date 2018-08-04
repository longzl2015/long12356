---
title: case class简单介绍
tags: 
  - scala
categories:
  - scala
---

# case class简单介绍

[TOC]

本文将基于下面这个简单的例子来说明 case class

```
case class Person( lastname: String, firstname: String, birthYear: Int )

```

## 你可能知道的知识

当你声明了一个 case class，Scala 编译器为你做了这些：

- 创建 case class 和它的伴生 object

- 实现了 apply 方法让你不需要通过 new 来创建类实例

  ```
  scala> case class Person(lastname: String, firstname: String, birthYear: Int)
  defined class Person

  scala> val p = Person("Lacava", "Alessandro", 1976)
  p: Person = Person(Lacava,Alessandro,1976)

  ```

- 默认为主构造函数参数列表的所有参数前加 val

  ```
  scala> println( p.lastname )
  Lacava

  scala> p.lastname = "jhon"
  <console>:10: error: reassignment to val
     p.lastname = "jhon"
                ^

  ```

- 添加天然的 hashCode、equals 和 toString 方法。由于 == 在 Scala 中总是代表 equals，所以 case class 实例总是可比较的

  ```
  scala> val p_1 = new Person( "Brown", "John", 1969 )
  p_1: Person = Person(Brown,John,1969)

  scala>val p_2 = new Person( "Lacave", "Alessandro", 1976)
  p_2: Person = Person(Lacave,Alessandro,1976)

  scala> p_1.hashCode
  res1: Int = -1362628729

  scala> p_1.toString
  res2: String = Person(Brown,John,1969)

  scala> p_1.equals(p_2)
  res3: Boolean = false

  scala> p_1 == p_2
  res4: Boolean = false

  ```

- 生成一个 `copy` 方法以支持从实例 a 生成另一个实例 b，实例 b 可以指定构造函数参数与 a 一致或不一致

  ```
  //< 保留 lastname 一致，修改 firstname 和 birthYear
  scala> val p_3 = p.copy(firstname = "Michele", birthYear = 1972)
  p_3: Person = Person(Lacava,Michele,1972)

  ```

- 由于编译器实现了 unapply 方法，一个 case class 支持模式匹配

  ```
  scala> case class A( a: Int )
  defined class A

  scala> case class B( b: String )
  defined class B

  scala> def classMath( x: AnyRef ): Unit = {
       |   x match {
       |     case A(a) => println( "A:" + a )
       |     case B(b) => println( "B:" + b )
       |     case A => println( A.apply(100) )
       |   }
       | }
  classMath: (x: AnyRef)Unit

  scala> val a = A( 1 )
  a: A = A(1)

  scala> val b = B( "b" )
  b: B = B(b)

  scala> classMath( a )
  A:1

  scala> classMath( b )
  B:b

  ```

  也许你已经知道，在模式匹配中，当你的 case class 没有参数的时候，你是在使用 case object 而不是一个空参数列表的 case class

  ```
  scala> classMath( A )
  A(100)

  ```

除了在模式匹配中使用之外，`unapply` 方法可以让你结构 case class 来提取它的字段，如：

```
scala> val Person(lastname, _, _) = p
lastname: String = Lacava

```

## 你可能不知道的知识

- 获取一个函数接收一个 tuple 作为参数，该 tuple 的元素类型与个数与某 case class 相同，那么可以将该 tuple 作为 case class 的 tuple 方法参数来构造 case class 实例

  ```
  scala> val meAsTuple: (String, String, Int) = ("Lacava", "Alessandro", 1976)
  meAsTuple: (String, String, Int) = (Lacava,Alessandro,1976)

  scala> Person.tupled( meAsTuple )
  res2: Person = Person(Lacava,Alessandro,1976)

  ```

- 相对用 tuple 来创建 case class 实例，还可以从 case class 实例中解构并提取出 tuple 对象

  ```
  scala> val transform: Person => Option[ (String, String, Int) ] = {
   |   Person.unapply _
   | }
  transform: Person => Option[(String, String, Int)] = <function1>

  scala> transform( p )
  res0: Option[(String, String, Int)] = Some((Lacava,Alessandro,1976))

  ```

  ------

## 另一种定义 case class 的方式

  还有另一种很少人知道的定义 case class 的方式，如：

  ```
  case class Person( lastname: String )( firstname: String, birthYear: Int )

  ```

  这种方式有点像偏函数，有两个参数列表，要注意的是，对这两个参数列表是区别对待的。上文提到的所有 case class 的特性在这种定义方式下只作用于第一个参数列表中的参数（比如在参数前自动加 val，模式匹配，copy 支持等等），第二个及之后的参数列表中的参数和普通的 class 参数列表参数无异。

  **firstname和birthYear前不再自动添加 val，不再是类的成员**

  ```
  scala> val p = Person("Lacava")("Alessandro", 1976)
  p: Person = Person(Lacava)

  scala> p.lastname
  res0: String = Lacava

  scala> p.firstname
  <console>:11: error: value firstname is not a member of Person
                p.firstname
                  ^

  scala> p.birthYear
  <console>:11: error: value birthYear is not a member of Person
                p.birthYear
                  ^

  ```

  **copy 时，当不指定birthYear的值时，不会使用 p 中的birthYear，因为根本没这个值，会报错**

  ```
  scala> p.copy()(firstname = "Jhon")
  <console>:11: error: not enough arguments for method copy: (firstname: String, birthYear: Int)Person.
  Unspecified value parameter birthYear.
                p.copy()(firstname = "Jhon")

  ```

  equals 和 toString 方法也发生了改变：

  ```
  scala> val p_1 = Person("Lacava")("Jhon", 2001)
  p_1: Person = Person(Lacava)

  scala> p.equals(p_1)
  res9: Boolean = true

  scala> p == p_1
  res10: Boolean = true

  scala> println ( p.toString )
  Person(Lacava)

  ```

其他特性不再一一列举..
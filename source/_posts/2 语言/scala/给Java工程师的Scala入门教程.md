---

title: 给Java工程师的Scala入门教程

date: 2019-02-28 17:58:00

categories: [语言,scala]

tags: [scala]

---





<!--more-->


## map vs foreach

- map: 逐行计算，返回一个新的集合
- foreach: 逐行计算，无返回结果











## 入门教程
[给java工程师的scala入门教程](https://docs.scala-lang.org/zh-cn/tutorials/scala-for-java-programmers.html)

## scala隐式转换

[scala隐式转换](https://fangjian0423.github.io/2015/12/20/scala-implicit/)

## future 

https://docs.scala-lang.org/zh-cn/overviews/core/futures.html

[Akka在并发程序中使用Future](https://www.jianshu.com/p/f858d31877c3)

### future 组合

- map: 将 前一个Future的成功执行的结果 应用到 f函数后，重新生成一个新的Future对象

- flatMap
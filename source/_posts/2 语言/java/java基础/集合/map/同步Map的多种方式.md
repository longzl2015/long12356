---

title: 同步Map的多种方式

date: 2019-08-01 10:11:03

categories: [语言,java,集合]

tags: [map,并发]

---





<!--more-->

## ConcurrentHashMap




## Collections.synchronizedMap

Collections.synchronizedMap 的实现方式较为简单: 

> 通过新建一个包装类，在所有的 map 方法加上 synchronized 关键字即可。


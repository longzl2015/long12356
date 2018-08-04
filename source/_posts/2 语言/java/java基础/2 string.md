---
title: string构建
date: 2016-08-05 03:30:09
tags: [string]
---

<!-- MarkdownTOC -->

- [String、StringBuffer与 StringBuilder](#string、stringbuffer与-stringbuilder)
	- [String](#string)
	- [StringBuffer](#stringbuffer)
	- [StringBuilder](#stringbuilder)
- [string能否被继承](#string能否被继承)
- [string的substring和spilt](#string的substring和spilt)

<!-- /MarkdownTOC -->

<!--more-->


## String、StringBuffer与 StringBuilder

### String
字符串常量，不能被改变。通常对字符串的操作都是新建一个字符串（不包括被编译器自动使用StringBuilder的情况，比如String的自加操作）。不能被继承。string其实是通过char数组来保存字符串的。

### StringBuffer
线程安全的可变字符序列（变量）。在对字符串进行操作时，是在源字符串进行修改的。

### StringBuilder
线程不安全的可变字符序列（变量）。由于不执行同步操作，速度比StringBuffer快。在不影响程序运行的情况下，优先使用StringBuilder。

在字符串需要频繁变动的情况使用 StringBuffer 或者 StringBuilder 。
执行效率: StringBuilder > StringBuffer > String

## string能否被继承

string是final类，不能被继承。

## string的substring和spilt

这两个方法是在原有的字符串上进行操作（添加一个位移量和长度），并不重新创建对象。

若使用不当会造成内存泄漏。

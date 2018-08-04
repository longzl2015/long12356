---
title: flatMap
tags: 
  - flatMap
categories:
  - scala
---
# flatMap

假设有个序列, 里面装了一堆人

```scala
val xs = Seq(john, mary, alice, bob)
```

每个人有一个朋友列表, 可以这么访问:

```scala
x.friends // 返回一个序列, 里面每个元素是一个人
```

比如 john.friends 可能返回 Seq(harry, hermione, ron)

用 map 的话, 可以把 xs 里的每一个元素都变成朋友列表:

```scala
xs.map(x => x.friends) 
// 得到一个序列的序列:
// Seq(
//   Seq(harry, hermione, ron),
//   Seq(sam, frodo),
//   Seq(),
//   Seq(jamie, tyrion, cersei)
// )
```

然而有些时候, 你并不希望得到这么一个需要访问两层才能拿到朋友对象的序列. 有时, 你希望得到的是一个在第一层就能访问到朋友的序列. 这就需要 flatMap:

```scala
xs.flatMap(x => x.friends)
// 得到一个序列
// Seq(harry, hermione, ron, sam, frodo, jamie, tyrion, cersei)
```

这个过程就像是先 map, 然后再将 map 出来的这些列表首尾相接 (flatten).
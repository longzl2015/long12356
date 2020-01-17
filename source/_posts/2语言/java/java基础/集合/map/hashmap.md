---
title: HashMap.md
date: 2018-08-01 10:11:05
tags: [HashMap,集合]
categories: [语言,java,集合]
---

[TOC]

<!--more-->

## 关键点

基于map接口的非同步实现，不保证顺序，允许null key/value，默认大小16，按2倍扩增。

## 重要参数

threshold 代表的是一个阈值，通常小于数组的实际长度。这个阈值的具体值则由负载因子（loadFactor）和数组容量来决定。

> threshold = capacity * loadFactor。

伴随着元素不断的被添加进数组，一旦数组中的元素数量达到这个threshold，那么表明数组应该被扩容而不应该继续任由元素加入。

```java
int threshold;
final float loadFactor;

//默认的容量，即默认的数组长度 16
static final int DEFAULT_INITIAL_CAPACITY = 1 << 4;
//HashMap 中默认负载因子为 0.75
static final float DEFAULT_LOAD_FACTOR = 0.75f;
//最大的容量，即数组可定义的最大长度 
static final int MAXIMUM_CAPACITY = 1 << 30;
```

## HashMap 数据结构

首先，HashMap 是 Map 的一个实现类，它代表的是一种键值对的数据存储形式。Key 不允许重复出现，Value 随意。jdk 8 之前，其内部是由数组+链表来实现的，而 jdk 8 对于链表长度超过 8 的链表将转储为红黑树。大致的数据存储形式如下：

![](/images/hashmap/hashmap.png)

主体为table数组结构，数组的每一项元素是一个链表。

下面的代码就是上述提到的数组，数组的元素都是 Node 类型，数组中的每个 Node 元素都是一个链表的头结点，通过它可以访问连接在其后面的所有结点。

```java
transient Node<K,V>[] table;
```


### Node<K,V>
Node 是一个单向列表，她实现了 Map.Entry接口

```java
    static class Node<K,V> implements Map.Entry<K,V> {
        final int hash;
        final K key;
        V value;
        Node<K,V> next;

        Node(int hash, K key, V value, Node<K,V> next) {
            this.hash = hash;
            this.key = key;
            this.value = value;
            this.next = next;
        }

        public final K getKey()        { return key; }
        public final V getValue()      { return value; }
        public final String toString() { return key + "=" + value; }

        public final int hashCode() {
            return Objects.hashCode(key) ^ Objects.hashCode(value);
        }

        public final V setValue(V newValue) {
            V oldValue = value;
            value = newValue;
            return oldValue;
        }
        ///判断两个node是否相等,若key和value都相等，返回true。
        public final boolean equals(Object o) {
            if (o == this)
                return true;
            if (o instanceof Map.Entry) {
                Map.Entry<?,?> e = (Map.Entry<?,?>)o;
                if (Objects.equals(key, e.getKey()) &&
                    Objects.equals(value, e.getValue()))
                    return true;
            }
            return false;
        }
    }
```

### 红黑树

```java
static final class TreeNode<K,V> extends LinkedHashMap.Entry<K,V> {
        TreeNode<K,V> parent;  // red-black tree links
        TreeNode<K,V> left;
        TreeNode<K,V> right;
        TreeNode<K,V> prev;    // needed to unlink next upon deletion
        boolean red;
        TreeNode(int hash, K key, V val, Node<K,V> next) {
            super(hash, key, val, next);
        }
        
        // 返回根节点
        final TreeNode<K,V> root() {
            for (TreeNode<K,V> r = this, p;;) {
                if ((p = r.parent) == null)
                    return r;
                r = p;
            }
        }
        //....
}
```
## index 计算

```java
static final int hash(Object key) {
    int h;
    return (key == null) ? 0 : (h = key.hashCode()) ^ (h >>> 16);
}
```

```java
int index = (n - 1) & hash(key)
```

![](/images/hashmap/index计算.png)

1. hash函数实现：高16bit不变，低16bit和高16bit做了一个异或
2. (n-1)&hash: n 表示table的大小，即是取hash的低（n-1）位作为index

## resize函数

### resize 巧妙设计

由于 hashMap 使用的是2次幂的扩展(指长度扩为原来2倍)，所以，元素的位置要么是在原位置，要么是在原位置再移动2次幂的位置。
看下图可以明白这句话的意思，n为table的长度，

- 图（a）表示扩容前的key1和key2两种key确定索引位置的示例，
- 图（b）表示扩容后key1和key2两种key确定索引位置的示例，

其中hash1是key1对应的哈希与高位运算结果。

![](/images/hashmap/resize2.png)

元素在重新计算hash之后，因为n变为2倍，那么n-1的mask范围在高位多1bit(红色)，因此新的index就会发生这样的变化：

![](/images/hashmap/resize3.png)

因此，我们在扩充HashMap的时候，不需要重新计算hash，只需要看看原来的hash值新增的那个bit是1还是0就好了，是0的话索引没变，是1的话索引变成“原索引+oldCap”

## 源码

### resize 函数实现

```java
public class HashMap<K,V> extends AbstractMap<K,V>
    implements Map<K,V>, Cloneable, Serializable {
    // .. 
    final Node<K,V>[] resize() {
        Node<K,V>[] oldTab = table;
        int oldCap = (oldTab == null) ? 0 : oldTab.length;
        int oldThr = threshold;
        int newCap, newThr = 0;
        if (oldCap > 0) {
            //如果大于 最大容量，直接返回
            if (oldCap >= MAXIMUM_CAPACITY) {
                threshold = Integer.MAX_VALUE;
                return oldTab;
            }
            //容量和阈值 扩大1倍
            else if ((newCap = oldCap << 1) < MAXIMUM_CAPACITY &&
                     oldCap >= DEFAULT_INITIAL_CAPACITY)
                newThr = oldThr << 1; // double threshold
        }
        // 如果原来的 thredshold 大于0则将容量设为原来的 thredshold
        // 在第一次带参数初始化时候会有这种情况
        else if (oldThr > 0) // initial capacity was placed in threshold
            newCap = oldThr;
        // 在默认无参数初始化会有这种情况
        else {               // zero initial threshold signifies using defaults
            newCap = DEFAULT_INITIAL_CAPACITY;
            newThr = (int)(DEFAULT_LOAD_FACTOR * DEFAULT_INITIAL_CAPACITY);
        }
        
        if (newThr == 0) {
            float ft = (float)newCap * loadFactor;
            newThr = (newCap < MAXIMUM_CAPACITY && ft < (float)MAXIMUM_CAPACITY ?
                      (int)ft : Integer.MAX_VALUE);
        }
        threshold = newThr;
        @SuppressWarnings({"rawtypes","unchecked"})
        //以 newCap 容量构造新表
        Node<K,V>[] newTab = (Node<K,V>[])new Node[newCap];
        table = newTab;
        if (oldTab != null) {
            //遍历 table 数组
            for (int j = 0; j < oldCap; ++j) {
                Node<K,V> e;
                if ((e = oldTab[j]) != null) {
                    oldTab[j] = null;
                    //链表只有一个，直接将其放入新 table 数组中
                    if (e.next == null)
                        newTab[e.hash & (newCap - 1)] = e;
                    //红黑树
                    else if (e instanceof TreeNode)
                        ((TreeNode<K,V>)e).split(this, newTab, j, oldCap);
                    //链表
                    else { // preserve order
                        //存储不需要移动的节点
                        // loHead 存储头部数据
                        // loTail 存储尾部数据
                        Node<K,V> loHead = null, loTail = null;
                        //存储移动到高位的节点
                        Node<K,V> hiHead = null, hiTail = null;
                        Node<K,V> next;
                        do {
                            next = e.next;
                            // (e.hash & oldCap) 为 0 表示元素位置不需要移动，
                            // 原理 请看上面的 `resize 巧妙设计` 小节
                            if ((e.hash & oldCap) == 0) {
                                if (loTail == null)
                                    loHead = e;
                                else
                                    loTail.next = e;
                                loTail = e;
                            }
                            // 需要移动
                            else {
                                if (hiTail == null)
                                    hiHead = e;
                                else
                                    hiTail.next = e;
                                hiTail = e;
                            }
                        } while ((e = next) != null);
                        
                        //将头部数据插入桶中
                        //原索引放到bucket里
                        if (loTail != null) {
                            loTail.next = null;
                            newTab[j] = loHead;
                        }
                        //原索引+oldCap放到bucket里
                        if (hiTail != null) {
                            hiTail.next = null;
                            newTab[j + oldCap] = hiHead;
                        }
                    }
                }
            }
        }
        return newTab;
    }    
    // ...
}
```

### put函数实现

```java
public class HashMap<K,V> extends AbstractMap<K,V>
    implements Map<K,V>, Cloneable, Serializable {
    
    
    public V put(K key, V value) {
        return putVal(hash(key), key, value, false, true);
    }

    /**
     * Implements Map.put and related methods
     *
     * @param hash hash for key
     * @param key the key
     * @param value the value to put
     * @param onlyIfAbsent if true, don't change existing value
     * @param evict if false, the table is in creation mode.
     * @return previous value, or null if none
     */
    final V putVal(int hash, K key, V value, boolean onlyIfAbsent,
                   boolean evict) {
        Node<K,V>[] tab;
        Node<K,V> p; 
        int n, i;
        //如果 tab[] 为空或为null,  执行 resize()
        if ((tab = table) == null || (n = tab.length) == 0)
            n = (tab = resize()).length;
        //如果 (n - 1) & hash 位置上的元素为 null(未发生碰撞)，则直接新建一个node
        if ((p = tab[i = (n - 1) & hash]) == null)
            tab[i] = newNode(hash, key, value, null);
        //发生碰撞
        else {
            Node<K,V> e; K k;
            //key的【 hash() 相同 && equal() 相同，直接替换
            if (p.hash == hash &&
                ((k = p.key) == key || (key != null && key.equals(k)))) 
                e = p;
            //红黑树
            else if (p instanceof TreeNode)
                e = ((TreeNode<K,V>)p).putTreeVal(this, tab, hash, key, value);
            //链表
            else {
                for (int binCount = 0; ; ++binCount) {
                    // next 为空，将新值挂在后面
                    if ((e = p.next) == null) {
                        p.next = newNode(hash, key, value, null);
                        //冲突节点超过8个，视情况将其转为红黑树或者resize()
                        if (binCount >= TREEIFY_THRESHOLD - 1) // -1 for 1st
                            treeifyBin(tab, hash);
                        break;
                    }
                    // key的【 hash() 相同 && equal() 相同，直接替换
                    if (e.hash == hash &&
                        ((k = e.key) == key || (key != null && key.equals(k))))
                        break;
                    p = e;
                }
            }
            //若存在对应的key，将HashMap中的旧值替换为新值，并返回旧值
            if (e != null) { // existing mapping for key
                V oldValue = e.value;
                if (!onlyIfAbsent || oldValue == null)
                    e.value = value;
                afterNodeAccess(e);
                return oldValue;
            }
        }
        ++modCount;
        //如果当前size大于 load factor*current capacity
        if (++size > threshold)
            resize();
        afterNodeInsertion(evict);
        return null;
    }
    //....
}
```

1. 对key的hashCode()做hash，然后再计算 index;
2. 如果index没碰撞直接放到table数组里；
3. 如果碰撞了，以链表的形式接在**数组中元素的后面**；
4. 如果碰撞导致链表过长(大于等于TREEIFY_THRESHOLD)，就把链表转换成红黑树；
5. 如果节点已经存在就替换old value(保证key的唯一性)
6. 如果bucket满了(超过load factor*current capacity)，就要resize。

### get函数实现

```java
public class HashMap<K,V> extends AbstractMap<K,V>
    implements Map<K,V>, Cloneable, Serializable {
    public V get(Object key) {
        Node<K,V> e;
        return (e = getNode(hash(key), key)) == null ? null : e.value;
    }
    
    final Node<K,V> getNode(int hash, Object key) {
        Node<K,V>[] tab; 
        Node<K,V> first, e; 
        int n; K k;
        // tab 不为空 && tab[(n - 1) & hash] 不为空
        if ((tab = table) != null && (n = tab.length) > 0 &&
            (first = tab[(n - 1) & hash]) != null) {
            // hash 和 equals 完全相同直接返回该值
            if (first.hash == hash && // always check first node
                ((k = first.key) == key || (key != null && key.equals(k))))
                return first;
            
            if ((e = first.next) != null) {
                // 红黑树
                if (first instanceof TreeNode)
                    return ((TreeNode<K,V>)first).getTreeNode(hash, key);
                // 遍历链表
                do {
                    if (e.hash == hash &&
                        ((k = e.key) == key || (key != null && key.equals(k))))
                        return e;
                } while ((e = e.next) != null);
            }
        }
        return null;
    }
    //...
}
```

1. table数组的第一个节点，直接命中；
2. 如果有冲突，则通过key.equals(k)去查找对应的entry。
	- 若为树，则在树中通过key.equals(k)查找，O(logn)；
	- 若为链表，则在链表中通过key.equals(k)查找，O(n)。


## 常见问题

1、hashMap中的键为自定义的类型。放入 HashMap 后，我们在外部把某一个 key 的属性进行更改，然后我们再用这个 key 从 HashMap 里取出元素，这时候 HashMap 会返回什么？

答：

这个需要根据 自定义类型的 hash函数 和 equals函数 来定:

- 若 属性 会影响到 hash函数 或者 equals函数 的结果，则 返回的结果会变成 null。
- 若 属性 不影响到 hash函数 和 equals函数 的结果，则 返回的结果不变。

注: 

- equal 默认实现为 指针比较
- hash 默认实现为 将内存地址经过特定算法转化而成的int值，具体实现有操作系统决定。

2、加载因子 loadFactor（默认0.75）：为什么需要使用加载因子，为什么需要扩容呢

答: 

如果loadFactor很大，空间利用率就会越高，但是碰撞的几率就会越来越高。
如果一直不进行扩容的话，链表就会越来越长，这样查找的效率很低，因为链表的长度很大（当然jdk8版本使用了红黑树后会改进很多），
扩容之后，将原来链表数组的每一个链表分成奇偶两个子链表分别挂在新链表数组的散列位置，这样就减少了每个链表的长度，增加查找效率

3、为什么需要红黑树

在一种极端情况下，多个 HashCode 的值 落在了同一个桶中，使 hashMap 变成了链表，查找时间从 O(1)到 O(n)。这样非常耗时。
红黑树: 当单个链表长度大于8时，hashMap 会将链表转换为红黑树，这样使得查询时间变成了O(logn)。

它是如何工作的？

> 刚开始前面产生冲突的 那些KEY 对应的记录只是简单的追加到一个链表后面，这些记录只能通过遍历来进行查找。
> 但是超过这个阈值（默认个为8）后 HashMap 开始将列表升级成一个二叉树.

----

[Java HashMap工作原理及实现](http://yikun.github.io/2015/04/01/Java-HashMap%E5%B7%A5%E4%BD%9C%E5%8E%9F%E7%90%86%E5%8F%8A%E5%AE%9E%E7%8E%B0/)

https://www.cnblogs.com/yangming1996/p/7997468.html

https://blog.csdn.net/weixin_37356262/article/details/80543218

http://www.importnew.com/20386.html

http://www.importnew.com/28263.html
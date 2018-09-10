---
title: HashMap.md
date: 2016-03-19 22:27:06
tags: [HashMap,集合]
---

[TOC]

<!--more-->

## 关键点

基于map接口的非同步实现，不保证顺序，允许null key/value，默认大小16，按2倍扩增。

## HashMap 数据结构

首先，HashMap 是 Map 的一个实现类，它代表的是一种键值对的数据存储形式。Key 不允许重复出现，Value 随意。jdk 8 之前，其内部是由数组+链表来实现的，而 jdk 8 对于链表长度超过 8 的链表将转储为红黑树。大致的数据存储形式如下：

![](hashmap/hashmap.png)

主体为table数组结构，数组的每一项元素是一个链表。

```java
//下面这三个属性是相关的，threshold 代表的是一个阈值，通常小于数组的实际长度。
// 伴随着元素不断的被添加进数组，一旦数组中的元素数量达到这个阈值，那么表明数组应该被扩容而不应该继续任由元素加入。
// 而这个阈值的具体值则由负载因子（loadFactor）和数组容量来决定，
// 公式：threshold = capacity * loadFactor。
int threshold;
//默认的容量，即默认的数组长度 16
static final int DEFAULT_INITIAL_CAPACITY = 1 << 4;
final float loadFactor;
//HashMap 中默认负载因子为 0.75
static final float DEFAULT_LOAD_FACTOR = 0.75f;
//最大的容量，即数组可定义的最大长度 
static final int MAXIMUM_CAPACITY = 1 << 30;

//实际存储的键值对个数
transient int size;
//用于迭代防止结构性破坏的标量
transient int modCount;

//这就是上述提到的数组，数组的元素都是 Node 类型，数组中的每个 Node 元素都是一个链表的头结点，
//通过它可以访问连接在其后面的所有结点。其实你也应该发现，上述的容量指的就是这个数组的长度。
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

1. hash函数实现：高16bit不变，低16bit和高16bit做了一个异或
2. (n-1)&hash: n 表示table的大小，即是取hash的低（n-1）位作为index

## put函数实现

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

## get函数实现

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

## resize函数

构造hash表时，如果不指明初始大小，默认大小为16（即Node数组大小16），
如果Node[]数组中的元素达到（填充比*Node.length）重新调整HashMap大小 变为原来2倍大小,扩容很耗时

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
        //第一次初始化表
        else if (oldThr > 0) // initial capacity was placed in threshold
            newCap = oldThr;
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
            for (int j = 0; j < oldCap; ++j) {
                Node<K,V> e;
                if ((e = oldTab[j]) != null) {
                    oldTab[j] = null;
                    if (e.next == null)
                        newTab[e.hash & (newCap - 1)] = e;
                    else if (e instanceof TreeNode)
                        ((TreeNode<K,V>)e).split(this, newTab, j, oldCap);
                    else { // preserve order
                        Node<K,V> loHead = null, loTail = null;
                        Node<K,V> hiHead = null, hiTail = null;
                        Node<K,V> next;
                        do {
                            next = e.next;
                            if ((e.hash & oldCap) == 0) {
                                if (loTail == null)
                                    loHead = e;
                                else
                                    loTail.next = e;
                                loTail = e;
                            }
                            else {
                                if (hiTail == null)
                                    hiHead = e;
                                else
                                    hiTail.next = e;
                                hiTail = e;
                            }
                        } while ((e = next) != null);
                        if (loTail != null) {
                            loTail.next = null;
                            newTab[j] = loHead;
                        }
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

## java8中解决冲突的改变

利用红黑树替换链表，将时间复杂度变为O(1)+O(logn)

## 面试题

1、hashmap中的键为自定义的类型。放入 HashMap 后，我们在外部把某一个 key 的属性进行更改，然后我们再用这个 key 从 HashMap 里取出元素，这时候 HashMap 会返回什么？

答：null

2、加载因子（默认0.75）：为什么需要使用加载因子，为什么需要扩容呢

因为如果填充比很大，说明利用的空间很多，如果一直不进行扩容的话，链表就会越来越长，这样查找的效率很低，因为链表的长度很大（当然最新版本使用了红黑树后会改进很多），扩容之后，将原来链表数组的每一个链表分成奇偶两个子链表分别挂在新链表数组的散列位置，这样就减少了每个链表的长度，增加查找效率

----

[Java HashMap工作原理及实现](http://yikun.github.io/2015/04/01/Java-HashMap%E5%B7%A5%E4%BD%9C%E5%8E%9F%E7%90%86%E5%8F%8A%E5%AE%9E%E7%8E%B0/)

https://www.cnblogs.com/yangming1996/p/7997468.html

https://blog.csdn.net/weixin_37356262/article/details/80543218
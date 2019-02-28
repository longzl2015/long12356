---

title: InterruptedException(译)

date: 2018-08-22 17:06:00

categories: [java]

tags: [java,InterruptedException]

---

InterruptedException 是对于初级java开发者是一个非常棘手的Exception。本文尝试以通俗易懂的方式介绍这个Exception。


<!--more-->

以下面的代码开始：

```java
while (true) {
  // Nothing
}
```

这段代码仅仅是无休止的运行cpu。
我们能够停止它吗？答案是无法停止。只有当整个JVM停止的时候(如Ctrl-C)，这段代码才会停止。

`除非java线程自己退出，否则无法以java代码的方式停止上述循环`。这是我们必须谨记的原则。


下面我们将 无限的loop 放入一个线程:

```java
Thread loop = new Thread(
  new Runnable() {
    @Override
    public void run() {
      while (true) {
      }
    }
  }
);
loop.start();
// Now how do we stop it?
```

因此，我们该怎么停止一个线程呢。

java是这样设计的:

> 每一个线程中拥有一个 flag 标志位，我们可以在线程外 set 这个标志位。线程可以周期性的检查这个标志位，一旦发现该标志位被set过，就可以停止线程的执行。

```java
Thread loop = new Thread(
  new Runnable() {
    @Override
    public void run() {
      while (true) {
        if (Thread.interrupted()) {
          break;
        }
        // Continue to do nothing
      }
    }
  }
);
loop.start();
loop.interrupt();
```

以上代码是 让线程停止的唯一方式。在上面的事例中，使用了两个方法。

- loop.interrupt(): 设置线程中的 flag 为 true。
- Thread.interrupted()：返回 flag 的值，并立即将 flag 设置为 false。

这种方式的设计是非常 ugly 的。如果线程内 没有使用Thread.interrupted()，即使 这个 flag 被置为 true，这个线程也不会结束。
简单来说就是 线程会忽略外部的interrupt()请求。外部请求线程停止运行，但是线程忽略了这个请求。

总结下我们目前学到的内容:

> 一个正确设计的线程 应该在 while 循环中检查 flag标志位，然后优雅的停止。如果代码没有检查flag(没有调用Thread.interrupted())，这就代表改程序只能通过 Ctrl-C来停止改程序。

> The code should either be bullet-fast or interruption-ready, nothing in between.


在JDK中，存在某些方法会检查 flag，如果 flag为true则会抛出 InterruptedException()。

如 Thread.sleep()方法。

```java
public static void sleep(long millis)
  throws InterruptedException {
  while (/* You still need to wait */) {
    if (Thread.interrupted()) {
      throw new InterruptedException();
    }
    // Keep waiting
  }
}
```

如果我们的代码是fast的，因为运行速度快，我们通常不需要考虑任何中断异常。但是如果我们的代码是slow的，我们就需要以某种方式的处理中断异常。

这就是`InterruptedException为checked exception`的原因。sleep()方法的设计告诉我们:

> 如果我们想要暂停一段时间，请确保代码是 interruption-ready。

下面的代码是正确的实践方式:

```java
try {
  Thread.sleep(100);
} catch (InterruptedException ex) {
  // Stop immediately and go home
}
```

当然，我们可以将这个异常抛向外层，让外层的代码去处理这个异常。这样做就必须要求某些人必须 catch 住这个异常，并做一些简单的处理。
最好的方式是，立即停止这个线程，因为这正是 flag标志位的设计初衷。如果一个InterruptedException被抛出，就意味着程序检测到了flag，这个线程应该尽快完成他正在做的工作。线程的拥有者不想在等待了，我们应该尊重拥有者的决定。

因此，当您捕获到InterruptedException时，您必须尽可能地总结您正在做的事情并退出。

现在，再次看下 Thread.sleep() 的代码:

```java
public static void sleep(long millis)
  throws InterruptedException {
  while (/* ... */) {
    if (Thread.interrupted()) {
      throw new InterruptedException();
    }
  }
}
```

需要注意的是 Thread.interrupted()  不仅返回了 flag 的值，同时将 flag 设置为了 false。因此一旦 InterruptedException is thrown，flag 会被重置。这个线程不再知道 拥有者曾经发送的中断请求。

线程的拥有者请求我们停止，Thread.sleep()检测到了这个请求，将flag重置并抛出InterruptedException异常。如果我们再一次调用 Thread.sleep()，Thread.sleep()就不会抛出异常了。因为 flag被重置了

因此 请不要忽略 InterruptedException 异常！！

下面的代码是我们大多数人的写法:

```java
try {
  Thread.sleep(100);
} catch (InterruptedException ex) {
  throw new RuntimeException(ex);
}
```

这看起来合乎逻辑，但是这并不能保证外层的人员会去停止任务并退出。外层人员很可能仅仅 catch 住这个异常，然后这个现场会继续执行。

我们应该通知外层人员我们 catch住了一个中断请求，而不是简单的抛出一个 runtime 异常。

比较合理的做法如下:

```java
try {
  Thread.sleep(100);
} catch (InterruptedException ex) {
  Thread.currentThread().interrupt(); // Here!
  throw new RuntimeException(ex);
}
```
我们将 flag再次设为 true。


我们可以获得更多的信息: Java Theory and Practice: Dealing With InterruptedException.


## 来源

https://www.yegor256.com/2015/10/20/interrupted-exception.html



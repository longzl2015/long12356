---

title: jdk8新特性之parallelStream

date: 2019-04-29 15:46:00

categories: [语言,java,jdk8,stream]

tags: [java]

---


下面的类简单演示了 parallelStream 并行原理

```java
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.concurrent.CopyOnWriteArraySet;
import java.util.concurrent.CountDownLatch;

public class TestTwo {

    public static void main(String[] args) throws Exception {
        System.out.println("Hello World!");
        // 构造一个10000个元素的集合
        List<Integer> list = new ArrayList<>();
        for (int i = 0; i < 10000; i++) {
            list.add(i);
        }
        // 统计并行执行list的线程
        Set<Thread> threadSet = new CopyOnWriteArraySet<>();
        // 并行执行
        list.parallelStream().forEach(integer -> {
            Thread thread = Thread.currentThread();
            // System.out.println(thread);
            // 统计并行执行list的线程
            threadSet.add(thread);
        });
        System.out.println("threadSet一共有" + threadSet.size() + "个线程");
        System.out.println("系统一个有" + Runtime.getRuntime().availableProcessors() + "个cpu");


        List<Integer> list1 = new ArrayList<>();
        List<Integer> list2 = new ArrayList<>();
        for (int i = 0; i < 100000; i++) {
            list1.add(i);
            list2.add(i);
        }
        Set<Thread> threadSetTwo1 = new CopyOnWriteArraySet<>();
        CountDownLatch countDownLatch = new CountDownLatch(2);
        Thread threadA = new Thread(() -> {
            list1.parallelStream().forEach(integer -> {
                Thread thread = Thread.currentThread();
                threadSetTwo1.add(thread);
            });
            countDownLatch.countDown();
        });
        Set<Thread> threadSetTwo2 = new CopyOnWriteArraySet<>();
        Thread threadB = new Thread(() -> {
            list2.parallelStream().forEach(integer -> {
                Thread thread = Thread.currentThread();
                threadSetTwo2.add(thread);
            });
            countDownLatch.countDown();
        });

        threadA.start();
        threadB.start();
        countDownLatch.await();
        System.out.println("threadSetTwo1一共有" + threadSetTwo1.size() + "个线程");
        System.out.println("threadSetTwo2一共有" + threadSetTwo2.size() + "个线程");

        System.out.println("---------------------------");
        System.out.println("threadSet:"+threadSet);
        System.out.println("threadSet1:"+threadSetTwo1);
        System.out.println("threadSet2:"+threadSetTwo2);
        System.out.println("---------------------------");
        //threadSetTwo.addAll(threadSet);
        //System.out.println(threadSetTwo);
        //System.out.println("threadSetTwo一共有" + threadSetTwo.size() + "个线程");
        //System.out.println("系统一个有" + Runtime.getRuntime().availableProcessors() + "个cpu");
    }
}
```

运行结果:

```text
Hello World!
threadSet一共有4个线程
系统一个有4个cpu
threadSetTwo1一共有4个线程
threadSetTwo2一共有4个线程
---------------------------
threadSet:[Thread[ForkJoinPool.commonPool-worker-1,5,main], Thread[ForkJoinPool.commonPool-worker-2,5,main], Thread[ForkJoinPool.commonPool-worker-3,5,main], Thread[main,5,main]]
threadSet1:[Thread[Thread-0,5,], Thread[ForkJoinPool.commonPool-worker-3,5,main], Thread[ForkJoinPool.commonPool-worker-1,5,main], Thread[ForkJoinPool.commonPool-worker-2,5,main]]
threadSet2:[Thread[ForkJoinPool.commonPool-worker-1,5,main], Thread[ForkJoinPool.commonPool-worker-3,5,main], Thread[ForkJoinPool.commonPool-worker-2,5,main], Thread[Thread-1,5,]]
---------------------------
```

从结果可以看出，ForkJoinPool 产生4个线程(一个调用线程+3个ForkJoinPool通用线程)。 为什么是生成 4个线程的原因是: ForkJoinPool 默认根据计算机的处理器数量来设定。


## parallelStream 缺点

默认情况下，parallelStream 使用的是 通用 ForkJoinPool。即 任何使用 parallelStream 方法的代码都公用 同一个 线程池。

当其中一个 任务阻塞时，会影响其他使用parallelStream的代码。

解决方案:

```java
class Tse{
    public static void main(String[] args){
      ForkJoinPool forkJoinPool = new ForkJoinPool(2);
      forkJoinPool.submit(() ->
          IntStream.range(1, 1_000_000).parallel().filter(PrimesPrint::isPrime).collect(toList())
      ).get();
    }
}
```


## 参考

https://blog.csdn.net/u011001723/article/details/52794455
---

title: JVM安全退出

date: 2018-08-26 15:46:00

categories: [语言,java,其他]

tags: [java]

---


## 使用关闭钩子的注意事项

- 关闭钩子本质上是一个线程（也称为Hook线程），对于一个JVM中注册的多个关闭钩子它们将会并发执行，所以JVM并不保证它们的执行顺序；由于是并发执行的，那么很可能因为代码不当导致出现竞态条件或死锁等问题，为了避免该问题，强烈建议在一个钩子中执行一系列操作。
- Hook线程会延迟JVM的关闭时间，这就要求在编写钩子过程中必须要尽可能的减少Hook线程的执行时间，避免hook线程中出现耗时的计算、等待用户I/O等等操作。
- 关闭钩子执行过程中可能被强制打断,比如在操作系统关机时，操作系统会等待进程停止，等待超时，进程仍未停止，操作系统会强制的杀死该进程，在这类情况下，关闭钩子在执行过程中被强制中止。
- 在关闭钩子中，不能执行注册、移除钩子的操作，JVM将关闭钩子序列初始化完毕后，不允许再次添加或者移除已经存在的钩子，否则JVM抛出 IllegalStateException。
- 不能在钩子调用System.exit()，否则卡住JVM的关闭过程，但是可以调用Runtime.halt()。
- Hook线程中同样会抛出异常，对于未捕捉的异常，线程的默认异常处理器处理该异常，不会影响其他hook线程以及JVM正常退出。


## 下一步

理清 @PreDestroy 、 hook 钩子 








## 测试

编写 简单的spring boot demo如下:

```java
@Component
public class AsyncService {
    @Async
    public void ss() {
        long l = System.currentTimeMillis() + 1000 * 600;
        boolean flag = false;
        try {
            while (l > System.currentTimeMillis()) {
                System.out.println(l);
                try {
                    System.out.println("当前时间1:" + System.currentTimeMillis());
                    Thread.sleep(1);
                    System.out.println("当前时间2:" + System.currentTimeMillis());
                } catch (InterruptedException e) {
                    e.printStackTrace();
                    flag = true;
                }

                if (flag) {
                    System.out.println("kill");
                }
            }
        }finally {
            System.out.println("finally 语句");
        }
    }
    
    @PreDestroy
    public void tt() {
        System.out.println("PreDestroy 语句");
    }
}
```

当程序在运行中时，使用 kill命令:

1. Thread.sleep() 程序会抛出一次中断异常 
2. finally 语句不会执行
3. PreDestroy注解 一定会执行

## 参考 

[java优雅的退出程序](https://jiyiren.github.io/2018/06/18/jvm-exit/)





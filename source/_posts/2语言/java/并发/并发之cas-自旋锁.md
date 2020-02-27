---

title: 并发之cas-自旋锁（转）

date: 2019-03-01 10:10:19

categories: [语言,java,并发]

tags: [并发,cas]

---

### 一、自旋锁提出的背景
由于在多处理器系统环境中有些资源因为其有限性，有时需要互斥访问（mutual exclusion），这时会引入锁的机制，只有获取了锁的进程才能获取资源访问。即是每次只能有且只有一个进程能获取锁，才能进入自己的临界区，同一时间不能两个或两个以上进程进入临界区，当退出临界区时释放锁。设计互斥算法时总是会面临一种情况，即没有获得锁的进程怎么办？通常有2种处理方式。一种是没有获得锁的调用者就一直循环在那里看是否该自旋锁的保持者已经释放了锁，这就是自旋锁，他不用将县城阻塞起来（NON-BLOCKING)；另一种是没有获得锁的进程就阻塞(BLOCKING)自己，请求OS调度另一个线程上处理器，这就是互斥锁。

### 二、自旋锁原理
跟互斥锁一样，一个执行单元要想访问被自旋锁保护的共享资源，必须先得到锁，在访问完共享资源后，必须释放锁。如果在获取自旋锁时，没有任何执行单元保持该锁，那么将立即得到锁；如果在获取自旋锁时锁已经有保持者，那么获取锁操作将自旋在那里，直到该自旋锁的保持者释放了锁。由此我们可以看出，自旋锁是一种比较低级的保护数据结构或代码片段的原始方式，这种锁可能存在两个问题：

**递归死锁**：试图递归地获得自旋锁必然会引起死锁：递归程序的持有实例在第二个实例循环，以试图获得相同自旋锁时，不会释放此自旋锁。在递归程序中使用自旋锁应遵守下列策略：递归程序决不能在持有自旋锁时调用它自己，也决不能在递归调用时试图获得相同的自旋锁。此外如果一个进程已经将资源锁定，那么，即使其它申请这个资源的进程不停地疯狂“自旋”,也无法获得资源，从而进入死循环。

**过多占用cpu资源**。如果不加限制，由于申请者一直在循环等待，因此自旋锁在锁定的时候,如果不成功,不会睡眠,会持续的尝试,单cpu的时候自旋锁会让其它process动不了. 因此，一般自旋锁实现会有一个参数限定最多持续尝试次数. 超出后, 自旋锁放弃当前time slice. 等下一次机会

由此可见，自旋锁比较适用于锁使用者保持锁时间比较短的情况。正是由于自旋锁使用者一般保持锁时间非常短，因此选择自旋而不是睡眠是非常必要的，自旋锁的效率远高于互斥锁。

### 三、Java CAS
CAS是一种系统原语（所谓原语属于操作系统用语范畴。原语由若干条指令组成的，用于完成一定功能的一个过程。primitive or atomic action 是由若干个机器指令构成的完成某种特定功能的一段程序，具有不可分割性·即原语的执行必须是连续的，在执行过程中不允许被中断）。CAS是Compare And Set的缩写。CAS有3个操作数，内存值V，旧的预期值A，要修改的新值B。当且仅当预期值A和内存值V相同时，将内存值V修改为B，否则什么都不做。

在x86 平台上，CPU提供了在指令执行期间对总线加锁的手段。CPU芯片上有一条引线#HLOCK pin，如果汇编语言的程序中在一条指令前面加上前缀"LOCK"，经过汇编以后的机器代码就使CPU在执行这条指令的时候把#HLOCK pin的电位拉低，持续到这条指令结束时放开，从而把总线锁住，这样同一总线上别的CPU就暂时不能通过总线访问内存了，保证了这条指令在多处理器环境中的原子性

sun.misc.Unsafe是JDK里面的一个内部类，这个类为JDK严格保护，因为他提供了大量的低级的内存操作和系统功能。如果因为错误的使用了这个类，不会有“异常”被扔出，甚至会造成JVM宕机。这也是为什么这个类的名字是Unsafe的原因。因此当使用这个类的时候，你一定要明白你在干什么。这个类中提供了3个CAS的操作

**方法名 解释**
compareAndSwapInt(Object object, long address, int expected, int newValue) 比较对象object的某个int型的属性（以地址的方式访问），如果他的数据值是expected，则设定为newValue，返回true；否则返回false

compareAndSwapLong(Object object, long address, long expected, long newValue) 比较对象object的某个long型的属性（以地址的方式访问），如果他的数据值是expected，则设定为newValue，返回true；否则返回false

compareAndSwapLong(Object object, long address, Object expected, Object newValue) 比较对象object的某个Object型的属性（以地址的方式访问），如果他的数据值是expected，则设定为newValue，返回true；否则返回false

### 四、Java自旋锁应用-原子包
Jdk1.5以后，提供了java.util.concurrent.atomic包，这个包里面提供了一组原子类。其基本的特性就是在多线程环境下，当有多个线程同时执行这些类的实例包含的方法时，具有排他性，即当某个线程进入方法，执行其中的指令时，不会被其他线程打断，而别的线程就像自旋锁一样，一直等到该方法执行完成，才由JVM从等待队列中选择一个另一个线程进入，这只是一种逻辑上的理解。实际上是借助硬件的相关指令来实现的，不会阻塞线程(或者说只是在硬件级别上阻塞了)。

其中的类可以分成4组

- AtomicBoolean，AtomicInteger，AtomicLong，AtomicReference
- AtomicIntegerArray，AtomicLongArray
- AtomicLongFieldUpdater，AtomicIntegerFieldUpdater，AtomicReferenceFieldUpdater
- AtomicMarkableReference，AtomicStampedReference，AtomicReferenceArray

AtomicInteger 例子(jdk1.8):

```java
public class AtomicInteger extends Number implements java.io.Serializable {
  // 内部调用 unsafe 实现自增操作
  public final int getAndIncrement() {
    return unsafe.getAndAddInt(this, valueOffset, 1);
  }
}
```

```java
public final class Unsafe {
  // 该方法实现了自旋操作。
  public final int getAndAddInt(Object var1, long var2, int var4) {
    int var5;
    do {
      // 调用 native 方法获取当前值
      var5 = this.getIntVolatile(var1, var2);
      // 调用 native 方法进行比较并赋值，若失败循环尝试。
    } while(!this.compareAndSwapInt(var1, var2, var5, var5 + var4));
    return var5;
  }
}
```



### 五、CAS实现原子操作的三大问题

在Java并发包中有一些并发框架也使用了自旋CAS的方式来实现原子操作，比如LinkedTransferQueue类的Xfer方法。CAS虽然很高效地解决了原子操作，但是CAS仍然存在三大问题。ABA问题，循环时间长开销大，以及只能保证一个共享变量的原子操作。

#### ABA问题
因为CAS需要在操作值的时候，检查值有没有发生变化，如果没有发生变化则更新，但是如果一个值原来是A，变成了B，又变成了A，那么使用CAS进行检查时会发现它的值没有发生变化，但是实际上却变化了。ABA问题的解决思路就是使用版本号。在变量前面追加上版本号，每次变量更新的时候把版本号加1，那么A→B→A就会变成1A→2B→3A。从Java 1.5开始，JDK的Atomic包里提供了一个类 AtomicStampedReference 来解决ABA问题。这个类的compareAndSet方法的作用是首先检查当前引用是否等于预期引用，并且检查当前标志是否等于预期标志，如果全部相等，则以原子方式将该引用和该标志的值设置为给定的更新值。

```java
public boolean compareAndSet(
  V expectedReference, // 预期引用
  V newReference, // 更新后的引用
  int expectedStamp, // 预期标志
  int newStamp // 更新后的标志
)
```

#### 循环时间长开销大
自旋CAS如果长时间不成功，会给CPU带来非常大的执行开销。如果JVM能支持处理器提供的pause指令，那么效率会有一定的提升。pause指令有两个作用：第一，它可以延迟流水线执行指令（de-pipeline），使CPU不会消耗过多的执行资源，延迟的时间取决于具体实现的版本，在一些处理器上延迟时间是零；第二，它可以避免在退出循环的时候因内存顺序冲突（Memory Order Violation）而引起CPU流水线被清空（CPU Pipeline Flush），从而提高CPU的执行效率。

#### 只能保证一个共享变量的原子操作
当对一个共享变量执行操作时，我们可以使用循环CAS的方式来保证原子操作，但是对多个共享变量操作时，循环CAS就无法保证操作的原子性，这个时候就可以用锁。还有一个取巧的办法，就是把多个共享变量合并成一个共享变量来操作。比如，有两个共享变量i＝2，j=a，合并一下ij=2a，然后用CAS来操作ij。从Java 1.5开始，JDK提供了AtomicReference类来保证引用对象之间的原子性，就可以把多个变量放在一个对象里来进行CAS操作。

### 六、volatile和synchronized的区别
volatile本质是在告诉jvm当前变量在寄存器（工作内存）中的值是不确定的，需要从主存中读取； synchronized则是锁定当前变量，只有当前线程可以访问该变量，其他线程被阻塞住。

volatile仅能使用在变量级别；synchronized则可以使用在变量、方法、和类级别的

volatile仅能实现变量的修改可见性，不能保证原子性；而synchronized则可以保证变量的修改可见性和原子性

volatile不会造成线程的阻塞；synchronized可能会造成线程的阻塞。

volatile标记的变量不会被编译器优化；synchronized标记的变量可以被编译器优化



————————————————
版权声明：本文为CSDN博主「归田」的原创文章，遵循 CC 4.0 BY-SA 版权协议，转载请附上原文出处链接及本声明。
原文链接：https://blog.csdn.net/qq924862077/article/details/68931622
---

title: tomcat优化

date: 2018-09-29 15:24:00

categories: [tomcat]

tags: [tomcat]

---

tomcat的优化。


<!--more-->


## 常见问题 

### tomcat 启动缓慢

> org.apache.catalina.util.SessionIdGeneratorBase.createSecureRandom Creation of SecureRandom instance for session ID generation using [SHA1PRNG] took [342,445] milliseconds.

**原因:**

Tomcat 7/8 都使用`org.apache.catalina.util.SessionIdGeneratorBase.createSecureRandom`类产生安全随机类SecureRandom的实例作为会话ID，
这里花去了342秒，也即接近6分钟。

tomcat使用的 SHA1PRNG 算法是基于SHA-1算法实现且保密性较强的伪随机数生成器。

在 SHA1PRNG 中，有一个种子产生器，它根据配置执行各种操作。

Linux 中的随机数可以从两个特殊的文件中产生，一个是 /dev/./urandom，另外一个是 /dev/random。
他们产生随机数的原理是利用当前系统的熵池来计算出固定一定数量的随机比特，然后将这些比特作为字节流返回。
熵池就是当前系统的环境噪音，熵指的是一个系统的混乱程度，系统噪音可以通过很多参数来评估，如内存的使用，文件的使用量，不同类型的进程数量等等。
如果当前环境噪音变化的不是很剧烈或者当前环境噪音很小，比如刚开机的时候，而当前需要大量的随机比特，这时产生的随机数的随机效果就不是很好了。

- /dev/random: 会阻塞当前的程序，直到根据熵池产生新的随机字节之后才返回
- /dev/./urandom: 不会阻塞，但产生的随机效果不好

SecureRandom generateSeed  默认使用 /dev/random 生成种子。
但是 /dev/random 是一个阻塞数字生成器，如果它没有足够的随机数据提供，它就一直等，这迫使 JVM 等待。
键盘和鼠标输入以及磁盘活动可以产生所需的随机性或熵。但在一个服务器缺乏这样的活动，可能会出现问题。

**解决方法:**

1. 命令行添加: `-Djava.security.egd=file:/dev/./urandom`

2. 在`$JAVA_PATH/jre/lib/security/java.security` 中更新为 `securerandom.source=file:/dev/./urandom`

## 参考

https://www.jb51.net/article/117086.html
https://www.cnblogs.com/chyg/p/6844737.html
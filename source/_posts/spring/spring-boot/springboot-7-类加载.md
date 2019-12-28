---

title: springboot-7-类加载

date: 2019-08-05 00:00:09

categories: [spring,springboot]

tags: [spring,springboot]

---



重写 第三方 jar 的 类文件.

https://dzone.com/articles/spring-boot-classloader-and-class-override



```
+--- spring-boot-loader-play-0.0.1-SNAPSHOT.jar
     +--- META-INF
     +--- BOOT-INF
     |    +--- classes                            # 1 - project classes
     |    |     +--- org.springframework.boot
     |    |     | \--- SpringBootBanner.class    # this is our fix
     |    |     | 
     |    |     +--- pl.dk.loaderplay
     |    |          \--- SpringBootLoaderApplication.class
     |    |
     |    +--- lib                                # 2 - nested jar libraries
     |          +--- javax.annotation-api-1.3.1
     |          +--- spring-boot-2.0.0.M7.jar     # original banner class inside
     |          \--- (...)
     |
     +--- org.springframework.boot.loader         # Spring Boot loader classes
          +--- JarLauncher.class
          +--- LaunchedURLClassLoader.class
          \--- (...)
```


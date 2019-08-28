---

title: request的获取

date: 2019-01-21 11:40:00

categories: [spring,其他]

tags: [spring,logback]

---

我们在编写代码的时候，有时候需要获取当前线程的request变量。本文简单介绍下，我目前已知的方式。

<!--more-->

## RequestContextHolder

RequestContextHolder类保存了 当前每一个线程的 RequestAttributes 变量，主要是通过 ThreadLocal来实现的。

RequestAttributes 变量有一个重要的实现类 ServletRequestAttributes，通过 ServletRequestAttributes 即可获取到当前线程的 request 信息。

> HttpServletRequest request = ((ServletRequestAttributes)requestAttributes).getRequest();
> HttpServletResponse response = ((ServletRequestAttributes)requestAttributes).getResponse();

## 方法参数

在controller的方法参数中添加  HttpServletRequest 变量即可。

```java
@RequestMapping("/method")
public void method(HttpServletRequest req) {
   // ...
}
```

## Autowire

还有更简单的方法: 自动注入

```java
@RequestMappin("/path")
public MyController {
  @Autowired
  private HttpServletRequest request;
}
```

[在Spring的bean中注入HttpServletRequest解密](https://www.cnblogs.com/kevin-yuan/p/5336124.html)


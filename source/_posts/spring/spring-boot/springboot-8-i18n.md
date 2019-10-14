---

title: springboot-8-i18n

date: 2019-10-14 09:00:06

categories: [spring,springboot]

tags: [springboot,i18n]

---

springboot 国际化支持。本文主要介绍国际化过程中比较重要的几个类。

<!--more-->

##LocaleResolver

区域解析器。主要用于获取和设置 Locale 信息。

该类主要有两个方法

- Locale resolveLocale(HttpServletRequest x) 
- void setLocale(HttpServletRequest x,  HttpServletResponse y, Locale z) 

在 controller 处理请求前，FrameworkServlet 会调用 LocaleResolver.resolveLocale() 方法。



LocaleResolver 有几个重要的子类。下面一一介绍。

### LocaleContextResolver

该类主要用于添加 Locale 的上下文支持。如 session基本和 cookie 级别。

添加了2个方法:

- LocaleContext resolveLocaleContext(HttpServletRequest x)
- void setLocaleContext(HttpServletRequest x,  HttpServletResponse y, LocaleContext z);

###AcceptHeaderLocaleResolver

AcceptHeaderLocaleResolver 是springboot 默认的LocaleResolver

LocaleResolver实现了 LocaleResolver 接口。

- 对于 LocaleResolver.resolveLocale() 的实现逻辑是 `通过检验HTTP请求的accept-language头部来获取Locale`

- 对于 LocaleResolver.setLocale()的实现逻辑是 `直接抛出UnsupportedOperationException异常`

总结来说: AcceptHeaderLocaleResolver通过检验HTTP请求的accept-language头部来解析Locale信息，而accept-language是由用户的web浏览器根据底层操作系统的区域设置进行设定。同时 AcceptHeaderLocaleResolver 不允许修改 Locale。

### SessionLocaleResolver

实现了LocaleContextResolver接口。

SessionLocaleResolver 该类的主要作用是添加 session 作用域范围的 Locale 信息。

当一个请求过来时，会从 session作用域中获取Locale信息。同时允许修改session作用域中的Locale信息。

###CookieLocaleResolver

同样实现了LocaleContextResolver接口。

与session类似，实现了 cookie 作用域的Locale信息。

### FixedLocaleResolver

一直使用固定的Local,改变Local 是不支持的。一旦启动时设定，则是固定的，无法改变Local

## LocaleChangeInterceptor

除了使用 LocaleResolver 来处理Locale信息之外，还可以通过添加LocaleChangeInterceptor来处理Locale信息。

LocaleChangeInterceptor 主要处理逻辑:

1. 通过解析 request 中的 Locale header参数，
2. 将header中的信息同步到 Locale对象中



当同时设置了 LocaleResolver 和 LocaleChangeInterceptor时，需要搞清楚 请求过程中 Locale 的先后处理逻辑:

1. 请求到达服务器
2. FrameworkServlet  调用 LocaleResolver 处理 Locale 信息
3. FrameworkServlet 委托 DispatcherServlet 处理请求
4. DispatcherServlet 调用 LocaleChangeInterceptor 来处理 Locale 信息。

从上面的流程中可以看出 LocaleChangeInterceptor 的结果会覆盖 LocaleResolver的结果。

## MessageSource

主要方法是 getMessage()。用于通过 code 获取对应的国际化字符串。

MessageSource 三个重要的实现类: 

- ReloadableResourceBundleMessageSource
- StaticMessageSource
- ResourceBundleMessageSource

简单介绍下 `ResourceBundleMessageSource`这个类的几个属性值：

- `alwaysUseMessageFormat`：默认值为false, 即默认不对返回信息做格式化处理。
- `useCodeAsDefaultMessage`：默认值为false，设置成true时，当无法通过`code`参数返回信息时，会默认将`code`的值进行返回。
- `fallbackToSystemLocale`：默认值为true，当根据`code`和`locale`参数无法获取对应的`ResourceBundle`时，会根据当前的环境设置获取`defaultLocale`，然后获取对应的`ResourceBundle`

## springboot配置

```yaml
#设置国际化配置文件存放在classpath:/i18n目录下
spring.messages.basename: i18n/messages
#设置加载资源的缓存失效时间，-1表示永久有效，默认为-1
spring.messages.cache-seconds: 3600
#设定message bundles编码方式，默认为UTF-8
#spring.messages.encoding=UTF-8
```



##参考

[聊聊国际化MessageSource](https://juejin.im/post/5cc25d6ef265da036d79c11a)

[Spring boot 国际化自动加载资源文件问题](https://segmentfault.com/a/1190000010757338)
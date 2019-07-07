---

title: web三大组件-filter

date: 2018-09-06 16:22:00

categories: [web,web三大组件]

tags: [web,filter]

---

filter 用于动态 拦截请求和响应。其可以在

- 在客户端的请求访问后端资源之前，拦截这些请求。
- 在服务器的响应发送回客户端之前，处理这些响应。

<!--more-->

## 简介

![](/images/web三大组件-filter/filter.png)

## 过滤器接口

```java
public interface Filter {
    /**
    * 创建之后立即执行，用来初始化一些参数
    * @param filterConfig
    * @throws ServletException
    */
    public void init(FilterConfig filterConfig) throws ServletException;

    /**
    * 实际的过滤处理逻辑
    * @param request
    * @param response
    * @param chain
    * @throws IOException
    * @throws ServletException
    */
    public void doFilter(ServletRequest request, ServletResponse response,
            FilterChain chain) throws IOException, ServletException;
    /**
    * 在关闭服务器时，对filter进行销毁和资源释放
    */
    public void destroy();
}
```

上面3个方法中，doFilter()最为重要: 服务器请求符合过滤范围的servlet和jsp页面都会执行该方法。
若不让该请求最终访问到资源，需要在最后执行 chain.doFilter()操作。
若需要让该请求最终访问到资源，则方法体中不能出现 chain.doFilter()操作。

## 关联的类介绍

### FilterConfig 

FilterConfig 与 ServletConfig 类似，拥有四个方法

- getInitParameter():获取初始化参数。
- getInitParameterNames():获取所有初始化参数的名称。
- getFilterName():获取过滤器的配置名称。
- getServletContext():获取ServletContext。

### FilterChain

该类仅一个方法 doFilter(), 该方法被FilterChain对象调用，表示对Filter过滤器过滤范围下的资源进行放行。

```java
public interface FilterChain {

    /**
     * Causes the next filter in the chain to be invoked, or if the calling
     * filter is the last filter in the chain, causes the resource at the end of
     * the chain to be invoked.
     *
     * @param request
     *            the request to pass along the chain.
     * @param response
     *            the response to pass along the chain.
     *
     * @throws IOException if an I/O error occurs during the processing of the
     *                     request
     * @throws ServletException if the processing fails for any other reason

     * @since 2.3
     */
    public void doFilter(ServletRequest request, ServletResponse response)
            throws IOException, ServletException;

}
```

### 过滤器执行顺序

对于 xml 配置模式: 在同一匹配url下，其执行顺序按照web.xml中的注册顺序。

由于 @WebFilter 没有 order 属性，因此只能通过在 web.xml 中配置相关参数来 order filter

### 过滤器拦截方式

过滤器有四种拦截方式！分别是：REQUEST、FORWARD、INCLUDE、ERROR。

#### REQUEST
该方式为默认的拦截方式.
直接访问目标资源时执行过滤器。包括：在地址栏中直接访问、表单提交、超链接、重定向，只要在地址栏中可以看到目标资源的路径，就是REQUEST；

#### FORWARD
转发访问执行过滤器。包括RequestDispatcher#forward()方法，`<jsp:forward>` 标签都是转发访问；

#### INCLUDE
包含访问执行过滤器。包括RequestDispatcher#include()方法，`<jsp:include>` 标签都是包含访问；

#### ERROR
当目标资源在web.xml中配置为<error-page>中时，并且真的出现了异常，转发到目标资源时，会执行过滤器。

## 创建过滤器

```java
@WebFilter(urlPatterns = "/*", displayName = "timeLogFilter", filterName = "timeLogFilter")
public class TimeLogFilter implements Filter {
    private static final Logger logger = LoggerFactory.getLogger(TimeLogFilter.class);

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {}

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain) throws IOException,
            ServletException {
        long time = System.currentTimeMillis();
        chain.doFilter(request, response);
        logger.debug("{}:\t {} ms ", ((HttpServletRequest) request).getRequestURI(), System.currentTimeMillis() - time);
    }

    @Override
    public void destroy() {}
}
```

## 常用的拦截器场景

1. 权限控制
2. 接口的耗时统计
3. 统计不同IP访问次数
4. 对非标准流编码的请求解码
5. 等等


## 拦截器注意点

1. 在filter中尽量不要使用流的访问获取参数，因为使用流后，servlet就会取不到请求参数了

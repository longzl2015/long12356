---

title: spring-5-DispatcherServlet

date: 2019-06-09 11:09:05

categories: [spring,springmvc]

tags: [springmvc,todo]

---


该章介绍了 DispatcherServlet 继承关系和 处理请求的过程。


<!--more-->

## DispatcherServlet 继承关系

下图为DispatcherServlet 完整的UML图。

![](/images/spring-6-DispatcherServlet/DispatcherServlet.png)

### HttpServlet

HttpServlet 完整UML图如下。

![](/images/spring-6-DispatcherServlet/HTTPServlet.png)

我们先从最底层的接口看起，最后再看HTTPServlet。

#### ServletConfig接口 

ServletConfig 是一个接口，定义了4个方法:  

- getInitParameter 
- getInitParameterNames
- getServletContext
- getServletName

#### Servlet接口 
Servlet 是一个接口，定义了5个方法: 

- destroy
- getServletConfig: 返回 ServletConfig 对象
- getServletInfo: 返回Servlet信息的字符串，如 作者、版本等
- init: 容器启动或者第一次请求Servlet时调用
- service: 该方法 处理所有的 http 请求。

#### GenericServlet

从名称就可以看出，GenericServlet 实现了一个通用的Servlet类。

他简单实现了绝大部分的接口，只留下一个 `void service(ServletRequest req, ServletResponse res)`抽象方法，由具体的子类实现。

#### HttpServlet

HttpServlet 实现了`void service(ServletRequest req, ServletResponse res)`方法。

将请求细分为7种http-method(doGet、doPost、doPut、doDelete等)。

- get: 用于请求资源
- head: 与get基本一致，区别在于服务器只返回HTTP头信息，不包含响应体
- post: 更新资源
- delete: 删除资源
- put: 局部更新资源
- options: 用于获取当前URL所支持的方法。是否支持 get、post等，非简单跨域访问就用到了该method。
- Trace: 用于Debug


### FrameworkServlet

![](/images/spring-6-DispatcherServlet/FrameworkServlet.png)

Aware接口: 实现该接口的bean能够从spring容器中获取对应的资源

#### EnvironmentAware接口
设置环境变量

- setEnvironment(*)

#### ApplicationContextAware接口
设置应用上下文

- setApplicationContext(*)

#### EnvironmentCapable接口
获取环境变量

- getEnvironment() 

#### HttpServletBean类

```java
public abstract class HttpServletBean extends HttpServlet implements EnvironmentCapable, EnvironmentAware {
    //...
    @Override
    public final void init() throws ServletException {

        // 加载 web.xml 中 DispatcherServlet 的 <init-param> 配置，
        // 将这些配置包装到Bean（这个bean默认是DispatcherServlet）
        PropertyValues pvs = new ServletConfigPropertyValues(getServletConfig(), this.requiredProperties);
        if (!pvs.isEmpty()) {
            try {
                BeanWrapper bw = PropertyAccessorFactory.forBeanPropertyAccess(this);
                ResourceLoader resourceLoader = new ServletContextResourceLoader(getServletContext());
                bw.registerCustomEditor(Resource.class, new ResourceEditor(resourceLoader, getEnvironment()));
                initBeanWrapper(bw);
                bw.setPropertyValues(pvs, true);
            }
            catch (BeansException ex) {
                if (logger.isErrorEnabled()) {
                    logger.error("Failed to set bean properties on servlet '" + getServletName() + "'", ex);
                }
                throw ex;
            }
        }

        //调用子类的initServletBean()
        initServletBean();
    }
}
```

#### FrameworkServlet类

- initServletBean() 初始化Spring上下文和子类信息
- service() 处理请求 针对每种httpMethod做些修改后，调用 processRequest()
- processRequest() 处理请求 获取本地信息和 RequestAttributes等
- doService 由子类完成


```java
public abstract class FrameworkServlet extends HttpServletBean implements ApplicationContextAware {
    //...
    @Override
    protected final void initServletBean() throws ServletException {
        getServletContext().log("Initializing Spring " + getClass().getSimpleName() + " '" + getServletName() + "'");
        if (logger.isInfoEnabled()) {
            logger.info("Initializing Servlet '" + getServletName() + "'");
        }
        long startTime = System.currentTimeMillis();

        try {
            // 初始化web应用上下文(即Spring容器上下文)
            this.webApplicationContext = initWebApplicationContext();
            // 调用子类 initFrameworkServlet
            initFrameworkServlet();
        }
        catch (ServletException | RuntimeException ex) {
            logger.error("Context initialization failed", ex);
            throw ex;
        }

        if (logger.isDebugEnabled()) {
            String value = this.enableLoggingRequestDetails ?
                    "shown which may lead to unsafe logging of potentially sensitive data" :
                    "masked to prevent unsafe logging of potentially sensitive data";
            logger.debug("enableLoggingRequestDetails='" + this.enableLoggingRequestDetails +
                    "': request parameters and headers will be " + value);
        }

        if (logger.isInfoEnabled()) {
            logger.info("Completed initialization in " + (System.currentTimeMillis() - startTime) + " ms");
        }
    }
    	
    protected WebApplicationContext initWebApplicationContext() {
        // 根上下文
        WebApplicationContext rootContext =
                WebApplicationContextUtils.getWebApplicationContext(getServletContext());
        WebApplicationContext wac = null;

        if (this.webApplicationContext != null) {
            // A context instance was injected at construction time -> use it
            wac = this.webApplicationContext;
            if (wac instanceof ConfigurableWebApplicationContext) {
                ConfigurableWebApplicationContext cwac = (ConfigurableWebApplicationContext) wac;
                if (!cwac.isActive()) {
                    // The context has not yet been refreshed -> provide services such as
                    // setting the parent context, setting the application context id, etc
                    if (cwac.getParent() == null) {
                        // The context instance was injected without an explicit parent -> set
                        // the root application context (if any; may be null) as the parent
                        cwac.setParent(rootContext);
                    }
                    configureAndRefreshWebApplicationContext(cwac);
                }
            }
        }
        if (wac == null) {
            // 通过 ContextAttribute 从根上下文获取 web上下文
            wac = findWebApplicationContext();
        }
        if (wac == null) {
            // 创建一个web上下文，以根上下文为parent
            wac = createWebApplicationContext(rootContext);
        }

        if (!this.refreshEventReceived) {
            // web上下文创建后会调用，Dispatcher实现了onRefresh
            synchronized (this.onRefreshMonitor) {
                onRefresh(wac);
            }
        }

        if (this.publishContext) {
            // 将新创建的web上下文设置到ServletContext中
            String attrName = getServletContextAttributeName();
            getServletContext().setAttribute(attrName, wac);
        }

        return wac;
    }
    
    protected final void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        long startTime = System.currentTimeMillis();
        Throwable failureCause = null;

        LocaleContext previousLocaleContext = LocaleContextHolder.getLocaleContext();
        LocaleContext localeContext = buildLocaleContext(request);

        RequestAttributes previousAttributes = RequestContextHolder.getRequestAttributes();
        ServletRequestAttributes requestAttributes = buildRequestAttributes(request, response, previousAttributes);

        WebAsyncManager asyncManager = WebAsyncUtils.getAsyncManager(request);
        asyncManager.registerCallableInterceptor(FrameworkServlet.class.getName(), new RequestBindingInterceptor());

        initContextHolders(request, localeContext, requestAttributes);

        try {
            doService(request, response);
        }
        catch (ServletException | IOException ex) {
            failureCause = ex;
            throw ex;
        }
        catch (Throwable ex) {
            failureCause = ex;
            throw new NestedServletException("Request processing failed", ex);
        }

        finally {
            resetContextHolders(request, previousLocaleContext, previousAttributes);
            if (requestAttributes != null) {
                requestAttributes.requestCompleted();
            }
            logResult(request, response, failureCause, asyncManager);
            publishRequestHandledEvent(request, response, startTime, failureCause);
        }
    }
}
```

### DispatcherServlet 类

- onRefresh() 由 FrameworkServlet 的 initWebApplicationContext方法调用
- doService() 实现 FrameworkServlet 的 doService 方法: 主要做一些请求的属性设置，然后调用 doDispatch()
- doDispatch() 通过 HandlerMapping 获取 Handler，再找到用于执行它的 HandlerAdapter，执行 Handler 后得到 ModelAndView ，ModelAndView 是连接“业务逻辑层”与“视图展示层”的桥梁，接下来就要通过 ModelAndView 获得 View，再通过它的 Model 对 View 进行渲染

```java
public class DispatcherServlet extends FrameworkServlet {
    //..
    
    @Override
    protected void onRefresh(ApplicationContext context) {
        initStrategies(context);
    }
    
    /**
     * Initialize the strategy objects that this servlet uses.
     * <p>May be overridden in subclasses in order to initialize further strategy objects.
     */
    protected void initStrategies(ApplicationContext context) {
        
        // Resolver 主要通过修改http的请求(cookie、session、head)达到各种目的
        initMultipartResolver(context);// MultipartResolver: 处理文件上传
        initLocaleResolver(context);// LocaleResolver: 处理多语言环境
        initThemeResolver(context);// ThemeResolver: 处理主题风格
        
        // 从Spring容器中查找 HandlerMapping 实例列表
        initHandlerMappings(context);
        // 从Spring容器中查找 HandlerAdapters 实例列表
        initHandlerAdapters(context);
        // 从Spring容器中查找 HandlerExceptionResolvers 实例
        initHandlerExceptionResolvers(context);
        // 从Spring容器中查找 RequestToViewNameTranslator 实例
        initRequestToViewNameTranslator(context);
        // 从Spring容器中查找 ViewResolvers 实例
        initViewResolvers(context);
        // 从Spring容器中查找 FlashMapManager 实例
        initFlashMapManager(context);
    }
    
    @Override
    protected void doService(HttpServletRequest request, HttpServletResponse response) throws Exception {
        logRequest(request);

        // Keep a snapshot of the request attributes in case of an include,
        // to be able to restore the original attributes after the include.
        Map<String, Object> attributesSnapshot = null;
        if (WebUtils.isIncludeRequest(request)) {
            attributesSnapshot = new HashMap<>();
            Enumeration<?> attrNames = request.getAttributeNames();
            while (attrNames.hasMoreElements()) {
                String attrName = (String) attrNames.nextElement();
                if (this.cleanupAfterInclude || attrName.startsWith(DEFAULT_STRATEGIES_PREFIX)) {
                    attributesSnapshot.put(attrName, request.getAttribute(attrName));
                }
            }
        }

        // Make framework objects available to handlers and view objects.
        request.setAttribute(WEB_APPLICATION_CONTEXT_ATTRIBUTE, getWebApplicationContext());
        request.setAttribute(LOCALE_RESOLVER_ATTRIBUTE, this.localeResolver);
        request.setAttribute(THEME_RESOLVER_ATTRIBUTE, this.themeResolver);
        request.setAttribute(THEME_SOURCE_ATTRIBUTE, getThemeSource());

        if (this.flashMapManager != null) {
            FlashMap inputFlashMap = this.flashMapManager.retrieveAndUpdate(request, response);
            if (inputFlashMap != null) {
                request.setAttribute(INPUT_FLASH_MAP_ATTRIBUTE, Collections.unmodifiableMap(inputFlashMap));
            }
            request.setAttribute(OUTPUT_FLASH_MAP_ATTRIBUTE, new FlashMap());
            request.setAttribute(FLASH_MAP_MANAGER_ATTRIBUTE, this.flashMapManager);
        }

        try {
            doDispatch(request, response);
        }
        finally {
            if (!WebAsyncUtils.getAsyncManager(request).isConcurrentHandlingStarted()) {
                // Restore the original attribute snapshot, in case of an include.
                if (attributesSnapshot != null) {
                    restoreAttributesAfterInclude(request, attributesSnapshot);
                }
            }
        }
    }
    
    protected void doDispatch(HttpServletRequest request, HttpServletResponse response) throws Exception {
        HttpServletRequest processedRequest = request;
        HandlerExecutionChain mappedHandler = null;
        boolean multipartRequestParsed = false;
        // 获取当前请求的WebAsyncManager，如果没找到则创建并与请求关联
        WebAsyncManager asyncManager = WebAsyncUtils.getAsyncManager(request);
        try {
            ModelAndView mv = null;
            Exception dispatchException = null;
            try {
                // 检查是否有 Multipart，有则将请求转换为 Multipart 请求
                processedRequest = checkMultipart(request);
                multipartRequestParsed = (processedRequest != request);
                // 遍历所有的 HandlerMapping 找到与请求对应的 Handler，并将其与一堆拦截器封装到 HandlerExecution 对象中。
                mappedHandler = getHandler(processedRequest);
                if (mappedHandler == null || mappedHandler.getHandler() == null) {
                    noHandlerFound(processedRequest, response);
                    return;
                }
                // 遍历所有的 HandlerAdapter，找到可以处理该 Handler 的 HandlerAdapter
                HandlerAdapter ha = getHandlerAdapter(mappedHandler.getHandler());
                // 处理 last-modified 请求头 
                String method = request.getMethod();
                boolean isGet = "GET".equals(method);
                if (isGet || "HEAD".equals(method)) {
                    long lastModified = ha.getLastModified(request, mappedHandler.getHandler());
                    if (new ServletWebRequest(request, response).checkNotModified(lastModified) && isGet) {
                        return;
                    }
                }
                // 遍历拦截器，执行它们的 preHandle() 方法
                if (!mappedHandler.applyPreHandle(processedRequest, response)) {
                    return;
                }
                try {
                    // 执行实际的处理程序
                    mv = ha.handle(processedRequest, response, mappedHandler.getHandler());
                } finally {
                    if (asyncManager.isConcurrentHandlingStarted()) {
                        return;
                    }
                }
                applyDefaultViewName(request, mv);
                // 遍历拦截器，执行它们的 postHandle() 方法
                mappedHandler.applyPostHandle(processedRequest, response, mv);
            } catch (Exception ex) {
                dispatchException = ex;
            }
            // 处理执行结果，是一个 ModelAndView 或 Exception，然后进行渲染
            processDispatchResult(processedRequest, response, mappedHandler, mv, dispatchException);
        } catch (Exception ex) {
        } catch (Error err) {
        } finally {
            if (asyncManager.isConcurrentHandlingStarted()) {
                // 遍历拦截器，执行它们的 afterCompletion() 方法  
                mappedHandler.applyAfterConcurrentHandlingStarted(processedRequest, response);
                return;
            }
            // Clean up any resources used by a multipart request.
            if (multipartRequestParsed) {
                cleanupMultipart(processedRequest);
            }
        }
    }
   	
}
```




## 其他资料
[Http get与pos的区别](https://blog.csdn.net/ysh1042436059/article/details/80985574)
[springMvc](https://www.cnblogs.com/tengyunhao/p/7518481.html)

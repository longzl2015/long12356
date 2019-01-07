---

title: spring(6)-DispatcherServlet

date: 2018-10-19 13:33:00

categories: [springmvc]

tags: [springmvc,todo]

---


ff


<!--more-->

## DispatcherServlet继承关系

![](spring(6)-DispatcherServlet/DispatcherServlet.png)

### 首先看 HttpServlet

![](spring(6)-DispatcherServlet/HTTPServlet.png)

ServletConfig 定义4个方法:  

- getInitParameter
- getInitParameterNames
- getServletContext
- getServletName

Servlet 定义了5个方法: 

- destroy
- getServletConfig
- getServletInfo
- init
- service: 该方法 处理所有的 http 请求。

GenericServlet: 

- 实现了一个通用的Servlet类
- 仍保留一个抽象方法 `void service(ServletRequest req, ServletResponse res)`

HttpServlet: 将请求细分为7种http-method(doGet、doPost、doPut、doDelete等)。

- get: 用于请求资源
- head: 与get基本一致，区别在于服务器只返回HTTP头信息，不包含响应体
- post: 更新资源
- delete: 删除资源
- put: 局部更新资源
- options: 用于获取当前URL所支持的方法。是否支持 get、post等
- Trace: 用于Debug


### FrameworkServlet

![](spring(6)-DispatcherServlet/FrameworkServlet.png)

Aware: 实现该接口的bean能够从spring容器中获取对应的资源

EnvironmentAware接口: 设置环境变量

- setEnvironment(*)

ApplicationContextAware接口: 设置应用上下文

- setApplicationContext(*)

EnvironmentCapable接口: 获取环境变量

- getEnvironment() 

HttpServletBean类: 

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

FrameworkServlet类:

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
            // 将新创建的容器上下文设置到ServletContext中
            String attrName = getServletContextAttributeName();
            getServletContext().setAttribute(attrName, wac);
        }

        return wac;
    }
}
```




## 其他资料
[Http get与pos的区别](https://blog.csdn.net/ysh1042436059/article/details/80985574)
[springMvc](https://www.cnblogs.com/tengyunhao/p/7518481.html)

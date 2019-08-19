---

title: spring-security架构

date: 2019-06-10 11:09:01

categories: [springboot,springsecurity]

tags: [SpringSecurity,todo]

---





<!--more-->



spring 过滤链 顺序。具体顺序可以通过 springboot 启动时 DefaultSecurityFilterChain 打印的日志查看

```text
org.springframework.security.web.context.request.async.WebAsyncManagerIntegrationFilter
org.springframework.security.web.context.SecurityContextPersistenceFilter
org.springframework.security.web.header.HeaderWriterFilter
org.springframework.security.web.authentication.logout.LogoutFilter
org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter
org.springframework.security.web.session.ConcurrentSessionFilter
org.springframework.security.web.savedrequest.RequestCacheAwareFilter
org.springframework.security.web.servletapi.SecurityContextHolderAwareRequestFilter
org.springframework.security.web.authentication.AnonymousAuthenticationFilter
org.springframework.security.web.session.SessionManagementFilter
org.springframework.security.web.access.ExceptionTranslationFilter
org.springframework.security.web.access.intercept.FilterSecurityInterceptor
```

## 参考

[springSecurity原理](http://www.importnew.com/20612.html)
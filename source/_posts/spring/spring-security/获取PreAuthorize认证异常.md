---
title: 获取PreAuthorize认证异常
date: 2019-06-10 11:09:07
tags: 
  - SpringSecurity
categories: [spring,springsecurity]
---

```java
@PreAuthorize("hasAuthority('ROLE_ZZZZ')")
public ModelAndView getUserInfo( @PathVariable long userId ){
    ModelAndView mv = new ModelAndView();
    User u = userService.findUser( userId );
    mv.addObject("user", u);
    return mv;
}
```

当 `hasAuthority('ROLE_ZZZZ')`认证失败时，会 throw AccessDeniedException 。 

原本的期望是 该异常被自定义的 AccessDeniedHandler处理。但发现并非如此，他会直接抛出500异常。

在google 找到答案：

https://stackoverflow.com/questions/21171882/spring-security-ignoring-access-denied-handler-with-method-level-security



The `access-denied-handler` is used by the `ExceptionTranslationFilter` in case of an `AccessDeniedException`. However, the `org.springframework.web.servlet.DispatcherServlet` was first trying the handle the exception. Specifically, I had a `org.springframework.web.servlet.handler.SimpleMappingExceptionResolver` defined with a `defaultErrorView`. Consequently, the `SimpleMappingExceptionResolver` was consuming the exception by redirecting to an appropriate view, and consequently, there was no exception left to bubble up to the `ExceptionTranslationFilter`.

The fix was rather simple. Configure the `SimpleMappingExceptionResolver` to ignore all `AccessDeniedException`.

```
<bean class="org.springframework.web.servlet.handler.SimpleMappingExceptionResolver">
    <property name="defaultErrorView" value="uncaughtException" />
    <property name="excludedExceptions" value="org.springframework.security.access.AccessDeniedException" />

    <property name="exceptionMappings">
        <props>
            <prop key=".DataAccessException">dataAccessFailure</prop>
            <prop key=".NoSuchRequestHandlingMethodException">resourceNotFound</prop>
            <prop key=".TypeMismatchException">resourceNotFound</prop>
            <prop key=".MissingServletRequestParameterException">resourceNotFound</prop>
        </props>
    </property>
</bean>
```

Now, whenever an `AccessDeniedException` is thrown, the resolver ignores it and allows it to bubble up the stack to the `ExceptionTranslationFilter` which then calls upon the `access-denied-handler` to handle the exception.




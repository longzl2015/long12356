---

title: mock几个关键类

date: 2019-02-14 13:25:00

categories: [springboot,mock]

tags: [mock]

---


本文用于记录 使用 mock时，遇到的几个重要的 java 类或者注解



<!--more-->


## MockMvcAutoConfiguration 自动配置类

当 环境中没有 `SpringBootMockMvcBuilderCustomizer`实例时， 根据配置信息生成一个 SpringBootMockMvcBuilderCustomizer 实例。
当 环境中没有 `MockMvcBuilder`实例时， 根据配置信息生成一个 MockMvcBuilder 实例。
当 环境中没有 `mockmvc`实例时， 根据配置信息生成一个 MockMvc 实例。

- SpringBootMockMvcBuilderCustomizer: 设置 全局printHandler 和 添加 addFilter
- MockMvcBuilder: MockMvc 的建造器
- MockMvc: 支持 SpringMvc test的主入口 

## FixMethodOrder 注解

FixMethodOrder 注解 能够保证Test注解的方法的执行顺序。

- MethodSorters.NAME_ASCENDING
- MethodSorters.JVM
- MethodSorters.DEFAULT

## AutoConfigureMockMvc注解

自动导入 以下类:

```text
org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc=\
org.springframework.boot.test.autoconfigure.web.servlet.MockMvcAutoConfiguration,\
org.springframework.boot.test.autoconfigure.web.servlet.MockMvcSecurityAutoConfiguration,\
org.springframework.boot.test.autoconfigure.web.servlet.MockMvcWebClientAutoConfiguration,\
org.springframework.boot.test.autoconfigure.web.servlet.MockMvcWebDriverAutoConfiguration
```

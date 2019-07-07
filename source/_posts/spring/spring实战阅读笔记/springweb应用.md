---

title: springweb应用

date: 2018-10-25 19:38:00

categories: [springboot,spring实战阅读笔记]

tags: [spring]

---





<!--more-->


## spring 请求过程

![](/images/springweb应用/请求过程.png)

### 第一步
请求离开浏览器，携带用户请求的信息前往 DispatcherServlet

### 第二步
DispatcherServlet 是一个前端控制器，任务是将请求发送给指定的 controller 方法。
因此 DispatcherServlet 需要通过查询 处理器映射 来确定请求的下一站是什么。

### 第三步
通过 处理器映射 确定好目的地后，DispatcherServlet 会将请求发送给指定的控制器

### 第四步

控制器在完成逻辑处理后，通常会产生一些信息(model)。之后，将 产生的model 和 指定的视图名 一起发回给 DispatcherServlet。

### 第五步

DispatcherServlet 通过视图解析器（view resolver）将 逻辑视图名 匹配为一个特定的视图实现。

### 第六步

DispatcherServlet 将模型数据交付给视图，渲染出最后的结果。

### 第七步

通过响应对象将 最终的渲染结果传递到客户端。

## spring MVC 基本环境搭建

详见 《spring实战》章节5.1.2 


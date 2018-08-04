---
title: Request 和 response
tags: 
  - web
categories:
  - web
---

主要的与请求和接口相关的类及接口

| 方    法                   | 说    明                                |
| -------------------------- | --------------------------------------- |
| ServletInputStream         | Servlet的输入流                         |
| ServletOutputStream        | Servlet的输出流                         |
| ServletRequest             | 代表Servlet请求的一个接口               |
| ServletResponse            | 代表Servlet响应的一个接口               |
| ServletRequestWrapper      | 该类实现ServletRequest接口              |
| ServletResponseWrapper     | 该类实现ServletResponse接口             |
| HttpServletRequest         | 继承了ServletRequest接口，表示HTTP请求  |
| HttpServletResponse        | 继承了ServletResponse接口，表示HTTP请求 |
| HttpServletRequestWrapper  | HttpServletRequest的实现                |
| HttpServletResponseWrapper | HttpServletResponse的实现               |

在上面给出的类和接口中，最主要的是HttpServletRequest和HttpServletResponse接口

## 1. HttpServletRequest

HttpServletRequest接口最常用的方法就是获得请求中的参数，这些参数一般是客户端表单中的数据。同时，HttpServletRequest接口可以获取由客户端传送的名称，也可以获取产生请求并且接收请求的服务器端主机名及IP地址，还可以获取客户端正在使用的通信协议等信息。

接口HttpServletRequest的常用方法:

| 方    法                        | 说    明                                                     |
| ------------------------------- | ------------------------------------------------------------ |
| getAttributeNames()             | 返回当前请求的所有属性的名字集合                             |
| getAttribute(String name)       | 返回name指定的属性值                                         |
| getCookies()                    | 返回客户端发送的Cookie                                       |
| getsession()                    | 返回和客户端相关的session，如果没有给客户端分配session，则返回null |
| getsession(boolean create)      | 返回和客户端相关的session，如果没有给客户端分配session，则创建一个session并返回 |
| getParameter(String name)       | 获取请求中的参数，该参数是由name指定的                       |
| getParameterValues(String name) | 返回请求中的参数值，该参数值是由name指定的                   |
| getCharacterEncoding()          | 返回请求的字符编码方式                                       |
| getContentLength()              | 返回请求体的有效长度                                         |
| getInputStream()                | 获取请求的输入流中的数据                                     |
| getMethod()                     | 获取发送请求的方式，如get、post                              |
| getParameterNames()             | 获取请求中所有参数的名字                                     |
| getProtocol()                   | 获取请求所使用的协议名称                                     |
| getReader()                     | 获取请求体的数据流                                           |
| getRemoteAddr()                 | 获取客户端的IP地址                                           |
| getRemoteHost()                 | 获取客户端的名字                                             |
| getServerName()                 | 返回接受请求的服务器的名字                                   |
| getServerPath()                 | 获取请求的文件的路径                                         |

 

## 2. HttpServletResponse

在Servlet中，当服务器响应客户端的一个请求时，就要用到HttpServletResponse接口。设置响应的类型可以使用setContentType()方法。发送字符数据，可以使用getWriter()返回一个对象。

接口HttpServletResponse的常用方法

| 方    法                             | 说    明                                 |
| ------------------------------------ | ---------------------------------------- |
| addCookie(Cookie cookie)             | 将指定的Cookie加入到当前的响应中         |
| addHeader(String name,String value)  | 将指定的名字和值加入到响应的头信息中     |
| containsHeader(String name)          | 返回一个布尔值，判断响应的头部是否被设置 |
| encodeURL(String url)                | 编码指定的URL                            |
| sendError(int sc)                    | 使用指定状态码发送一个错误到客户端       |
| sendRedirect(String location)        | 发送一个临时的响应到客户端               |
| setDateHeader(String name,long date) | 将给出的名字和日期设置响应的头部         |
| setHeader(String name,String value)  | 将给出的名字和值设置响应的头部           |
| setStatus(int sc)                    | 给当前响应设置状态码                     |
| setContentType(String ContentType)   | 设置响应的MIME类型                       |
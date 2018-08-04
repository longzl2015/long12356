---
title: forward和redirect的区别
date: 2015-08-19 13:22:58
tag: [forward,redirect]
categories: springMVC

---

### 1.从地址栏显示来说  
forward是服务器请求资源,服务器直接访问目标地址的URL,把那个URL的响应内容读取过来,然后把这些内容再发给浏览器.浏览器根本不知道服务器发送的内容从哪里来的,所以它的地址栏还是原来的地址.
redirect是服务端根据逻辑,发送一个状态码,告诉浏览器重新去请求那个地址.所以地址栏显示的是新的URL.

### 2.从数据共享来说
forward:转发页面和转发到的页面可以共享request里面的数据.
redirect:不能共享数据.

### 3.从运用地方来说  
forward:一般用于用户登陆的时候,根据角色转发到相应的模块.
redirect:一般用于用户注销登陆时返回主页面和跳转到其它的网站等.

### 4.从效率来说  
forward:高.
redirect:低.

## 本质区别

### 解释一　　

一句话，转发是服务器行为，重定向是客户端行为。为什么这样说呢，这就要看两个动作的工作流程：

转发过程：客户浏览器发送http请求----》web服务器接受此请求--》调用内部的一个方法在容器内部完成请求处理和转发动作----》将目标资源发送给客户；在这里，转发的路径必须是同一个web容器下的url，其不能转向到其他的web路径上去，中间传递的是自己的容器内的request。在客户浏览器路径栏显示的仍然是其第一次访问的路径，也就是说客户是感觉不到服务器做了转发的。转发行为是浏览器只做了一次访问请求。

重定向过程：客户浏览器发送http请求----》web服务器接受后发送302状态码响应及对应新的location给客户浏览器--》客户浏览器发现是302响应，则自动再发送一个新的http请求，请求url是新的location地址----》服务器根据此请求寻找资源并发送给客户。在这里 location可以重定向到任意URL，既然是浏览器重新发出了请求，则就没有什么request传递的概念了。在客户浏览器路径栏显示的是其重定向的路径，客户可以观察到地址的变化的。重定向行为是浏览器做了至少两次的访问请求的。

### 解释二

重定向，其实是两次request,
第一次，客户端request A,服务器响应，并response回来，告诉浏览器，你应该去B。这个时候IE可以看到地址变了，而且历史的回退按钮也亮了。重定向可以访问自己web应用以外的资源。在重定向的过程中，传输的信息会被丢失。

请求转发,是服务器内部把对一个request/response的处理权，移交给另外一个
对于客户端而言，它只知道自己最早请求的那个A，而不知道中间的B，甚至C、D。 传输的信息不会丢失。

## 请求重定向与请求转发的比较

尽管HttpServletResponse.sendRedirect方法和RequestDispatcher.forward方法都可以让浏览器获得另外一个URL所指向的资源，但两者的内部运行机制有着很大的区别。下面是HttpServletResponse.sendRedirect方法实现 的请求重定向与RequestDispatcher.forward方法实现的请求转发的总结比较：

（1）RequestDispatcher.forward方法只能将请求转发给同一个WEB应用中的组件；而 HttpServletResponse.sendRedirect 方法不仅可以重定向到当前应用程序中的其他资源，还可以重定向到同一个站点上的其他应用程序中的资源，甚至是使用绝对URL重定向到其他站点的资源。如果 传递给HttpServletResponse.sendRedirect 方法的相对URL以“/”开头，它是相对于整个WEB站点的根目录；如果创建RequestDispatcher对象时指定的相对URL以“/”开头，它 是相对于当前WEB应用程序的根目录。

（2）调用HttpServletResponse.sendRedirect方法重定向的访问过程结束后，浏览器地址栏中显示的URL会发生改变，由初 始的URL地址变成重定向的目标URL；而调用RequestDispatcher.forward 方法的请求转发过程结束后，浏览器地址栏保持初始的URL地址不变。

（3）HttpServletResponse.sendRedirect方法对浏览器的请求直接作出响应，响应的结果就是告诉浏览器去重新发出对另外一 个URL的 访问请求，这个过程好比有个绰号叫“浏览器”的人写信找张三借钱，张三回信说没有钱，让“浏览器”去找李四借，并将李四现在的通信地址告诉给了“浏览 器”。于是，“浏览器”又按张三提供通信地址给李四写信借钱，李四收到信后就把钱汇给了“浏览器”。可见，“浏览器”一共发出了两封信和收到了两次回复， “浏览器”也知道他借到的钱出自李四之手。RequestDispatcher.forward方 法在服务器端内部将请求转发给另外一个资源，浏览器只知道发出了请求并得到了响应结果，并不知道在服务器程序内部发生了转发行为。这个过程好比绰号叫“浏 览器”的人写信找张三借钱，张三没有钱，于是张三找李四借了一些钱，甚至还可以加上自己的一些钱，然后再将这些钱汇给了“浏览器”。可见，“浏览器”只发 出了一封信和收到了一次回复，他只知道从张三那里借到了钱，并不知道有一部分钱出自李四之手。

（4）RequestDispatcher.forward方法的调用者与被调用者之间共享相同的request对象和response对象，它们属于同 一个访问请求和响应过程；而HttpServletResponse.sendRedirect方法调用者与被调用者使用各自的request对象和 response对象，它们属于两个独立的访问请求和响应过程。对于同一个WEB应用程序的内部资源之间的跳转，特别是跳转之前要对请求进行一些前期预处 理，并要使用HttpServletRequest.setAttribute方法传递预处理结果，那就应该使用 RequestDispatcher.forward方法。不同WEB应用程序之间的重定向，特别是要重定向到另外一个WEB站点上的资源的情况，都应该 使用HttpServletResponse.sendRedirect方法。

（5）无论是RequestDispatcher.forward方法，还是HttpServletResponse.sendRedirect方法，在调用它们之前，都不能有内容已经被实际输出到了客户端。如果缓冲区中已经有了一些内容，这些内容将被从缓冲区中清除。


参考：
---
[forward和redirect的区别](http://zhulin902.iteye.com/blog/939049)

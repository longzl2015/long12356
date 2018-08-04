---
title: hexo-多说使用配置
date: 2015-08-14 09:09:28
tags: [hexo,多说]
categories: hexo

---

## 创建应用获取通用代码
首先进入多说网站，注册用户。可以使用第三方登录。
接着就是需要创建一个应用。点击“我要安装”，来创建应用。

![点击我要安装](http://i.imgur.com/ZRSuztc.jpg)

然后会跳到一个页面，里面有需要的通用代码。

![多说的管理系统](http://i.imgur.com/z8VLarb.jpg)


## 修改文件
- 非jacman主题：
在hexo/_config.yml文件里的添加duoshuo_shortname:

> 	###Disqus  disqus
> 	disqus_shortname:
> 	duosuo_shortname: sunhongtao

- jacman主题：
在Hexo\themes\jacman/_config.yml文件里：

> 	#### Comment
> 	duoshuo_shortname:  longzl  ## e.g. sunhongtao   your duoshuo short name.
> 	disqus_shortname:    ## e.g. wuchong   your disqus short name.

**注：**
这里的duosho_shortname _不是你的用户名_。而是在你创建应用之后出现的
那个名字。例如这个：http://longzl.duoshuo.com/admin/tools/
其中longzl就是我们duoshuo_shortname

## 修改comment.ejs
在Hexo\themes\jacman\layout_partial\post下面的comment.ejs。

添加我们刚才获得源码

```javascript
	<% if (theme.duoshuo_shortname || config.duoshuo_shortname && page.comments){ %>
	<section id="comments" class="comment">
	<div class="ds-thread" data-thread-key="<%- page.path %>" data-title="<%- page.title %>" data-url="<%- page.permalink %>"></div>

	<!-- 多说公共JS代码 start (一个网页只需插入一次) -->
	<script type="text/javascript">
	var duoshuoQuery = {short_name:"longzl"};
	(function() {
	    var ds = document.createElement('script');
	    ds.type = 'text/javascript';ds.async = true;
	    ds.src = (document.location.protocol == 'https:' ? 'https:' : 'http:') + '//static.duoshuo.com/embed.js';
	    ds.charset = 'UTF-8';
	    (document.getElementsByTagName('head')[0]
	     || document.getElementsByTagName('body')[0]).appendChild(ds);
	})();
	</script>
	<!-- 多说公共JS代码 end -->

	</section>
	<% } %>
```

接着访问我们的网页就可以看到效果了。

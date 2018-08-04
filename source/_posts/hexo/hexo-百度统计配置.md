---
title: hexo-百度统计配置
date: 2015-08-14 10:09:28
tags: [hexo,百度统计]
categories: hexo

---

## 注册百度统计账号

###

进入[百度统计](http://tongji.baidu.com/)页面:注册一个账号并登录。

## 新建网站

进入上方的网站中心页面，下面会列出你当前账户正在检测的网站。
点击右侧的新增网站。
在弹出的对话框中输入你的网站URL，然后在列表中就出现了你要检测的网站。

![点击“网站中心”](http://i.imgur.com/3ZWctiY.jpg)

![输入你的网址](http://i.imgur.com/enYThfu.png)

## 获取32位长的codeID

鼠标放上去会显示获取代码，然后就获取一个32位长的字符串。保存之。

![32位code](http://i.imgur.com/sUQqtMv.jpg)

## 修改配置文件

进入你的Hexo-->themes-->jacman-->_config.yml中，把上述的32位字符串复制到baidu_tongji后面的sitecode中。同时需要将enable设为true。

    baidu_tongji:
      enable: ture
      sitecode: your baidu tongji site code

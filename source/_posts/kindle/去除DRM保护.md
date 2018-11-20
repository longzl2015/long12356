---

title: 去除DRM保护

date: 2018-11-20 11:03:00

categories: [kindle]

tags: [kindle]

---


kindle 自带app太难用了，需要将 电子书转为 其他通用格式。


<!--more-->


## 获取电子书

首先，我们先获取需要进行破解的 azw 或 azw3 格式的电子书，总共有三种方法。

### 1.1 从亚马逊官网下载

登录亚马逊官网，从右上角“我的帐户”中选择“管理我的内容和设备”。

然后，从当中选择你想下载的书籍，点击“操作”中的“…”按钮，选择“通过电脑下载USB传输”。

然后，在弹窗中，选择点击“下载”，即可将电子书保存到本地。

注: 该方法下载的文件，破解时需要登录官网查找书籍序列号。

### 1.2 使用 Kindle 桌面端进行下载

首先，去官网下载 kindle 桌面端软件并安装。

安装完成后，登录对应的亚马逊帐号，然后下载想要破解的电子书，从电子书的存放路径中找到它们，并将其拷贝到桌面（或其它你想要的目录）。

Kindle for Windows 的电子书存放路径为：C:\Users\你的用户名\Documents\My Kindle Content。

Kindle for Mac 的电子书存放路径为：/Users/你的用户名/Library/Application Support/Kindle/My Kindle Content。

注: 使用这种方法，电子书的命名由应用自行生成，类似 B00FF3JVAC_EBOK.azw，识别起来比较麻烦。

### 1.3 直接从 Kindle 设备中进行拷贝

使用 USB 线将 Kindle 连接到电脑，找到对应的 Kindle 目录，在其下的 Documents 文件夹内找到 azw 或 azw3 格式的文件，将其拷出。

## 移除 Kindle 电子书的 DRM

破解 DRM 其实很简单，只需要使用到 DeDRM_tools 工具即可，这个工具是开源的，可以直接在 GitHub 上下载到。

这个工具提供了两种方法来破解 DRM，

- 第一种是直接使用它提供的 Mac 或 Windows 应用，
- 第二种是使用 Calibre 插件，并配合 Calibre 进行破解。

这里推荐使用第二种方法，因为第一种方法还需要到 Kindle 设备序列号，比较麻烦。

### 安装 Calibre 应用
Calibre 是一款开源的电子书管理应用，详细信息可以参考它的官网。安装方法也很简单，直接在官网下载安装文件，并进行安装即可。

### 安装去除 DRM 保护的插件
Calibre 是支持插件的，并且它还有一个插件仓库用于方便安装各种插件。但是 Calibre 本身是不支持去除 DRM 的，并且官方插件仓库也没有提供这个插件。

到 DeDRM_tools 的 releases中下载最新的 zip 包，解压，在 DeDRM_tools_6.5.4/DeDRM_calibre_plugin 目录下有一个 readme 文档，还有一个 calibre 插件包 DeDRM_plugin.zip。

打开 Calibre，点击首选项（Mac 快捷键，cmd + ,），在“高级选项”中点选“插件”。接着，点击“从文件加载插件”，选择刚刚解压得到的 DeDRM_plugin.zip 进行安装。Calibre 会有一些安全警告，直接选择忽略，并一路下一步即可。

安装完后，需要重启下 calibre

### 使用插件
安装完插件之后，直接将要破解的 azw 或 azw3 文件添加到 Calibre 就可以了。插件会自动将有 DRM 保护的文件转换成原始格式。

有了原始格式的文件，无论是推送到自己的 Kindle 设备，还是使用 Calibre 将其转换成 epub 或者 txt 格式都是没有问题的。


## 来源

[去除Kindle电子书保护](http://www.swiftyper.com/2017/10/08/remove-kindle-drm-protection/)
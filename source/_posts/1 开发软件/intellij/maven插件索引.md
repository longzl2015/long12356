---

title: maven插件索引更新

date: 2018-08-09 13:30:42

categories: [开发软件,intellij]

tags: [maven,intellij]

---

## Maven的仓库、索引

**中央仓库**：目前来说，http://repo1.maven.org/maven2/ 是真正的Maven中央仓库的地址，该地址内置在Maven的源码中，其它地址包括著名的ibiblio.org，都是镜像。

**索引**：中央仓库带有索引文件以方便用户对其进行搜索，完整的索引文件至2015年12月8日大小约为1.11G，索引每周更新一次。

**本地仓库**：是建立在本地机器上的Maven仓库，本地仓库是中央仓库（或者说远程仓库）的一个缓冲和子集，当你构建Maven项目的时候，首先会从本地仓库查找资源，如果没有，那么Maven会从远程仓库下载到你本地仓库。
这样在你下次使用的时候就不需要从远程下载了。如果你所需要的Jar包版本在本地仓库没有，而且也不存在于远程仓库，Maven在构建的时候会报错，这种情况可能发生在有些Jar包的新版本没有在Maven仓库中及时更新。
Maven缺省的本地仓库地址为`${user.home}/.m2/repository`。也就是说，一个用户会对应的拥有一个本地仓库。当然你可以通过修改`${user.home}/.m2/settings.xml`配置这个地址：

```xml
<settings>
  ···
  <localRepository> D:/java/repository</localRepository>
  ...
</settings>
```

**提交内容**：只要你的项目是开源的，而且你能提供完备的POM等信息，你就可以提交项目文件至中央仓库，这可以通过Sonatype提供的开源Maven仓库托管服务实现。


## IntelliJ IDEA利用索引实现自动补全

`setting -> maven -> repositories`

![图](/images/maven插件索引/图.png)

注意这是一个非常耗时的过程，建议利用晚上或者出去午饭时间下载。下载过程及下载完成之后状态如下图所示。本次下载整体耗时在一个小时左右。
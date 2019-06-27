---

title: artifactory

date: 2019-06-02 16:09:00

categories: [开发软件,maven]

tags: [maven,artifactory]

---



artifactory 是一个通用的仓库管理器。可以管理 npm、docker、maven和 ivy 等等。

repositories 分为三种:

- Local : 公司内部 jar 和 ArtifactoryWeb 页面上传的jar
- remote: 缓存 其他远程仓库的jar
- virtual: 仅是 local和 remote的集合，通过一个 virtual，代表多个local和remote的访问

artifactory 有个默认的全局 virtual仓库。访问路劲为 `http://ip:port/artifactory/repo`


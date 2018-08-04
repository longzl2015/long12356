---
title: git命令使用
tags: 
- git
categories:
- 版本管理
---

[TOC]

## git log

### 查看提交历史

```bash
git log branch1 
```

结果如下：

```
$ git log branch1
commit ca82a6dff817ec66f44342007202690a93763949
Author: Scott Chacon <schacon@gee-mail.com>
Date:   Mon Mar 17 21:52:11 2008 -0700

    changed the version number

commit 085bb3bcb608e1e8451d4b2432f8ecbe6306e7e7
Author: Scott Chacon <schacon@gee-mail.com>
Date:   Sat Mar 15 16:40:33 2008 -0700

    removed unnecessary test code

commit a11bef06a3f659402fe7563abf99ad00de2209e6
Author: Scott Chacon <schacon@gee-mail.com>
Date:   Sat Mar 15 10:31:28 2008 -0700

    first commit
```

###自定义格式查看提交历史

```
git log --pretty=format:"%h - %an, %ar : %s"
```

结果如下：

```
$ git log --pretty=format:"%h - %an, %ar : %s"
ca82a6d - Scott Chacon, 11 months ago : changed the version number
085bb3b - Scott Chacon, 11 months ago : removed unnecessary test code
a11bef0 - Scott Chacon, 11 months ago : first commit
```

###  规定查看日志时间

```
git log --since=2.weeks
```

####选项

| 选项                  | 说明             |
| ------------------- | -------------- |
| `-(n)`              | 仅显示最近的 n 条提交   |
| `--since, --after`  | 仅显示指定时间之后的提交。  |
| `--until, --before` | 仅显示指定时间之前的提交。  |
| `--author`          | 仅显示指定作者相关的提交。  |
| `--committer`       | 仅显示指定提交者相关的提交。 |

####格式符号

| 选项    | 说明                        |
| ----- | ------------------------- |
| `%H`  | 提交对象（commit）的完整哈希字串       |
| `%h`  | 提交对象的简短哈希字串               |
| `%T`  | 树对象（tree）的完整哈希字串          |
| `%t`  | 树对象的简短哈希字串                |
| `%P`  | 父对象（parent）的完整哈希字串        |
| `%p`  | 父对象的简短哈希字串                |
| `%an` | 作者（author）的名字             |
| `%ae` | 作者的电子邮件地址                 |
| `%ad` | 作者修订日期（可以用 -date= 选项定制格式） |
| `%ar` | 作者修订日期，按多久以前的方式显示         |
| `%cn` | 提交者(committer)的名字         |
| `%ce` | 提交者的电子邮件地址                |
| `%cd` | 提交日期                      |
| `%cr` | 提交日期，按多久以前的方式显示           |
| `%s`  | 提交说明                      |







## 参考

[ Git 基础 - 查看提交历史](https://git-scm.com/book/zh/v1/Git-%E5%9F%BA%E7%A1%80-%E6%9F%A5%E7%9C%8B%E6%8F%90%E4%BA%A4%E5%8E%86%E5%8F%B2)


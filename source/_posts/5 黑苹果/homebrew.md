---
title: Mac下加快HomeBrew下载速度
date: 2017-01-05 03:30:09
tags: 
  -  黑苹果
categories:
  - 系统
---

## 使用代理 

本机socks5 代理端口为 127.0.0.1:1086

在 ~/.bash_profile 中添加如下配置即可

```bash
alias brews='all_proxy=socks5://127.0.0.1:1086 brew '
```

之后使用 brews 代替 brews

## 切换镜像

### 1.使用清华源

#### 替换默认源 
第一步：替换现有上游

```
cd "$(brew --repo)"
```

```
git remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git
```

```
cd "$(brew --repo)/Library/Taps/homebrew/homebrew-core"
```

```
git remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git
```

```
cd 
```

```
brew update
```

第二步：使用homebrew-science或者homebrew-python(两个模块不存在，已被合并进core)

```
cd "$(brew --repo)/Library/Taps/homebrew/homebrew-science"
```

```
git remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-science.git
```

或

```
cd "$(brew --repo)/Library/Taps/homebrew/homebrew-python"
```

```
git remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-python.git
```

```
cd 
```

```
brew update
```

#### 替换Homebrew Bottles源

```
echo 'export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles' >> ~/.bash_profile
```

```
source ~/.bash_profile
```

### 2.在清华源失效或宕机时可以切换回官方源

#### 第一步：重置brew.git

```
cd "$(brew --repo)"1
```

```
git remote set-url origin https://github.com/Homebrew/brew.git
```

#### 第二步：重置homebrew-core.git

```
cd "$(brew --repo)/Library/Taps/homebrew/homebrew-core"
```

```
git remote set-url origin https://github.com/Homebrew/homebrew-core.git
```

```
cd
brew update
```

#### 第三步：注释掉bash配置文件里的有关Homebrew Bottles即可恢复官方源。 重启bash或让bash重读配置文件。
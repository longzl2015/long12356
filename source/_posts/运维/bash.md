---

title: bash

date: 2018-09-25 10:21:00

categories: [linux,命令]

tags: [linux]

---


翻译自 man bash


<!--more-->

### 启动

`login` 登录shell: 参数的第一个字符为 `-`，或者 在启动时指定 `--login` 选项。 

`interactive` 交互式shell: 一个启动时没有指定非选项的参数，并且没有指定 `-c` 选项，标准输出和标准输入都连接到了终端 (在 isatty(3) 中判定) 的shell，或者启动时指定了 -i 选项的 shell。如果 bash 是交互的， PS1 环境变量将被设置，并且 `$-` 包含 i ，允许一个 shell 脚本或者一个启动文件来检测这一状态。

下列段落描述了 bash 如何执行它的启动文件。如果这些启动文件中的任一个存在但是不可读取， bash 将报告一个错误。文件名中的波浪号 (~,tilde) 将像 EXPANSION 章节中 Tilde Expansion 段描述的那样展开。

#### 登录shell启动
当 bash 是作为交互的登录 shell 启动的，或者是一个非交互的 shell 但是指定了 `--login` 选项， 它首先读取并执行 `/etc/profile` 中的命令(只要那个文件存在)。 
读取那个文件之后，它以如下的顺序查找 `~/.bash_profile`, `~/.bash_login`, 和 `~/.profile`, 从存在并且可读的第一个文件中读取并执行其中的命令。
`--noprofile` 选项可以用来在 shell 启动时阻止它这样做。

#### 登录shell退出
当一个登录 shell 退出时， bash 读取并执行文件` ~/.bash_logout` 中的命令(只要它存在)。

#### 交互式shell非登录启动
当一个交互的 shell 但不是登录 shell 启动时， bash 从文件 `~/.bashrc` 中读取并执行命令(只要它存在)。
可以用 `--norc` 选项来阻止它这样做。 `--rcfile file` 选项将强制 bash 读取并执行文件 file 中的命令，而不是 `~/.bashrc中`的。

#### 非交互式shell启动
当 bash 以非交互的方式启动时，例如在运行一个 shell 脚本时，它在环境中查找变量 BASH_ENV ，如果它存在则将它的值展开，使用展开的值作为一个文件的名称，读取并执行。 
Bash 运作的过程就如同执行了下列命令： 

> if [ -n "$BASH_ENV" ]; then . "$BASH_ENV"; fi

但是没有使用 PATH 变量的值来搜索那个文件名。

#### sh 启动
如果 bash 以名称 sh 启动，它试图模仿 (mimic) sh 历史版本的启动过程，尽可能地相似，同时也遵循 POSIX 标准。 
当作为交互式登录shell启动时,或者是非交互但使用了`--login`选项 启动的时候,它首先尝试读取并执行文件 `/etc/profile` 和 `~/.profile`中的命令. 选项 `--noprofile` 用于避免这种行为.
当使用命令 sh 来启动一个交互式的 shell 时, bash 查找环境变量 ENV, 如果有定义的话就扩展它的值,然后使用扩展后的值作为要读取和执行的文件的名称.由于使用 sh 启动的 shell 不会读取和执行任何其他的启动文件,选项 `--rcfile` 没有意义.
使用名称 sh 启动的非交互的 shell 不会读取任何其他启动文件.当以 sh 启动时, bash 在读取启动文件之后进入 posix 模式.

#### posix 模式启动
当 bash 以 posix 模式启动时,(和使用 `--posix` 命令行参数效果相同),它遵循 POSIX 标准. 
这种模式下,交互式 shell 扩展 ENV 环境变量的值,读取并执行以扩展后值为文件名的配置文件. 不会读取其他文件.

Bash 试着检测它是不是由远程 shell 守护程序,通常为 rshd 启动的.
如果 bash 发现它是由 rshd 启动的,它将读取并执行 `~/.bashrc` 文件中的命令（只要这个文件存在并且可读）.
如果以 sh 命令启动,它不会这样做. 
选项 `--norc` 可以用来阻止这种行为, 选项 `--rcfile` 用来强制读取另一个文件,但是通常 rshd 不会允许它们, 或者用它们来启动 shell.

如果 shell 是以与真实用户(组) id 不同的有效用户(组) id 来启动的, 并且没有 `-` 选项,那么它不会读取启动文件, 也不会从环境中继承 shell 函数. 环境变量中如果出现 SHELLOPTS， 它将被忽略.有效用户 id 将设置为真实用户 id. 
如果启动时给出了 `-` 选项,那么启动时的行为是类似的, 但是不会重置有效用户 id.  

### 文件区别

- `/bin/bash`: bash 可执行文件
- `/etc/profile`: 系统范围的初始化文件，登录 shell 会执行它
- `~/.bash_profile`: 个人初始化文件，登录 shell 会执行它
- `~/.bashrc`: 个人的每个交互式 shell 启动时执行的文件
- `~/.bash_logout`: 个人的登录 shell 清理文件，当一个登录 shell 退出时会执行它
- `~/.inputrc`: 个人的 readline 初始化文件
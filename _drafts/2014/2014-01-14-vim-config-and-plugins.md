---
layout: post
title: Vim配置和插件管理
description: 这篇文章主要是记录vim配置中各个配置项的含义并且收藏一些常用的插件及其使用方法。
category: devops
tags: [vim]
---

这篇文章主要是记录vim配置中各个配置项的含义并且收藏一些常用的插件及其使用方法。

# 1. Vim配置

目前我的vimrc配置放置在:[https://github.com/javachen/snippets/blob/master/dotfiles/.vimrc](https://github.com/javachen/snippets/blob/master/dotfiles/.vimrc)，其中大多数用英文注释。

# 2. 插件管理

使用 pathogen来管理插件

项目地址:	[https://github.com/tpope/vim-pathogen](https://github.com/tpope/vim-pathogen)

安装方法：

~~~bash 
$ mkdir -p ~/.vim/autoload ~/.vim/bundle && \
$ curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim
~~~

要记得把以下内容加入到vimrc文件中:

~~~
execute pathogen#infect()
~~~

# 3. 安装插件

## 3.1 NERDTree

NERD tree允许你在Vim编辑器中以树状方式浏览系统中的文件和目录, 支持快捷键与鼠标操作, 使用起来十分方便. NERD tree能够以不同颜色高亮显示节点类型, 并包含书签, 过滤等实用功能. 配合taglist或txtviewer插件, 右边窗口显示本文件夹的文件, 左边窗口显示本文的文档结构, 将会使管理一个工程变得相当容易.

项目地址:	[https://github.com/scrooloose/nerdtree](https://github.com/scrooloose/nerdtree)

安装方法很简单，只要把项目clone一份到bundle目录就可以了。

~~~
cd ~/.vim/bundle
git clone https://github.com/scrooloose/nerdtree.git
~~~

之后的插件也都是这么安装。

使用：

1. 在linux命令行界面，输入vim
2. 输入`:NERDTree` ，回车，默认打开当前目录，当然可以打开指定目录，如 `:NERDTree /home/` 打开
3. 入当前目录的树形界面，通过小键盘上下键，能移动选中的目录或文件
4. 目录前面有`+`号，摁 `Enter` 会展开目录，文件前面是`-`号，摁 `Enter` 会在右侧窗口展现该文件的内容，并光标的焦点focus右侧。
5. `ctr+w+h` 光标 focus 左侧树形目录，`ctrl+w+l` 光标 focus 右侧文件显示窗口。多次摁 `ctrl+w`，光标自动在左右侧窗口切换
6. 光标focus左侧树形窗口，按 `?` 弹出NERDTree的帮助，再次按 `？`关闭帮助显示
7. 输入 `:q` 回车，关闭光标所在窗口

除了使用鼠标可以基本操作以外，还可以使用键盘。下下面列出常用的快捷键：

- `j`、`k` 分别下、上移动光标
- `o` 或者回车打开文件或是文件夹，如果是文件的话，光标直接定位到文件中，想回到目录结构中，按住 `Ctrl`，然后点两下 `w` 就回来了
- `go` 打开文件，但是光标不动，仍然在目录结构中
- `i`、`s` 分别是水平、垂直打开文件，就像vim命令的 `:vs`、`:sp`一样
- `gi`、`gs` 水平、垂直打开文件，光标不动
- `p` 快速定位到上层目录
- `P` 快速定位到根目录
- `K`、`J` 快速定位到同层目录第一个、最后一个节点
- `q` 关闭

## 3.2 NERDTree-Tabs

项目地址:[https://github.com/jistr/vim-nerdtree-tabs](https://github.com/jistr/vim-nerdtree-tabs)

安装完 NERDTree 以后我觉得还需要安装一下 NERDTree-Tabs 这个插件，提供了很多 NERDTree 的加强功能，包括保持 目录树状态、优化tab标题等等。

安装方法：

~~~bash
$ cd ~/.vim/bundle
$ git clone https://github.com/jistr/vim-nerdtree-tabs.git
~~~

可以把一下内容添加到 vimrc 文件中

~~~
let g:nerdtree_tabs_open_on_console_startup=1       "设置打开vim的时候默认打开目录树
map <leader>n <plug>NERDTreeTabsToggle <CR>         "设置打开目录树的快捷键
~~~

## 3.3 supertab

SuperTab使键入Tab键时具有上下文提示及补全功能。如下图（图片来自 [图灵社区](http://www.ituring.com.cn/article/124970)）：

![](http://www.ituring.com.cn/download/01g6WiEUEKaO)

项目地址:	[https://github.com/ervandew/supertab](https://github.com/ervandew/supertab)

安装方法：

~~~bash
$ cd ~/.vim/bundle
$ git clone git@github.com:ervandew/supertab.git
~~~

打开vim配置文件，`vim ~/.vimrc`，在最后加上一行内容

~~~
let g:SuperTabDefaultCompletionType="context"
~~~

## 3.4 ctrlp

项目地址:	[https://github.com/kien/ctrlp.vim](https://github.com/kien/ctrlp.vim)

安装方法：

~~~bash
$ cd ~/.vim/bundle
$ git clone git@github.com:kien/ctrlp.vim.git
~~~

快捷键：`ctrl+p`

# 4. 参考

- [1] [https://github.com/wklken/k-vim](https://github.com/wklken/k-vim)
- [2] [http://www.zhihu.com/question/19989337](http://www.zhihu.com/question/19989337)
- [3] [http://www.cnblogs.com/ma6174/archive/2011/12/10/2283393.html](http://www.cnblogs.com/ma6174/archive/2011/12/10/2283393.html)

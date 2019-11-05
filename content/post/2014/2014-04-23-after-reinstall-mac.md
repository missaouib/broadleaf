---
layout: post

title: 重装Mac系统之后
date: 2014-04-23T08:00:00+08:00

description: 重装Mac系统之后的一些软件安装和环境变量配置。

keywords: 重装Mac系统

categories: [ devops ]

tags: [mac]

---


本文主要记录重装Mac系统之后的一些软件安装和环境变量配置。

#系统偏好设置

## 触控板

- 系统设置 > 触控板
  - 光标与点击
    - ✓ 轻拍来点按
    - ✓ 辅助点按
    - ✓ 查找
    - ✓ 三指拖移
  - 滚动缩放
    - ✓ 默认全选
  - 更多手势
    - ✓ 默认全选

## 程序坞

- 置于屏幕上的位置：右边
- 设置 Dock 图标更小（大小随个人喜好）

## Finder

- Finder > 显示
  - 显示标签页栏
  - 显示路径栏
  - 显示状态栏
  - 自定工具栏 > 去除所有按钮，仅剩搜索栏
- Finder > 偏好设置
  - 通用
    - 开启新 Finder 窗口时打开：HOME「用户名」目录
  - 边栏
    - 添加 HOME「用户名」目录
    - 将 共享的(shared) 和 标记(tags) 目录去掉

## 菜单栏

- 去掉蓝牙等无需经常使用的图标
- 将电池显示设置为百分比

## Spotlight

- 去掉字体和书签与历史记录等不需要的内容
- 设置合适的快捷键

# XCode

```
 xcode-select --install
```

# Homebrew

## 安装

[Brew](http://brew.sh/) 是 Mac 下面的包管理工具，通过 Github 托管适合 Mac 的编译配置以及 Patch，可以方便的安装开发工具。

~~~bash
$ ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"
~~~

通过brew安装软件：

~~~bash
$ brew install git git-flow  curl  wget  putty  tmux ack source-highlight  dos2unix nmap iotop htop  ctags tree 
~~~

紧接着，我们需要做一件事让通过 Homebrew 安装的程序的启动链接 (在 /usr/local/bin中）可以直接运行，无需将完整路径写出。通过以下命令将 /usr/local/bin 添加至 $PATH 环境变量中:

~~~bash
$ echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bash_profile
~~~

Cmd+T 打开一个新的 terminal 标签页，运行以下命令，确保 brew 运行正常。

~~~bash
$ brew doctor
~~~

##基本使用

## Cask

[Brew cask](https://github.com/phinze/homebrew-cask) 是类似 Brew 的管理工具， 直接提供 dmg 级别的二进制包，（Brew 是不带源码，只有对应项目所在的 URL）。我们可以通过 Homebrew Cask 优雅、简单、快速的安装和管理 OS X 图形界面程序，比如 Google Chrome 和 Dropbox。

Brew cask 安装：

~~~bash
$ brew tap phinze/homebrew-cask
$ brew install brew-cask
~~~

我通过 Brew cask 安装的软件：

~~~bash
brew cask install google-chrome 
brew cask install virtualbox 

Vagrant Unarchiver Iterm2
~~~

更新：

```bash
brew update && brew upgrade brew-cask && brew cleanup
```



# oh-msy-zsh

使用 Homebrew 完成 zsh 和 zsh completions 的安装

~~~bash
brew install zsh zsh-completions
~~~

把默认 Shell 换为 zsh。

~~~bash
$ chsh -s /bin/zsh
~~~

安装 oh-my-zsh：

~~~bash
$ curl -L https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sh
~~~

编辑 ~/.zshrc：

~~~
echo 'source ~/.bashrc' >>~/.zshrc
echo 'source ~/.bash_profile' >>~/.zshrc
~~~

用文本编辑器或 vi 打开 .zshrc 添加插件:

~~~bash
ZSH_THEME=pygmalion
plugins=(git mvn colorize encode64 urltools wd last-working-dir sublime vagrant Z zsh-syntax-highlighting git-open)
~~~


# Java开发环境

下载 jdk：

- jdk6：<http://support.apple.com/downloads/DL1572/en_US/JavaForOSX2013-05.dmg>
- jdk7：<http://download.oracle.com/otn-pub/java/jdk/7u60-b19/jdk-7u60-macosx-x64.dmg?AuthParam=1403450902_0b8ed262d4128ca82031dcbdc2627aaf>

设置 java_home 为 1.8:

~~~bash
echo 'export JAVA_HOME=$(/usr/libexec/java_home -v 1.8)
' >> ~/.bashrc
~~~

# 参考文章

- [Mac 开发配置手册](http://aaaaaashu.gitbooks.io/mac-dev-setup/content/index.html)

  

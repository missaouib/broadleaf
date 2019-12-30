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

# 系统偏好设置

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

# 安装软件

## XCode

```
 xcode-select --install
```

## Homebrew

[Brew](http://brew.sh/) 是 Mac 下面的包管理工具，通过 Github 托管适合 Mac 的编译配置以及 Patch，可以方便的安装开发工具。

~~~bash
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
~~~

替换brew.git

```bash
git -C "$(brew --repo)" remote set-url origin https://mirrors.cloud.tencent.com/homebrew/brew.git

git -C "$(brew --repo homebrew/core)" remote set-url origin https://mirrors.cloud.tencent.com//homebrew/homebrew-core.git

brew update
```

通过brew安装软件：

~~~bash
brew install vim zsh git git-flow curl httpie wget putty tmux source-highlight ctags tree node autojump
~~~

 以上命令会安装如下依赖：

```bash
Installing dependencies for vim: lua, perl, gdbm, openssl@1.1, readline, sqlite, xz, python, libyaml and ruby
```

安装目录在 `/usr/local/Cellar`

通过以下命令将 /usr/local/bin 添加至 $PATH 环境变量中:

~~~bash
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bash_profile
~~~

更新：

```bash
brew update && brew upgrade brew-cask && brew cleanup
```



## Cask

[Brew cask](https://github.com/phinze/homebrew-cask) 是类似 Brew 的管理工具， 直接提供 dmg 级别的二进制包，（Brew 是不带源码，只有对应项目所在的 URL）。我们可以通过 Homebrew Cask 优雅、简单、快速的安装和管理 OS X 图形界面程序，比如 Google Chrome 和 Dropbox。

Brew cask 安装：

~~~bash
brew tap phinze/homebrew-cask
~~~

我通过 Brew cask 安装的软件：

~~~bash
brew cask install qq qqmusic google-chrome virtualbox vagrant iterm2 the-unarchiver cheatsheet
~~~

- cheatsheet：示当前程序的快捷键列表，默认快捷键是长按command键



### 配置 iTerm2

打开 Preferences 偏好设置

- General 关闭 Native full screen windows 我不使用系统的全屏（因为有过渡动画），是为了使用全局快捷键 **立即** 调出命令行
- Profiles-Window-Transparency 设置透明度 10%~20% 即可，太高会和桌面背景冲突。如果需要临时禁用透明度可以使用快捷键 ⌘+u
- Keys-Hotkey 设置全局显示隐藏快捷键 系统级别的快捷键设置为 ⌘+\

> 最佳实践，启动 iTerm2 后按 ⌘+enter 全屏，然后 ⌘+\ 隐藏它，这时候就可以做别的事情去了。任何时间想再用 iTerm2 只需要按 ⌘+\ 即可

## oh-msy-zsh

使用 Homebrew 完成 zsh 和 zsh completions 的安装

~~~bash
brew install zsh zsh-completions
~~~

设置zsh为默认：

~~~bash
sudo sh -c "echo $(which zsh) >> /etc/shells" 
chsh -s $(which zsh)
~~~

bash切换到zsh

```bash
chsh -s /bin/zsh
```

安装 oh-my-zsh：

~~~bash
curl -L https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sh
~~~

用文本编辑器或 vi 打开 .zshrc 添加插件:

~~~bash
ZSH_THEME=pygmalion
plugins=(git mvn colorize encode64 urltools wd last-working-dir sublime vagrant Z zsh-syntax-highlighting git-open)
~~~

执行以下指令生效

```bash
exec $SHELL # 或 source .zshrc
```



安装自动补全提示插件 [zsh-autosuggestions](https://link.zhihu.com/?target=https%3A//github.com/zsh-users/zsh-autosuggestions)

```text
git clone git://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
```

## Java开发环境

### 安装Java

下载 jdk：

- jdk6：<http://support.apple.com/downloads/DL1572/en_US/JavaForOSX2013-05.dmg>
- jdk7：<http://download.oracle.com/otn-pub/java/jdk/7u60-b19/jdk-7u60-macosx-x64.dmg?AuthParam=1403450902_0b8ed262d4128ca82031dcbdc2627aaf>

设置 java_home 为 1.8:

~~~bash
echo 'export JAVA_HOME=$(/usr/libexec/java_home -v 1.8)
' >> ~/.zshrc
~~~

### 安装Maven

```bash
brew install maven
```

## 编辑器

- [SublimeText](https://link.zhihu.com/?target=https%3A//www.sublimetext.com/) 
- [JetBrains](https://link.zhihu.com/?target=https%3A//www.jetbrains.com/) 

## 其他

- 百度云网盘
- 搜狗输入法
- Typora
- Sublime Text

# 配置文件

参考 https://github.com/javachen/snippets/tree/master/dotfiles

```bash
git clone https://github.com/javachen/snippets.git
cd snippets/dotfiles
cp * ~/
```



# 参考文章

- [Mac 开发配置手册](http://aaaaaashu.gitbooks.io/mac-dev-setup/content/index.html)

  

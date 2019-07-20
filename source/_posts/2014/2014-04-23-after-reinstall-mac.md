---
layout: post

title: 重装Mac系统之后

description: 重装Mac系统之后的一些软件安装和环境变量配置。

keywords: 重装Mac系统

category: devops

tags: [mac]

---


本文主要记录重装Mac系统之后的一些软件安装和环境变量配置。


# 系统偏好配置

设置主机名：

~~~bash
$ sudo scutil --set HostName june
~~~

设置鼠标滚轮滑动的方向：系统偏好设置－－>鼠标－－>"滚动方向：自然"前面的勾去掉

显示/隐藏Mac隐藏文件：

~~~bash
defaults write com.apple.finder AppleShowAllFiles -bool true  #显示Mac隐藏文件的命令
defaults write com.apple.finder AppleShowAllFiles -bool false #隐藏Mac隐藏文件的命令
~~~

- 触控板
 - 光标与点按 > 三指移动 ：这样就可以三指拖动文件了
 - 光标与点按 > 轻拍来点按 ：习惯了轻点完成实际按击
 - 光标与点按 > 跟踪速度 ：默认的指针滑动速度有点慢，设置成刻度7差不多了 
- 键盘
 - 快捷键 > 服务 > 新建位于文件夹位置的终端标签：勾选这设置并设置了快捷键（control+cmt+c），以后在Finder中选择一个目录按下快捷键就可以打开终端并来到当前当前目录，功能很实用啊！注意：在Finder中文件列表使用分栏方式显示时快捷键是无效的。
- 网络
 -高级... > DNS ：公共DNS是必须添加的
  - 223.6.6.6 阿里提供的
  - 8.8.4.4 google提供的
  - 114.114.114.114 114服务提供的

# Apps

- VirtualBox
- Vagrant
- Unarchiver: 支持多种格式（包括 windows下的格式）的压缩/解压缩工具
- OminiFocus ：时间管理工具
- Xmind
- Iterm2

# Homebrew

[Brew](http://brew.sh/) 是 Mac 下面的包管理工具，通过 Github 托管适合 Mac 的编译配置以及 Patch，可以方便的安装开发工具。

~~~bash
$ ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"
~~~

通过brew安装软件：

~~~bash
$ brew install git git-flow  curl  wget  putty  tmux ack source-highlight aria2 dos2unix nmap iotop htop  ctags tree openvpn
~~~

紧接着，我们需要做一件事让通过 Homebrew 安装的程序的启动链接 (在 /usr/local/bin中）可以直接运行，无需将完整路径写出。通过以下命令将 /usr/local/bin 添加至 $PATH 环境变量中:

~~~bash
$ echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bash_profile
~~~

Cmd+T 打开一个新的 terminal 标签页，运行以下命令，确保 brew 运行正常。

~~~bash
$ brew doctor
~~~

## 使用

安装一个包，可以简单的运行：

~~~bash
$ brew install <package_name>
~~~

更新 Homebrew 在服务器端上的包目录：

~~~bash
$ brew update
~~~

查看你的包是否需要更新：

~~~bash
$ brew outdated
~~~

更新包：

~~~bash
$ brew upgrade <package_name>
~~~

Homebrew 将会把老版本的包缓存下来，以便当你想回滚至旧版本时使用。但这是比较少使用的情况，当你想清理旧版本的包缓存时，可以运行：

~~~bash
$ brew cleanup
~~~

查看你安装过的包列表（包括版本号）：

~~~bash
$ brew list --versions
~~~

## Cask

[Brew cask](https://github.com/phinze/homebrew-cask) 是类似 Brew 的管理工具， 直接提供 dmg 级别的二进制包，（Brew 是不带源码，只有对应项目所在的 URL）。我们可以通过 Homebrew Cask 优雅、简单、快速的安装和管理 OS X 图形界面程序，比如 Google Chrome 和 Dropbox。

Brew cask 安装：

~~~bash
$ brew tap phinze/homebrew-cask
$ brew install brew-cask
~~~

我通过 Brew cask 安装的软件：

~~~bash
$ brew cask install google-chrome omnigraffle xtrafinder

$ brew update && brew upgrade brew-cask && brew cleanup # 更新
~~~

> 相对于 brew cask 的安装方式，本人更倾向于到 App Store 或官方下载 OS X 图形界面程序。主要因为名字不好记忆、偶尔需要手动更新，另外当你使用 Alfred 或 Spotlight ，你将发现将程序安装在 ~/Application 会很方便。

# Git 

安装：

~~~bash
$ brew install git
~~~

好的，现在我们来测试一下 gti 是否安装完好：

~~~bash
$ git --version
~~~

运行 `$ which git` 将会输出 /usr/local/bin/git.

接着，我们将定义你的 Git 帐号（与你在 GitHub 使用的用户名和邮箱一致）

~~~bash
$ git config --global user.name "Your Name Here"
$ git config --global user.email "your_email@youremail.com"
~~~

这些配置信息将会添加进 ~/.gitconfig 文件中.

我们将推荐使用 HTTPS 方法（另一个是 SSH），将你的代码推送到 Github 上的仓库。如果你不想每次都输入用户名和密码的话，可以按照此 [描述](https://help.github.com/articles/set-up-git) 说的那样，运行：

~~~bash
$ git config --global credential.helper osxkeychain
~~~

此外，如果你打算使用 SSH方式，可以参考此 [链接](https://help.github.com/articles/generating-ssh-keys)。

## Git Ignore

创建一个新文件 ~/.gitignore ，并将以下内容添加进去，这样全部 git 仓库将会忽略以下内容所提及的文件。

~~~
# Folder view configuration files
.DS_Store
Desktop.ini

# Thumbnail cache files
._*
Thumbs.db

# Files that might appear on external disks
.Spotlight-V100
.Trashes

# Compiled Java files
.classpath
.project
.settings
bin
build
target
dependency-reduced-pom.xml
.gradle
README.html
.idea
*.iml

# Compiled Python files
*.pyc

# Compiled C++ files
*.out

# Application specific files
venv
node_modules
.sass-cache
~~~


# oh-my-zsh

使用 Homebrew 完成 zsh 和 zsh completions 的安装

~~~bash
brew install zsh zsh-completions
~~~

把默认 Shell 换为 zsh。

~~~bash
$ chsh -s /bin/zsh
~~~

然后用下面的两句（任选其一）可以自动安装 oh-my-zsh：

~~~bash
$ curl -L https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sh
~~~

~~~bash
$ wget --no-check-certificate https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O - | sh
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


## Git插件

Git插件的所有配置：

参考： https://github.com/robbyrussell/oh-my-zsh/blob/master/plugins/git/git.plugin.zsh

```bash
alias g='git'

alias ga='git add'
alias gaa='git add --all'
alias gapa='git add --patch'
alias gau='git add --update'

alias gb='git branch'
alias gba='git branch -a'
alias gbd='git branch -d'
alias gbda='git branch --no-color --merged | command grep -vE "^(\*|\s*(master|develop|dev)\s*$)" | command xargs -n 1 git branch -d'
alias gbl='git blame -b -w'
alias gbnm='git branch --no-merged'
alias gbr='git branch --remote'
alias gbs='git bisect'
alias gbsb='git bisect bad'
alias gbsg='git bisect good'
alias gbsr='git bisect reset'
alias gbss='git bisect start'

alias gc='git commit -v'
alias gc!='git commit -v --amend'
alias gcn!='git commit -v --no-edit --amend'
alias gca='git commit -v -a'
alias gca!='git commit -v -a --amend'
alias gcan!='git commit -v -a --no-edit --amend'
alias gcans!='git commit -v -a -s --no-edit --amend'
alias gcam='git commit -a -m'
alias gcsm='git commit -s -m'
alias gcb='git checkout -b'
alias gcf='git config --list'
alias gcl='git clone --recursive'
alias gclean='git clean -fd'
alias gpristine='git reset --hard && git clean -dfx'
alias gcm='git checkout master'
alias gcd='git checkout develop'
alias gcmsg='git commit -m'
alias gco='git checkout'
alias gcount='git shortlog -sn'
compdef _git gcount
alias gcp='git cherry-pick'
alias gcpa='git cherry-pick --abort'
alias gcpc='git cherry-pick --continue'
alias gcs='git commit -S'

alias gd='git diff'
alias gdca='git diff --cached'
alias gdct='git describe --tags `git rev-list --tags --max-count=1`'
alias gdt='git diff-tree --no-commit-id --name-only -r'
alias gdw='git diff --word-diff'

gdv() { git diff -w "$@" | view - }
compdef _git gdv=git-diff

alias gf='git fetch'
alias gfa='git fetch --all --prune'
alias gfo='git fetch origin'

function gfg() { git ls-files | grep $@ }
compdef _grep gfg

alias gg='git gui citool'
alias gga='git gui citool --amend'

ggf() {
  [[ "$#" != 1 ]] && local b="$(git_current_branch)"
  git push --force origin "${b:=$1}"
}
compdef _git ggf=git-checkout

ggl() {
  if [[ "$#" != 0 ]] && [[ "$#" != 1 ]]; then
    git pull origin "${*}"
  else
    [[ "$#" == 0 ]] && local b="$(git_current_branch)"
    git pull origin "${b:=$1}"
  fi
}
compdef _git ggl=git-checkout

ggp() {
  if [[ "$#" != 0 ]] && [[ "$#" != 1 ]]; then
    git push origin "${*}"
  else
    [[ "$#" == 0 ]] && local b="$(git_current_branch)"
    git push origin "${b:=$1}"
  fi
}
compdef _git ggp=git-checkout

ggpnp() {
  if [[ "$#" == 0 ]]; then
    ggl && ggp
  else
    ggl "${*}" && ggp "${*}"
  fi
}
compdef _git ggpnp=git-checkout

ggu() {
  [[ "$#" != 1 ]] && local b="$(git_current_branch)"
  git pull --rebase origin "${b:=$1}"
}
compdef _git ggu=git-checkout

alias ggpur='ggu'
compdef _git ggpur=git-checkout

alias ggpull='git pull origin $(git_current_branch)'
compdef _git ggpull=git-checkout

alias ggpush='git push origin $(git_current_branch)'
compdef _git ggpush=git-checkout

alias ggsup='git branch --set-upstream-to=origin/$(git_current_branch)'
alias gpsup='git push --set-upstream origin $(git_current_branch)'

alias ghh='git help'

alias gignore='git update-index --assume-unchanged'
alias gignored='git ls-files -v | grep "^[[:lower:]]"'
alias git-svn-dcommit-push='git svn dcommit && git push github master:svntrunk'
compdef _git git-svn-dcommit-push=git

alias gk='\gitk --all --branches'
compdef _git gk='gitk'
alias gke='\gitk --all $(git log -g --pretty=%h)'
compdef _git gke='gitk'

alias gl='git pull'
alias glg='git log --stat'
alias glgp='git log --stat -p'
alias glgg='git log --graph'
alias glgga='git log --graph --decorate --all'
alias glgm='git log --graph --max-count=10'
alias glo='git log --oneline --decorate'
alias glol="git log --graph --pretty='%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
alias glola="git log --graph --pretty='%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --all"
alias glog='git log --oneline --decorate --graph'
alias gloga='git log --oneline --decorate --graph --all'
alias glp="_git_log_prettily"
compdef _git glp=git-log

alias gm='git merge'
alias gmom='git merge origin/master'
alias gmt='git mergetool --no-prompt'
alias gmtvim='git mergetool --no-prompt --tool=vimdiff'
alias gmum='git merge upstream/master'

alias gp='git push'
alias gpd='git push --dry-run'
alias gpoat='git push origin --all && git push origin --tags'
compdef _git gpoat=git-push
alias gpu='git push upstream'
alias gpv='git push -v'

alias gr='git remote'
alias gra='git remote add'
alias grb='git rebase'
alias grba='git rebase --abort'
alias grbc='git rebase --continue'
alias grbi='git rebase -i'
alias grbm='git rebase master'
alias grbs='git rebase --skip'
alias grh='git reset HEAD'
alias grhh='git reset HEAD --hard'
alias grmv='git remote rename'
alias grrm='git remote remove'
alias grset='git remote set-url'
alias grt='cd $(git rev-parse --show-toplevel || echo ".")'
alias gru='git reset --'
alias grup='git remote update'
alias grv='git remote -v'

alias gsb='git status -sb'
alias gsd='git svn dcommit'
alias gsi='git submodule init'
alias gsps='git show --pretty=short --show-signature'
alias gsr='git svn rebase'
alias gss='git status -s'
alias gst='git status'
alias gsta='git stash save'
alias gstaa='git stash apply'
alias gstc='git stash clear'
alias gstd='git stash drop'
alias gstl='git stash list'
alias gstp='git stash pop'
alias gsts='git stash show --text'
alias gsu='git submodule update'

alias gts='git tag -s'
alias gtv='git tag | sort -V'

alias gunignore='git update-index --no-assume-unchanged'
alias gunwip='git log -n 1 | grep -q -c "\-\-wip\-\-" && git reset HEAD~1'
alias gup='git pull --rebase'
alias gupv='git pull --rebase -v'
alias glum='git pull upstream master'

alias gwch='git whatchanged -p --abbrev-commit --pretty=medium'
alias gwip='git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit --no-verify -m "--wip-- [skip ci]"'
```

## aliases插件

使用上默认加了很多快捷映射，如：

- `~`: 进入用户根目录，可以少打cd三个字符了
- `l`: 相当于ls -lah
- `..`: 返回上层目录
- `...`: 返回上上层目录
- `-`: 打开上次所在目录

具体的可以查看其[配置文件](https://github.com/robbyrussell/oh-my-zsh/blob/master/lib/aliases.zsh)。


# 安装Vim插件

安装 pathogen：

~~~bash
$ mkdir -p ~/.vim/autoload ~/.vim/bundle; \
$ curl -Sso ~/.vim/autoload/pathogen.vim \
    https://raw.github.com/tpope/vim-pathogen/master/autoload/pathogen.vim
~~~

安装NERDTree：

~~~bash
$ cd ~/.vim/bundle
$ git clone https://github.com/scrooloose/nerdtree.git
~~~

更多请参考：[vim配置和插件管理](/2014/01/14/vim-config-and-plugins.html)

# 安装Ruby

先安装依赖：

~~~bash
$ brew install libksba autoconf automake libtool gcc libyaml readline
~~~

通过rvm安装ruby，目前需要ruby 2的版本：

~~~bash
$ curl -L get.rvm.io | bash -s stable 
$ source ~/.bash_profile
$ gem sources --remove https://rubygems.org/
# 如果http://ruby.taobao.org/有效的话，则添加源
$ gem sources -a http://ruby.taobao.org/ 
$ rvm install 2.2.1
$ rvm --default 2.2.1
~~~

# Java开发环境

下载 jdk：

- jdk6：<http://support.apple.com/downloads/DL1572/en_US/JavaForOSX2013-05.dmg>
- jdk7：<http://download.oracle.com/otn-pub/java/jdk/7u60-b19/jdk-7u60-macosx-x64.dmg?AuthParam=1403450902_0b8ed262d4128ca82031dcbdc2627aaf>

设置 java_home 为 1.8:

~~~bash
export JAVA_HOME=$(/usr/libexec/java_home -v 1.8)
~~~

# 参考文章

- [Mac 开发配置手册](http://aaaaaashu.gitbooks.io/mac-dev-setup/content/index.html)
- [MacBook Pro 配置](http://nootn.com/blog/archives/87/)

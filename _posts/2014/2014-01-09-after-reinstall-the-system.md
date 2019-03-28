---
layout: post
title: 重装Linux-Mint系统之后
description: 重装Linux-Mint系统之后的一些软件安装和环境变量配置。
category: devops
tags: [linux]
---

本文主要记录重装Linux-Mint系统之后的一些软件安装和环境变量配置。

# 安装常用工具

~~~
sudo apt-get install ctags curl vsftpd git vim tmux meld htop putty subversion  nload  iptraf iftop tree openssh-server gconf-editor gnome-tweak-tool
~~~

# 挂载exfat格式磁盘

~~~
sudo apt-get install exfat-fuse exfat-utils
~~~

# 安装ibus

在终端输入命令:

~~~
sudo add-apt-repository ppa:shawn-p-huang/ppa
sudo apt-get update
sudo apt-get install ibus-gtk ibus-pinyin
~~~

启用IBus框架:

~~~
im-switch -s ibus
~~~

启动ibus：

~~~
ibus-daemon
~~~

# 安装gedit-markdown

~~~
wget https://gitorious.org/projets-divers/gedit-markdown/archive/master.zip
unzip master.zip
cd projets-divers-gedit-markdown
./gedit-markdown.sh install
~~~

# 安装wiz

~~~
sudo add-apt-repository ppa:wiznote-team
sudo apt-get update
sudo apt-get install wiznote
~~~

# 安装 oh-my-zsh

~~~
sudo apt-get install zsh
~~~

把默认 Shell 换为 zsh。

~~~
chsh -s /bin/zsh
~~~

然后用下面的两句（任选其一）可以自动安装 oh-my-zsh：

~~~
curl -L https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sh
~~~

~~~
wget --no-check-certificate https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O - | sh
~~~

编辑`~/.zshrc`：

~~~
echo 'source ~/.bashrc' >>~/.zshrc
echo 'source ~/.bash_profile' >>~/.zshrc
~~~

# 博客相关
## 安装Ruby

通过rvm安装ruby：

~~~
curl -L get.rvm.io | bash -s stable
source ~/.bash_profile
sed -i -e 's/ftp\.ruby-lang\.org\/pub\/ruby/ruby\.taobao\.org\/mirrors\/ruby/g' ~/.rvm/config/db
~~~

安装rvm:

~~~
sudo apt-get install clang -y
rvm install 1.9.3 --with-gcc=clang
rvm --default 1.9.3
~~~

## 安装jekyll

~~~
gem update --system
gem install rdoc jekyll redcarpet
~~~

## 安装七牛同步脚本

~~~
wget http://devtools.qiniudn.com/linux_amd64/qiniu-devtools.zip
unzip qiniu-devtools.zip
mv _package_linux_amd64/* /usr/bin/
source ~/.bashrc
~~~

## 更新ssh-key

更新github和gitcafe的ssh-key

# 安装 virtualbox

~~~
wget -q http://download.virtualbox.org/virtualbox/debian/oracle_vbox.asc -O- | sudo apt-key add -
sudo apt-get update
sudo apt-get install virtualbox-4.3
~~~

# 安装fortune-zh

~~~
sudo apt-get install fortune-zh
~~~

`/usr/bin/mint-fortune` 中调用语句改为:

~~~bash
/usr/games/fortune 70% tang300 30% song100 | $command -f $cow -n
~~~

这里的70%与30%是显示唐诗与宋词的概率。

~~~
gsettings set com.linuxmint.terminal show-fortunes true
~~~

# 修改分区权限

~~~
sudo chown -R june:june /chan
~~~

# 重命名home下目录

先手动重命名:

~~~
文档   --->  projects
音乐   --->  app
图片   --->  codes
视频   --->  workspace
下载   --->  downloads
~~~

然后,删除这些目录,建立软连接:

~~~
rm -rf projects app codes workspace downloads
ln -s /chan/app  ~/app
ln -s /chan/codes   ~/codes
ln -s /chan/projects  ~/projects
ln -s /chan/workspace  ~/workspace
ln -s /chan/downloads    ~/downloads
~~~

# 安装开发环境

配置ant、maven和ivy仓库

~~~
chmod +x /chan/app/apache/apache-maven-3.0.5/bin/mvn
chmod +x /chan/app/apache/apache-ant-1.9.4/bin/ant

rm -rf /home/june/.ivy2/cache /home/june/.m2/repository
mkdir -p /home/june/.ivy2 /home/june/.m2
ln -s /chan/app/repository/cache/  /home/june/.ivy2/cache
ln -s /chan/app/repository/m2/  /home/june/.m2/repository
~~~

安装jdk1.6

~~~
wget http://archive.cloudera.com/cm4/ubuntu/precise/amd64/cm/pool/contrib/o/oracle-j2sdk1.6/oracle-j2sdk1.6_1.6.0+update31_amd64.deb
dpkg -i oracle-j2sdk1.6_1.6.0+update31_amd64.deb
~~~

配置环境变量：

~~~
sudo mkdir -p /usr/java/
sudo ln -s /usr/lib/jvm/j2sdk1.6-oracle /usr/java/latest
sudo update-alternatives --install /usr/bin/java java /usr/java/latest/bin/java 5
sudo update-alternatives --install /usr/bin/javac javac /usr/java/latest/bin/javac 5
sudo update-alternatives --set java /usr/java/latest/bin/java


if [ -f ~/.bashrc ] ; then
    sed -i '/^export[[:space:]]\{1,\}JAVA_HOME[[:space:]]\{0,\}=/d' ~/.bashrc
    sed -i '/^export[[:space:]]\{1,\}CLASSPATH[[:space:]]\{0,\}=/d' ~/.bashrc
    sed -i '/^export[[:space:]]\{1,\}PATH[[:space:]]\{0,\}=/d' ~/.bashrc
fi
echo "export JAVA_HOME=/usr/java/latest" >> ~/.bashrc
echo "export CLASSPATH=.:\$JAVA_HOME/lib/tools.jar:\$JAVA_HOME/lib/dt.jar">>~/.bashrc
echo "export MVN_HOME=/chan/app/apache/apache-maven-3.0.5" >> ~/.bashrc

echo "export ANT_HOME=/chan/app/apache/apache-ant-1.9.4" >> ~/.bashrc
echo "export PATH=\$JAVA_HOME/bin:\$MVN_HOME/bin:\$ANT_HOME/bin:\$PATH" >> ~/.bashrc
source ~/.bashrc
~~~

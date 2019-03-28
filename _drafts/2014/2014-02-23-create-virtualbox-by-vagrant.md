---
layout: post
title: 使用Vagrant创建虚拟机安装Hadoop
description: Vagrant是一款用来构建虚拟开发环境的工具，非常适合 php/python/ruby/java 这类语言开发 web 应用，使用Vagrant可以快速的搭建虚拟机并安装自己的一些应用。本文主要是使用Vagrant创建3个虚拟机并用来安装hadoop集群。
category: hadoop
tags: [hadoop, vagrant]

---

# 安装VirtualBox

下载地址：[https://www.virtualbox.org/wiki/Downloads/](https://www.virtualbox.org/wiki/Downloads/)

# 安装Vagrant

下载安装包：[http://downloads.vagrantup.com/](http://downloads.vagrantup.com/)，然后安装。

# 下载box

下载适合你的box，地址：<http://www.vagrantbox.es/>。

例如下载 CentOS6.5：

~~~
$ wget https://github.com/2creatives/vagrant-centos/releases/download/v6.5.3/centos65-x86_64-20140116.box
~~~

# 添加box

首先查看已经添加的box：

~~~bash
$ vagrant box list
~~~

添加新的box，可以是远程地址也可以是本地文件，建议先下载到本地再进行添加：

~~~bash
$ vagrant box add centos6.5 ./centos65-x86_64-20140116.box
~~~

其语法如下：

~~~bash
vagrant box add {title} {url}
~~~

box 被安装在 `~/.vagrant.d/boxes` 目录下面。

# 创建虚拟机

先创建一个目录：

~~~bash
$ mkdir -p ~/workspace/vagrant/cdh
~~~

初始化，使用 centos6.5 box：

~~~bash
$ cd ~/workspace/vagrant/cdh
$ vagrant init centos6.5
~~~

输出如下日志：

~~~
A `Vagrantfile` has been placed in this directory. You are now
ready to `vagrant up` your first virtual environment! Please read
the comments in the Vagrantfile as well as documentation on
`vagrantup.com` for more information on using Vagrant.
~~~

在当前目录生成了 Vagrantfile 文件。

# 修改Vagrantfile

修改文件如下：

~~~ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  (1..3).each do |i|
    config.vm.define vm_name = "cdh#{i}"  do |config|
        config.vm.provider "virtualbox" do |v|
            v.customize ["modifyvm", :id, "--name", vm_name, "--memory", "2048",'--cpus', 1]
        end
        config.vm.box = "centos6.5"
        config.vm.hostname =vm_name
        config.ssh.username = "vagrant"
        config.vm.network :private_network, ip: "192.168.56.12#{i}"
	  	config.vm.provision :shell, :path => "bootstrap.sh"
    end
  end
end
~~~

上面的文件中定义了三个虚拟机，三个虚拟机的名字和 hostname 分别为cdh1、cdh2、cdh3，网络使用的是 `host-only` 网络。

在启动成功之后，会运行 bootstrap.sh 脚本，你可以编写你自己的脚本。

# 启动虚拟机

执行以下命令会依次启动三个虚拟机：

~~~bash
$ vagrant up
~~~

启动成功之后，就可以通过 ssh 登陆到虚拟机：

~~~bash
$ vagrant ssh cdh1
~~~

# 虚拟机的初始化设置

创建好的虚拟机有很多地方没有设置，有一些软件没有安装，可以编写一个shell脚本（例如，命名为 bootstrap.sh）进行手动执行,也可以通过provision启动之后自动运行。该脚本内容如下：

~~~bash
#!/usr/bin/env bash

# The output of all these installation steps is noisy. With this utility
# the progress report is nice and concise.
function install {
    echo Installing $1
    shift
    yum -y install "$@" >/dev/null 2>&1
}

echo "Update /etc/hosts"
cat > /etc/hosts <<EOF
127.0.0.1       localhost

192.168.56.121 cdh1
192.168.56.122 cdh2
192.168.56.123 cdh3
EOF

echo "Remove unused logs"
sudo rm -rf /root/anaconda-ks.cfg /root/install.log /root/install.log.syslog /root/install-post.log

echo "Disable iptables"
setenforce 0 >/dev/null 2>&1 && iptables -F

### Set env ###
echo "export LC_ALL=en_US.UTF-8"  >>  /etc/profile
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

echo "Setup yum repos"
rm -rf /etc/yum.repos.d/*
cp /vagrant/*.repo /etc/yum.repos.d/
yum clean all >/dev/null 2>&1

echo "Setup root account"
# Setup sudo to allow no-password sudo for "admin". Additionally,
# make "admin" an exempt group so that the PATH is inherited.
cp /etc/sudoers /etc/sudoers.orig
echo "root            ALL=(ALL)               NOPASSWD: ALL" >> /etc/sudoers
echo 'redhat'|passwd root --stdin >/dev/null 2>&1

echo "Setup nameservers"
# http://ithelpblog.com/os/linux/redhat/centos-redhat/howto-fix-couldnt-resolve-host-on-centos-redhat-rhel-fedora/
# http://stackoverflow.com/a/850731/1486325
echo "nameserver 8.8.8.8" | tee -a /etc/resolv.conf
echo "nameserver 8.8.4.4" | tee -a /etc/resolv.conf

echo "Setup ssh"
[ ! -d /root/.ssh ] && ( mkdir /root/.ssh ) && ( chmod 600 /root/.ssh  ) && yes|ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ""

install Git git
install "Base tools" vim wget curl
install "Hadoop dependencies" expect rsync pssh

install PostgreSQL postgresql-server postgresql-jdbc
sudo -u postgres createuser --superuser vagrant
sudo -u postgres createdb -O vagrant test1
sudo -u postgres createdb -O vagrant test2


echo 'All set, rock on!'
~~~

以上脚本主要做了以下几件事：

- 设置hosts文件
- 设置公网网络下的命名服务解析
- 关掉防火墙
- 设置虚拟机时区
- 修改root帐号密码为redhat
- 生成ssh公要文件
- 配置yum源并安装一些常用软件

以上所有配置可以在 [这里找](https://github.com/javachen/snippets/tree/master/vagrant/cdh) 找到，其中 cdh.repo 内容如下：

~~~
[cdh]
name=cdh
baseurl=http://192.168.56.1/cdh/5.2.0/
enabled=1
gpgcheck=0

[hadoop-repo]
name=hadoop-repo
baseurl=http://192.168.56.1/hadoop-repo/
enabled=1
gpgcheck=0
~~~

上面文件包括 cdh 和 hadoop 相关的一些依赖，这些需要通过 apache 服务在宿主机上配置好。

# 安装hadoop

可以参考[这些文章](http://blog.javachen.com/categories.html#hadoop-ref)

你可以参考上面的文章手动安装 hadoop，也可以通过我写的 [shell](https://github.com/javachen/hadoop-install/tree/master/shell) 脚本来安装。

步骤：

1.在虚拟机中选择一个节点为管理节点，然后下载仓库

~~~bash
$ git clone https://github.com/javachen/hadoop-install.git
~~~

2.进入 hadoop-install/shell 目录，参考 READEME.md 中说明来安装集群。

---
layout: post
title: 使用Vagrant创建虚拟机
description: Vagrant是一款用来构建虚拟开发环境的工具，非常适合 php/python/ruby/java 这类语言开发 web 应用，使用Vagrant可以快速的搭建虚拟机并安装自己的一些应用。本文主要是使用Vagrant创建3个虚拟机并用来安装hadoop集群。
category: devops
tags: [ vagrant]

---

# 安装VirtualBox

下载地址：[https://www.virtualbox.org/wiki/Downloads/](https://www.virtualbox.org/wiki/Downloads/)

# 安装Vagrant

下载安装包：[http://downloads.vagrantup.com/](http://downloads.vagrantup.com/)，然后安装。

# 下载box

下载适合你的box，地址：<http://www.vagrantbox.es/>。

例如下载 CentOS7.2：

~~~
$ wget https://github.com/CommanderK5/packer-centos-template/releases/download/0.7.2/vagrant-centos-7.2.box
~~~

# 添加box

首先查看已经添加的box：

~~~bash
$ vagrant box list
~~~

添加新的box，可以是远程地址也可以是本地文件，建议先下载到本地再进行添加：

~~~bash
$ vagrant box add centos7.2 ./vagrant-centos-7.2.box
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

初始化，使用 centos7.2 box：

~~~bash
$ cd ~/workspace/vagrant/cdh
$ vagrant init centos7.2
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

修改Vagrantfile文件，创建三个虚拟机，如下：

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
        config.vm.box = "centos7.2"
        config.vm.hostname ="#{vm_name}.example.com"
        config.ssh.username = "vagrant"
        config.vm.network :private_network, ip: "192.168.56.12#{i}"
      config.vm.provision :shell, :path => "bootstrap.sh"
    end
  end
end
~~~

这里设置hostname为域名格式，如：cdh1.example.com。

网络使用的是 `host-only` 网络。

在启动成功之后，会运行 bootstrap.sh 脚本进行初始化工作。该脚本内容如下：

~~~bash
#!/usr/bin/env bash

# The output of all these installation steps is noisy. With this utility
# the progress report is nice and concise.
function install {
    echo Install $1
    shift
    yum -y install "$@" >/dev/null 2>&1
}

echo "Begin to run bootstrap: $(date)"

echo "Remove unused logs"
rm -rf /root/*.log

echo "Setup yum repos"
rm -rf /etc/yum.repos.d/*
yum clean all >/dev/null 2>&1
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
yum install wget vim -y

echo "Disable iptables"
setenforce 0 >/dev/null 2>&1 && iptables -F

echo "Disable IPv6"
cat > /etc/sysctl.conf <<EOF
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1
EOF
sysctl -p
cat /proc/sys/net/ipv6/conf/all/disable_ipv6

echo "Update /etc/hosts"
cat > /etc/hosts <<EOF
127.0.0.1       localhost
192.168.56.121 cdh1 cdh1.example.com
192.168.56.122 cdh2 cdh2.example.com
192.168.56.123 cdh3 cdh3.example.com
EOF

echo "Set hostname"
echo "hostname:${hostname}"
hostnamectl set-hostname $(hostname)
cat > /etc/sysconfig/network<<EOF
HOSTNAME=$(hostname)
EOF
echo "Check hostname"
cat /etc/sysconfig/network
uname -a
yum install net-tools -y && ifconfig |grep -B1 broadcast
yum install bind-utils -y && host -v -t A `hostname`

echo "Set locale and timezone"
#yum groupinstall "fonts" -y
cat > /etc/locale.conf <<EOF
LANG="zh_CN.UTF-8"
LC_CTYPE=zh_CN.UTF-8
LC_ALL=zh_CN.UTF-8
EOF
source   /etc/locale.conf
echo "Check locale"
cat /etc/locale.conf
cp /usr/share/zoneinfo/Asia/Shanghai -f -n /etc/localtime

echo "Setup root paassword"
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

echo "Generate root ssh"
[ ! -d ~/.ssh ] && ( mkdir /root/.ssh ) && ( chmod 600 ~/.ssh  ) && yes|ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ""

echo "Set npt service"
yum install ntp -y
cat > /etc/ntp.conf  <<EOF
restrict default ignore   //默认不允许修改或者查询ntp,并且不接收特殊封包
restrict 127.0.0.1        //给于本机所有权限
restrict 192.168.56.0 mask 255.255.255.0 notrap nomodify  //给于局域网机的机器有同步时间的权限
server  192.168.56.121     # local clock
driftfile /var/lib/ntp/drift
fudge   127.127.1.0 stratum 10
EOF
chkconfig ntpd on && service ntpd restart

echo "Set swappiness"
sysctl -w vm.swappiness=0
echo vm.swappiness = 0 >> /etc/sysctl.conf

echo "Install jdk"
yum install java-1.7.0-openjdk  java-1.7.0-openjdk-devel -y

echo "Finish to run bootstrap: $(date)"
~~~

以上脚本主要做了以下几件事：

- 1、删除无用的日志
- 2、设置yum源
- 3、禁用iptables
- 4、禁用IPv6
- 5、设置hosts文件
- 6、设置hostname
- 7、设置时区
- 8、修改root帐号密码为redhat
- 9、设置命名服务
- 10、生成ssh公要文件
- 11、安装并启动ntp服务
- 12、设置swappiness
- 13、安装jdk

以上所有配置可以在 [这里找](https://github.com/javachen/snippets/tree/master/vagrant/cdh) 找到。

# 创建并启动虚拟机

执行以下命令会依次启动三个虚拟机：

~~~bash
$ vagrant up
~~~

启动成功之后，就可以通过 ssh 登陆到虚拟机：

~~~bash
$ vagrant ssh cdh1
~~~

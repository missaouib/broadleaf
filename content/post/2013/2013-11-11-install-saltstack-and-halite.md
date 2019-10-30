---
layout: post
title: 安装SaltStack和Halite
date: 2013-11-11T00:00:00+08:00
description: 本文记录安装SaltStack和halite过程。
hadoop: [devops]
tags: [saltstack,halite]
---

本文记录安装SaltStack和halite过程。

首先准备两台rhel或者centos虚拟机sk1和sk2，sk1用于安装master，sk2安装minion。


# 配置yum源

在每个节点上配置yum源：

~~~
$ rpm -ivh http://mirrors.sohu.com/fedora-epel/6/x86_64/epel-release-6-8.noarch.rpm
~~~

然后通过下面命令查看epel参考是否安装成功：

~~~
$ yum list #或者查看/etc/yum.repos.d目录下是否有epel.repo
~~~

如果没有安装成功，则可以手动下载`epel-release-6-8.noarch.rpm`，然后打开该rpm找到`./etc/yum.repos.d/epel.repo`，将其拷贝到`/etc/yum.repos.d`目录


# 安装依赖

因为我用jinja2作为SaltStack的渲染引擎，故需要在每个节点上安装`python-jinja2`：

~~~
$ yum install python-jinja2 -y
~~~

# 安装saltstack

在sk1上安装master：

~~~
$ yum install salt-master
~~~

在sk1上安装minion：

~~~
$ yum install salt-minion
~~~

# 关闭防火墙

~~~
$ iptables -F
$ setenforce 0
~~~

# 修改配置文件

修改master配置文件，使其监听`0.0.0.0`地址，并设置自动接受minion的请求。

~~~
$ vim /etc/salt/master
 interface: 0.0.0.0 #去掉对该行的注释
 auto_accept: True #去掉对该行的注释,并修改False为True
~~~

在所有的minion节点配置master的id和自己的id：

~~~
$ vim /etc/salt/minion
 master: sk1
 id: sk2
~~~

# 启动

分别在sk1和sk2上配置开机启动：

~~~
$ chkconfig salt-master on
$ chkconfig salt-minion on
~~~

分别在sk1和sk2上以service方式启动：

~~~
$ /etc/init.d/salt-master start
$ /etc/init.d/salt-minion start
~~~

你可以在sk2上以后台运行salt-minion

~~~
$ salt-minion -d
~~~

或者在sk2上debug方式运行：

~~~
$ salt-minion -l debug
~~~

# 排错

如果启动提示如下错误：

~~~
$  /etc/init.d/salt-master start
Starting salt-master daemon: Traceback (most recent call last):
 File "/usr/bin/salt-master", line 10, in <module>
   salt_master()
 File "/usr/lib/python2.6/site-packages/salt/scripts.py", line 20, in salt_master
   master.start()
 File "/usr/lib/python2.6/site-packages/salt/__init__.py", line 114, in start
   if check_user(self.config['user']):
 File "/usr/lib/python2.6/site-packages/salt/utils/verify.py", line 296, in check_user
   if user in e.gr_mem] + [pwuser.gid])
AttributeError: 'pwd.struct_passwd' object has no attribute 'gid'
~~~

请下载saltstack源码重新编译：

~~~
$ wget https://github.com/saltstack/salt/archive/develop.zip
$ unzip develop
$ cd salt-develop/
$ python2.6 setup.py install
~~~

如果你通过'cmd.run'命令去运行java命令，你会得到这样的结果：

~~~
[root@sk1 salt]# salt '*' cmd.run 'java' 
sk2:
    /bin/bash: java: command not found
~~~

这是因为minion在启动过程中并没有加载系统的环境变量，解决这个问题有两种方式：

- 运行java命令前先`source`环境变量
- 修改minion启动脚本，添加source命令：

~~~
# Source function library.
if [ -f $DEBIAN_VERSION ]; then
   break
elif [ -f $SUSE_RELEASE -a -r /etc/rc.status ]; then
    . /etc/rc.status
else
    . /etc/rc.d/init.d/functions
    . ~/.bashrc
    . /etc/profile
fi
~~~


# salt minion和master的认证过程

- minion在第一次启动时，会在/etc/salt/pki/minion/下自动生成minion.pem(private key), minion.pub(public key)，然后将minion.pub发送给master
- master在接收到minion的public key后，通过salt-key命令accept minion public key，这样在master的/etc/salt/pki/master/minions下的将会存放以minion id命名的public key, 然后master就能对minion发送指令了

master上执行：

~~~
[root@sk1 pillar]# salt-key -L
Accepted Keys:
Unaccepted Keys:
Rejected Keys:
~~~

接受所有的认证请求：

~~~
[root@sk1 pillar]# salt-key -A
~~~

再次查看：

~~~
[root@sk1 pillar]# salt-key -L
Accepted Keys:
sk2
Unaccepted Keys:
Rejected Keys:
~~~


`salt-key`更多说明：[http://docs.saltstack.com/ref/cli/salt-key.html](http://docs.saltstack.com/ref/cli/salt-key.html)

# 测试运行

在master上运行ping：

~~~
[root@sk1 pillar]# salt '*' test.ping
sk2:salt '*' test.ping
    True
~~~


True表明测试成功。


# 安装halite

## 下载代码

~~~
$ git clone https://github.com/saltstack/halite
~~~

## 生成index.html

~~~
$ cd halite/halite
$ ./genindex.py -C
~~~

## 安装salt-api

~~~
$ yum install salt-api
~~~

## 配置salt master文件

配置salt的master文件，添加：

~~~python
rest_cherrypy:
 host: 0.0.0.0
 port: 8080
 debug: true
 static: /root/halite/halite
 app: /root/halite/halite/index.html
external_auth:
   pam:
     admin:
	 - .*
	 - '@runner'
	 - '@wheel'
~~~

重启master;

~~~
$ /etc/init.d/salt-master restart
~~~

## 添加登陆用户

~~~
$ useradd admin
$ echo admin|passwd –stdin admin
~~~

## 启动 salt-api

~~~
$ cd halite/halite
$ python2.6 server_bottle.py -d -C -l debug -s cherrypy
~~~

然后打开`http://ip:8080/app`，通过admin/admin登陆即可。


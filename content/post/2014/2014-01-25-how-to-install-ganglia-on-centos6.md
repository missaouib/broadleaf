---
layout: post
title: 在CentOs6系统上安装Ganglia
date: 2014-01-25T08:00:00+08:00
description: Ganglia是UC Berkeley发起的一个开源集群监视项目，设计用于测量数以千计的节点。Ganglia的核心包含gmond、gmetad以及一个Web前端。主要是用来监控系统性能，由RRDTool工具处理数据，并生成相应的的图形显示，以Web方式直观的提供给客户端。如：cpu 、mem、硬盘利用率， I/O负载、网络流量情况等，通过曲线很容易见到每个节点的工作状态，对合理调整、分配系统资源，提高系统整体性能起到重要作用。
categories: [ devops ]
tags: [ganglia]
---

Ganglia是UC Berkeley发起的一个开源集群监视项目，设计用于测量数以千计的节点。Ganglia的核心包含gmond、gmetad以及一个Web前端。主要是用来监控系统性能，由RRDTool工具处理数据，并生成相应的的图形显示，以Web方式直观的提供给客户端。如：cpu 、mem、硬盘利用率， I/O负载、网络流量情况等，通过曲线很容易见到每个节点的工作状态，对合理调整、分配系统资源，提高系统整体性能起到重要作用。

# 配置yum源

首先配置好CentOs系统的yum源，然后需要包含有ganglia的yum源。

在`/etc/yum.repos.d`下创建`ganglia.repo`，内容如下：

~~~
[ganglia]
name= ganglia
baseurl = http://vuksan.com/centos/RPMS/
enabled = 1
gpgcheck = 0
~~~
为了方便离线使用，你可以下载该yum源内容：

~~~
$ cd /opt
$ reposync -r ganglia
~~~
<!-- more -->

然后在`/opt/ganglia`下执行如下的命令：

~~~
$ createrepo .
~~~

这样你就可以将`ganglia.repo`修改为本地yum的方式。

# 管理机上安装gmetad

执行如下命令：

~~~
$ yum -y install ganglia-gmetad
~~~

安装时遇到如下的错误：

~~~
Error: Package: rrdtool-1.4.5-1.x86_64 (ganglia)
          Requires: dejavu-lgc-fonts
~~~

rrdtool依赖`dejavu-lgc-fonts`，但是系统源并不包含这个，你可以从网上下载，然后安装：

~~~
$ rpm -Uvh http://mirror.steadfast.net/centos/5/os/x86_64//CentOS/dejavu-lgc-fonts-2.10-1.noarch.rpm
~~~
# 管理机上安装ganglia-web

先安装apache和php等依赖：

~~~
$ yum install php* httpd
~~~

然后下载ganglia-web:

~~~
$ wget http://sourceforge.net/projects/ganglia/files/ganglia-web/3.5.12/ganglia-web-3.5.12.tar.gz/download

$ tar zxvf ganglia-web-3.5.12.tar.gz
$ cd ganglia-web-3.5.12
$ make install
~~~
将ganglia-web拷贝或者添加软链接到apache的目录下去，以下是拷贝：

~~~
$ mkdir /var/www/html/ganglia
$ cp -a  /usr/share/ganglia/   /var/www/html/ganglia
~~~

在httpd的conf.d目录下添加ganglia.conf，命令：

~~~
$ vim /etc/httpd/conf.d/ganglia.conf
~~~

内容如下：

~~~
<Location /ganglia>
    Order deny,allow
    Deny from all
    ALLOW from all
#    Allow from 127.0.0.1
#    Allow from ::1
#    Allow from .example.com
</Location>
~~~

# 客户端机器上安装gmond

执行如下命令：

~~~
$ yum install gmond
~~~

# 启动服务

在管理机上启动gmetad

~~~
$ /etc/init.d/gmetad start
~~~

在客户端机器上启动gmond

~~~
$ /etc/init.d/gmond start
~~~

在管理机上启动httpd

~~~
$ /etc/init.d/httpd start
~~~

然后通过web界面（`http://manager-ip/ganglia`）访问ganglia-web

# 参考文章

- [1] [ganglia监控的搭建部署(从源码安装)](http://www.elain.org/?p=359)



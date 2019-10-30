---
layout: post
title: SaltStack学习笔记
date: 2013-11-18T00:00:00+08:00
description: 这份文档如其名，是我自己整理的学习 SaltStack 的过程记录。只是过程记录，没有刻意像教程那样去做。所以呢，从前至后，中间不免有一些概念不清不明的地方。因为事实上，在某个阶段对于一些概念本来就不可能明白。所以，整个过程只求在形式上的能用即可。前面就不要太纠结概念和原理，知道怎么用就好。
hadoop: [devops]
tags: [saltstack]
---

# 1. 关于本文档

这份文档如其名，是我自己整理的学习 SaltStack 的过程记录。只是过程记录，没有刻意像教程那样去做。所以呢，从前至后，中间不免有一些概念不清不明的地方。因为事实上，在某个阶段对于一些概念本来就不可能明白。所以，整个过程只求在形式上的能用即可。前面就不要太纠结概念和原理，知道怎么用就好。

希望这篇文章能够让你快速了解并使用saltstack。文章还在编写中。

# 2. 关于SaltStack

## 2.1. 什么是SaltStack
SaltStack是开源的管理基础设置的轻量级工具，容易搭建，为远程管理服务器提供一种更好、更快速、更有扩展性的解决方案。通过简单、可管理的接口，Salt实现了可以管理成千上百的服务器和处理大数据的能力。

- 轻量级配置管理系统，能够维持远端节点运行在预定状态（例如，确保指定的软件包已经安装和特定的系统服务正在运行）
- 分布式远程执行系统，用于在远端节点执行命令和查询数据，可以是单独，也可以是选定的条件

## 2.2. SaltStack特点

###  简单

兼顾大规模部署与更小的系统的同时提供多功能性是很困难的，Salt是非常简单配置和维护，不管项目的大小。Salt可以胜任管理任意的数量的服务器，不管是本地网络，还是跨数据中心。架构采用C/S模式，在一个后台程序中集成必要功能。默认不需要复杂的配置就可以工作，同时可以定制用于特殊的需求。

### 并行执行

Salt的核心功能：

- 通过并行方式让远端节点执行命令
- 采用安全的加密/解析协议
- 最小化使用网络和负载
- 提供简单的程序接口
- Salt引入了更细粒度的控制，允许不通过目标名字，二是通过系统属性分类

### 构建在成熟技术之上

Salt采用了很多技术和技巧。网络层采用优秀的ZeroMQ库，所以守护进程里面包含AMQ代理。Salt采用公钥和主控通讯，同时使用更快的AES加密通信，验证和加密都已经集成在Salt里面。Salt使用msgpack通讯，所以更快速和更轻量网络交换。

### Python 客户端接口

为了实现简单的扩展，Salt执行例程可以写成简单的Python模块。客户端程序收集的数据可以发送回主控端，可以是其他任意程序。可以通过Python API调用Salt程序，或者命令行，因此，Salt可以用来执行一次性命令，或者大型应用程序中的一部分模块。

###  快速，灵活，可扩展

结果是一个系统可以高速在一台或者一组服务器执行命令。Salt速度很快，配置简单，扩展性好，提供了一个远程执行架构，可以管理多样化需求的任何数量的服务器。整合了世界上最好的远程执行方法，增强处理能力，扩展使用范围，使得可以适用任何多样化复杂的网络。

### 开源

Salt基于Apache 2.0 licence开发，可以用于开源或者自有项目。请反馈你的扩展给项目组，以便更多人受益，共同促进Salt发展。请在你的系统部署 系统，让运维更便捷。

开发语言：Python

## 2.3. 支持的系统

常见的系统包可以直接下载安装使用：

- [Fedora](https://admin.fedoraproject.org/pkgdb/acls/name/salt)
- RedHat Enterprise Linux / Centos ([EPEL 5](http://dl.fedoraproject.org/pub/epel/5/x86_64/repoview/salt.html), [EPEL 6](http://dl.fedoraproject.org/pub/epel/6/x86_64/repoview/salt.html))
- [Ubuntu (PPA)](https://launchpad.net/~saltstack)
- [Arch (AUR)](http://aur.archlinux.org/packages.php?ID=47512)
- [FreeBSD](http://www.freebsd.org/cgi/cvsweb.cgi/ports/sysutils/salt/)
- [Gentoo](http://packages.gentoo.org/package/app-admin/salt)
- [Debian (sid)](http://packages.debian.org/sid/salt-master)
- [Debian (experimental)](http://packages.debian.org/experimental/salt-master)

# 3. 安装SaltStack

## 3.1. 依赖
SaltStack只能安装在类unix的操作系统上并依赖以下组件：

- [Python 2.6](http://python.org/download/) >= 2.6 <3.0
- [ZeroMQ](http://www.zeromq.org/) >= 2.1.9
- [pyzmq](https://github.com/zeromq/pyzmq) >= 2.1.9 - ZeroMQ Python bindings
- [PyCrypto](http://www.dlitz.net/software/pycrypto/) - The Python cryptography toolkit
- [msgpack-python](http://pypi.python.org/pypi/msgpack-python/0.1.12) - High-performance message interchange format
- [YAML](http://pyyaml.org/) - Python YAML bindings
- [Jinja2](http://jinja.pocoo.org/) - parsing Salt States (configurable in the master settings)

可选的依赖：

- [mako](http://www.makotemplates.org/) - an optional parser for Salt States (configurable in the master settings)
- gcc - dynamic [Cython](http://cython.org/) module compiling

## 3.2. 快速安装
可以使用官方提供的[Salt Bootstrap](https://github.com/saltstack/salt-bootstrap)来快速安装SaltStack。

安装master：

~~~
curl -L http://bootstrap.saltstack.org | sudo sh -s -- -M -N
~~~

安装minion：

~~~
wget -O - http://bootstrap.saltstack.org | sudo sh
~~~

当前[Salt Bootstrap](https://github.com/saltstack/salt-bootstrap)已经在以下操作系统测试通过：

- Ubuntu 10.x/11.x/12.x
- Debian 6.x
- CentOS 6.3
- Fedora
- Arch
- FreeBSD 9.0

## 3.3. 通过rpm安装

### 3.3.1. 下载EPEL yum源：

RHEL 5系统:

~~~
rpm -Uvh http://mirror.pnl.gov/epel/5/i386/epel-release-5-4.noarch.rpm
~~~

RHEL 6系统:

~~~
rpm -Uvh http://ftp.linux.ncsu.edu/pub/epel/6/i386/epel-release-6-8.noarch.rpm
~~~

### 3.3.2. 安装包
在master上运行：

~~~
yum install salt-master
~~~

在minion上运行：

~~~
yum install salt-minion
~~~

### 3.3.3. 安装后
master上设置开启启动并启动服务：

~~~
chkconfig salt-master on
service salt-master start
~~~

minion上设置开启启动并启动服务：

~~~
chkconfig salt-minion on
service salt-minion start
~~~

### 3.4. 排错
当前最新版为0.17.1，如果你也是使用的这个版本并且启动提示如下错误：

~~~
[root@sk1 vagrant]# /etc/init.d/salt-master start
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

通过google搜索关键字`saltstack 'pwd.struct_passwd' object has no attribute 'gid'`，可以找到这个[issues](https://github.com/saltstack/salt/issues/8176)，查看评论可以发现这是一个bug，将会在0.17.2中被修复。


我的解决方法是：下载saltstack源码重新编译

~~~
wget https://github.com/saltstack/salt/archive/develop.zip
unzip develop
cd salt-develop/
python2.6 setup.py install
~~~

# 4. 配置SaltStack

## 4.1. master配置
master不修改配置文件就可以运行，而minion必须修改配置文件中的master id才能和master通讯，配置文件分别在`/etc/salt/master` 和 `/etc/salt/minion`。

master默认监控0.0.0.0上4505和4506端口，你可以在`/etc/salt/master`中修改为指定ip。

master关键配置：

- `interface`
- `publish_port`
- `user`
- `max_open_files`
- `worker_threads`
- `ret_port`
- `pidfile`
- `root_dir`
- `pki_dir`
- `cachedir`
- `keep_jobs`
- `job_cache`
- `ext_job_cache`
- `minion_data_cache`
- `enforce_mine_cache`
- `sock_dir`

Master Security配置

- `open_mode`
- `auto_accept`
- `autosign_file`
- `client_acl`
- `client_acl_blacklist`
- `external_auth`
- `token_expire`

Master Module管理

- `runner_dirs`
- `cython_enable`

Master State设置

- `state_verbose`
- `state_output`
- `state_top`
- `external_nodes`
- `renderer`
- `failhard`
- `test`

Master File Server设置

- `fileserver_backend`
- `file_roots`
- `hash_type`
- `file_buffer_size`

Pillar配置

- `pillar_roots`
- `ext_pillar`

Syndic Server设置

- `order_masters`
- `syndic_master`
- `syndic_master_port`
- `syndic_log_file`
- `syndic_pidfile`

Peer发布设置

- `peer`
- `peer_run`

Node Groups设置

Master Logging设置

- `log_file`
- `log_level`
- `log_level_logfile`
- `log_datefmt`
- `log_datefmt_logfile`
- `log_fmt_console`
- `log_fmt_logfile`
- `log_granular_levels`

Include配置

- `default_include`
- `include`

## 4.4. minion配置

Minion主要配置：

- `master`
- `master_port`
- `user`
- `pidfile`
- `root_dir`
- `pki_dir`
- `id`
- `append_domain`
- `cachedir`
- `verify_env`
- `cache_jobs`
- `sock_dir`
- `backup_mode`
- `acceptance_wait_time`
- `random_reauth_delay`
- `cceptance_wait_time_max`
- `dns_check`
- `ipc_mode`
- `tcp_pub_port`
- `tcp_pull_port`

Minion Module管理

- `disable_modules`
- `disable_returners`
- `module_dirs`
- `returner_dirs`
- `states_dirs`
- `render_dirs`
- `cython_enable`
- `providers`

State Management 设置

- `renderer`
- `state_verbose`
- `state_output`
- `autoload_dynamic_modules`
- `environment`

File目录设置

- `file_client`
- `file_roots`
- `hash_type`
- `pillar_roots`

Security设置

- `open_mode`

线程设置

- `multiprocessing`

Minion日志设置

- `log_file`
- `log_level`
- `log_level_logfile`
- `log_datefmt`
- `log_datefmt_logfile`
- `log_fmt_console`
- `log_fmt_logfile`
- `log_granular_levels`

Include配置

- `default_include`
- `include`

Frozen Build Update Settings

- `update_url`
- `update_restart_services`

# 5. 初识SaltStack

## 5.1. 配置
参考上面的配置文件说明修改master和minion配置。这里我的master主机名为sk1，minion主机名为sk2。

修改master配置文件/etc/salt/master

~~~
interface: 0.0.0.0
auto_accept: True
~~~

修改minion配置文件/etc/salt/minion

~~~
master: sk1
id: sk2
~~~

## 5.2. 运行salt
然后运行salt，启动master（添加`-d`参数可以让其后台运行）：

~~~
salt-master
~~~

启动minion（添加-d参数可以让其后台运行）：

~~~
salt-minion
~~~

如果需要排错，可以添加设置日志级别：

~~~
salt-master --log-level=debug
~~~

如果想以非用户运行，可以添加`--user`参数

## 5.3. 管理Key
Salt在master和minion通信之间使用AES加密。在master和minion通信之前，minion上的key需要发送到master并被master接受。可以在master上查看已经接受的key：

~~~
[root@sk1 pillar]# salt-key -L
Accepted Keys:
Unaccepted Keys:
sk2
Rejected Keys:
~~~

然后运行下面命令可以接受所有未被接受的key：

~~~
[root@sk1 pillar]# salt-key -A
~~~

## 5.4. 发送命令

在master上发送ping命令检测minon是否被认证成功：

~~~
[root@sk1 pillar]# salt '*' test.ping
sk2:salt '*' test.ping
    True
~~~

True表明测试成功。

# 6. 配置管理
## 6.1 states
## 6.1.1 states文件

salt states的核心是sls文件，该文件使用YAML语法定义了一些k/v的数据。

sls文件存放根路径在master配置文件中定义，默认为`/srv/salt`,该目录在操作系统上不存在，需要手动创建。

在salt中可以通过`salt://`代替根路径，例如你可以通过`salt://top.sls`访问`/srv/salt/top.sls`。

在states中top文件也由master配置文件定义，默认为top.sls，该文件为states的入口文件。

一个简单的sls文件如下：

~~~
 apache:
  pkg:
    - installed
  service:
    - running
    - require:
      - pkg: apache
~~~

说明：此SLS数据确保叫做"apache"的软件包(package)已经安装,并且"apache"服务(service)正在运行中。

- 第一行，被称为ID说明(ID Declaration)。ID说明表明可以操控的名字。
- 第二行和第四行是State说明(State Declaration)，它们分别使用了pkg和service states。pkg state通过系统的包管理其管理关键包，service state管理系统服务(daemon)。 在pkg及service列下边是运行的方法。方法定义包和服务应该怎么做。此处是软件包应该被安装，服务应该处于运行中。
- 第六行使用require。本方法称为"必须指令"(Requisite Statement)，表明只有当apache软件包安装成功时，apache服务才启动起来。

state和方法可以通过点连起来，上面sls文件和下面文件意思相同。

~~~
 apache:
  pkg.installed
  service.running
    - require:
      - pkg: apache
~~~

将上面sls保存为init.sls并放置`在sal://apache`目录下，结果如下：

~~~
/srv/salt
├── apache
│   └── init.sls
└── top.sls
~~~

top.sls如何定义呢？

master配置文件中定义了三种环境，每种环境都可以定义多个目录，但是要避免冲突，分别如下：

~~~
# file_roots:
#   base:
#     - /srv/salt/
#   dev:
#     - /srv/salt/dev/services
#     - /srv/salt/dev/states
#   prod:
#     - /srv/salt/prod/services
#     - /srv/salt/prod/states
~~~

top.sls可以这样定义：

~~~
 base:
   '*':
    - apache
~~~

说明：

- 第一行，声明使用base环境
- 第二行，定义target，这里是匹配所有
- 第三行，声明使用哪些states目录，salt会寻找每个目录下的init.sls文件。

## 6.1.2 运行states

一旦创建完states并修改完top.sls之后，你可以在master上执行下面命令：

~~~
[root@sk1 salt]# salt '*' state.highstate
sk2:
----------
    State: - pkg
    Name:      httpd
    Function:  installed
        Result:    True
        Comment:   The following packages were installed/updated: httpd.
        Changes:
                   ----------
                   httpd:
                       ----------
                       new:
                           2.2.15-29.el6.centos
                       old:

----------
    State: - service
    Name:      httpd
    Function:  running
        Result:    True
        Comment:   Service httpd has been enabled, and is running
        Changes:
                   ----------
                   httpd:
                       True

Summary
------------
Succeeded: 2
Failed:    0
------------
Total:     2
~~~

上面命令会触发所有minion从master下载top.sls文件以及其中定一个的states，然后编译、执行。执行完之后，minion会将执行结果的摘要信息汇报给master。

## 6.2. Grains
## Pillar
## Renderers

# 远程执行命令

在上面的例子中，test.ping是最简单的一个远程执行的命令，你还可以执行一些更加复杂的命令。

salt执行命令的格式如下：

~~~
salt '<target>' <function> [arguments]
~~~

- target: 执行salt命令的目标，可以使用正则表达式
- function： 方法，由module提供
- arguments：function的参数

target可以使用正则表达式匹配：

~~~
salt '*' test.ping
salt 'sk2' test.ping
~~~

function是module提供的方法。通过下面命令可以查看所有的function：

~~~
salt '*' sys.doc
~~~

function可以接受参数：

~~~
salt '*' cmd.run 'uname -a'
~~~

并且支持关键字参数：

~~~
salt '*' cmd.run 'uname -a' cwd=/ user=salt
~~~

上面例子意思是：在所有minion上切换到/目录以salt用户运行`uname -a`命令。


关键字参数可以参考module的[api](http://docs.saltstack.com/py-modindex.html),通过api你可以查看[cmd.run](http://docs.saltstack.com/ref/states/all/salt.states.cmd.html#salt.states.cmd.run)的定义：

~~~
salt.states.cmd.mod_watch(name, **kwargs)
Execute a cmd function based on a watch call

salt.states.cmd.run(name, onlyif=None, unless=None, cwd=None, user=None, group=None, shell=None, env=(), stateful=False, umask=None, quiet=False, timeout=None, **kwargs)
~~~

所有module中的方法定义都与上面类似，说明：

- name： 第一个参数，为执行的命令
- 中间的key=alue为keyword参数，都有默认值
- 最后一个参数为name中命令的输入参数

## TARGETING
## Returners
## Mine

# 参考文章

- [1][Saltstack服务器集中管理和并行下发命令工具](http://zhoulg.blog.51cto.com/48455/1140178)




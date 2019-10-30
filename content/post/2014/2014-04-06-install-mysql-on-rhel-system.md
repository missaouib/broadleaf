---
layout: post
title: RHEL系统安装MySql
date: 2014-04-06T08:00:00+08:00
description: 使用yum方式在RHEL系统下安装MySql数据库
categories: [ database ]
tags: 
 - mysql
published: true
---

# 环境说明

- 操作系统:linux6.4
- MySql版本：percona 5.6.14
- rpm包下载地址：[http://www.percona.com/downloads/Percona-Server-5.6/LATEST/RPM/rhel6/x86_64](http://www.percona.com/downloads/Percona-Server-5.6/LATEST/RPM/rhel6/x86_64)

# 安装步骤

## 1. 安装所需要的rpm包

~~~
rpm -ivh Percona-Server-shared-56-5.6.14-rel62.0.483.rhel6.x86_64.rpm
rpm -ivh Percona-Server-client-56-5.6.14-rel62.0.483.rhel6.x86_64.rpm
rpm -ivh Percona-Server-server-56-5.6.14-rel62.0.483.rhel6.x86_64.rpm
~~~

**注意:**

第三个包依赖前2个包，第三个包安装时可能会报错，需要将系统中原先的mysql-libs卸载（`yum remove mysql-libs`）

没有yum使用`rpm -e --nodeps`的方式卸载安装包，可以使用`rpm -qa | grep mysql`的方式查看安装的包

## 2. 启动mysql

~~~
#service mysql start 
~~~

停止：stop 重启：restart，查看状态：status

## 3. 设置远程登录

~~~
#mysql
mysql> grant all PRIVILEGES on test.* to test@'%' identified by 'test';
mysql>flush privileges;
~~~

将test数据库的权限授予test用户，登录密码是test，%代表所有ip。

## 4. 配置文件

rpm包默认配置启动文件模板`/usr/share/doc/Percona-Server-server-56-5.6.14/my-default.cnf`，可以将他拷贝到`/etc/my.cnf`作为配置文件使用。

配置文件修改举例：

~~~
$ cp /usr/share/doc/Percona-Server-server-56-5.6.14/my-default.cnf /etc/my.cnf
$ vim /etc/my.cnf 			#将需要修改的参数做如下填写
[mysqld]
# These are commonly set, remove the # and set as required.
# basedir = .....
# datadir = .....
# port = .....
# server_id = .....
# socket = .....
innodb_file_format=barracuda
innodb_file_per_table=true
innodb_large_prefix=on
~~~

上面参数作用，可以解决建索引时`Specified key was too long; max key length is 767 bytes`的报错，拓展支持的最大索引长度，如使用上述功能建表时加`ROW_FORMAT=DYNAMIC`

数据目录默认：`/var/lib/mysql/`

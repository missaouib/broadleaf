---
layout: post
title: RHEL系统安装PostgreSQL
date: 2014-04-07T08:00:00+08:00
description: PostgreSQL 是一个开放源码的免费数据库系统。Postgres 最初由加州大学伯克利分校计算机科学系开发，倡导了很多关系对象的观念，这些观念现在已经用在一些商业数据库系统中。它提供了 SQL92/SQL99 语言支持，事务处理，引用集成，存储过程以及类型扩展。PostgreSQL 则是 Postgres 的一个开放源代码的后代。
categories: [ database ]
tags: 
 - postgresql
published: true
---

# 环境说明

- OS：RHEL6.4（x86_64）
- postgresql版本：PostgreSQL9.2.8

# 安装步骤

## 1. 下载所需的PostgreSQL rpm包

基础安装：

- postgresql92-libs-9.2.8-1PGDG.rhel6.x86_64.rpm
- postgresql92-9.2.8-1PGDG.rhel6.x86_64.rpm
- postgresql92-server-9.2.8-1PGDG.rhel6.x86_64.rpm

扩展安装：

- postgresql92-contrib-9.2.8-1PGDG.rhel6.x86_64.rpm
- postgresql92-devel-9.2.8-1PGDG.rhel6.x86_64.rpm

下载地址：[http://yum.postgresql.org/9.2/redhat/rhel-6.4-x86_64/](http://yum.postgresql.org/9.2/redhat/rhel-6.4-x86_64/)

## 2. 安装基础的rpm包

在命令行执行如下命令进行安装： 

~~~
$ rpm -ivh postgresql92-libs-9.2.8-1PGDG.rhel6.x86_64.rpm
$ rpm -ivh postgresql92-9.2.8-1PGDG.rhel6.x86_64.rpm
$ rpm -ivh postgresql92-server-9.2.8-1PGDG.rhel6.x86_64.rpm
~~~

按照上面的顺序安装rpm时，会报与系统的libcrypto.so.10和libssl.so.10依赖错误，错误信息如下：

~~~
$ rpm -ivh postgresql92-libs-9.2.8-1PGDG.rhel6.x86_64.rpm 
warning: postgresql92-libs-9.2.8-1PGDG.rhel6.x86_64.rpm: Header V4 DSA/SHA1 Signature, key ID 442df0f8: NOKEY
error: Failed dependencies:
 libcrypto.so.10(libcrypto.so.10)(64bit) is needed by postgresql92-libs-9.2.8-1PGDG.rhel6.x86_64
 libssl.so.10(libssl.so.10)(64bit) is needed by postgresql92-libs-9.2.8-1PGDG.rhel6.x86_64
~~~

因此，我们需要对系统的openssl进行升级。

**升级步骤**

首先，使用下面的命令卸载系统的openssl：

~~~ 
$ rpm --nodeps -e openssl
~~~

然后，下载PostgreSQL9.2.8依赖的的openssl10并安装。

下载地址：

[ftp://ftp.pbone.net/mirror/dl.iuscommunity.org/pub/ius/stable/Redhat/6/x86_64/openssl10-libs-1.0.1e-1.ius.el6.x86_64.rpm](ftp://ftp.pbone.net/mirror/dl.iuscommunity.org/pub/ius/stable/Redhat/6/x86_64/openssl10-libs-1.0.1e-1.ius.el6.x86_64.rpm)


最后，重新安装PostgreSQL9.2.8的rpm包。

## 3. 初始化数据到自定义目录

创建自定义目录`/opt/pg/data`

~~~
$ mkdir /opt/pg_data
~~~

更改目录所有者

~~~
$ chown postgres:postgres /opt/pg_data
~~~

使用postgres用户初始化数据目录（每次启动数据库的时加`-D`参数指定路径，或者修改postgres用户下的`$PGDATA`变量为当前数据目录）

~~~
/usr/pgsql-9.1/bin/initdb -D /opt/pg_data
~~~

初始化数据后，会显示启动数据库的命令。

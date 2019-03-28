---
layout: post
title: Centos上安装 OpenNebula Management Console
category: cloud
tags: [openNebula]
keywords: OpenNebula 
description: Centos上安装 OpenNebula Management Console

---

我们可以通过onehost/onevm/onevnet等等 这些命令行工具来管理 OpenNebula 云计算平台，也可以通过OpenNebula项目组开发的web控制台来访问OpenNebula。OpenNebula项目组提供了两个web程序来管理OpenNebula，一个即本文提到的[OpenNebula Management Console](http://dev.opennebula.org/projects/management-console)，一个是[The Cloud Operations Center](http://opennebula.org/documentation:rel2.2:sunstone" target="_blank)，前者需要额外下载，后者内嵌与OpenNebula安装包内。

OpenNebula 2.2提供的文档相对较少并且零散，在网上可以找到一篇关于OpenNebula Management Console安装的文章：
[安装 OpenNebula 基于 Web 的管理控制台](http://www.vpsee.com/2011/03/install-opennebula-management-console-on-centos/)，我的这篇文章参考了这篇文章并加以完善，这篇文章对我完成OpenNebula Management Console的安装起到很大帮助，感谢原文作者。

我的安装环境：centos5.6 ，OpenNebula2.2，在安装OpenNebula2.2之前，我执行了yum update，即更新系统的软件。

以下来自[官方文档](http://dev.opennebula.org/projects/management-console/wiki)：

# 要求:

- Apache or whatever webserver.
- php5 (May work with php4 but not tested)
- php-adodb
- And you need a db driver for adodb: php-mysql or php-pgsql.
- Mysql or postgresql database
- php-curl
- php-xmlrpc
- php-pear: pecl install uploadprogress (Only if you want a nice upload progress bar)

如果你想查看更多资料，您可以去官网：[OpenNebula Management Console Wiki](http://dev.opennebula.org/projects/management-console/wiki)；如果你想在ubutun上安装OpenNebula Management Console，参照这篇文章：[Install onemc on ubuntu](http://dev.opennebula.org/projects/management-console/wiki/onemc_install_ubuntu)

# 安装过程

## 必要软件

	# yum -y install php mysql-server httpd mysql-connector-odbc mysql-devel libdbi-dbd-mysql

## 安装php-adodb

从http://sourceforge.net/projects/adodbhttp://7xnrdo.com1.z0.glb.clouddn.com/adodb-php5-only下载 

注意：将adobd包解压拷贝到/var/www/html/onemc/include/，将文件名改为adobd

## 安装php的扩展

	# yum -y install php-gd php-xml php-mbstring php-ldap php-pear php-xmlrpc php-curl php-mysql

## 安装apache扩展

	# yum -y install httpd-manual mod_ssl mod_perl mod_auth_mysql

## 修改配置文件权限

	# chmod 644 /var/www/html/onemc/include/config.php

我下载的是OpenNebula 2.2其中/config.php的权限很特别，如果你从浏览器访问onemc时候页面都是空白的，你可以看看日志（我使用的是httpd，日志在httpd.log），可以看到日志中提示没有权限访问`/var/www/html/onemc/include/config.php`

## 下载 onemc

下载和解压 onemc-1.0.0.tar.gz 后直接放在 apache 的默认目录里：

	# cd /var/www/html
	# wget http://dev.opennebula.org/attachments/download/128/onemc-1.0.0.tar.gz
	# tar zxvf onemc-1.0.0.tar.gz
	# cd onemc

## 配置数据库

	# mysql -uroot -p
	Enter password:
	mysql> create database onemc;
	mysql> create user 'oneadmin'@'localhost' identified by 'oneadmin';
	mysql> grant all privileges on onemc.* to 'oneadmin'@'localhost';
	mysql> \q

## 初始化数据库

	# mysql -u oneadmin -p onemc < /var/www/html/onemc/include/mysql.sql

## 配置onemc

	# vi /var/www/html/onemc/include/config.php
	...
	// vmm: kvm or xen
	$vmm = "xen";
	...
	// ADODB settings
	$adodb_type = "mysql";
	$adodb_server = "localhost";
	$adodb_user = "oneadmin";
	$adodb_pass = "oneadmin";
	$adodb_name = "onemc";

## 登录

如果系统设置了 http_proxy 环境变量的话一定要先关闭，然后重启 one 和 httpd：

	# unset http_proxy
	# one stop; one start
	# /etc/init.d/httpd restar

访问地址为`http://localhost/onemc/index.php`，用户名和密码在`one_auth` 中。

# 总结

以上步骤最重要的是配置好centos的yum源，一次将php和mysql及相关组件安装成功，然后需要注意的是上面红色部分标出的部分。其实，除了红色那部分之外，其余和开头提到的那篇文章内容没什么差别。

# 参考文章

- [1][OpenNebula Management Console Wiki](http://dev.opennebula.org/projects/management-console/wiki)
- [2][Install onemc on ubuntu](http://dev.opennebula.org/projects/management-console/wiki/onemc_install_ubuntu)

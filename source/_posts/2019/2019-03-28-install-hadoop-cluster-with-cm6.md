---
layout: post

title: Cloudera Manager安装Haddop集群
category: hadoop
tags: [hadoop,vagrant,cdh]
description:  在开始之前，请参考我博客中的关于如何安装cdh集群的文章，这里只做简单说明。因为只是为了测试，所以是在vagrant虚拟机中创建三个虚拟机搭建一个集群来安装cdh6。
published: true
---

在开始之前，请参考我博客中的关于如何安装cdh集群的文章，这里只做简单说明。因为只是为了测试，所以是在vagrant虚拟机中创建三个虚拟机搭建一个集群来安装cdh6。

# 环境准备

参考[使用yum源安装CDH Hadoop集群](/2013/04/06/install-cloudera-cdh-by-yum)文章中的第一部分。

# 安装CM

    sudo yum install cloudera-manager-server

# 安装数据库

这里使用的是postgresql

    yum install postgresql-server

初始化数据：

    echo 'LC_ALL="zh_CN.UTF-8"' >> /etc/locale.conf
    sudo su -l postgres -c "postgresql-setup initdb"

修改 pg_hba.conf 文件，在`/var/lib/pgsql/data`或者`/etc/postgresql/<version>/main`目录：

    host all all 127.0.0.1/32 md5
  

修改postgresql.conf优化参数，参考<https://www.cloudera.com/documentation/enterprise/6/6.0/topics/cm_ig_extrnl_pstgrs.html#cmig_topic_5_6>。

    listen_addresses = '*'

启动posgresql：

    sudo systemctl restart postgresql

创建数据库：

    sudo -u postgres psql
    CREATE ROLE scm LOGIN PASSWORD 'scm';
    CREATE DATABASE scm OWNER scm ENCODING 'UTF8';
    ALTER DATABASE scm SET standard_conforming_strings=off;  #for the Hive Metastore and Oozie databases:

使用cm自带脚本创建数据库：

    sudo /opt/cloudera/cm/schema/scm_prepare_database.sh postgresql scm scm

# 安装cdh和其他模块

启动cm：

    sudo systemctl start cloudera-scm-server

查看日志：

    sudo tail -f /var/log/cloudera-scm-server/cloudera-scm-server.log

待启动成功之后，访问`http://<server_host>:7180`。

如果你配置了`auto-TLS`，可以通过https登录`https://<server_host>:7183`

用户名admin，密码admin。

# 参考文章

- [使用Vagrant创建虚拟机安装Hadoop](/2014/02/23/create-virtualbox-by-vagrant)
- [手动安装Cloudera Hadoop CDH](/2013/03/24/manual-install-Cloudera-Hadoop-CDH)
- [Cloudera Manager6安装文档](https://www.cloudera.com/documentation/enterprise/6/6.0/topics/installation.html)
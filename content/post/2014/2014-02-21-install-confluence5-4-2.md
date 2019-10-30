---
layout: post
title: Confluence 5.4.2安装
date: 2014-02-21T08:00:00+08:00
description: 本文记录Confluence 5.4.2安装过程。Confluence是Atlassian公司出品的团队协同与知识管理工具。 Confluence是一个专业的企业知识管理与协同软件，也可以用于构建企业wiki。通过它可以实现团队成员之间的协作和知识共享。
categories: [ devops ]
tags: [confluence]
---

Confluence是Atlassian公司出品的团队协同与知识管理工具。 Confluence是一个专业的企业知识管理与协同软件，也可以用于构建企业wiki。通过它可以实现团队成员之间的协作和知识共享。

# 1、下载

下载指定版本Confluence

~~~
$ mkdir -p /data/confluence
$ cd /data/confluence
$ wget www.atlassian.com/software/confluence/downloads/binary/atlassian-confluence-5.4.2.tar.gz
~~~

# 2、安装

解压：

~~~
$ tar -zxvf atlassian-confluence-5.4.2.tar.gz
~~~

进入目录：

~~~
$ cd atlassian-confluence-5.4.2
~~~

配置confluence安装目录：

~~~
$ vim confluence/WEB-INF/classes/confluence-init.properties
~~~

在属性文件中添加安装目录路径：

~~~
###########################
# Note for Unix Users     #
###########################
# - For example:
confluence.home=/data/confluence/confluence-data
~~~

创建目录：

~~~
$ mkdir confluence-data
~~~

创建完成后，运行启动：

~~~
$ sh bin/start-confluence.sh
~~~

访问ip+portnum，默认端口为8090，如果出现破解界面，以上步骤即为成功

# 3、启停服务

使用压缩包形式的Confluence无法直接使用服务启停，需要配合目录的sh文件

启动服务：

~~~
$ sh bin/start-confluence.sh
~~~

停止服务：

~~~
$ sh bin/stop-confluence.sh
~~~

# 4、修改默认端口

配置文件位置：`atlassian-confluence-5.4.2/conf/server.xml`

打开文件，

~~~xml
<Connector className="org.apache.coyote.tomcat4.CoyoteConnector" port="8090" minProcessors="5"
~~~

修改 port 为需要的端口。

# 5、更换默认的数据库

在完成之前的步骤后，数据库使用的是一个 confluence 默认的 hsql 数据库，此数据库缺陷较多，例如：不支持事务管理。因此需要将数据库迁移为指定的数据库类型。

进入 confluence-data 目录，修改 `confluence-cfg.xml` 文件中数据库相关的连接信息。

# 6、安装中文字体：

默认情况下 Confluence 导出 PDF 不支持中文，需要修改如下：

管理员登录 "Confluence Admin"，选择左边菜单 "CONFIGURATION"-"PDF Export Language Support"，选择安装中文字体，例如：simsun.ttc

# 7、破解

请参考：[http://582033.vicp.net/?p=1085](http://582033.vicp.net/?p=1085)

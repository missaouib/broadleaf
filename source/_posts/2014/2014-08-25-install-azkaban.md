---
layout: post

title:  安装Azkaban

description: Azkaban 是由 Linkedin 开源的一个批量工作流任务调度器。用于在一个工作流内以一个特定的顺序运行一组工作和流程。Azkaban 定义了一种 KV 文件格式来建立任务之间的依赖关系，并提供一个易于使用的 web 用户界面维护和跟踪你的工作流。

keywords:  

category:  devops

tags: [azkaban]

published: true

---

Azkaban 是由 Linkedin 开源的一个批量工作流任务调度器。用于在一个工作流内以一个特定的顺序运行一组工作和流程。Azkaban 定义了一种 KV 文件格式来建立任务之间的依赖关系，并提供一个易于使用的 web 用户界面维护和跟踪你的工作流。

Azkaban 官网地址：<http://azkaban.github.io/>
Azkaban 的下载地址：<http://azkaban.github.io/downloads.html>

Azkaban 包括三个关键组件：

- `关系数据库`：使用 Mysql数据库，主要用于保存流程、权限、任务状态、任务计划等信息。
- `AzkabanWebServer`：为用户提供管理留存、任务计划、权限等功能。
- `AzkabanExecutorServer`：执行任务，并把任务执行的输出日志保存到 Mysql；可以同时启动多个 AzkabanExecutorServer ，他们通过 mysql 获取流程状态来协调工作。

![](http://azkaban.github.io/azkaban/docs/2.5/images/azkaban2overviewdesign.png)

在 2.5 版本之后，Azkaban 提供了两种模式来安装：

- 一种是 standalone 的 “solo-server” 模式；
- 另一种是两个 server 的模式，分别为 AzkabanWebServer 和 AzkabanExecutorServer。

这里主要介绍第二种模式的安装方法。

# 1. 安装过程

## 1.1 安装 MySql

目前 Azkaban 只支持 MySql ，故需安装 MySql 服务器，安装 MySql 的过程这里不作介绍。

安装之后，创建 azkaban 数据库，并创建 azkaban 用户，密码为 azkaban，并设置权限。

~~~sql
# Example database creation command, although the db name doesn't need to be 'azkaban'
mysql> CREATE DATABASE azkaban;
# Example database creation command. The user name doesn't need to be 'azkaban'
mysql> CREATE USER 'azkaban'@'%' IDENTIFIED BY 'azkaban';
# Replace db, username with the ones created by the previous steps.
mysql> GRANT SELECT,INSERT,UPDATE,DELETE ON azkaban.* to 'azkaban'@'%' WITH GRANT OPTION;
~~~

修改 `/etc/my.cnf` 文件，设置 `max_allowed_packet` 值：

~~~
[mysqld]
...
max_allowed_packet=1024M
~~~

然后重启 MySql。

解压缩 azkaban-sql-2.5.0.tar.gz文件，并进入到 azkaban-sql-script目录，然后进入 mysql 命令行模式：

~~~bash
$ mysql -uazkaban -pazkaban
mysql> use azkaban
mysql> source create-all-sql-2.5.0.sql
~~~

## 1.2 安装 azkaban-web-server

解压缩 azkaban-web-server-2.5.0.tar.gz，创建 SSL 配置，命令：`keytool -keystore keystore -alias jetty -genkey -keyalg RSA`

完成上述工作后，将在当前目录生成 keystore 证书文件，将 keystore 考贝到 azkaban web 目录中。

修改 azkaban web 服务器配置，主要包括：

a. 修改时区和首页名称:

~~~properties
# Azkaban Personalization Settings
azkaban.name=ETL Task
azkaban.label=By BI
azkaban.color=#FF3601
azkaban.default.servlet.path=/index
web.resource.dir=web/
default.timezone.id=Asia/Shanghai
~~~

b. 修改 MySql 数据库配置

~~~properties
database.type=mysql
mysql.port=3306
mysql.host=localhost
mysql.database=azkaban
mysql.user=azkaban
mysql.password=azkaban
mysql.numconnections=100
~~~

c. 修改 Jetty 服务器属性，包括 keystore 的相关配置

~~~properties
# Azkaban Jetty server properties.
jetty.hostname=0.0.0.0
jetty.maxThreads=25
jetty.ssl.port=8443
jetty.port=8081
jetty.keystore=keystore
jetty.password=redhat
jetty.keypassword=redhat
jetty.truststore=keystore
jetty.trustpassword=redhat
~~~

d. 修改邮件设置（可选）

~~~properties
# mail settings
mail.sender=admin@javachen.com
mail.host=javachen.com
mail.user=admin
mail.password=admin
~~~

## 1.3 安装 azkaban-executor-server

解压缩 azkaban-executor-server-2.5.0.tar.gz，然后修改配置文件，包括：

a. 修改时区为：`default.timezone.id=Asia/Shanghai`

b. 修改 MySql 数据库配置

~~~properties
database.type=mysql
mysql.port=3306
mysql.host=localhost
mysql.database=azkaban
mysql.user=azkaban
mysql.password=azkaban
mysql.numconnections=100
~~~

## 1.4 用户设置

进入 azkaban web 服务器 conf 目录，修改 azkaban-users.xml ，增加管理员用户：

~~~xml
<azkaban-users>
        <user username="azkaban" password="azkaban" roles="admin" groups="azkaban" />
        <user username="metrics" password="metrics" roles="metrics"/>
        <user username="admin" password="admin" roles="admin,metrics" />
        <role name="admin" permissions="ADMIN" />
        <role name="metrics" permissions="METRICS"/>
</azkaban-users>
~~~

## 1.5 启动服务

azkaban-web-server，需要在 azkaban-web-server 目录下执行下面命令：

~~~bash
sh bin/azkaban-web-start.sh
~~~

azkaban-executor-server，需要在 azkaban-executor-server 目录下执行下面命令：

~~~bash
sh bin/azkaban-executor-start.sh
~~~

## 1.6 配置插件

下载 [HDFS Browser](https://s3.amazonaws.com/azkaban2/azkaban-plugins/2.5.0/azkaban-hdfs-viewer-2.5.0.tar.gz) 插件，解压然后重命名为 hdfs，然后将其拷贝到 azkaban-web-server/plugins/viewer 目录下。

下载 [Job Types Plugins](https://s3.amazonaws.com/azkaban2/azkaban-plugins/2.5.0/azkaban-jobtype-2.5.0.tar.gz) 插件，解压然后重命名为 jobtype，然后将其拷贝到 azkaban-executor-server/plugins/ 目录下，然后修改以下文件，设置 `hive.home`：

- plugins/jobtypes/commonprivate.properties
- plugins/jobtypes/common.properties
- plugins/jobtypes/hive/plugin.properties

>说明：
>
>在实际使用中，这些插件都没有配置成功，故最后的生产环境没有使用这些插件，而是基于最基本的 command 或 script 方式来编写作业。

## 1.7 生产环境使用

这部分内容详细说明见 [当前数据仓库建设过程](/2014/10/23/hive-warehouse-in-2014.html) 一文中的任务调度这一章节内容。

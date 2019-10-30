---
layout: post
title: RHEL系统下安装atlassian-jira-5
date: 2014-04-09T08:00:00+08:00
description: JIRA是Atlassian公司出品的项目与事务跟踪工具，被广泛应用于缺陷跟踪、客户服务、需求收集、流程审批、任务跟踪、项目跟踪和敏捷管理等工作领域。
categories: [ devops ]
tags: 
 - jira
published: true
---

# 部署环境

- 操作系统：RHEL 6.4 x86_64
- Jira版本：`atlassian-jira-5.2.11-x64.bin`
- 安装路径:`/opt/atlassian/jira/`
- 数据保存路径：`/opt/atlassian/application-data/jira`
- 安装用户：jira
- 数据库：postgresql
- JDK：1.6.0_43

jira下载页面：[https://www.atlassian.com/software/jira/download](https://www.atlassian.com/software/jira/download)

# 安装步骤

## 运行安装文件

~~~
$ . atlassian-jira-5.2.11-x64.bin
~~~

在安装过程中会出现选项：

确认安装

~~~
This will install JIRA 6.2.2 on your computer.
OK [o, Enter], Cancel [c]
o
~~~

选择安装类型－1默认安装 －2自定义安装 －3升级

~~~
Choose the appropriate installation or upgrade option.
Please choose one of the following:
Express Install (use default settings) [1], Custom Install (recommended for advanced users) [2], Upgrade an existing JIRA installation [3, Enter]
3
~~~
你可以选择2自定义安装路径、启动端口等等。

接下来选择确认直到安装成功。

## 初始化数据库

这里我选择PostgreSql数据库，先安装数据库，然后创建用户(jira)和数据库(jira)。

~~~
$ su - postgres
-bash-4.1$ cd
-bash-4.1$ cd bin
-bash-4.1$ ./psql -U postgres
psql (9.0.3)
Type "help" for help.

Cannot read termcap database;
using dumb terminal settings.
postgres=# CREATE USER jira WITH PASSWORD 'redhat';
postgres=# CREATE DATABASE jira owner=jira;
postgres=# GRANT ALL privileges ON DATABASE jira TO jira;
~~~

然后打开浏览器范围jira页面：`http://ip:8080/`，在该页面选择数据库类型，并填写数据库连接信息，测试是否可以ping通，接着运行下一步,在jira官网上注册一个帐号。

## 破解

破解文件：

- [atlassian-extras-2.2.2.jar](http://download.csdn.net/detail/royalapex/6710573)
- [atlassian-extras-2.2.2.crack](http://download.csdn.net/detail/royalapex/6710589)

执行以下命令覆盖原来文件：

~~~
$ cp atlassian-extras-2.2.2.crack /opt/atlassian/jira/atlassian-jira/WEB-INF/classes/
$ \cp atlassian-extras-2.2.2.jar /opt/atlassian/jira/atlassian-jira/WEB-INF/lib/
~~~

检查是否可以创建issue，并查看jira版本和过期时间。

## 汉化

下载JIRA汉化包：[JIRA-5.0-language-pack-zh_CN.jar](http://download.csdn.net/detail/royalapex/6711881),并在jira管理页面将其上传，然后在个人设置页面，可以设置语言为中文。

## JIRA使用

启动：

~~~
$ cd /opt/atlassian/jira/bin
$ sh start-jira.sh
~~~

停止：

~~~
$ cd /opt/atlassian/jira/bin
$ sh stop-jira.sh
~~~

查看日志：

~~~
$ cd /opt/atlassian/jira/bin
$ tailf catalina.out
~~~
## 修改JVM参数

~~~bash
$ vi /opt/atlassian/jira/bin/setenv.sh
JAVA_OPTS="-Xms1024m -Xmx2048m -XX:MaxPermSize=256m $JAVA_OPTS -Djava.awt.headless=true "
~~~

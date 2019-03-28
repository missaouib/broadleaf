---
layout: post
title:  使用Hadoop中遇到的一些问题
description: 本文主要记录安装hadoop过程需要注意的一些细节以及使用hadoop过程中发现的一些问题以及对应解决办法，有些地方描述的不是很清楚可能还会不准确，之后会重现问题然后修改完善这篇文章。
category: hadoop
tags: [hadoop, hive, hbase, mapreduce]
---

本文主要记录安装hadoop过程需要注意的一些细节以及使用hadoop过程中发现的一些问题以及对应解决办法，有些地方描述的不是很清楚可能还会不准确，之后会重现问题然后修改完善这篇文章。

# 安装hadoop过程中需要注意以下几点：

1. 每个节点配置hosts
2. 每个节点配置时钟同步
3. 如果没有特殊要求，关闭防火墙
4. hadoop需要在`/tmp`目录下存放一些日志和临时文件，要求`/tmp`目录权限必须为`1777`

---

<!-- more -->

# 使用intel的hadoop发行版IDH过程遇到问题：

1、 IDH集群中需要配置管理节点到集群各节点的无密码登录，公钥文件存放路径为`/etc/intelcloud`目录下，文件名称为`idh-id_rsa`。

如果在管理界面发现不能启动/停止hadoop组件的进程，请检查ssh无密码登录是否有问题。

	ssh -i /etc/intelcloud/idh-id_rsa nodeX

如果存在问题，请重新配置无密码登录：

	scp -i /etc/intelcloud/idh-id_rsa nodeX

2、 IDH使用puppt和shell脚本来管理hadoop集群，shell脚本中有一处调用puppt的地方存在问题，详细说明待整理！！

---

# 使用CDH4.3.0的hadoop（通过rpm安装）过程中发现如下问题：

## 说明：以下问题不局限于CDH的hadoop版本。

1、 在hive运行过程中会打印如下日志

	Starting Job = job_1374551537478_0001, Tracking URL = http://june-fedora:8088/proxy/application_1374551537478_0001/
	Kill Command = /usr/lib/hadoop/bin/hadoop job  -kill job_1374551537478_0001

通过上面的`kill command`可以killjob，但是运行过程中发现提示错误，错误原因：`HADOOP_LIBEXEC_DIR`未做设置

解决方法：在hadoop-env.sh中添加如下代码

	export HADOOP_LIBEXEC_DIR=$HADOOP_COMMON_HOME/libexec

2、 查看java进程中发现，JVM参数中-Xmx重复出现

解决办法：`/etc/hadoop/conf/hadoop-env.sh`去掉第二行。

	export HADOOP_OPTS="-Djava.net.preferIPv4Stack=true $HADOOP_OPTS"

3、 hive中mapreduce运行为本地模式，而不是远程模式

解决办法：`/etc/hadoop/conf/hadoop-env.sh`设置`HADOOP_MAPRED_HOME`变量

	export HADOOP_MAPRED_HOME=/usr/lib/hadoop-mapreduce

4、 如何设置hive的jvm启动参数

hive脚本运行顺序：

	hive-->hive-config.sh-->hive-env.sh-->hadoop-config.sh-->hadoop-env.sh

故如果hadoop-env.sh中设置了`HADOOP_HEAPSIZE`，则hive-env.sh中设置的无效

5、如何设置JOB_HISTORYSERVER的jvm参数

在`/etc/hadoop/conf/hadoop-env.sh`添加如下代码：

	export HADOOP_JOB_HISTORYSERVER_HEAPSIZE=256




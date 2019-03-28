---
layout: post
title: 【笔记】Hadoop安装部署
category: hadoop
tags: [hadoop, cdh]
keywords: hadoop, hdfs
---

# 安装虚拟机

   使用VirtualBox安装rhel6.3，存储为30G，内存为1G，并使用复制克隆出两个新的虚拟机，这样就存在3台虚拟机，设置三台虚拟机的主机名称，如：rhel-june、rhel-june-1、rhel-june-2

# 配置网络

a. VirtualBox全局设定-网络中添加一个新的连接：vboxnet0

b. 设置每一个虚拟机的网络为Host-Only

c.分别修改每个虚拟机的ip，DHCP或手动设置

	vim /etc/sysconfig/network-scripts/ifcfg-eth0
	vim /etc/udev/rules.d/70-persistent-net.rules  #删掉第一个，修改第二个名字为eth0
	start_udev

d.修改主机名

	vim /etc/sysconfig/network
     
e.每个虚拟机中修改hosts：

	192.168.56.100 rhel-june
	192.168.56.101 rhel-june-1
	192.168.56.102 rhel-june-2

最后机器列表为：

	rhel-june:   192.168.56.100
	rhel-june-1: 192.168.56.101
	rhel-june-2: 192.168.56.102

# 机群规划

版本：

	hadoop:1.1.1
	JDK:1.6.0_38

集群各节点：

	NameNode:192.168.56.100
	NameSecondary:192.168.56.100
	DataNode:192.168.56.101
	DataNode:192.168.56.102

# 安装过程

   a.将hadoop压缩包解压缩到/opt目录

   b.修改以下配置文件：

	core-site.xml
	hdfs-site.sml
	mapred-site.xml

   c.设置master、slaves文件

master中内容为：

~~~
	192.168.56.100
~~~

slaves中内容为：

~~~
	192.168.56.101
	192.168.56.102
~~~


   d.设置环境变量

   方便执行java命令及hadoop命令. 使用root登录，`vi ~/.bash_profile`追加下列信息

	export JAVA_HOME=/opt/jdk1.6.0_38
	export HADOOP_INSTALL=/opt/hadoop-1.1.1
	export PATH=$PATH:$HADOOP_INSTALL/bin:$JAVA_HOME/bin

   e.修改hadoop脚本中`JAVA_HOME`：`/opt/hadoop-1.1.1/conf/hadoop-env.sh`

   f.格式化namenode

	hadoop namenode -format

   g.启动hdfs集群

	sh /opt/hadoop-1.1.1/bin/start-all.sh

   h.查看节点进程
		
	jps

# 查看状态

	http://rhel-june:50030/
	http://rhel-june:50070/


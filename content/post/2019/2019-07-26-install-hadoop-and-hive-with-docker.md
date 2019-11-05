---
layout: post
title: Docker搭建hadoop和hive环境
date: 2019-07-26T08:00:00+08:00
categories: [ docker ]
tags: [hadoop,docker]
description:  文将介绍如何在docker上从零开始安装hadoop以及hive环境。本文不会介绍如何安装docker，也不会过多的介绍docker各个命令的具体含义，对docker完全不了解的同学建议先简单的学习一下docker再来看本教程。
---

文将介绍如何在docker上从零开始安装hadoop以及hive环境。本文不会介绍如何安装docker，也不会过多的介绍docker各个命令的具体含义，对docker完全不了解的同学建议先简单的学习一下docker再来看本教程。

# 构建Centos镜像

Dockerfile

```dockerfile
FROM centos:7
MAINTAINER by javachen(junecloud@163.com)

#升级系统、安装常用软件
RUN yum -y update && yum -y install openssh-server openssh-clients.x86_64 vim less wget java-1.8.0-openjdk.x86_64 java-1.8.0-openjdk-devel

ENV JAVA_HOME=/usr/lib/jvm/java

#生成秘钥、公钥
RUN [ ! -d ~/.ssh ] && ( mkdir ~/.ssh ) && ( chmod 600 ~/.ssh ) && [ ! -f ~/.ssh/id_rsa.pub ] \
&& (yes|ssh-keygen -f ~/.ssh/id_rsa -t rsa -N "") && ( chmod 600 ~/.ssh/id_rsa.pub ) \
&& cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

#设置时区
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo '$TZ' > /etc/timezone

#变更root密码为root
RUN  cp /etc/sudoers /etc/sudoers.orig && echo "root            ALL=(ALL)               NOPASSWD: ALL" >> /etc/sudoers && echo "root:root"| chpasswd

#开放窗口的22端口
EXPOSE 22
```

更多的配置镜像脚本，可以参考 [config_system.sh](https://github.com/javachen/snippets/blob/master/hadoop-install/bin/config_system.sh)

构建镜像：

```
docker build -t centos-hadoop:v1 .
```

通过镜像启动容器:

```
docker run -d --name centos-hadoop centos-hadoop:v1 
```

启动容器后，我们就可以进入容器进行hadoop和hive的相关安装了。

```
docker exec -it centos-hadoop /bin/bash
```

# 安装Hadoop

下载安装包：

```
wget http://mirrors.tuna.tsinghua.edu.cn/apache/hadoop/common/hadoop-3.1.2/hadoop-3.1.2.tar.gz
```

解压：

```
tar xvf hadoop-3.1.2.tar.gz -C /usr/local/
```

vim /usr/local/hadoop-3.1.2/etc/hadoop/core-site.xml

```xml
<property>
      <name>fs.defaultFS</name>
      <value>hdfs://127.0.0.1:9000</value>
</property>
```

vim /usr/local/hadoop-3.1.2/etc/hadoop/hdfs-site.xml

```xml
<property>
      <name>dfs.replication</name>
      <value>1</value>
</property>
```

vim /usr/local/hadoop-3.1.2/etc/hadoop/mapred-site.xml

```xml
<property>
     <name>mapreduce.framework.name</name>
     <value>yarn</value>
</property>
```

vim /usr/local/hadoop-3.1.2/etc/hadoop/hadoop-env.sh

```bash
JAVA_HOME=/usr/lib/jvm/java
```

/usr/local/hadoop-3.1.2/sbin/目录下将start-dfs.sh，stop-dfs.sh两个文件顶部添加以下参数

```bash
!/usr/bin/env bash

HDFS_DATANODE_USER=root
HDFS_DATANODE_SECURE_USER=hdfs
HDFS_NAMENODE_USER=root
HDFS_SECONDARYNAMENODE_USER=root
```

vim /etc/profile

```
export HADOOP_HOME="/usr/local/hadoop-3.1.2"
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
```

配置生效：

```
source /etc/profile
```

namenode 初始化

```
hadoop namenode -format
```

启动hdfs相关进程:

```
start-dfs.sh
```

执行`start-dfs.sh`脚本后，hadoop会启动3个和hdfs相关的进程。通过`ps -ef | grep hadoop`我们可以看到这几个进程分别是`NameNode`、`SecondaryNamenode`、`Datanode`。如果少了就要注意hdfs是否没有正常启动了。

```
ps -ef | grep hadoop
```

之后启动yarn的相关进程:

```
start-yarn.sh
```

验证程序已经正确启动

```bash
hadoop fs -mkdir /test

hadoop fs -ls /
Found 1 items
drwxr-xr-x   - root supergroup          0 2019-07-26 19:15 /test
```

hadoop默认的存储数据的目录为：/tmp/hadoop-${user}

```bash
$ ll /tmp/hadoop-root/dfs/
total 0
drwx------ 3 root root 40 Jul 26 19:39 data
drwxr-xr-x 3 root root 40 Jul 26 19:39 name
drwxr-xr-x 3 root root 40 Jul 26 19:39 namesecondary
```

/usr/local/hadoop-3.1.2/sbin/目录下将start-yarn.sh，stop-yarn.sh两个文件顶部添加以下参数

```bash
YARN_RESOURCEMANAGER_USER=root
YARN_NODEMANAGER_USER=root
```

之后启动yarn的相关进程

```
start-yarn.sh
```

执行脚本后正常会有`ResourceManager`和`NodeManager`这两个进程。

# 安装Hive

下载：

```
wget http://mirror.bit.edu.cn/apache/hive/hive-3.1.1/apache-hive-3.1.1-bin.tar.gz
```

解压：

```
tar xvf apache-hive-3.1.1-bin.tar.gz -C /usr/local/
mv /usr/local/apache-hive-3.1.1-bin /usr/local/hive-3.1.1
```

vim /usr/local/hive-3.1.1/conf/hive-site.xml

```xml
<configuration>
   <property>
      <name>system:java.io.tmpdir</name>
      <value>/tmp/hive/java</value>
    </property>
    <property>
      <name>system:user.name</name>
      <value>${user.name}</value>
    </property>
<configuration>
```

vim /etc/profile

```bash
export HIVE_HOME="/usr/local/hive-3.1.1"
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HIVE_HOME/bin
```

配置生效：

```
source /etc/profile
```

查看docker运行的mysql容器的ip：

```bash
docker inspect mysql | grep "IPAddress"
            "SecondaryIPAddresses": null,
            "IPAddress": "",
                    "IPAddress": "172.22.0.2",
```

并在mysql数据库中创建hive数据库：

```
create database hive;
```

修改hive的相关配置 vim /usr/local/hive-3.1.1/conf/hive-site.xml

```xml
<property>
  <name>javax.jdo.option.ConnectionUserName</name>
  <value>root</value>
</property>
<property>
  <name>javax.jdo.option.ConnectionPassword</name>
  <value>123456</value>
</property>
<property>
  <name>javax.jdo.option.ConnectionURL</name>
  <value>jdbc:mysql://172.22.0.2:3306/hive?useSSL=false</value>
  </property>
<property>
  <name>javax.jdo.option.ConnectionDriverName</name>
  <value>com.mysql.jdbc.Driver</value>
</property>
```

wget获取mysql驱动到hive的lib下

```bash
cd /usr/local/hive-3.1.1/lib
wget http://central.maven.org/maven2/mysql/mysql-connector-java/5.1.47/mysql-connector-java-5.1.47.jar
```

初始化元数据库

```
schematool -initSchema -dbType mysql
```

我们先创建一个数据文件放到`/usr/local`，vim test.txt

```
1,jack
2,hel
3,nack
```

之后通过`hive`命令进入hive交互界面，然后执行相关操作

```
create table test(
id      int
,name    string
)
row format delimited
fields terminated by ',';


load data local inpath '/usr/local/test.txt' into table test;


select * from test;
OK
1       jack
2       hel
3       nack
```

启动 Hiveserver2

vim /usr/local/hadoop-3.1.2/etc/hadoop/core-site.xml

```xml
<property>
    <name>hadoop.proxyuser.root.hosts</name>
    <value>*</value>
</property>
<property>
    <name>hadoop.proxyuser.root.groups</name>
    <value>*</value>
</property>
```

然后重启hdfs:

```
stop-dfs.sh
start-dfs.sh
```

后台启动hiveserver2

```
nohup hiveserver2 &
```

通过beeline连接

```
beeline -u jdbc:hive2://127.0.0.1:10000
```

查询一下之前建立的表看下是否能正常访问

```
select * from test;
```

# 总结

本篇文章记录了，如果使用docker搭建hadoop单机环境，如果你想更全面的使用Docker构建Hadoop集群，可以参考 https://github.com/big-data-europe ，另外，需要注意的是这个镜像只向宿主机暴露了22端口，如果想暴露更多端口，可以将该镜像提交：

```bash
docker commit \
    --author "XXX <XXX@gmail.com>" \
    --message "XXXXX" \
    centos-hadoop \
    centos-hadoop:v2
```

然后，再次使用新镜像启动容器，并暴露hadoop的端口。

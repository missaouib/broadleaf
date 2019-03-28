---
layout: post
title:  通过Cloudera Manager安装CDH
category: hadoop
tags: [hadoop, cdh]
---

# 1 方法一

你可以从[https://ccp.cloudera.com/display/SUPPORT/Downloads](https://ccp.cloudera.com/display/SUPPORT/Downloads)下载`cloudera-manager-installer.bin`，然后修改执行权限并执行该脚本。

该脚本中配置的rhel6的yum源为：[http://archive.cloudera.com/cm4/redhat/6/x86_64/cm/4/](http://archive.cloudera.com/cm4/redhat/6/x86_64/cm/4/)，下载的过程必须连网并且rpm的过程会非常慢，这种方法对虚拟机或者是无法连网的内网机器来说根本无法使用。

因为知道所有的rpm都在上面网址可以下载到，故你可以手动下载这些rpm然后手动安装，详细过程请参考：[通过cloudera-manager来安装hadoop](http://dreamyue.com/post/41090075449/cloudera-manager-hadoop)。

# 2 方法二

这里还有一种方法，就是手动下载`Cloudera Manager`的yum tar包，在虚拟机中搭建一个本地yum源，然后修改hosts文件，使`archive.cloudera.com`域名映射到本地ip。

# 3 方法三
出于好奇，想破解`cloudera-manager-installer.bin`，然后看看其中做了哪些操作。通过以下脚本即可解压该文件：

~~~bash
$ mv cloudera-manager-installer.bin cloudera-manager-installer.zip
$ unzip cloudera-manager-installer.zip 
~~~

解压之后的目录如下：

~~~bash
$ ll
总用量 512
-rwxrwxr-x. 1 june june 501698 5月  25 09:53 cloudera-manager-installer.zip
drwxr-xr-x. 2 june june   4096 5月  23 03:05 data
drwxr-xr-x. 2 june june   4096 5月  22 21:48 guis
drwxr-xr-x. 2 june june   4096 5月  22 21:48 meta
drwxr-xr-x. 2 june june   4096 5月  22 21:48 scripts
~~~

查看解压之后的文件可以看到安装脚本是用lua编写并用MojoSetup编译的，从`scripts/config.lua`脚本中大概可以看出安装脚本的执行过程。

整理下该脚本逻辑，主要是做了以下操作：

~~~bash
$ yum install -y jdk.x86_64 
$ yum install -y cloudera-manager-server 
$ yum install -y cloudera-manager-server-db
$ /etc/init.d/cloudera-scm-server start
$ /etc/init.d/cloudera-scm-server-db start
~~~

知道了上面这点之后，就可以在本地的cloudera-manager yum中，执行以上操作完成cloudera-manager的安装，安装成功之后查看7180端口是否打开：

~~~bash
$ netstat -na| grep 7180
~~~

通过浏览器访问`http://IP:7180`登录cloudera manager界面：用户名/密码：`admin/admin`,按照界面提示完成hadoop集群安装。

# 卸载

执行以下命令，可以卸载并删除相应的文件和目录：

~~~bash
yum remove -y hadoop hbase hive zookeeper hue oozie sqoop flume
yum remove cloudera*

rm -rf /usr/lib/{hadoop,hbase,oozie}
rm -rf /etc/{hadoop,hadoop-httpfs,hbase,hive,zookeeper}
rm -rf /etc/{hadoop,hadoop-httpfs,hbase,hive,zookeeper,sqoop,oozie,flume}
rm -rf /etc/cloudera-scm-agent/
rm -rf /tmp/hadoop-hive/ /usr/share/hue/  /var/log/hive/
rm -rf /var/log/hadoop-*
rm -rf /var/log/hbase/
rm -rf /var/log/zookeeper/
rm -rf /var/log/cloudera-scm-*
rm -rf /var/log/flume-ng/
rm -rf /var/log/hue
rm -rf /usr/share/doc/oozie*
rm -rf /etc/hue/ /etc/rc.d/init.d/hue
~~~

# 5 排错
在执行下面一个命令时候可能会出现如下异常

~~~bash
$ /etc/init.d/cloudera-scm-server-db start
~~~
异常信息如下：

~~~bash
[root@cdh1 cloudera-scm-server-db]# /etc/init.d/cloudera-scm-server-db start
属于此数据库系统的文件宿主为用户 "cloudera-scm".
此用户也必须为服务器进程的宿主.
数据库簇将带有 locale en_US.UTF8 初始化.
缺省的文本搜索配置将会被设置到"english"

修复已存在目录 /var/lib/cloudera-scm-server-db/data 的权限 ... initdb: 无法改变目录 "/var/lib/cloudera-scm-server-db/data" 的权限: 权限不够
Could not initialize database server.
  This usually means that your PostgreSQL installation failed or isn't working properly.
  PostgreSQL is installed using the set of repositories found on this machine. Please
  ensure that PostgreSQL can be installed. Please also uninstall any other instances of
  PostgreSQL and then try again., giving up
~~~

这时候，请执行如下命令：
	
~~~bash
$ su -s /bin/bash cloudera-scm -c "touch /var/log/cloudera-scm-server/db.log; /usr/share/cmf/bin/initialize_embedded_db.sh /var/lib/cloudera-scm-server-db/data /var/log/cloudera-scm-server/db.log"
$ su -s /bin/bash cloudera-scm -c "pg_ctl start -w -D /var/lib/cloudera-scm-server-db/data -l /var/log/cloudera-scm-server/db.log"
~~~

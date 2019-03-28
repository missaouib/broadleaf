---
layout: post
title:  Hadoop自动化安装shell脚本
description: 之前写过一些如何安装Cloudera Hadoop的文章，安装hadoop过程中，最开始是手动安装apache版本的hadoop，其次是使用Intel的IDH管理界面安装IDH的hadoop，再然后分别手动和通过cloudera manager安装hadoop，也使用bigtop-util yum方式安装过apache的hadoop。
category: hadoop
tags: [hadoop, hive, hbase, mapreduce]
---

之前写过一些如何安装Cloudera Hadoop的文章，安装hadoop过程中，最开始是手动安装apache版本的hadoop，其次是使用Intel的IDH管理界面安装IDH的hadoop，再然后分别手动和通过cloudera manager安装hadoop，也使用bigtop-util yum方式安装过apache的hadoop。

安装过程中参考了很多网上的文章，解压缩过cloudera的`cloudera-manager-installer.bin`，发现并修复了IDH shell脚本中关于puppt的自认为是bug的一个bug，最后整理出了一个自动安装hadoop的shell脚本，脚本托管在github上面: [hadoop-install](https://github.com/javachen/hadoop-install)。

<!-- more -->

# hadoop安装文章
博客中所有关于安装hadoop的文章列出如下：

1. [【笔记】Hadoop安装部署](/2013/03/08/note-about-installing-hadoop-cluster.html)

2. [手动安装Cloudera Hive CDH](/2013/03/24/manual-install-Cloudera-hive-CDH.html)

3. [手动安装Cloudera HBase CDH](/2013/03/24/manual-install-Cloudera-hbase-CDH.html)

4. [手动安装Cloudera Hadoop CDH](/2013/03/24/manual-install-Cloudera-Hadoop-CDH.html)

5. [安装impala过程](/2013/03/29/install-impala.html)

6. [从yum安装Cloudera CDH集群](/2013/04/06/install-cloudera-cdh-by-yum.html)

7. [通过Cloudera Manager安装CDH](/2013/06/24/install-cdh-by-cloudera-manager.html)


# hadoop-install
[hadoop-install](https://github.com/javachen/hadoop-install)上脚本，all-in-one-install.sh是在一个节点上安装hdfs、hive、yarn、zookeeper和hbase，编写该脚本是为了在本机（fedora19系统）上调试mapreduce、hive和hbase；cluster-install.sh是在多个节点上安装hadoop集群，同样目前完成了hdfs、hive、yarn、zookeeper和hbase的自动安装。


# 脚本片段
IDH安装脚本中有一些写的比较好的shell代码片段，摘出如下，供大家学习。

## 检测操作系统版本

    ( grep -i "CentOS" /etc/issue > /dev/null ) && OS_DISTRIBUTOR=centos
    ( grep -i "Red[[:blank:]]*Hat[[:blank:]]*Enterprise[[:blank:]]*Linux" /etc/issue > /dev/null ) && OS_DISTRIBUTOR=rhel
    ( grep -i "Oracle[[:blank:]]*Linux" /etc/issue > /dev/null ) && OS_DISTRIBUTOR=oel
    ( grep -i "Asianux[[:blank:]]*Server" /etc/issue > /dev/null ) && OS_DISTRIBUTOR=an
    ( grep -i "SUSE[[:blank:]]*Linux[[:blank:]]*Enterprise[[:blank:]]*Server" /etc/issue > /dev/null ) && OS_DISTRIBUTOR=sles
    ( grep -i "Fedora" /etc/issue > /dev/null ) && OS_DISTRIBUTOR=fedora

    major_revision=`grep -oP '\d+' /etc/issue | sed -n "1,1p"`
    minor_revision=`grep -oP '\d+' /etc/issue | sed -n "2,2p"`
    OS_RELEASE="$major_revision.$minor_revision"

## 修改root密码

	echo 'redhat'|passwd root --stdin

## 修改dns

	# Set up nameservers.
	# http://ithelpblog.com/os/linux/redhat/centos-redhat/howto-fix-couldnt-resolve-host-on-centos-redhat-rhel-fedora/
	# http://stackoverflow.com/a/850731/1486325
	echo "nameserver 8.8.8.8" | tee -a /etc/resolv.conf
	echo "nameserver 8.8.4.4" | tee -a /etc/resolv.conf

## 修改操作系统时区

	cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

## 修改hosts文件

	cat > /etc/hosts <<EOF
	127.0.0.1       localhost

	192.168.56.121 cdh1
	192.168.56.122 cdh2
	192.168.56.123 cdh3
	EOF

## 去掉b文件中包括a文件的内容

	grep -vf a b >result.log

## 修改file-max

	echo -e "Global file limit ..."
	rst=`grep "^fs.file-max" /etc/sysctl.conf`
	if [ "x$rst" = "x" ] ; then
		echo "fs.file-max = 727680" >> /etc/sysctl.conf || exit $?
	else
		sed -i "s:^fs.file-max.*:fs.file-max = 727680:g" /etc/sysctl.conf
	fi

## 生成ssh公要

	[ ! -d ~/.ssh ] && ( mkdir ~/.ssh ) && ( chmod 600 ~/.ssh )
	yes|ssh-keygen -f ~/.ssh/id_rsa -t rsa -N "" && ( chmod 600 ~/.ssh/id_rsa.pub )


## ssh设置无密码登陆

	set timeout 20

	set host [lindex $argv 0]
	set password [lindex $argv 1]
	set pubkey [exec cat /root/.ssh/id_rsa.pub]
	set localsh [exec cat ./config_ssh_local.sh]

	#spawn ssh-copy-id -i /root/.ssh/id_rsa.pub root@$host
	spawn ssh root@$host "
	umask 022
	mkdir -p  /root/.ssh
	echo \'$pubkey\' > /root/.ssh/authorized_keys
	echo \'$localsh\' >  /root/.ssh/config_ssh_local.sh
	cd /root/.ssh/; sh config_ssh_local.sh
	"
	expect {
		timeout exit
		yes/no  {send "yes\r";exp_continue}
		assword {send "$password\r"}
	}
	expect eof
	#interact

## 配置JAVA_HOME

	### JAVA_HOME ###
	if [ -f ~/.bashrc ] ; then
	    sed -i '/^export[[:space:]]\{1,\}JAVA_HOME[[:space:]]\{0,\}=/d' ~/.bashrc
	    sed -i '/^export[[:space:]]\{1,\}CLASSPATH[[:space:]]\{0,\}=/d' ~/.bashrc
	    sed -i '/^export[[:space:]]\{1,\}PATH[[:space:]]\{0,\}=/d' ~/.bashrc
	fi
	echo "" >>~/.bashrc
	echo "export JAVA_HOME=/usr/java/latest" >>~/.bashrc
	echo "export CLASSPATH=.:\$JAVA_HOME/lib/tools.jar:\$JAVA_HOME/lib/dt.jar">>~/.bashrc
	echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> ~/.bashrc

	alternatives --install /usr/bin/java java /usr/java/latest 5
	alternatives --set java /usr/java/latest 
	source ~/.bashrc

## 格式化集群

	su -s /bin/bash hdfs -c 'yes Y | hadoop namenode -format >> /tmp/format.log 2>&1'

## 创建hadoop目录

	su -s /bin/bash hdfs -c "hadoop fs -chmod a+rw /"
	while read dir user group perm
	do
	     su -s /bin/bash hdfs -c "hadoop fs -mkdir -R $dir && hadoop fs -chmod -R $perm $dir && hadoop fs -chown -R $user:$group $dir"
	     echo "."
	done << EOF
	/tmp hdfs hadoop 1777 
	/tmp/hadoop-yarn mapred mapred 777
	/var hdfs hadoop 755 
	/var/log yarn mapred 1775 
	/var/log/hadoop-yarn/apps yarn mapred 1777
	/hbase hbase hadoop 755
	/user hdfs hadoop 777
	/user/history mapred hadoop 1777
	/user/root root hadoop 777
	/user/hive hive hadoop 777
	EOF

## hive中安装并初始化postgresql

	yum install postgresql-server postgresql-jdbc -y >/dev/null
	chkconfig postgresql on
	rm -rf /var/lib/pgsql/data
	rm -rf /var/run/postgresql/.s.PGSQL.5432
	service postgresql initdb

	sed -i "s/max_connections = 100/max_connections = 600/" /var/lib/pgsql/data/postgresql.conf
	sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /var/lib/pgsql/data/postgresql.conf
	sed -i "s/shared_buffers = 32MB/shared_buffers = 256MB/" /var/lib/pgsql/data/postgresql.conf
	sed -i "s/127.0.0.1\/32/0.0.0.0\/0/" /var/lib/pgsql/data/pg_hba.conf

	sudo cat /var/lib/pgsql/data/postgresql.conf | grep -e listen -e standard_conforming_strings

	rm -rf /usr/lib/hive/lib/postgresql-jdbc.jar
	ln -s /usr/share/java/postgresql-jdbc.jar /usr/lib/hive/lib/postgresql-jdbc.jar

	su -c "cd ; /usr/bin/pg_ctl start -w -m fast -D /var/lib/pgsql/data" postgres
	su -c "cd ; /usr/bin/psql --command \"create user hiveuser with password 'redhat'; \" " postgres
	su -c "cd ; /usr/bin/psql --command \"CREATE DATABASE metastore owner=hiveuser;\" " postgres
	su -c "cd ; /usr/bin/psql --command \"GRANT ALL privileges ON DATABASE metastore TO hiveuser;\" " postgres
	su -c "cd ; /usr/bin/psql -U hiveuser -d metastore -f /usr/lib/hive/scripts/metastore/upgrade/postgres/hive-schema-0.10.0.postgres.sql" postgres
	su -c "cd ; /usr/bin/pg_ctl restart -w -m fast -D /var/lib/pgsql/data" postgres

# 总结

更多脚本，请关注github：[hadoop-install](https://github.com/javachen/hadoop-install)，你可以下载、使用并修改其中代码！





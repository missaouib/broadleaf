---
layout: post

title: Cloudera Manager安装Haddop集群
category: hadoop
tags: [hadoop,vagrant,cdh6]
description:  在开始之前，请参考我博客中的关于如何安装cdh集群的文章，这里只做简单说明。因为只是为了测试，所以是在vagrant虚拟机中创建三个虚拟机搭建一个集群来安装cdh6。
published: true
---

在开始之前，请参考我博客中的关于如何安装cdh集群的文章，这里只做简单说明。因为只是为了测试，所以是在vagrant虚拟机中创建三个虚拟机搭建一个集群来安装cdh6。

- [使用Vagrant创建虚拟机安装Hadoop](http://blog.javachen.com/2014/02/23/create-virtualbox-by-vagrant.html)
- [手动安装Cloudera Hadoop CDH](http://blog.javachen.com/2013/03/24/manual-install-Cloudera-Hadoop-CDH.html)

# 准备虚拟机
从<http://www.vagrantbox.es/>下载一个centos7的虚拟机，我这里下载的是[centos7.2](https://github.com/CommanderK5/packer-centos-template/releases/download/0.7.2/vagrant-centos-7.2.box)

    wget https://github.com/CommanderK5/packer-centos-template/releases/download/0.7.2/vagrant-centos-7.2.box
    vagrant box add centos7.2 ./vagrant-centos-7.2.box
    mkdir -p ~/workspace/vagrant/cdh6
    cd ~/workspace/vagrant/cdh6
    vagrant init centos7.2

修改Vagrantfile文件并创建bootstrap.sh文件，然后启动三个虚拟机：

    vagrant up

# 配置yum和导入GPG key

root用户登陆三个虚拟机，更新yum源：

    sudo  wget http://mirrors.aliyun.com/repo/Centos-7.repo -P /etc/yum.repos.d/
    sudo  wget -P /etc/yum.repos.d/ https://archive.cloudera.com/cm6/6.2.0/redhat7/yum/cloudera-manager.repo 
    sudo  rpm --import https://archive.cloudera.com/cm6/6.2.0/redhat7/yum/RPM-GPG-KEY-cloudera

# 配置网络名称
在每天机器上分别配置网络名称，例如在cdh1机器上：

    sudo hostnamectl set-hostname foo-1.example.com

    cat > /etc/sysconfig/network  <<EOF
    HOSTNAME=cdh1.example.com
    EOF

验证一下是否修改过来了：

    #  uname -a
    Linux cdh1.example.com 3.10.0-327.4.5.el7.x86_64 #1 SMP Mon Jan 25 22:07:14 UTC 2016 x86_64 x86_64 x86_64 GNU/Linux

安装net-tools使用ifconfig命令验证IP是否正确：

    yum install net-tools
    ifconfig

# 关掉防火墙

centos7上关掉防火墙命令：

    sudo systemctl disable firewalld
    sudo systemctl stop firewalld

    setenforce 0 >/dev/null 2>&1 && iptables -F

# 设置时钟同步

    yum install ntp -y

修改 cdh1 上的配置文件 /etc/ntp.conf :

    restrict default ignore   //默认不允许修改或者查询ntp,并且不接收特殊封包
    restrict 127.0.0.1        //给于本机所有权限
    restrict 192.168.56.0 mask 255.255.255.0 notrap nomodify  //给于局域网机的机器有同步时间的权限
    server  192.168.56.121     # local clock
    driftfile /var/lib/ntp/drift
    fudge   127.127.1.0 stratum 10

设置开机启动

    systemctl enable ntpd
    systemctl start ntpd

在其他机器上同步时钟到cdh1

    ntpdate -u cdh1

设置系统时钟：

    hwclock --systohc

#  虚拟内存设置

Cloudera 建议将`/proc/sys/vm/swappiness`设置为 0。当前设置为 60。使用 sysctl 命令在运行时更改该设置并编辑 `/etc/sysctl.conf `以在重启后保存该设置。您可以继续进行安装，但可能会遇到问题，Cloudera Manager 报告您的主机由于交换运行状况不佳。以下主机受到影响：

临时解决，通过`echo 0 > /proc/sys/vm/swappiness`即可解决。

永久解决

    sysctl -w vm.swappiness=0
    echo vm.swappiness = 0 >> /etc/sysctl.conf

# 安装jdk

    sudo yum install oracle-j2sdk1.8

#yum安装CM

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

- [使用Vagrant创建虚拟机安装Hadoop](http://blog.javachen.com/2014/02/23/create-virtualbox-by-vagrant.html)
- [手动安装Cloudera Hadoop CDH](http://blog.javachen.com/2013/03/24/manual-install-Cloudera-Hadoop-CDH.html)
- [Cloudera Manager6安装文档](https://www.cloudera.com/documentation/enterprise/6/6.0/topics/installation.html)
---
layout: post
title:  使用yum源安装CDH集群
description: 本文主要是记录使用yum源安装CDH Hadoop集群的过程，包括HDFS、Yarn、Hive和HBase。本文针对的集群版本为CDH5.4。
category: hadoop
tags: [hadoop, hdfs, yarn, hive ,hbase]
---

本文主要是记录使用yum安装CDH Hadoop集群的过程，包括HDFS、Yarn、Hive和HBase。`目前使用的是CDH6.2.0安装集群`。

# 0. 环境说明

系统环境：

- 操作系统：`CentOs 7.2`
- Hadoop版本：`CDH6.2.0`
- JDK版本：`java-1.8.0-openjdk`
- 运行用户：root

集群各节点角色规划为：

~~~
192.168.56.11  cdh1   NameNode、ResourceManager、HBase、Hive metastore、Impala Catalog、Impala statestore、Sentry 
192.168.56.12  cdh2   DataNode、NodeManager、HBase、Hive Server2、Impala Server
192.168.56.13  cdh3   DataNode、NodeManager、HBase、Hive Server2、Impala Server
~~~

cdh1作为管理节点，安装脚本在cdh1上执行。

# 1. 准备工作

## 1.1 准备虚拟机

参考[使用Vagrant创建虚拟机安装Hadoop](/2014/02/23/create-virtualbox-by-vagrant)创建三台虚拟机。

##  1.2、禁用防火墙

保存存在的iptables规则：

~~~bash
iptables-save > ~/firewall.rules
~~~

rhel7系统禁用防火墙：

~~~bash
systemctl disable firewalld
systemctl stop firewalld
~~~

设置SELinux模式：

~~~bash
setenforce 0  >/dev/null 2>&1
sed -i "s/.*SELINUX=.*/SELINUX=disabled/g" /etc/selinux/config   
~~~

一个考虑操作系统情况的综合示例：

```bash
[ -f /etc/init.d/iptables ] && FIREWALL="iptables"
[ -f /etc/init.d/SuSEfirewall2_setup ] && FIREWALL="SuSEfirewall2_setup"
[ -f /etc/init.d/boot.apparmor ] && SELINUX="boot.apparmor"
[ -f /usr/sbin/setenforce ] && SELINUX="selinux"
service $FIREWALL stop >/dev/null 2>&1
chkconfig $FIREWALL off > /dev/null 2>&1

if [ $SELINUX == "selinux" ]; then
    sed -i "s/.*SELINUX=.*/SELINUX=disabled/g" /etc/selinux/config
    setenforce 0  >/dev/null 2>&1
elif [ $SELINUX == "boot.apparmor" ]; then
    service boot.apparmor stop >/dev/null 2>&1
    chkconfig boot.apparmor off >/dev/null 2>&1
fi
```

## 1.4 禁用IPv6

CDH 要求使用 IPv4，IPv6 不支持，禁用IPv6方法：

~~~bash
cat > /etc/sysctl.conf <<EOF
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1
EOF
~~~

使其生效：

~~~bash
sysctl -p
~~~

最后确认是否已禁用：

~~~bash
cat /proc/sys/net/ipv6/conf/all/disable_ipv6
1
~~~

## 1.5 配置hosts

修改每个节点/etc/hosts文：

~~~bash
cat > /etc/hosts <<EOF
127.0.0.1       localhost
192.168.56.11 cdh1 cdh1.example.com
192.168.56.12 cdh2 cdh2.example.com
192.168.56.13 cdh3 cdh3.example.com
EOF
~~~

在每个节点分别配置网络名称。例如在cdh1节点上：

~~~bash
hostname
cdh1.example.com
hostnamectl set-hostname $(hostname)
~~~

修改网络名称：

~~~bash
cat > /etc/sysconfig/network<<EOF
HOSTNAME=$(hostname)
EOF
~~~

查看hostname是否修改过来：

~~~bash
uname -a
Linux cdh1.example.com 3.10.0-327.4.5.el7.x86_64 #1 SMP Mon Jan 25 22:07:14 UTC 2016 x86_64 x86_64 x86_64 GNU/Linux
~~~

查看ip是否正确：

~~~bash
yum install net-tools -y && ifconfig |grep -B1 broadcast
enp0s3: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.0.2.15  netmask 255.255.255.0  broadcast 10.0.2.255
--
enp0s8: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.56.11  netmask 255.255.255.0  broadcast 192.168.56.255
~~~

检查一下：

~~~bash
yum install bind-utils -y && host -v -t A `hostname`
~~~


## 1.6 设置中文编码和时区

查看中文：

```bash
locale -a | grep zh
```

如果没有，则安装：

```bash
yum install glibc-common
```

修改配置文件：
~~~bash
cat > /etc/locale.conf <<EOF
LANG="zh_CN.UTF-8"
LC_CTYPE=zh_CN.UTF-8
LC_ALL=zh_CN.UTF-8
EOF
source   /etc/locale.conf

cat > /etc/sysconfig/i18n <<EOF
LANG="zh_CN.UTF-8"
LC_ALL="zh_CN.UTF-8"
EOF
~~~

设置时区：
~~~bash
sudo ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
~~~

## 1.7 设置root密码

~~~bash
# Setup sudo to allow no-password sudo for "admin". Additionally,
# make "admin" an exempt group so that the PATH is inherited.
cp /etc/sudoers /etc/sudoers.orig
echo "root            ALL=(ALL)               NOPASSWD: ALL" >> /etc/sudoers
echo 'redhat'|passwd root --stdin >/dev/null 2>&1
~~~

## 1.8 设置命名服务

~~~bash
# http://ithelpblog.com/os/linux/redhat/centos-redhat/howto-fix-couldnt-resolve-host-on-centos-redhat-rhel-fedora/
# http://stackoverflow.com/a/850731/1486325
echo "nameserver 8.8.8.8" | tee -a /etc/resolv.conf
echo "nameserver 8.8.4.4" | tee -a /etc/resolv.conf
~~~

## 1.9 生成ssh

在每个节点依次执行：

~~~bash
[ ! -d ~/.ssh ] && ( mkdir ~/.ssh ) && ( chmod 600 ~/.ssh )
[ ! -f ~/.ssh/id_rsa.pub ] && (yes|ssh-keygen -f ~/.ssh/id_rsa -t rsa -N "") \
  && ( chmod 600 ~/.ssh/id_rsa.pub ) && cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
~~~

## 1.10 时钟同步

每个节点执行

~~~bash
yum install ntp -y
~~~

修改时钟服务器：
~~~
sed -i "/^server/ d" /etc/ntp.conf   #删除行
cat << EOF | sudo tee -a /etc/ntp.conf
server ntp1.aliyun.com
server ntp2.aliyun.com
server ntp3.aliyun.com
server ntp4.aliyun.com
EOF
~~~

启动 ntp：

~~~bash
sudo systemctl start ntpd

#设置开机启动
sudo systemctl enable ntpd
~~~

同步硬件时钟：

~~~bash
hwclock --systohc
~~~

查看硬件时钟：

```bash
hwclock --show
```

同步时间：

```bash
ntpdate -u ntp1.aliyun.com
```

##  1.11 虚拟内存设置

Cloudera 建议将`/proc/sys/vm/swappiness`设置为 0，当前设置为 60。

临时解决，通过`echo 0 > /proc/sys/vm/swappiness`即可解决。

永久解决：

~~~bash
sysctl -w vm.swappiness=0
echo vm.swappiness = 0 >> /etc/sysctl.conf
~~~

## 1.12 设置透明大页面

~~~
echo "echo never > /sys/kernel/mm/redhat_transparent_hugepage/defrag" >/etc/rc.local
echo "echo never > /sys/kernel/mm/redhat_transparent_hugepage/enabled" >/etc/rc.local
~~~

给与可执行权限：chmod +x /etc/rc.d/rc.local

## 1.13 设置文件打开数

```bash
rst=`grep "^fs.file-max" /etc/sysctl.conf`
if [ "x$rst" = "x" ] ; then
	echo "fs.file-max = 727680" >> /etc/sysctl.conf || exit $?
else
	sed -i "s:^fs.file-max.*:fs.file-max = 727680:g" /etc/sysctl.conf
fi

addline "*	soft		nofile	327680" /etc/security/limits.conf
addline "*	hard	    nofile	327680" /etc/security/limits.conf
addline "root	soft	nofile	327680" /etc/security/limits.conf
addline "root	hard	nofile	327680" /etc/security/limits.conf

curuser=`whoami`
for user in hdfs mapred hbase zookeeper hive impala flume $curuser ;do
    addline "$user	soft	nproc	131072" /etc/security/limits.conf
    addline "$user	hard	nproc	131072" /etc/security/limits.conf
done
```

这里用到了一个函数：

```bash
function addline {
    line=$1
    file=$2
    tempstr=`grep "$line" $file  2>/dev/null`
    if [ "$tempstr" == "" ]; then
        echo "$line" >>$file
    fi
}
```

## 1.14 安装jdk

jdk版本看cdh版本而定，我这里是jdk1.8。

先卸载：

~~~
yum remove java* -y
~~~

每个节点安装jdk：

~~~bash
yum install -y java-1.8.0-openjdk-devel
~~~

设置环境变量：

~~~bash
cat << EOF | sudo tee -a /etc/profile
export JAVA_HOME=/usr/lib/jvm/java
export CLASSPATH=.:\$JAVA_HOME/lib:\$JAVA_HOME/jre/lib:\$CLASSPATH
export PATH=\$JAVA_HOME/bin:\$JAVA_HOME/jre/bin:\$PATH
EOF
source /etc/profile
~~~

## 1.15 配置SSH无密码登陆

![image-20190703162002253](/images/ssh-1.png)

每个节点先生成ssh公钥，参考上面说明。

配置无密码登陆，在每个节点上执行以下命令：

~~~bash
ssh-copy-id -i /root/.ssh/id_rsa.pub root@cdh1
ssh-copy-id -i /root/.ssh/id_rsa.pub root@cdh2
ssh-copy-id -i /root/.ssh/id_rsa.pub root@cdh3
~~~

然后，在其他节点上类似操作。

也可以使用expect来操作：

```bash
ssh_nopassword.expect cdh1 root #root是要设置的密码
ssh_nopassword.expect cdh1 root
ssh_nopassword.expect cdh1 root
```

ssh_nopassword.expect文件内容如下：

```bash
#! /usr/bin/expect -f

set host [lindex $argv 0]
set password [lindex $argv 1]

spawn ssh-copy-id -i /root/.ssh/id_rsa.pub root@$host
expect {
yes/no  {send "yes\r";exp_continue}
-nocase "password:" {send "$password\r"}
}
expect eof
```

.ssh文件夹下的文件功能解释

​	（1）~/.ssh/known_hosts	：记录ssh访问过计算机的公钥(public key)

​	（2）id_rsa	：生成的私钥

​	（3）id_rsa.pub	：生成的公钥

​	（4）authorized_keys	：存放授权过得无秘登录服务器公钥

## 1.16 配置cdh yum源

配置cdh6.2的远程yum源：

```bash
cat > /etc/yum.repos.d/cdh6.repo  <<EOF
[cloudera-cdh]  
name=Cloudera's Distribution for Hadoop, Version 6  
baseurl=https://archive.cloudera.com/cdh6/6.2.0/redhat7/yum/
gpgkey = https://archive.cloudera.com/cdh6/6.2.0/redhat7/yum/RPM-GPG-KEY-cloudera
enabled=1      
gpgcheck = 1 
EOF
```

将/etc/yum.repos.d/cdh6.repo拷贝到其他节点：

```bash
scp /etc/yum.repos.d/cdh6.repo root@cdh2:/etc/yum.repos.d/cdh6.repo
scp /etc/yum.repos.d/cdh6.repo root@cdh3:/etc/yum.repos.d/cdh6.repo
```

也可以将yum远程同步到本地，设置本地yum源：

```bash
yum -y install createrepo yum-utils
mkdir -p /mnt/yum
cd /mnt/yum
reposync -r cloudera-cdh
createrepo cloudera-cdh
yum clean all
```

# 2. 安装HDFS

根据文章开头的节点规划，cdh1 为NameNode节点，cdh1、cdh2 和 cdh3 为DataNode节点

在 cdh1 节点安装 hadoop-hdfs-namenode：

~~~bash
yum install hadoop-hdfs-namenode -y
~~~

在cdh1、cdh2、cdh3节点安装 hadoop-hdfs-datanode

~~~bash
yum install hadoop hadoop-hdfs-datanode -y
~~~

NameNode HA 的配置过程请参考[CDH中配置HDFS HA](/2014/07/18/install-hdfs-ha-in-cdh.html)，建议暂时不用配置。

## 2.1 修改hadoop配置文件

修改`/etc/hadoop/conf/core-site.xml`：

~~~xml
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://cdh1:8020</value>
    </property>

     <property>
        <name>hadoop.tmp.dir</name>
        <value>/var/hadoop</value>
    </property>
~~~

> 更多的配置信息说明，请参考 [Apache Cluster Setup](http://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/ClusterSetup.html)

修改`/etc/hadoop/conf/hdfs-site.xml`，dfs.namenode.http-address如果不指定，默认端口为9870：

~~~xml
<configuration>
  	<property>
        <name>dfs.namenode.http-address</name>
        <value>cdh1:9870</value>
    </property>
    <!-- CLOUDERA-BUILD: CDH-64745. -->
    <property>
        <name>cloudera.erasure_coding.enabled</name>
        <value>true</value>
    </property>
</configuration>
~~~

>注意：需要将配置文件同步到各个节点。

设置文件权限相关，请参考 [HDFS Extended ACLs](https://www.cloudera.com/documentation/enterprise/latest/topics/cdh_sg_hdfs_ext_acls.html) 和 [0630-6.2-什么是HDFS ACL](https://cloud.tencent.com/developer/article/1429112)

```xml
  <property>
		<name>dfs.permissions.superusergroup</name>
		<value>hadoop</value>
	</property>

	<property>
		<name>dfs.permissions.umask-mode</name>
		<value>022</value>
	</property>
```

## 2.2 指定本地文件目录

在hadoop中默认的文件路径以及权限要求如下：

~~~
目录		所有者		权限			默认路径
hadoop.tmp.dir	hdfs:hdfs	drwx------	/tmp/hadoop-${user}
dfs.namenode.name.dir	hdfs:hdfs	drwx------	file://${hadoop.tmp.dir}/dfs/name
dfs.datanode.data.dir	hdfs:hdfs	drwx------	file://${hadoop.tmp.dir}/dfs/data
dfs.namenode.checkpoint.dir	hdfs:hdfs	drwx------ file://${hadoop.tmp.dir}/dfs/namesecondary
~~~

我在hdfs-site.xm l中配置了`hadoop.tmp.dir`的路径为`/var/hadoop`，其他路径使用默认配置，所以，在NameNode上手动创建 `dfs.namenode.name.dir` 的本地目录：

~~~bash
mkdir -p /var/hadoop/dfs/name
chown -R hdfs:hdfs /var/hadoop/dfs/name 
~~~

在DataNode上手动创建 `dfs.datanode.data.dir`目录：

~~~bash
mkdir -p /var/hadoop/dfs/data
chown -R hdfs:hdfs /var/hadoop/dfs/data
~~~

hadoop的进程会自动设置 `dfs.data.dir` 或 `dfs.datanode.data.dir`，但是 `dfs.name.dir` 或 `dfs.namenode.name.dir` 的权限默认为755，需要手动设置为700：

~~~bash
chmod 700 /var/hadoop/dfs/name
# 或者
chmod go-rx /var/hadoop/dfs/name
~~~

注意：DataNode的本地目录可以设置多个，你可以设置 `dfs.datanode.failed.volumes.tolerated` 参数的值，表示能够容忍不超过该个数的目录失败。

## 2.3 配置 SecondaryNameNode

不建议使用。

## 2.4 开启回收站功能

回收站功能默认是关闭的，建议打开。在 `/etc/hadoop/conf/core-site.xml` 中添加如下两个参数：

- `fs.trash.interval`,该参数值为时间间隔，单位为分钟，默认为0，表示回收站功能关闭。该值表示回收站中文件保存多长时间，如果服务端配置了该参数，则忽略客户端的配置；如果服务端关闭了该参数，则检查客户端是否有配置该参数；
- `fs.trash.checkpoint.interval`，该参数值为时间间隔，单位为分钟，默认为0。该值表示检查回收站时间间隔，该值要小于`fs.trash.interval`，该值在服务端配置。如果该值设置为0，则使用 `fs.trash.interval` 的值。

## 2.5 (可选)配置DataNode存储的负载均衡

在 `/etc/hadoop/conf/hdfs-site.xml` 中配置以下三个参数：

- `dfs.datanode.fsdataset. volume.choosing.policy`
- `dfs.datanode.available-space-volume-choosing-policy.balanced-space-threshold`
- `dfs.datanode.available-space-volume-choosing-policy.balanced-space-preference-fraction`

详细说明，请参考 [Optionally configure DataNode storage balancing](http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH5/latest/CDH5-Installation-Guide/cdh5ig_hdfs_cluster_deploy.html#concept_ncq_nnk_ck_unique_1)。

## 2.6 开启WebHDFS

在NameNode节点上安装：

~~~bash
yum install hadoop-httpfs -y
~~~

然后修改 /etc/hadoop/conf/core-site.xml配置代理用户：

~~~xml
    <property>  
        <name>hadoop.proxyuser.httpfs.hosts</name>  
        <value>*</value>  
    </property>  

    <property>  
        <name>hadoop.proxyuser.httpfs.groups</name>  
        <value>*</value>  
    </property>
~~~

## 2.7 配置LZO

下载repo文件到 `/etc/yum.repos.d/`:

 - 如果你安装的是 CDH4，请下载[Red Hat/CentOS 6](http://archive.cloudera.com/gplextras/redhat/6/x86_64/gplextras/cloudera-gplextras4.repo)
 - 如果你安装的是 CDH5，请下载[Red Hat/CentOS 6](http://archive.cloudera.com/gplextras5/redhat/6/x86_64/gplextras/cloudera-gplextras5.repo)
 - 如果你安装的是 CDH6，请直接使用yum源：https://archive.cloudera.com/gplextras6/6.2.0/redhat7/yum/

然后，安装lzo:

~~~bash
yum install hadoop-lzo* impala-lzo  -y
~~~

最后，在 `/etc/hadoop/conf/core-site.xml` 中添加如下配置：

~~~xml
<property>
  <name>io.compression.codecs</name>
  <value>org.apache.hadoop.io.compress.DefaultCodec,org.apache.hadoop.io.compress.GzipCodec,
org.apache.hadoop.io.compress.BZip2Codec,com.hadoop.compression.lzo.LzoCodec,
com.hadoop.compression.lzo.LzopCodec</value>
</property>
<property>
  <name>io.compression.codec.lzo.class</name>
  <value>com.hadoop.compression.lzo.LzoCodec</value>
</property>
~~~

更多关于LZO信息，请参考：[Using LZO Compression](http://wiki.apache.org/hadoop/UsingLzoCompression)

## 2.8 (可选)配置Snappy

cdh 的 rpm 源中默认已经包含了 snappy ，直接在每个节点安装Snappy：

~~~bash
yum install snappy snappy-devel  -y
~~~

然后，在 `core-site.xml` 中修改`io.compression.codecs`的值，添加 `org.apache.hadoop.io.compress.SnappyCodec` 。

使 snappy 对 hadoop 可用：

~~~bash
ln -sf /usr/lib64/libsnappy.so /usr/lib/hadoop/lib/native/
~~~

## 2.9 启动HDFS

将cdh1上的配置文件同步到每一个节点：

~~~bash
scp -r /etc/hadoop/conf root@cdh2:/etc/hadoop/
scp -r /etc/hadoop/conf root@cdh3:/etc/hadoop/
~~~

在cdh1节点格式化NameNode：

~~~bash
sudo -u hdfs hdfs namenode -format
~~~

在cdh1启动namenode，其他节点启动datanode：

~~~bash
/etc/init.d/hadoop-hdfs-namenode start
/etc/init.d/hadoop-hdfs-datanode start
~~~

在cdh1节点上查看java进程：

```
jps
12721 DataNode
12882 Jps
12587 NameNode
```

在 hdfs 运行之后，创建 `/tmp` 临时目录，并设置权限为 `1777`：

~~~bash
sudo -u hdfs hadoop fs -mkdir /tmp
sudo -u hdfs hadoop fs -chmod -R 1777 /tmp
~~~

如果安装了HttpFS，则启动 HttpFS 服务：

~~~bash
service hadoop-httpfs start
~~~

## 2.10 测试

如果使用CM安装，则Hadoop各组件使用的端口可查阅 [Ports Used by CDH Components](https://www.cloudera.com/documentation/enterprise/6/6.2/topics/cdh_ports.html#cdh_ports)。

可以通过 <http://cdh1:9870/> （需要先在本机配置虚拟机节点的hosts映射才能访问）可以访问 NameNode 页面，也可以访问datanode节点，如：[http://cdh1:9864/](http://cdh1:9864/)。

如果安装了webhdfs，可以使用 curl 运行下面命令，可以测试 webhdfs 并查看执行结果：

~~~bash
curl "http://cdh1:14000/webhdfs/v1?op=gethomedirectory&user.name=hdfs"
{"Path":"\/var\/lib\/hadoop-httpfs"}
~~~

更多的 API，请参考 [WebHDFS REST API](http://archive.cloudera.com/cdh5/cdh/5/hadoop/hadoop-project-dist/hadoop-hdfs/WebHDFS.html)

# 3. 安装YARN

根据文章开头的节点规划，cdh1 为resourcemanager节点，cdh2 和 cdh3 为nodemanager节点，为了简单，historyserver 也装在 cdh1 节点上。

## 3.1 安装服务

在 cdh1 节点安装:

~~~bash
yum install hadoop-yarn-resourcemanager -y

#安装 historyserver
yum install hadoop-mapreduce-historyserver hadoop-yarn-proxyserver -y
~~~

在 cdh2、cdh3 节点安装:

~~~bash
yum install hadoop-yarn-nodemanager -y
~~~

## 3.2 修改配置参数

1、要想使用YARN，需要在 `/etc/hadoop/conf/mapred-site.xml` 中做如下配置:

~~~xml
    <property>
    	<name>mapreduce.framework.name</name>
    	<value>yarn</value>
    </property>
~~~

2、修改 `/etc/hadoop/conf/yarn-site.xml `文件内容：

```xml
<configuration>
  <property>
    <name>yarn.resourcemanager.hostname</name>
    <value>cdh1</value>
  </property>
  
  <property>
    <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce_shuffle</value>
  </property>

  <property>
    <name>yarn.nodemanager.aux-services.mapreduce_shuffle.class</name>
    <value>org.apache.hadoop.mapred.ShuffleHandler</value>
  </property>

  <property>
    <description>Classpath for typical applications.</description>
     <name>yarn.application.classpath</name>
     <value>
        $HADOOP_CONF_DIR,
        $HADOOP_COMMON_HOME/*,$HADOOP_COMMON_HOME/lib/*,
        $HADOOP_HDFS_HOME/*,$HADOOP_HDFS_HOME/lib/*,
        $HADOOP_MAPRED_HOME/*,$HADOOP_MAPRED_HOME/lib/*,
        $HADOOP_YARN_HOME/*,$HADOOP_YARN_HOME/lib/*
     </value>
  </property>
</configuration>
```

**注意：**

- `yarn.nodemanager.aux-services` 的值在 cdh4 中应该为 `mapreduce.shuffle`，并配置参数`yarn.nodemanager.aux-services.mapreduce.shuffle.class`值为 `org.apache.hadoop.mapred.ShuffleHandler` ，在cdh5之后中为`mapreduce_shuffle`，这时候请配置`yarn.nodemanager.aux-services.mapreduce_shuffle.class`参数

- 这里配置了 `yarn.application.classpath` ，需要设置一些喜欢环境变量：

~~~bash

export HADOOP_HOME=/usr/lib/hadoop
export HIVE_HOME=/usr/lib/hive
export HBASE_HOME=/usr/lib/hbase

export HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop
export HADOOP_COMMON_HOME=${HADOOP_HOME}
export HADOOP_HDFS_HOME=/usr/lib/hadoop-hdfs
export HADOOP_MAPRED_HOME=/usr/lib/hadoop-mapreduce
export HADOOP_YARN_HOME=/usr/lib/hadoop-yarn

export HADOOP_LIBEXEC_DIR=${HADOOP_HOME}/libexec
~~~

在hadoop中默认的文件路径以及权限要求如下：

~~~
目录		所有者		 权限		默认路径
yarn.nodemanager.local-dirs	yarn:yarn	  drwxr-xr-x    ${hadoop.tmp.dir}/nm-local-dir
yarn.nodemanager.log-dirs		yarn:yarn	  drwxr-xr-x	  ${yarn.log.dir}/userlogs
yarn.nodemanager.remote-app-log-dir	hdfs:hadoop /tmp/logs
~~~

- `${yarn.log.dir}`默认值为：`/var/log/hadoop-yarn/userlogs`，这是本地目录。

- /tmp/logs为hdfs上的地址，运行时自动创建

在nodemanager节点cdh2、cdh3创建 `yarn.nodemanager.local-dirs` 和 `yarn.nodemanager.log-dirs` 参数对应的目录：

~~~bash
mkdir -p /var/hadoop/nm-local-dir
chown -R yarn:yarn /var/hadoop/nm-local-dir
~~~

3、在 `/etc/hadoop/conf/mapred-site.xml` 中配置 MapReduce History Server：

~~~xml
<property>
  <name>mapreduce.jobhistory.address</name>
  <value>cdh1:10020</value>
</property>
<property>
  <name>mapreduce.jobhistory.webapp.address</name>
  <value>cdh1:19888</value>
</property>
~~~

4、此外，确保 mapred、yarn 用户能够使用代理，在 `/etc/hadoop/conf/core-site.xml` 中添加如下参数：

~~~xml
<property>
  <name>hadoop.proxyuser.mapred.groups</name>
  <value>*</value>
</property>
<property>
  <name>hadoop.proxyuser.mapred.hosts</name>
  <value>*</value>
</property>
<property>
  <name>hadoop.proxyuser.yarn.groups</name>
  <value>*</value>
</property>
<property>
  <name>hadoop.proxyuser.yarn.hosts</name>
  <value>*</value>
</property>
~~~

5、开启日志聚集

日志聚集概念：应用运行完成以后，将日志信息上传到HDFS系统上。

```xml
<!-- 日志聚集功能使能 -->
<property>
  <name>yarn.log-aggregation-enable</name>
  <value>true</value>
</property>
<!-- 日志保留时间设置7天 -->
<property>
  <name>yarn.log-aggregation.retain-seconds</name>
  <value>604800</value>
</property>
```

查看日志 http://cdh1:19888/jobhistory

## 3.4 验证 HDFS 结构：

~~~bash
sudo -u hdfs hadoop fs -ls -R /
~~~

你应该看到如下结构：

~~~bash
drwxrwxrwt   - hdfs  hadoop          0 2019-07-03 23:40 /tmp
~~~

## 3.5 同步配置文件

同步配置文件到整个集群:

~~~bash
scp -r /etc/hadoop/conf root@cdh2:/etc/hadoop/
scp -r /etc/hadoop/conf root@cdh3:/etc/hadoop/
~~~

## 3.6 启动服务

在 cdh1 节点启动 resourceManager

```bash
/etc/init.d/hadoop-yarn-resourcemanager start
```

在 cdh1 节点启动 mapred-historyserver :

~~~bash
/etc/init.d/hadoop-mapreduce-historyserver start
~~~

在 cdh2、cdh3 节点启动nodeManager :

```bash
/etc/init.d/hadoop-yarn-nodemanager start
```

为每个 MapReduce 用户创建主目录，比如说 hive 用户或者当前用户：

~~~bash
sudo -u hdfs hadoop fs -mkdir /user/$USER
sudo -u hdfs hadoop fs -chown $USER /user/$USER
~~~

## 3.7 测试

通过 <http://cdh1:8088/> 可以访问 Yarn 的管理页面，通过 <http://cdh1:19888/> 可以访问 JobHistory 的管理页面，查看在线的节点：<http://cdh1:8088/cluster/nodes>。

运行下面的测试程序，看是否报错：

~~~bash
# Find how many jars name ending with examples you have inside location /usr/lib/
find /usr/lib/ -name "*hadoop*examples*.jar"

# To list all the class name inside jar
find /usr/lib/ -name "hadoop*examples.jar" | xargs -0 -I '{}' sh -c 'jar tf {}'

# To search for specific class name inside jar
find /usr/lib/ -name "hadoop*examples.jar" | xargs -0 -I '{}' sh -c 'jar tf {}' | grep -i wordcount.class

# 运行 randomwriter 例子
sudo -u hdfs hadoop jar /usr/lib/hadoop-mapreduce/hadoop-mapreduce-examples.jar randomwriter out
~~~

> 注意：在虚拟机上，内存不足，跑不出来结果。

## 3.8 最后的配置文件

/etc/hadoop/conf/yarn-site.xml：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <property>
    <name>yarn.resourcemanager.hostname</name>
    <value>cdh1</value>
  </property>
  <property>
    <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce_shuffle</value>
  </property>

  <property>
    <name>yarn.nodemanager.aux-services.mapreduce_shuffle.class</name>
    <value>org.apache.hadoop.mapred.ShuffleHandler</value>
  </property>

  <property>
    <name>yarn.log-aggregation-enable</name>
    <value>true</value>
  </property>

  <property>
    <name>yarn.app.mapreduce.am.staging-dir</name>
    <value>/user</value>
  </property>

  <property>
     <name>yarn.application.classpath</name>
     <value>
        $HADOOP_CONF_DIR,
        $HADOOP_COMMON_HOME/*,$HADOOP_COMMON_HOME/lib/*,
        $HADOOP_HDFS_HOME/*,$HADOOP_HDFS_HOME/lib/*,
        $HADOOP_MAPRED_HOME/*,$HADOOP_MAPRED_HOME/lib/*,
        $HADOOP_YARN_HOME/*,$HADOOP_YARN_HOME/lib/*
     </value>
  </property>
</configuration>
```

/etc/hadoop/conf/mapred-site.xml：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <property>
    <name>mapreduce.framework.name</name>
    <value>yarn</value>
  </property>
  <property>
    <name>mapreduce.jobhistory.address</name>
    <value>cdh1:10020</value>
  </property>
  <property>
    <name>mapreduce.jobhistory.webapp.address</name>
    <value>cdh1:19888</value>
  </property>
</configuration>
```



## 3.9 YARN默认配置

**ResourceManager**

| 选项                                                      | 默认值                                                       |
| --------------------------------------------------------- | ------------------------------------------------------------ |
| yarn.resourcemanager.address                              | ${yarn.resourcemanager.hostname}:8032                        |
| yarn.resourcemanager.scheduler.address                    | ${yarn.resourcemanager.hostname}:8030                        |
| yarn.resourcemanager.resource-tracker.address             | ${yarn.resourcemanager.hostname}:8031                        |
| yarn.resourcemanager.admin.address                        | ${yarn.resourcemanager.hostname}:8033                        |
| yarn.resourcemanager.webapp.address                       | ${yarn.resourcemanager.hostname}:8088                        |
| yarn.resourcemanager.webapp.https.address                 | ${yarn.resourcemanager.hostname}:8090                        |
| yarn.resourcemanager.scheduler.class                      | org.apache.hadoop.yarn.server.resourcemanager<br/>.scheduler.capacity.CapacityScheduler |
| yarn.resourcemanager.resource-tracker.client.thread-count | 50                                                           |
| yarn.scheduler.minimum-allocation-mb                      | 1024                                                         |
| yarn.scheduler.maximum-allocation-mb                      | 8192                                                         |
| yarn.scheduler.minimum-allocation-vcores                  | 1                                                            |
| yarn.scheduler.maximum-allocation-vcores                  | 32                                                           |
| yarn.resourcemanager.nodes.include-path                   | 空                                                           |
| yarn.resourcemanager.nodes.exclude-path                   | 空                                                           |
| yarn.resourcemanager.nodemanagers.heartbeat-interval-ms   | 1000（毫秒）                                                 |

**NodeManager**

| 选项                                                  | 默认值                            |
| ----------------------------------------------------- | --------------------------------- |
| yarn.nodemanager.resource.memory-mb                   | 2.1                               |
| yarn.nodemanager.resource.cpu-vcores                  | 8                                 |
| yarn.nodemanager.local-dirs                           | ${hadoop.tmp.dir}/nm-local-dir    |
| yarn.nodemanager.log.retain-seconds                   | 10800（3小时）                    |
| yarn.nodemanager.aux-services                         |                                   |
| yarn.nodemanager.aux-services.mapreduce_shuffle.class |                                   |
| yarn.nodemanager.localizer.address                    | ${yarn.nodemanager.hostname}:8040 |
| yarn.nodemanager.webapp.address                       | ${yarn.nodemanager.hostname}:8042 |
| yarn.nodemanager.log-dirs                             | ${yarn.log.dir}/userlogs          |
| yarn.nodemanager.remote-app-log-dir                   | /tmp/logs                         |

**ResourceManager HA**

| 选项                                                    | 默认值                                                       |
| ------------------------------------------------------- | ------------------------------------------------------------ |
| yarn.resourcemanager.ha.enabled                         | false                                                        |
| yarn.resourcemanager.cluster-id                         |                                                              |
| yarn.resourcemanager.ha.id                              |                                                              |
| yarn.resourcemanager.ha.rm-ids                          |                                                              |
| yarn.resourcemanager.ha.automatic-failover.enabled      | true                                                         |
| yarn.resourcemanager.ha.automatic-failover.embedded     | true                                                         |
| yarn.resourcemanager.hostname.xxx                       |                                                              |
| yarn.resourcemanager.recovery.enabled                   | false                                                        |
| yarn.resourcemanager.zk-address                         |                                                              |
| yarn.resourcemanager.store.class                        | org.apache.hadoop.yarn.server.resourcemanager.recovery.ZKRMStateStore |
| yarn.client.failover-proxy-provider                     | org.apache.hadoop.yarn.client.ConfiguredRMFailoverProxyProvider |
| yarn.client.failover-max-attempts                       | （yarn.resourcemanager.connect.max-wait.ms）                 |
| yarn.resourcemanager.ha.automatic-failover.zk-base-path | /yarn-leader-election                                        |
| yarn.client.failover-sleep-max-ms                       | （yarn.resourcemanager.connect.retry-interval.ms）           |
| yarn.client.failover-retries                            | 0                                                            |
| yarn.client.failover-retries-on-socket-timeouts         | 0                                                            |

**Timeline Server**

| 选项                                                      | 默认值                                  |
| --------------------------------------------------------- | --------------------------------------- |
| yarn.timeline-service.enabled                             | false                                   |
| yarn.resourcemanager.system-metrics-publisher.enabled     | false                                   |
| yarn.timeline-service.generic-application-history.enabled | false                                   |
| yarn.timeline-service.hostname                            | 0.0.0.0                                 |
| yarn.timeline-service.address                             | ${yarn.timeline-service.hostname}:10200 |
| yarn.timeline-service.webapp.address                      | {yarn.timeline-service.hostname}:8188   |
| yarn.timeline-service.webapp.https.address                | ${yarn.timeline-service.hostname}:8190  |
| yarn.timeline-service.leveldb-timeline-store.path         | ${hadoop.tmp.dir}/yarn/timeline         |

**sharedcache**

| 选项                                     | 默认值       |
| ---------------------------------------- | ------------ |
| yarn.sharedcache.enabled                 | false        |
| yarn.sharedcache.root-dir                | /sharedcache |
| yarn.sharedcache.admin.address           | 0.0.0.0:8047 |
| yarn.sharedcache.webapp.address          | 0.0.0.0:8788 |
| yarn.sharedcache.uploader.server.address | 0.0.0.0:8046 |
| yarn.sharedcache.client-server.address   | 0.0.0.0:8045 |

# 4. 安装 Zookeeper

Zookeeper 至少需要3个节点，并且节点数要求是基数，这里在所有节点上都安装 Zookeeper。

## 4.1 安装

在每个节点上安装zookeeper：

~~~bash
yum install zookeeper-server -y
~~~

## 4.2 修改配置文件

设置 zookeeper 配置 `/etc/zookeeper/conf/zoo.cfg`

~~~properties
maxClientCnxns=50
tickTime=2000
initLimit=10
syncLimit=5
dataDir=/var/lib/zookeeper
clientPort=2181
server.1=cdh1:2888:3888
server.2=cdh3:2888:3888
server.3=cdh3:2888:3888
~~~

##4.3  同步配置文件

将配置文件同步到其他节点：

~~~bash
scp -r /etc/zookeeper/conf root@cdh2:/etc/zookeeper/
scp -r /etc/zookeeper/conf root@cdh3:/etc/zookeeper/
~~~

## 4.4 初始化并启动服务

在每个节点上初始化并启动 zookeeper，注意 n 的值需要和 zoo.cfg 中的编号一致。

在 cdh1 节点运行：

~~~bash
service zookeeper-server init --myid=1
service zookeeper-server start
~~~

在 cdh2 节点运行：

~~~bash
service zookeeper-server init --myid=2
service zookeeper-server start
~~~

在 cdh3 节点运行：

~~~
service zookeeper-server init --myid=3
service zookeeper-server start
~~~

## 4.5 测试

通过下面命令测试是否启动成功：

~~~bash
zookeeper-client -server cdh1:2181
~~~

# 5. 安装 HBase

HBase 依赖 ntp 服务，故需要提前安装好 ntp。

## 5.1 安装前设置

修改 `dfs.datanode.max.xcievers`，在 `hdfs-site.xml` 中修改该参数值，将该值调整到较大的值：

~~~xml
<property>
  <name>dfs.datanode.max.xcievers</name>
  <value>8192</value>
</property>
~~~

## 5.2 安装

在每个节点上安装 master 和 regionserver，如果需要你可以安装 hbase-rest、hbase-solr-indexer、hbase-thrift

~~~bash
yum install hbase-master hbase-regionserver -y
~~~

## 5.3 修改配置文件

修改 `hbase-site.xml`文件，关键几个参数及含义如下：

- `hbase.distributed`：是否为分布式模式
- `hbase.rootdir`：HBase在hdfs上的目录路径
- `hbase.tmp.dir`：本地临时目录
- `hbase.zookeeper.quorum`：zookeeper集群地址，逗号分隔
- `hbase.hregion.max.filesize`：hregion文件最大大小
- `hbase.hregion.memstore.flush.size`：memstore文件最大大小

默认配置参数，请参考：https://hbase.apache.org/2.1/book.html#hbase_default_configurations 。

另外，在CDH5中建议`关掉Checksums`（见[Upgrading HBase](http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH5/latest/CDH5-Installation-Guide/cdh5ig_hbase_upgrade.html)）以提高性能，最后的配置如下：

~~~xml
<configuration>
  <property>
    <name>hbase.cluster.distributed</name>
    <value>true</value>
  </property>
  <property>
    <name>hbase.rootdir</name>
    <value>hdfs://cdh1:8020/hbase</value>
  </property>
  <property>
    <name>hbase.tmp.dir</name>
    <value>/var/hbase</value>
  </property>
</configuration>
~~~

在 hdfs 中创建 `/hbase` 目录

~~~bash
sudo -u hdfs hadoop fs -mkdir /hbase
sudo -u hdfs hadoop fs -chown hbase:hadoop /hbase
~~~

设置 crontab 定时删除日志：

~~~
crontab -e
* 10 * * * cd /var/log/hbase/; rm -rf `ls /var/log/hbase/|grep -P 'hbase\-hbase\-.+\.log\.[0-9]'\`>> /dev/null &
~~~

## 5.4 同步配置文件

将配置文件同步到其他节点：

~~~bash
scp -r /etc/hbase/conf root@cdh2:/etc/hbase/
scp -r /etc/hbase/conf root@cdh3:/etc/hbase/
~~~

## 5.5 创建本地目录

在 hbase-site.xml 配置文件中配置了 `hbase.tmp.dir` 值为 `/data/hbase`，现在需要在每个 hbase 节点创建该目录并设置权限：

~~~bash
mkdir -p /var/hbase
chown -R hbase:hbase /var/hbase
chmod -R 700 /var/hbase
~~~

## 5.6 启动HBase

~~~bash
for x in `ls /etc/init.d/|grep hbase` ; do service $x start ; done
~~~

## 5.7 测试

通过 <http://cdh2:16030/> 可以访问 RegionServer 页面，然后通过该页面可以知道哪个节点为 Master，然后再通过 16010 端口访问 Master 管理界面。

在安装有HBase的节点如cdh2运行下面命令：

```bash
hbase shell
```



# 6. 安装hive

在一个 NameNode 节点上安装 hive：

~~~bash
yum install hive hive-metastore hive-server2 hive-jdbc hive-hbase  -y
~~~

在其他 DataNode 上安装：

~~~bash
yum install hive hive-server2 hive-jdbc hive-hbase -y
~~~

## 安装postgresql

这里使用 postgresq l数据库来存储元数据，如果你想使用 mysql 数据库，请参考下文。手动安装、配置 postgresql 数据库，请参考 [手动安装Cloudera Hive CDH](/hadoop/images/03/24/manual-install-Cloudera-hive-CDH.html)

yum 方式安装：

~~~
yum install postgresql-server postgresql-jdbc -y

ln -s /usr/share/java/postgresql-jdbc.jar /usr/lib/hive/lib/postgresql-jdbc.jar
~~~

配置开启启动，并初始化数据库：

~~~bash
chkconfig postgresql on
service postgresql initdb
~~~

修改配置文件/var/lib/pgsql/data/postgresql.conf：

~~~bash
sed -i "s/max_connections = 100/max_connections = 600/" /var/lib/pgsql/data/postgresql.conf
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /var/lib/pgsql/data/postgresql.conf
sed -i "s/shared_buffers = 32MB/shared_buffers = 256MB/" /var/lib/pgsql/data/postgresql.conf
sed -i "s/#standard_conforming_strings = on/standard_conforming_strings = off/" /var/lib/pgsql/data/postgresql.conf
~~~

修改 /var/lib/pgsql/data/pg_hba.conf：

~~~bash
	sed -i "s/127.0.0.1\/32/0.0.0.0\/0/" /var/lib/pgsql/data/pg_hba.conf
	sed -i "s/ident/trust/" /var/lib/pgsql/data/pg_hba.conf
	sed -i "s/peer/trust/" /var/lib/pgsql/data/pg_hba.conf
~~~

创建数据库metastore和用户hive，设置密码为hive：

~~~bash
su -c "cd ; /usr/bin/pg_ctl start -w -m fast -D /var/lib/pgsql/data" postgres
su -c "cd ; /usr/bin/psql --command \"create user hive with password 'hive'; \" " postgres
su -c "cd ; /usr/bin/psql --command \"drop database metastore;\" " postgres
su -c "cd ; /usr/bin/psql --command \"CREATE DATABASE metastore owner=hive;\" " postgres
su -c "cd ; /usr/bin/psql --command \"GRANT ALL privileges ON DATABASE metastore TO hive;\" " postgres
su -c "cd ; /usr/bin/pg_ctl restart -w -m fast -D /var/lib/pgsql/data" postgres
~~~

重启数据库：

```bash
su -c "cd ; /usr/bin/pg_ctl restart -w -m fast -D /var/lib/pgsql/data" postgres
```

初始化数据库，这里使用的是最新的脚本：

```bash
$ ls /usr/lib/hive/scripts/metastore/upgrade/postgres/hive-schema-* |tail -n 1
/usr/lib/hive/scripts/metastore/upgrade/postgres/hive-schema-2.1.1.postgres.sql

$ su -c "cd ; /usr/bin/psql -U hive -d metastore -f `ls /usr/lib/hive/scripts/metastore/upgrade/postgres/hive-schema-* |tail -n 1`" postgres
```

这时候的hive-site.xml文件内容如下：

~~~xml
<configuration>
  <property>
    <name>javax.jdo.option.ConnectionURL</name>
    <value>jdbc:postgresql://cdh1/hive</value>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionDriverName</name>
    <value>org.postgresql.Driver</value>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionUserName</name>
    <value>hive</value>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionPassword</name>
    <value>hive</value>
  </property>
  <property>
    <name>datanucleus.autoCreateSchema</name>
    <value>false</value>
  </property>
  <property>
    <name>mapreduce.framework.name</name>
    <value>yarn</value>
  </property>
  <property>
    <name>yarn.resourcemanager.resource-tracker.address</name>
    <value>cdh1:8031</value>
  </property>

  <property>
    <name>hive.auto.convert.join</name>
    <value>true</value>
  </property>
  <property>
    <name>hive.metastore.schema.verification</name>
    <value>true</value>
  </property>
  <property>
    <name>hive.metastore.warehouse.dir</name>
    <value>/user/hive/warehouse</value>
  </property>
  <property>
    <name>hive.warehouse.subdir.inherit.perms</name>
    <value>true</value>
  </property>
  <property>
    <name>hive.metastore.uris</name>
    <value>thrift://cdh1:9083</value>
  </property>
  <property>
    <name>hive.support.concurrency</name>
    <value>true</value>
  </property>
  <property>
    <name>hive.zookeeper.quorum</name>
    <value>cdh1,cdh2,cdh3</value>
  </property>
</configuration>
~~~

默认情况下，hive-server和 hive-server2 的 thrift 端口都为10000，如果要修改 hive-server2 thrift 端口，请修改 `hive.server2.thrift.port` 参数的值。

如果要设置运行 hive 的用户为连接的用户而不是启动用户，则添加：

~~~xml
<property>
  <name>hive.server2.enable.impersonation</name>
  <value>true</value>
</property>
~~~

并在 core-site.xml 中添加：

~~~xml
<property>
  <name>hadoop.proxyuser.hive.hosts</name>
  <value>*</value>
</property>
<property>
  <name>hadoop.proxyuser.hive.groups</name>
  <value>*</value>
</property>
~~~

## 安装mysql

yum方式安装mysql以及jdbc驱动：

~~~bash
yum install mysql mysql-devel mysql-server mysql-libs -y

yum install mysql-connector-java
ln -s /usr/share/java/mysql-connector-java.jar /usr/lib/hive/lib/mysql-connector-java.jar
~~~

创建数据库和用户，并设置密码为hive：

~~~bash
mysql -e "
	CREATE DATABASE hive;
	USE hive;
	CREATE USER 'hive'@'cdh1' IDENTIFIED BY 'hive';
	GRANT ALL PRIVILEGES ON metastore.* TO 'hive'@'cdh1';
	FLUSH PRIVILEGES;
"
~~~

如果是第一次安装，则初始化 hive 的元数据库：

~~~bash
/usr/lib/hive/bin/schematool --dbType mysql --initSchema
~~~

如果是更新，则执行：

~~~bash
/usr/lib/hive/bin/schematool --dbType mysql --upgradeSchema
~~~

配置开启启动并启动数据库：

~~~bash
chkconfig mysqld on
service mysqld start
~~~

修改 hive-site.xml 文件中以下内容：

~~~xml
<property>
  <name>javax.jdo.option.ConnectionURL</name>
  <value>jdbc:mysql://cdh1:3306/metastore?useUnicode=true&amp;characterEncoding=UTF-8</value>
</property>
<property>
  <name>javax.jdo.option.ConnectionDriverName</name>
  <value>com.mysql.jdbc.Driver</value>
</property>
<property>
  <name>javax.jdo.option.ConnectionUserName</name>
  <value>hive</value>
</property>
<property>
  <name>javax.jdo.option.ConnectionPassword</name>
  <value>hive</value>
</property>
~~~

## 配置hive

修改`/etc/hadoop/conf/hadoop-env.sh`，添加环境变量 `HADOOP_MAPRED_HOME`，如果不添加，则当你使用 yarn 运行 mapreduce 时候会出现 `UNKOWN RPC TYPE` 的异常

~~~bash
export HADOOP_MAPRED_HOME=/usr/lib/hadoop-mapreduce
~~~

在 hdfs 中创建 hive 数据仓库目录:

- hive 的数据仓库在 hdfs 中默认为 `/user/hive/warehouse`,建议修改其访问权限为 `1777`，以便其他所有用户都可以创建、访问表，但不能删除不属于他的表。
- 每一个查询 hive 的用户都必须有一个 hdfs 的 home 目录( `/user` 目录下，如 root 用户的为 `/user/root`)
- hive 所在节点的 `/tmp` 必须是 world-writable 权限的。

创建目录并设置权限：

~~~bash
sudo -u hdfs hadoop fs -mkdir /user/hive
sudo -u hdfs hadoop fs -chown hive /user/hive

sudo -u hdfs hadoop fs -mkdir /user/hive/warehouse
sudo -u hdfs hadoop fs -chmod 1777 /user/hive/warehouse
sudo -u hdfs hadoop fs -chown hive /user/hive/warehouse
~~~

启动hive-server和metastore:

~~~bash
service hive-metastore start
service hive-server start
service hive-server2 start
~~~

## 测试

~~~bash
hive -e 'create table t(id int);'
hive -e 'select * from t limit 2;'
hive -e 'select id from t;'
~~~

访问beeline:

~~~bash
beeline
beeline> !connect jdbc:hive2://cdh1:10000 hive hive org.apache.hive.jdbc.HiveDriver
Connecting to jdbc:hive2://cdh1:10000
Connected to: Apache Hive (version 2.1.1-cdh6.2.0)
Driver: Hive JDBC (version 2.1.1-cdh6.2.0)
Transaction isolation: TRANSACTION_REPEATABLE_READ
~~~

注意：core-site.xml中需要加以下配置：

```xml
<property>
  <name>hadoop.proxyuser.hive.hosts</name>
  <value>*</value>
</property>
<property>
  <name>hadoop.proxyuser.hive.groups</name>
  <value>*</value>
</property>
```

## 与hbase集成

先安装 hive-hbase:

~~~bash
yum install hive-hbase -y
~~~

如果你是使用的 cdh4，则需要在 hive shell 里执行以下命令添加 jar：

~~~bash
ADD JAR /usr/lib/hive/lib/zookeeper.jar;
ADD JAR /usr/lib/hive/lib/hbase.jar;
ADD JAR /usr/lib/hive/lib/hive-hbase-handler-<hive_version>.jar
# guava 包的版本以实际版本为准。
ADD JAR /usr/lib/hive/lib/guava-11.0.2.jar;
~~~

如果你是使用的 cdh5，则需要在 hive shell 里执行以下命令添加 jar：

~~~
ADD JAR /usr/lib/hive/lib/zookeeper.jar;
ADD JAR /usr/lib/hive/lib/hive-hbase-handler.jar;
ADD JAR /usr/lib/hbase/lib/guava-12.0.1.jar;
ADD JAR /usr/lib/hbase/hbase-client.jar;
ADD JAR /usr/lib/hbase/hbase-common.jar;
ADD JAR /usr/lib/hbase/hbase-hadoop-compat.jar;
ADD JAR /usr/lib/hbase/hbase-hadoop2-compat.jar;
ADD JAR /usr/lib/hbase/hbase-protocol.jar;
ADD JAR /usr/lib/hbase/hbase-server.jar;
~~~

以上你也可以在 hive-site.xml 中通过 `hive.aux.jars.path` 参数来配置，或者你也可以在 hive-env.sh 中通过 `export HIVE_AUX_JARS_PATH=` 来设置。

# 7. 遇到的问题

## 安装hadoop过程中需要注意以下几点：

- 1. 每个节点配置hosts
- 2. 每个节点配置时钟同步
- 3. 如果没有特殊要求，关闭防火墙
- 4. hadoop需要在`/tmp`目录下存放一些日志和临时文件，要求`/tmp`目录权限必须为`1777`

## 使用intel的hadoop发行版IDH过程遇到问题：

1、 IDH集群中需要配置管理节点到集群各节点的无密码登录，公钥文件存放路径为`/etc/intelcloud`目录下，文件名称为`idh-id_rsa`。

如果在管理界面发现不能启动/停止hadoop组件的进程，请检查ssh无密码登录是否有问题。

    ssh -i /etc/intelcloud/idh-id_rsa nodeX

如果存在问题，请重新配置无密码登录：

    scp -i /etc/intelcloud/idh-id_rsa nodeX

2、 IDH使用puppt和shell脚本来管理hadoop集群，shell脚本中有一处调用puppt的地方存在问题，详细说明待整理！！

### 使用CDH4.3.0的hadoop（通过rpm安装）过程中发现如下问题：

>说明：以下问题不局限于CDH的hadoop版本。

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

# 8. 参考文章

* [1] [CDH5-Installation-Guide](http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH5/latest/CDH5-Installation-Guide/CDH5-Installation-Guide.html)
* [2] [hadoop cdh 安装笔记](http://roserouge.iteye.com/blog/1558498)
* [3] [017-Centos7.6+CDH 6.2 安装和使用](https://www.codercto.com/a/75971.html)
* [4] [Yarn（二） 详解](https://blog.csdn.net/android_bar/article/details/80494215)

---
layout: post

title:  手动安装Hadoop集群的过程

description: 最近又安装 Hadoop 集群，由于一些原因没有使用 Hadoop 管理工具或者自动化安装脚本来安装集群，而是手动一步步的来安装，本篇文章主要是记录我手动安装 Hadoop 集群的过程，给大家做个参考。

keywords:  

category: hadoop

tags: [hadoop]

published: true

---

最近又安装 Hadoop 集群，由于一些原因，没有使用 Hadoop 管理工具或者自动化安装脚本来安装集群，而是手动一步步的来安装，本篇文章主要是记录我手动安装 Hadoop 集群的过程，给大家做个参考。

这里所说的手动安装，是指一步步的通过脚本来安装集群，并不是使用一键安装脚本或者一些管理界面来安装。

开始之前，还是说明一下环境：

- 操作系统：CentOs6.4
- CDH版本：4.7.0
- 节点数：4个

在开始之前，你可以看看我以前写的一篇文章 [使用yum安装CDH Hadoop集群](/2013/04/06/install-cloudera-cdh-by-yum.html)，因为有些细节已经为什么这样做我不会在这篇文章中讲述。

## 一些准备工作

在开始前，先选择一个节点为管理节点或者说是 NameNode 节点，其他节点为普通节点。

安装的过程中，是使用 root 用户来运行脚本。

为了部署方便，我会创建三个批量执行脚本，存放目录为/opt，一个脚本用于批量执行，文件名称为 cmd.sh，内容如下：

~~~bash
for node in 1 2 3;do
	echo "========$node========"
	ssh 192.168.56.12$node $1
done
~~~

另外一个文件用于批量拷贝，文件名称为 syn.sh，内容如下：

~~~bash
for node in 1 2 3;do
	echo "========$node========"
	scp -r $1 192.168.56.12$node:$2
done
~~~

第三个文件用于批量管理 hadoop 服务，文件名称为 cluster.sh，内容如下：

~~~bash
for node in 1 2 3;do
	ssh 192.168.56.12$node 'for src in `ls /etc/init.d|grep '$1'`;do service $src '$2'; done'
done
~~~

当然，以上三个脚本需要你从当前管理节点配置无密码登陆到所有节点上。

配置无密码登陆之后，需要在每台机器上安装 jdk 并设置环境变量：

~~~bash
$ sh /opt/cmd.sh '
$ yum remove jdk* -y
$ yum install jdk -y
$ rm -rf /usr/bin/java
$ ln -s /usr/java/default/bin/java /usr/bin/java
$ echo "export JAVA_HOME=/usr/java/default" >>/root/.bashrc
$ echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> /root/.bashrc
$ source /root/.bashrc
'
~~~

## 配置 hosts 文件

在该节点上配置 hosts 文件，我安装的集群节点如下：

~~~
192.168.56.121 cdh1
192.168.56.122 cdh2
192.168.56.123 cdh3
~~~

将该文件同步到其他节点：

~~~bash
$ sh /opt/syn.sh /etc/hosts  /etc/hosts
~~~

## 安装 hadoop-hdfs

首先，在所有节点上安装一些基本的必须的依赖：

~~~bash
$ sh /opt/cmd.sh 'yum install hadoop hadoop-hdfs yarn hadoop-mapreduce hive hbase zookeeper hbase'
~~~

以上只是安装一些基本依赖，并不会在/etc/init.d/下生成一些服务，而会在/etc/目录下创建一些 conf 目录，这样方便修改配置文件并执行批量同步。

然后，按照你的集群规划，在每个节点上仅仅安装其需要的服务，例如在 cdh1上安装 NameNode，而在其他节点上安装 DataNode。

接下来在管理节点上修改配置文件（可以参考 <https://github.com/javachen/snippets/tree/master/hadoop-install/template/hadoop>），然后做同步：

~~~bash
$ sh /opt/syn.sh /etc/hadoop/conf  /etc/hadoop/
~~~

创建本地目录。NameNode 的数据目录，我定义在/data/dfs/nn；DataNode 的在/data/dfs/dn，当然还有 yarn 的目录。

批量创建目录命令：

~~~bash
$ sh /opt/cmd.sh '
$ mkdir -p /data/dfs/nn /data/dfs/dn  /data/yarn/local   /var/log/hadoop-yarn;
$ chown -R hdfs:hdfs /data/dfs;
$ chown -R yarn:yarn /data/yarn/local;
$ chown -R yarn:yarn /var/log/hadoop-yarn;
$ mkdir -p /var/run/hadoop-hdfs
'
~~~

最后，就是格式化 NameNode：

~~~bash
$ sudo -u hdfs hadoop namenode -format
~~~

启动 hadoop-hdfs 相关的服务：

~~~bash
$ sh /opt/cluster.sh hadoop-hdfs start
~~~

查看状态：

~~~bash
$ sh /opt/cluster.sh hadoop-hdfs status
~~~

在无法直接服务 web 界面的情况下，可以通过下面命令来检查每个节点是否启动成功：

~~~bash
$ sudo -u hdfs hadoop dfsadmin -report
~~~

创建 /tmp 临时目录，并设置权限为 1777：

~~~bash
$ sudo -u hdfs hadoop fs -mkdir /tmp
$ sudo -u hdfs hadoop fs -chmod -R 1777 /tmp
~~~

## 安装 yarn

在 NN 节点上安装 hadoop-yarn-resourcemanager 和 hadoop-mapredice-history，其他节点安装 hadoop-yarn-nodemanager，修改配置文件。

在 hdfs 上创建目录：

~~~bash
$ sudo -u hdfs hadoop fs -mkdir -p /yarn/apps
$ sudo -u hdfs hadoop fs -chown yarn:mapred /yarn/apps
$ sudo -u hdfs hadoop fs -chmod -R 1777 /yarn/apps
$ sudo -u hdfs hadoop fs -mkdir -p /user/history
$ sudo -u hdfs hadoop fs -chmod -R 1777 /user/history
$ sudo -u hdfs hadoop fs -chown mapred:hadoop /user/history
~~~

验证 HDFS 结构：

~~~bash
$ sudo -u hdfs hadoop fs -ls -R /
~~~

你将会看到：

~~~
drwxrwxrwt   - hdfs hadoop          0 2014-07-16 11:02 /tmp
drwxr-xr-x   - hdfs hadoop          0 2014-07-16 11:20 /user
drwxrwxrwt   - mapred hadoop          0 2014-07-16 11:20 /user/history
drwxr-xr-x   - hdfs   hadoop          0 2014-07-16 11:20 /yarn
drwxr-xr-x   - yarn   mapred          0 2014-07-16 11:20 /yarn/apps
~~~

为每个 MapReduce 用户创建主目录，比如说 hive 用户或者当前用户：

~~~bash
$ sudo -u hdfs hadoop fs -mkdir /user/$USER
$ sudo -u hdfs hadoop fs -chown $USER /user/$USER
~~~

启动 mapred-historyserver :

~~~bash
$ etc/init.d/hadoop-mapreduce-historyserver start
~~~

每个节点启动 YARN :

~~~bash
$ sh /opt/cluster.sh hadoop-yarn start
~~~

检查yarn是否启动成功：

~~~bash
$ sh /opt/cluster.sh hadoop-yarn status
~~~

## 其他

其他服务均可以参考此方法来简化安装，这里不做详述。


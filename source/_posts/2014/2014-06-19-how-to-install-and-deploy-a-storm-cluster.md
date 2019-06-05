---
layout: post

title:  Storm集群安装部署步骤

description:  开始学习Storm，本文主要记录Storm集群安装部署步骤，不包括对Storm的介绍。

keywords:  Storm集群安装部署步骤

category: devops

tags: [storm]

published: true

---

开始学习Storm，本文主要记录Storm集群安装部署步骤，不包括对Storm的介绍。

安装storm集群，需要依赖以下组件：

- Zookeeper
- Python
- Zeromq
- Storm
- JDK
- JZMQ

故安装过程根据上面的组件分为以下几步：

- 安装JDK
- 安装Zookeeper集群
- 安装Python及依赖
- 安装Storm

另外，操作系统环境为：Centos6.4，安装用户为：root。


# 1. 安装JDK

安装jdk有很多方法，可以参考文博客[使用yum安装CDH Hadoop集群](/2013/04/06/install-cloudera-cdh-by-yum.html)中的jdk安装步骤，需要说明的是下面的zookeeper集群安装方法也可以参考此文。

不管你用什么方法，最后需要配置JAVA_HOME并检测当前jdk版本：

~~~bash
$ java -version
java version "1.6.0_31"
Java(TM) SE Runtime Environment (build 1.6.0_31-b04)
Java HotSpot(TM) 64-Bit Server VM (build 20.6-b01, mixed mode)
~~~

# 2. 安装Zookeeper集群

可以参考文博客[使用yum安装CDH Hadoop集群](/2013/04/06/install-cloudera-cdh-by-yum.html)中的Zookeeper集群安装步骤。

# 3. 安装Python及依赖

一般操作系统上都安装了Python，查看当前Python版本：

~~~bash
$ python -V
Python 2.6.6
~~~

## 3.1 下载Zeromq

~~~bash
$ wget http://download.zeromq.org/zeromq-4.0.4.tar.gz
$ tar zxvf zeromq-4.0.4.tar.gz
$ ./configure
$ make & make install
~~~

## 3.2 安装Jzmq

~~~bash
$ git clone git://github.com/nathanmarz/jzmq.git
$ cd jzmq
$ ./autogen.sh
$ ./configure
$ make & make install
~~~

# 4. 安装Storm

下载稳定版本的storm，然后解压将其拷贝到/usr/lib/storm目录：

~~~bash
$ wget https://github.com/downloads/nathanmarz/storm/storm-0.8.1.zip
$ unzip storm-0.8.1.zip 
$ mv storm-0.8.1 /usr/lib/storm
~~~

接下来，配置环境变量：

~~~
export STORM_HOME=/usr/lib/storm
export PATH=$PATH:$STORM_HOME/bin
~~~

建立storm存储目录：

~~~bash
$ mkdir /tmp/storm
~~~

修改配置文件/usr/lib/storm/conf/storm.yaml，修改为如下：

~~~yaml
 storm.zookeeper.servers:
     - "cdh1"
     - "cdh2"
     - "cdh3"
 ui.port: 8081
 nimbus.host: "cdh2"
 storm.local.dir: "/tmp/storm"
 supervisor.slots.ports:
    - 6700
    - 6701
    - 6702
    - 6703
~~~

其中，配置参数说明：

 - `storm.zookeeper.servers`：Storm集群使用的Zookeeper集群地址，如果Zookeeper集群使用的不是默认端口，那么还需要`storm.zookeeper.port`选项
 - `ui.port`：Storm UI的服务端口
 - `storm.local.dir`：Nimbus和Supervisor进程用于存储少量状态，如jars、confs等的本地磁盘目录
 - `java.library.path`: Storm使用的本地库（ZMQ和JZMQ）加载路径，默认为"/usr/local/lib:/opt/local/lib:/usr/lib"，一般来说ZMQ和JZMQ默认安装在`/usr/local/lib`下，因此不需要配置即可。
 - `nimbus.host`: Storm集群Nimbus机器地址
 - `supervisor.slots.ports`: 对于每个Supervisor工作节点，需要配置该工作节点可以运行的worker数量。每个worker占用一个单独的端口用于接收消息，该配置选项即用于定义哪些端口是可被worker使用的。默认情况下，每个节点上可运行4个workers，分别在6700、6701、6702和6703端口

更多配置参数，请参考[Storm配置项详解](http://www.alidata.org/archives/2118)。

最后，启动Storm各个后台进程：

主控节点上启动nimbus：

~~~bash
$ storm nimbus >/dev/null 2>&1 &
~~~

在Storm各个工作节点上运行：

~~~bash
$ storm supervisor >/dev/null 2>&1 &
~~~

在Storm主控节点上启动ui：

~~~bash
$ storm ui >/dev/null 2>&1 &
~~~

然后，你可以访问<http://cdh2:8081/>查看集群的worker资源使用情况、Topologies的运行状态等信息。

---
layout: post

title:  Spark集群安装和使用

description: 本文主要记录 CDH5 集群中 Spark 集群模式的安装过程配置过程并测试 Spark 的一些基本使用方法。

keywords:  

category: spark

tags: [spark,yarn,mesos]

published: true

---

本文主要记录 CDH5 集群中 Spark 集群模式的安装过程配置过程并测试 Spark 的一些基本使用方法。

安装环境如下：

- 操作系统：CentOs 6.5
- Hadoop 版本：`cdh-5.4.0`
- Spark 版本：`cdh5-1.3.0_5.4.0`

关于 yum 源的配置以及 Hadoop 集群的安装，请参考 [使用yum安装CDH Hadoop集群](/2013/04/06/install-cloudera-cdh-by-yum.html)。

# 1. 安装

首先查看 Spark 相关的包有哪些：

~~~bash
$ yum list |grep spark
spark-core.noarch                  1.3.0+cdh5.4.0+24-1.cdh5.4.0.p0.52.el6
spark-history-server.noarch        1.3.0+cdh5.4.0+24-1.cdh5.4.0.p0.52.el6
spark-master.noarch                1.3.0+cdh5.4.0+24-1.cdh5.4.0.p0.52.el6
spark-python.noarch                1.3.0+cdh5.4.0+24-1.cdh5.4.0.p0.52.el6
spark-worker.noarch                1.3.0+cdh5.4.0+24-1.cdh5.4.0.p0.52.el6
hue-spark.x86_64                   3.7.0+cdh5.4.0+1145-1.cdh5.4.0.p0.58.el6
~~~

以上包作用如下：

- `spark-core`: spark 核心功能
- `spark-worker`: spark-worker 初始化脚本
- `spark-master`: spark-master 初始化脚本
- `spark-python`: spark 的 Python 客户端
- `hue-spark`: spark 和 hue 集成包
- `spark-history-server`

在已经存在的 Hadoop 集群中，选择一个节点来安装 Spark Master，其余节点安装 Spark worker ，例如：在 cdh1 上安装 master，在 cdh1、cdh2、cdh3 上安装 worker：

~~~bash
# 在 cdh1 节点上运行
$ sudo yum install spark-core spark-master spark-worker spark-python spark-history-server -y

# 在 cdh1、cdh2、cdh3 上运行
$ sudo yum install spark-core spark-worker spark-python -y
~~~

安装成功后，我的集群各节点部署如下：

~~~
cdh1节点:  spark-master、spark-worker、spark-history-server
cdh2节点:  spark-worker 
cdh3节点:  spark-worker 
~~~

# 2. 配置

## 2.1 修改配置文件

设置环境变量，在 `.bashrc` 或者 `/etc/profile` 中加入下面一行，并使其生效：

~~~properties
export SPARK_HOME=/usr/lib/spark
~~~

可以修改配置文件 `/etc/spark/conf/spark-env.sh`，其内容如下，你可以根据需要做一些修改，例如，修改 master 的主机名称为cdh1。

~~~bash
# 设置 master 主机名称
export STANDALONE_SPARK_MASTER_HOST=cdh1
~~~

设置 shuffle 和 RDD 数据存储路径，该值默认为`/tmp`。使用默认值，可能会出现`No space left on device`的异常，建议修改为空间较大的分区中的一个目录。

~~~bash
export SPARK_LOCAL_DIRS=/data/spark
~~~

如果你和我一样使用的是虚拟机运行 spark，则你可能需要修改 spark 进程使用的 jvm 大小（关于 jvm 大小设置的相关逻辑见 `/usr/lib/spark/bin/spark-class`）：

~~~bash
export SPARK_DAEMON_MEMORY=256m
~~~

更多spark相关的配置参数，请参考 [Spark Configuration](https://spark.apache.org/docs/latest/configuration.html)。

## 2.2 配置 Spark History Server

 在运行Spark应用程序的时候，driver会提供一个webUI给出应用程序的运行信息，但是该webUI随着应用程序的完成而关闭端口，也就是说，Spark应用程序运行完后，将无法查看应用程序的历史记录。Spark history server就是为了应对这种情况而产生的，通过配置，Spark应用程序在运行完应用程序之后，将应用程序的运行信息写入指定目录，而Spark history server可以将这些运行信息装载并以web的方式供用户浏览。

创建 `/etc/spark/conf/spark-defaults.conf`：

~~~bash
cp /etc/spark/conf/spark-defaults.conf.template /etc/spark/conf/spark-defaults.conf
~~~

添加下面配置：

~~~properties
spark.master=spark://cdh1:7077
spark.eventLog.dir=/user/spark/applicationHistory
spark.eventLog.enabled=true
spark.yarn.historyServer.address=cdh1:18082
~~~

如果你是在hdfs上运行Spark，则执行下面命令创建`/user/spark/applicationHistory`目录：

~~~bash
$ sudo -u hdfs hadoop fs -mkdir /user/spark
$ sudo -u hdfs hadoop fs -mkdir /user/spark/applicationHistory
$ sudo -u hdfs hadoop fs -chown -R spark:spark /user/spark
$ sudo -u hdfs hadoop fs -chmod 1777 /user/spark/applicationHistory
~~~

设置 `spark.history.fs.logDirectory` 参数：

~~~bash
export SPARK_HISTORY_OPTS="$SPARK_HISTORY_OPTS -Dspark.history.fs.logDirectory=/tmp/spark -Dspark.history.ui.port=18082"
~~~

创建 /tmp/spark 目录：

~~~bash
$ mkdir -p /tmp/spark
$ chown spark:spark /tmp/spark
~~~

如果集群配置了 kerberos ，则添加下面配置：

~~~bash
HOSTNAME=`hostname -f`
export SPARK_HISTORY_OPTS="$SPARK_HISTORY_OPTS -Dspark.history.kerberos.enabled=true -Dspark.history.kerberos.principal=spark/${HOSTNAME}@LASHOU.COM -Dspark.history.kerberos.keytab=/etc/spark/conf/spark.keytab -Dspark.history.ui.acls.enable=true"
~~~

## 2.3 和Hive集成

Spark和hive集成，最好是将hive的配置文件链接到Spark的配置文件目录：

~~~bash
$ ln -s /etc/hive/conf/hive-site.xml /etc/spark/conf/hive-site.xml
~~~

## 2.4 同步配置文件

修改完 cdh1 节点上的配置文件之后，需要同步到其他节点：

~~~bash
scp -r /etc/spark/conf  cdh2:/etc/spark
scp -r /etc/spark/conf  cdh3:/etc/spark
~~~

# 3. 启动和停止

## 3.1 使用系统服务管理集群

启动脚本：

~~~bash
# 在 cdh1 节点上运行
$ sudo service spark-master start

# 在 cdh1 节点上运行，如果 hadoop 集群配置了 kerberos，则运行之前需要先获取 spark 用户的凭证
# kinit -k -t /etc/spark/conf/spark.keytab spark/cdh1@JAVACHEN.COM
$ sudo service spark-history-server start

# 在cdh2、cdh3 节点上运行
$ sudo service spark-worker start
~~~

停止脚本：

~~~bash
$ sudo service spark-master stop
$ sudo service spark-worker stop
$ sudo service spark-history-server stop
~~~

当然，你还可以设置开机启动：

~~~bash
$ sudo chkconfig spark-master on
$ sudo chkconfig spark-worker on
$ sudo chkconfig spark-history-server on
~~~

## 3.2 使用 Spark 自带脚本管理集群

另外，你也可以使用 Spark 自带的脚本来启动和停止，这些脚本在 `/usr/lib/spark/sbin` 目录下：

~~~bash
$ ls /usr/lib/spark/sbin
slaves.sh        spark-daemons.sh  start-master.sh  stop-all.sh
spark-config.sh  spark-executor    start-slave.sh   stop-master.sh
spark-daemon.sh  start-all.sh      start-slaves.sh  stop-slaves.sh
~~~

在master节点修改 `/etc/spark/conf/slaves` 文件添加worker节点的主机名称，并且还需要在master和worker节点之间配置无密码登陆。

~~~
# A Spark Worker will be started on each of the machines listed below.
cdh2
cdh3
~~~

然后，你也可以通过下面脚本启动 master 和 worker：

~~~bash
$ cd /usr/lib/spark/sbin
$ ./start-master.sh
$ ./start-slaves.sh
~~~

当然，你也可以通过`spark-class`脚本来启动，例如，下面脚本以standalone模式启动worker：

~~~bash
$ ./bin/spark-class org.apache.spark.deploy.worker.Worker spark://cdh1:18080
~~~

## 3.3 访问web界面

你可以通过 <http://cdh1:18080/> 访问 spark master 的 web 界面。

![spark-master-web-ui](http://7xnrdo.com1.z0.glb.clouddn.com/spark/spark-master-web-ui.jpg)

访问Spark History Server页面：http://cdh1:18082/。

![spark-hs-web-ui](http://7xnrdo.com1.z0.glb.clouddn.com/spark/spark-hs-web-ui.jpg)

注意：我这里使用的是CDH版本的 Spark，Spark master UI的端口为`18080`，不是 Apache Spark 的 `8080` 端口。CDH发行版中Spark使用的端口列表如下：

- `7077` – Default Master RPC port
- `7078` – Default Worker RPC port
- `18080` – Default Master web UI port
- `18081` – Default Worker web UI port
- `18080` – Default HistoryServer web UI port

# 4. 测试

Spark可以以[本地模式运行](/2015/03/30/spark-test-in-local-mode.html)，也支持三种集群管理模式：

- [Standalone](https://spark.apache.org/docs/latest/spark-standalone.html)  – Spark原生的资源管理，由Master负责资源的分配。
- [Apache Mesos](https://spark.apache.org/docs/latest/running-on-mesos.html)  – 运行在Mesos之上，由Mesos进行资源调度
- [Hadoop YARN](https://spark.apache.org/docs/latest/running-on-yarn.html) –  运行在Yarn之上，由Yarn进行资源调度。

另外 Spark 的 [EC2 launch scripts](https://spark.apache.org/docs/latest/ec2-scripts.html) 可以帮助你容易地在Amazon EC2上启动standalone cluster.

>- 在集群不是特别大，并且没有 mapReduce 和 Spark 同时运行的需求的情况下，用 Standalone 模式效率最高。
>- Spark可以在应用间（通过集群管理器）和应用中（如果一个 SparkContext 中有多项计算任务）进行资源调度。

## 4.1 Standalone 模式

该模式中，资源调度是Spark框架自己实现的，其节点类型分为Master和Worker节点，其中Driver节点运行在Master节点中，并且有常驻内存的Master进程守护，Worker节点上常驻Worker守护进程，负责与Master通信。

Standalone 模式是Master-Slaves架构的集群模式，Master存在着单点故障问题，目前，Spark提供了两种解决办法：基于文件系统的故障恢复模式，基于Zookeeper的HA方式。

Standalone 模式需要在每一个节点部署Spark应用，并按照实际情况配置故障恢复模式。

你可以使用交互式命令spark-shell、pyspark或者[spark-submit script](https://spark.apache.org/docs/latest/submitting-applications.html)连接到集群，下面以wordcount程序为例：

~~~bash
$ spark-shell --master spark://cdh1:7077
scala> val file = sc.textFile("hdfs://cdh1:8020/tmp/test.txt")
scala> val counts = file.flatMap(line => line.split(" ")).map(word => (word, 1)).reduceByKey(_ + _)
scala> counts.count()
scala> counts.saveAsTextFile("hdfs://cdh1:8020/tmp/output")
~~~

如果运行成功，可以打开浏览器访问 http://cdh1:4040 查看应用运行情况。

运行过程中，可能会出现下面的异常：

~~~
14/10/24 14:51:40 WARN hdfs.BlockReaderLocal: The short-circuit local reads feature cannot be used because libhadoop cannot be loaded.
14/10/24 14:51:40 ERROR lzo.GPLNativeCodeLoader: Could not load native gpl library
java.lang.UnsatisfiedLinkError: no gplcompression in java.library.path
	at java.lang.ClassLoader.loadLibrary(ClassLoader.java:1738)
	at java.lang.Runtime.loadLibrary0(Runtime.java:823)
	at java.lang.System.loadLibrary(System.java:1028)
	at com.hadoop.compression.lzo.GPLNativeCodeLoader.<clinit>(GPLNativeCodeLoader.java:32)
	at com.hadoop.compression.lzo.LzoCodec.<clinit>(LzoCodec.java:71)
	at java.lang.Class.forName0(Native Method)
	at java.lang.Class.forName(Class.java:249)
	at org.apache.hadoop.conf.Configuration.getClassByNameOrNull(Configuration.java:1836)
	at org.apache.hadoop.conf.Configuration.getClassByName(Configuration.java:1801)
	at org.apache.hadoop.io.compress.CompressionCodecFactory.getCodecClasses(CompressionCodecFactory.java:128)
~~~

解决方法可以参考 [Spark连接Hadoop读取HDFS问题小结](http://blog.csdn.net/pelick/article/details/11599391) 这篇文章，执行以下命令，然后重启服务即可：

~~~bash
cp /usr/lib/hadoop/lib/native/libgplcompression.so $JAVA_HOME/jre/lib/amd64/
cp /usr/lib/hadoop/lib/native/libhadoop.so $JAVA_HOME/jre/lib/amd64/
cp /usr/lib/hadoop/lib/native/libsnappy.so $JAVA_HOME/jre/lib/amd64/
~~~

使用 spark-submit 以 Standalone 模式运行 SparkPi 程序的命令如下：

~~~bash
$ spark-submit --class org.apache.spark.examples.SparkPi  --master spark://cdh1:7077 /usr/lib/spark/lib/spark-examples-1.3.0-cdh5.4.0-hadoop2.6.0-cdh5.4.0.jar 10
~~~

**需要说明的是**：`Standalone mode does not support talking to a kerberized HDFS`，如果你以 `spark-shell --master spark://cdh1:7077` 方式访问安装有 kerberos 的 HDFS 集群上访问数据时，会出现下面异常:

~~~
15/04/02 11:58:32 INFO TaskSchedulerImpl: Removed TaskSet 0.0, whose tasks have all completed, from pool
org.apache.spark.SparkException: Job aborted due to stage failure: Task 0 in stage 0.0 failed 4 times, most recent failure: Lost task 0.3 in stage 0.0 (TID 6, bj03-bi-pro-hdpnamenn): java.io.IOException: Failed on local exception: java.io.IOException: org.apache.hadoop.security.AccessControlException: Client cannot authenticate via:[TOKEN, KERBEROS]; Host Details : local host is: "cdh1/192.168.56.121"; destination host is: "192.168.56.121":8020;
        org.apache.hadoop.net.NetUtils.wrapException(NetUtils.java:764)
        org.apache.hadoop.ipc.Client.call(Client.java:1415)
        org.apache.hadoop.ipc.Client.call(Client.java:1364)
        org.apache.hadoop.ipc.ProtobufRpcEngine$Invoker.invoke(ProtobufRpcEngine.java:206)
        com.sun.proxy.$Proxy17.getBlockLocations(Unknown Source)
~~~

## 4.2 Spark On Mesos 模式

参考 <http://dongxicheng.org/framework-on-yarn/apache-spark-comparing-three-deploying-ways/>。

## 4.3 Spark on Yarn 模式

Spark on Yarn 模式同样也支持两种在 Yarn 上启动 Spark 的方式，一种是 cluster 模式，Spark driver 在 Yarn 的 application master 进程中运行，客户端在应用初始化完成之后就会退出；一种是 client 模式，Spark driver 运行在客户端进程中。Spark on Yarn 模式是可以访问配置有 kerberos 的 HDFS 文件的。

CDH Spark中，以 cluster 模式启动，命令如下：

~~~bash
$ spark-submit --class path.to.your.Class --deploy-mode cluster --master yarn [options] <app jar> [app options]
~~~

CDH Spark中，以 client 模式启动，命令如下：

~~~bash
$ spark-submit --class path.to.your.Class --deploy-mode client --master yarn [options] <app jar> [app options]
~~~

以SparkPi程序为例：

~~~bash
$ spark-submit --class org.apache.spark.examples.SparkPi \
    --deploy-mode cluster  \
    --master yarn  \
    --num-executors 3 \
    --driver-memory 4g \
    --executor-memory 2g \
    --executor-cores 1 \
    --queue thequeue \
    /usr/lib/spark/lib/spark-examples-1.3.0-cdh5.4.0-hadoop2.6.0-cdh5.4.0.jar \
    10
~~~

另外，运行在 YARN 集群之上的时候，可以手动把 spark-assembly 相关的 jar 包拷贝到 hdfs 上去，然后设置 `SPARK_JAR` 环境变量：

~~~bash
$ hdfs dfs -mkdir -p /user/spark/share/lib
$ hdfs dfs -put $SPARK_HOME/lib/spark-assembly.jar  /user/spark/share/lib/spark-assembly.jar

$ SPARK_JAR=hdfs://<nn>:<port>/user/spark/share/lib/spark-assembly.jar
~~~

# 5. Spark-SQL

Spark 安装包中包括了 Spark-SQL ，运行 spark-sql 命令，在 cdh5.2 中会出现下面异常：

~~~bash
$ cd /usr/lib/spark/bin
$ ./spark-sql
java.lang.ClassNotFoundException: org.apache.spark.sql.hive.thriftserver.SparkSQLCLIDriver
	at java.net.URLClassLoader$1.run(URLClassLoader.java:202)
	at java.security.AccessController.doPrivileged(Native Method)
	at java.net.URLClassLoader.findClass(URLClassLoader.java:190)
	at java.lang.ClassLoader.loadClass(ClassLoader.java:306)
	at java.lang.ClassLoader.loadClass(ClassLoader.java:247)
	at java.lang.Class.forName0(Native Method)
	at java.lang.Class.forName(Class.java:247)
	at org.apache.spark.deploy.SparkSubmit$.launch(SparkSubmit.scala:319)
	at org.apache.spark.deploy.SparkSubmit$.main(SparkSubmit.scala:75)
	at org.apache.spark.deploy.SparkSubmit.main(SparkSubmit.scala)

Failed to load Spark SQL CLI main class org.apache.spark.sql.hive.thriftserver.SparkSQLCLIDriver.
You need to build Spark with -Phive.
~~~

在 cdh5.4 中会出现下面异常：

~~~
Caused by: java.lang.ClassNotFoundException: org.apache.hadoop.hive.cli.CliDriver
  at java.net.URLClassLoader$1.run(URLClassLoader.java:366)
  at java.net.URLClassLoader$1.run(URLClassLoader.java:355)
  at java.security.AccessController.doPrivileged(Native Method)
  at java.net.URLClassLoader.findClass(URLClassLoader.java:354)
  at java.lang.ClassLoader.loadClass(ClassLoader.java:425)
  at sun.misc.Launcher$AppClassLoader.loadClass(Launcher.java:308)
  at java.lang.ClassLoader.loadClass(ClassLoader.java:358)
  ... 18 more
~~~
  
从上可以知道  Spark-SQL 编译时没有集成 Hive，故需要重新编译 spark 源代码。

## 编译 Spark-SQL

以下内容参考 [编译Spark源代码](/2015/04/28/compile-cdh-spark-source-code.html)。

下载cdh5-1.3.0_5.4.0分支的代码：

~~~bash
$ git clone git@github.com:cloudera/spark.git
$ cd spark
$ git checkout -b origin/cdh5-1.3.0_5.4.0
~~~

使用maven 编译，先修改根目录下的 pom.xml，添加一行 `<module>sql/hive-thriftserver</module>`：

~~~xml
<modules>
    <module>core</module>
    <module>bagel</module>
    <module>graphx</module>
    <module>mllib</module>
    <module>tools</module>
    <module>streaming</module>
    <module>sql/catalyst</module>
    <module>sql/core</module>
    <module>sql/hive</module>
    <module>sql/hive-thriftserver</module> <!--添加的一行-->
    <module>repl</module>
    <module>assembly</module>
    <module>external/twitter</module>
    <module>external/kafka</module>
    <module>external/flume</module>
    <module>external/flume-sink</module>
    <module>external/zeromq</module>
    <module>external/mqtt</module>
    <module>examples</module>
  </modules>
~~~

然后运行：

~~~bash
$ export MAVEN_OPTS="-Xmx2g -XX:MaxPermSize=512M -XX:ReservedCodeCacheSize=512m"
$ mvn -Pyarn -Dhadoop.version=2.6.0-cdh5.4.0 -Phive -Phive-thriftserver -DskipTests clean package
~~~

如果编译成功之后， 会在 assembly/target/scala-2.10 目录下生成：spark-assembly-1.3.0-cdh5.4.0.jar，在 examples/target/scala-2.10 目录下生成：spark-examples-1.3.0-cdh5.4.0.jar，然后将 spark-assembly-1.3.0-cdh5.4.0.jar 拷贝到 /usr/lib/spark/lib 目录，然后再来运行 spark-sql。

但是，经测试 cdh5.4.0 版本中的 spark 的 sql/hive-thriftserver 模块存在编译错误，最后无法编译成功，故需要等到 cloudera 官方更新源代码或者等待下一个 cdh 版本集成 spark-sql。

虽然 spark-sql 命令用不了，但是我们可以在 spark-shell 中使用 SQLContext 来运行 sql 语句，限于篇幅，这里不做介绍，你可以参考 <http://www.infoobjects.com/spark-sql-schemardd-programmatically-specifying-schema/>。

# 6. 总结

本文主要介绍了 CDH5 集群中 Spark 的安装过程以及三种集群运行模式：

- Standalone – `spark-shell --master spark://host:port` 
- Apache Mesos – `spark-shell --master mesos://host:port`
- Hadoop YARN – `spark-shell --master yarn`

如果以本地模式运行，则为 `spark-shell --master local`。

关于 Spark 的更多介绍可以参考官网或者一些[中文翻译的文章](http://colobu.com/tags/Spark/)。

# 7. 参考文章

- [Spark Standalone Mode](https://spark.apache.org/docs/latest/spark-standalone.html)
- [Spark连接Hadoop读取HDFS问题小结](http://blog.csdn.net/pelick/article/details/11599391) 
- [Apache Spark探秘：三种分布式部署方式比较](http://dongxicheng.org/framework-on-yarn/apache-spark-comparing-three-deploying-ways/)

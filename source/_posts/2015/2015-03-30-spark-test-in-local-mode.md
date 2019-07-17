---
layout: post

title: Spark本地模式运行

category:  spark

tags: [ spark,scala ]

description: Spark的安装分为几种模式，其中一种是本地运行模式，只需要在单节点上解压即可运行，这种模式不需要依赖Hadoop 环境。在本地运行模式中，master和worker都运行在一个jvm进程中，通过该模式，可以快速的测试Spark的功能。

published: true

---

Spark的安装分为几种模式，其中一种是本地运行模式，只需要在单节点上解压即可运行，这种模式不需要依赖Hadoop 环境。在本地运行模式中，master和worker都运行在一个jvm进程中，通过该模式，可以快速的测试Spark的功能。

# 下载 Spark

下载地址为<http:/.apache.org/downloads.html>，根据页面提示选择一个合适的版本下载，这里我下载的是 [spark-1.3.0-bin-cdh4.tgz](http://mirror.bit.edu.cn/apache-1.3.0-1.3.0-bin-cdh4.tgz)。下载之后解压：

~~~bash
 cd ~
 wget http://mirror.bit.edu.cn/apache-1.3.0-1.3.0-bin-cdh4.tgz
 tar -xf spark-1.3.0-bin-cdh4.tgz
 cd spark-1.3.0-bin-cdh4
~~~

下载之后的目录为：

~~~
⇒  tree -L 1
.
├── CHANGES.txt
├── LICENSE
├── NOTICE
├── README.md
├── RELEASE
├── bin
├── conf
├── data
├── ec2
├── examples
├── lib
├── python
└── sbin
~~~

# 运行 spark-shell

本地模式运行spark-shell非常简单，只要运行以下命令即可，假设当前目录是$SPARK_HOME

~~~bash
$ MASTER=local 
$ bin-shell
~~~

`MASTER=local`就是表明当前运行在单机模式。如果一切顺利，将看到下面的提示信息：

~~~
Created spark context..
Spark context available as sc.
~~~

这表明spark-shell中已经内置了Spark context的变量，名称为sc，我们可以直接使用该变量进行后续的操作。

spark-shell 后面设置 master 参数，可以支持更多的模式，请参考 <http:/.apache.org/docs/latest/submitting-applications.html#master-urls>。

我们在sparkshell中运行一下最简单的例子，统计在README.md中含有Spark的行数有多少，在spark-shell中输入如下代码：

~~~bash
scala>sc.textFile("README.md").filter(_.contains("Spark")).count
~~~

如果你觉得输出的日志太多，你可以从模板文件创建  conf/log4j.properties ：

~~~bash
$ mv conf/log4j.properties.template conf/log4j.properties
~~~

然后修改日志输出级别为`WARN`：

~~~
log4j.rootCategory=WARN, console
~~~

如果你设置的 log4j 日志等级为 INFO，则你可以看到这样的一行日志 `INFO SparkUI: Started SparkUI at http://10.9.4.165:4040`，意思是 Spark 启动了一个 web 服务器，你可以通过浏览器访问<http://10.9.4.165:4040>来查看 Spark 的任务运行状态等信息。

# pyspark

运行 bin/pyspark 的输出为：

~~~
$ bin/pyspark
Python 2.7.6 (default, Sep  9 2014, 15:04:36)
[GCC 4.2.1 Compatible Apple LLVM 6.0 (clang-600.0.39)] on darwin
Type "help", "copyright", "credits" or "license" for more information.
Spark assembly has been built with Hive, including Datanucleus jars on classpath
Picked up JAVA_TOOL_OPTIONS: -Dfile.encoding=UTF-8
15/03/30 15:19:07 WARN Utils: Your hostname, june-mac resolves to a loopback address: 127.0.0.1; using 10.9.4.165 instead (on interface utun0)
15/03/30 15:19:07 WARN Utils: Set SPARK_LOCAL_IP if you need to bind to another address
15/03/30 15:19:07 WARN NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
Welcome to
      ____              __
     / __/__  ___ _____/ /__
    _\ \/ _ \/ _ / __/  _/
   /__ / .__/\_,_/_/ /_/\_\   version 1.3.0
      /_/

Using Python version 2.7.6 (default, Sep  9 2014 15:04:36)
SparkContext available as sc, HiveContext available as sqlCtx.
~~~

你也可以使用 IPython 来运行 Spark：

~~~
IPYTHON=1  ./bin/pyspark
~~~

如果要使用 IPython NoteBook，则运行：

~~~
IPYTHON_OPTS="notebook"  ./bin/pyspark
~~~

从日志可以看到，不管是 bin/pyspark 还是 bin-shell，他们都有两个内置的变量：sc 和 sqlCtx。

~~~scala
SparkContext available as sc, HiveContext available as sqlCtx
~~~

sc 代表着 Spark 的上下文，通过该变量可以执行 Spark 的一些操作，而 sqlCtx 代表着 HiveContext 的上下文。

# spark-submit

在Spark1.0之后提供了一个统一的脚本spark-submit来提交任务。

对于 python 程序，我们可以直接使用 spark-submit：

~~~bash
$ mkdir -p /usr/lib/examples/python
$ tar zxvf /usr/lib/lib/python.tar.gz -C /usr/lib/examples/python

$ ./bin-submit examples/python/pi.py 10
~~~

对于 Java 程序，我们需要先编译代码然后打包运行：

~~~bash
$ spark-submit --class "SimpleApp" --master local[4] simple-project-1.0.jar
~~~


# 测试 RDD

在 Spark 中，我们操作的集合被称为 RDD，他们被并行拷贝到集群各个节点上。我们可以通过 sc 来创建 RDD 。

创建 RDD 有两种方式：

- `sc.parallelize()`
- `sc.textFile()`

使用 Scala 对 RDD 的一些操作：

~~~scala
val rdd1=sc.parallelize(List(1,2,3,3))
val rdd2=sc.parallelize(List(3,4,5))

//转换操作
rdd1.map(2*).collect //等同于：rdd1.map(t=>2*t).collect
//Array[Int] = Array(2, 4, 6, 6)

rdd1.filter(_>2).collect
//Array[Int] = Array(3, 3)

rdd1.flatMap(_ to 4).collect
//Array[Int] = Array(1, 2, 3, 4, 2, 3, 4, 3, 4, 3, 4)

rdd1.sample(false, 0.3, 4).collect
//Array[Int] = Array(3, 3)

rdd1.sample(true, 0.3, 4).collect
//Array[Int] = Array(3)

rdd1.union(rdd2).collect
//Array[Int] = Array(1, 2, 3, 3, 3, 4, 5)

rdd1.distinct().collect
//Array[Int] = Array(1, 2, 3)

rdd1.map(i=>(i,i)).groupByKey.collect
//Array[(Int, Iterable[Int])] = Array((1,CompactBuffer(1)), (2,CompactBuffer(2)), (3,CompactBuffer(3, 3)))

rdd1.map(i=>(i,i)).reduceByKey(_ + _).collect
//Array[(Int, Int)] = Array((1,1), (2,2), (3,6))

rdd1.map(i=>(i,i)).sortByKey(false).collect
//Array[(Int, Int)] = Array((3,3), (3,3), (2,2), (1,1))

rdd1.map(i=>(i,i)).join(rdd2.map(i=>(i,i))).collect
//Array[(Int, (Int, Int))] = Array((3,(3,3)), (3,(3,3)))

rdd1.map(i=>(i,i)).cogroup(rdd2.map(i=>(i,i))).collect
//Array[(Int, (Iterable[Int], Iterable[Int]))] = Array((4,(CompactBuffer(),CompactBuffer(4))), (1,(CompactBuffer(1),CompactBuffer())), (5,(CompactBuffer(),CompactBuffer(5))), (2,(CompactBuffer(2),CompactBuffer())), (3,(CompactBuffer(3, 3),CompactBuffer(3))))

rdd1.cartesian(rdd2).collect()
//Array[(Int, Int)] = Array((1,3), (1,4), (1,5), (2,3), (2,4), (2,5), (3,3), (3,4), (3,5), (3,3), (3,4), (3,5))

rdd1.pipe("head -n 1").collect
//Array[String] = Array(1, 2, 3, 3)

//动作操作
rdd1.reduce(_ + _)
//Int = 9

rdd1.collect
//Array[Int] = Array(1, 2, 3, 3)

rdd1.first()
//Int = 1

rdd1.take(2)
//Array[Int] = Array(1, 2)

rdd1.top(2)
//Array[Int] = Array(3, 3)

rdd1.takeOrdered(2)
//Array[Int] = Array(1, 2)

rdd1.map(i=>(i,i)).countByKey()
//scala.collection.Map[Int,Long] = Map(1 -> 1, 2 -> 1, 3 -> 2)

rdd1.countByValue()
//scala.collection.Map[Int,Long] = Map(1 -> 1, 2 -> 1, 3 -> 2)

rdd1.intersection(rdd2).collect()
//Array[Int] = Array(3)

rdd1.subtract(rdd2).collect()
//Array[Int] = Array(1, 2)

rdd1.foreach(println)
//3
//2
//3
//1

rdd1.foreachPartition(x => println(x.reduce(_ + _)))
~~~

更多例子，参考<http://homepage.cs.latrobe.edu.au/zhe/ZhenHeSparkRDDAPIExamples.html>。


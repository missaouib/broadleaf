---
layout: post

title: Spark编程指南笔记

category: spark

tags: [ spark ]

description: 本文是参考Spark官方编程指南（Spark 版本为1.2）整理出来的学习笔记，主要是用于加深对 Spark 的理解，并记录一些知识点。

published: true

---

本文是参考Spark官方编程指南（Spark 版本为1.2）整理出来的学习笔记，主要是用于加深对 Spark 的理解，并记录一些知识点。

# 1. Spark介绍

Spark是UC Berkeley AMP lab所开源的类Hadoop MapReduce 框架，都是基于map reduce算法所实现的分布式计算框架，拥有Hadoop MapReduce所具有的优点；不同于MapReduce的是Job中间输出和结果可以保存在内存中，而不需要读写HDFS，因此Spark能更好地适用于machine learning等需要迭代的map reduce算法。

## 产生原因

 1、 MapReduce具有很多局限性：

 -  仅支持Map和Reduce两种操作
 -  迭代效率低
 -  不适合交互式处理
 -  不擅长流式处理
 
 2、 现有的计算框架各自为战

 -  批处理计算：MapReduce、Hive
 -  流式计算：Storm
 -  交互式计算：Impala ​

## 设计目标

在一个统一的框架下能够进行批处理、流式计算和交互式计算。

# 2. 一些概念

每一个 Spark 的应用，都是由一个驱动程序构成，它运行用户的 main 函数，在一个集群上执行各种各样的并行操作。

Spark 提出的最主要抽象概念是`弹性分布式数据集`，它是一个有容错机制（划分到集群的各个节点上）并可以被并行操作的元素集合。

- 分布在集群中的对象集合
- 存储在磁盘或者内存中
- 通过并行“转换”操作构造
- 失效后自动重构

目前有两种类型的RDD：

- `并行集合`：接收一个已经存在的 Scala 集合，然后进行各种并行计算。
- `外部数据集`：外部存储系统，例如一个共享的文件系统，HDFS、HBase以及任何支持 Hadoop InputFormat 的数据源。

这两种类型的 RDD 都可以通过相同的方式进行操作。用户可以让 Spark 保留一个 RDD 在内存中，使其能在并行操作中被有效的重复使用，并且，RDD 能自动从节点故障中恢复。

Spark 的第二个抽象概念是`共享变量`，可以在并行操作中使用。在默认情况下，Spark 通过不同节点上的一系列任务来运行一个函数，它将每一个函数中用到的变量的拷贝传递到每一个任务中。有时候，一个变量需要在任务之间，或任务与驱动程序之间被共享。

Spark 支持两种类型的共享变量：`广播变量`，可以在内存的所有的结点上缓存变量；`累加器`：只能用于做加法的变量，例如计数或求和。

# 3. 如何编程

## 初始化 Spark

在一个Spark程序中要做的第一件事就是创建一个SparkContext对象来告诉Spark如何连接一个集群。为了创建SparkContext，你首先需要创建一个SparkConf对象，这个对象会包含你的应用的一些相关信息。这个通常是通过下面的构造器来实现的：

~~~java
new SparkContext(master, appName, [sparkHome], [jars])
~~~

参数说明：

- `master`：用于指定所连接的 Spark 或者 Mesos 集群的 URL。
- `appName` ：应用的名称，将会在集群的 Web 监控 UI 中显示。
- `sparkHome`：可选，你的集群机器上 Spark 的安装路径（所有机器上路径必须一致）。
- `jars`：可选，在本地机器上的 JAR 文件列表，其中包括你应用的代码以及任何的依赖，Spark 将会把他们部署到所有的集群结点上。

在 python 中初始化，示例代码如下：

~~~python
//conf = SparkContext("local", "Hello Spark")
conf = SparkConf().setAppName("Hello Spark").setMaster("local")
sc = SparkContext(conf=conf)
~~~

说明：如果部署到集群，在分布式模式下运行，最后两个参数是必须的，第一个参数可以是以下任一种形式：

|Master URL  |含义|
|:---|:---|
|`loca` | 默认值，使用一个 Worker 线程本地化运行(完全不并行) |
|`local[N]` |  使用 N 个 Worker 线程本地化运行，N 为 `*` 时，表示使用系统中所有核 |
|`local[N,M]`| 第一个代表的是用到的核个数；第二个参数代表的是容许该作业失败M次 |
|`spark://HOST:PORT`  | 连接到指定的 Spark 单机版集群 master 进程所在的主机和端口，端口默认是7077 |
|`mesos://HOST:PORT`  | 连接到指定的 Mesos 集群。host 参数是Moses master的hostname。端口默认是5050 |

如果你在一个集群上运行 spark-shell，则 master 参数默认为 `local`。在实际使用中，当你在集群中运行你的程序，你一般不会把 master 参数写死在代码中，而是通过用 spark-submit 运行程序来获得这个参数。但是，在本地测试以及单元测试时，你仍需要自行传入 local 来运行Spark程序。

## 运行代码

运行代码有几种方式，一是通过 spark-shell 来运行 scala 代码，一是编写 java 代码并打成包以 spark on yarn 方式运行，还有一种是通过 PySpark 来运行 python 代码。

在  spark-shell 和 PySpark 命令行中，一个特殊的集成在解释器里的 SparkContext 变量已经建立好了，变量名叫做 sc，创建你自己的 SparkContext 不会起作用。



# 4. 弹性分布式数据集

## 4.1 并行集合

并行集合是通过调用 SparkContext 的 `parallelize` 方法，在一个已经存在的 Scala 集合上创建一个 Seq 对象。

parallelize 方法还可以接受一个参数 `slices`，表示数据集切分的份数。Spark 将会在集群上为每一份数据起一个任务。典型地，你可以在集群的每个 CPU 上分布 2-4个 slices。一般来说，Spark 会尝试根据集群的状况，来自动设定 slices 的数目，当然，你也可以手动设置。

Scala 示例程序：

~~~java
scala> val data = Array(1, 2, 3, 4, 5)
data: Array[Int] = Array(1, 2, 3, 4, 5)

scala> var distData = sc.parallelize(data)
distData: org.apache.spark.rdd.RDD[Int] = ParallelCollectionRDD[0] at parallelize at <console>:14

scala> distData.reduce((a, b) => a + b)
res4: Int = 15
~~~

Java 示例程序：

~~~java
List<Integer> data = Arrays.asList(1, 2, 3, 4, 5);
JavaRDD<Integer> distData = sc.parallelize(data);
Integer sum=distData.reduce((a, b) -> a + b);
~~~

Python 示例程序：

~~~python
data = [1, 2, 3, 4, 5]
distData = sc.parallelize(data)
distData.reduce(lambda a, b: a + b)
~~~

## 4.2 外部数据源

Spark可以从存储在 HDFS，或者 Hadoop 支持的其它文件系统（包括本地文件，Amazon S3， Hypertable， HBase 等等）上的文件创建分布式数据集。Spark 支持 `TextFile`、`SequenceFiles` 以及其他任何 `Hadoop InputFormat` 格式的输入。

TextFile 的 RDD 可以通过下面方式创建，该方法接受一个文件的 URI 地址，该地址可以是本地路径，或者 `hdfs://`、`s3n://` 等 URL 地址。

~~~java
// scala 语法
val distFile = sc.textFile("data.txt")

// java 语法
JavaRDD<String> distFile = sc.textFile("data.txt");

// python 语法
distFile = sc.textFile("data.txt")
~~~

一些说明：

- 如果使用了本地文件路径时，要保证在worker节点上这个文件也能够通过这个路径访问。这点可以通过将这个文件拷贝到所有worker上或者使用网络挂载的共享文件系统来解决。
- 包括textFile在内的所有基于文件的Spark读入方法，都支持将文件夹、压缩文件、包含通配符的路径作为参数。比如，以下代码都是合法的：

~~~scala
textFile("/my/directory")
textFile("/my/directory/*.txt")
textFile("/my/directory/*.gz")
~~~

- textFile方法也可以传入第二个可选参数来控制文件的分片数量。默认情况下，Spark会为文件的每一个块（在HDFS中块的大小默认是64MB）创建一个分片。但是你也可以通过传入一个更大的值来要求Spark建立更多的分片。注意，分片的数量绝不能小于文件块的数量。

除了文本文件之外，Spark 还支持其他格式的输入：

- `SparkContext.wholeTextFiles` 方法可以读取一个包含多个小文件的目录，并以 filename，content 键值对的方式返回结果。
- 对于 SequenceFiles，可以使用 SparkContext 的 `sequenceFile[K, V]`` 方法创建。像 IntWritable 和 Text 一样，它们必须是 Hadoop 的 Writable 接口的子类。另外，对于几种通用 Writable 类型，Spark 允许你指定原生类型来替代。例如：sequencFile[Int, String] 将会自动读取 IntWritable 和 Texts。
- 对于其他类型的 Hadoop 输入格式，你可以使用 `SparkContext.hadoopRDD` 方法，它可以接收任意类型的 JobConf 和输入格式类，键类型和值类型。按照像 Hadoop 作业一样的方法设置输入源就可以了。
- `RDD.saveAsObjectFile` 和 `SparkContext.objectFile` 提供了以 Java 序列化的简单方式来保存 RDD。虽然这种方式没有 Avro 高效，但也是一种简单的方式来保存任意的 RDD。
 
## 4.3 RDD 操作

RDD支持两类操作：

- 转化操作，用于从已有的数据集转化产生新的数据集；
- 启动操作，用于在计算结束后向驱动程序返回结果。

举个例子，map是一个转化操作，可以将数据集中每一个元素传给一个函数，同时将计算结果作为一个新的RDD返回。另一方面，reduce操作是一个启动操作，能够使用某些函数来聚集计算RDD中所有的元素，并且向驱动程序返回最终结果（同时还有一个并行的reduceByKey操作可以返回一个分布数据集）。

在Spark所有的转化操作都是惰性求值的，就是说它们并不会立刻真的计算出结果。相反，它们仅仅是记录下了转换操作的操作对象（比如：一个文件）。只有当一个启动操作被执行，要向驱动程序返回结果时，转化操作才会真的开始计算。这样的设计使得Spark运行更加高效——比如，我们会发觉由map操作产生的数据集将会在reduce操作中用到，之后仅仅是返回了reduce的最终的结果而不是map产生的庞大数据集。

在默认情况下，每一个由转化操作得到的RDD都会在每次执行启动操作时重新计算生成。但是，你也可以通过调用persist(或cache)方法来将RDD持久化到内存中，这样Spark就可以在下次使用这个数据集时快速获得。Spark同样提供了对将RDD持久化到硬盘上或在多个节点间复制的支持。

Scala 示例：

~~~scala
val lines = sc.textFile("data.txt")
val lineLengths = lines.map(s => s.length)
val totalLength = lineLengths.reduce((a, b) => a + b)
~~~

Java 示例：

~~~java
JavaRDD<String> lines = sc.textFile("data.txt");
JavaRDD<Integer> lineLengths = lines.map(s -> s.length());
int totalLength = lineLengths.reduce((a, b) -> a + b);
~~~

Python 示例：

~~~python
lines = sc.textFile("data.txt")
lineLengths = lines.map(lambda s: len(s))
totalLength = lineLengths.reduce(lambda a, b: a + b)
~~~

第一行定义了一个由外部文件产生的基本RDD。这个数据集不是从内存中载入的也不是由其他操作产生的；lines仅仅是一个指向文件的指针。第二行将lineLengths定义为map操作的结果。再强调一次，由于惰性求值的缘故，lineLengths并不会被立即计算得到。最后，我们运行了reduce操作，这是一个启动操作。从这个操作开始，Spark将计算过程划分成许多任务并在多机上运行，每台机器运行自己部分的map操作和reduce操作，最终将自己部分的运算结果返回给驱动程序。

如果我们希望以后重复使用lineLengths，只需在reduce前加入下面这行代码：

~~~scala
lineLengths.persist()
~~~

这条代码将使得 lineLengths 在第一次计算生成之后保存在内存中。

除了使用 lambda 表达式，也可以通过函数来运行转换或者动作，使用函数需要注意局部变量的作用域问题。

例如下面的 Python 代码中的 field 变量：

~~~python
class MyClass(object):
    def __init__(self):
        self.field = "Hello"

    def doStuff(self, rdd):
        field = self.field
        return rdd.map(lambda s: field + x)    
~~~

如果使用 Java 语言，则需要用到匿名内部类：

~~~java
class GetLength implements Function<String, Integer> {
  public Integer call(String s) { return s.length(); }
}
class Sum implements Function2<Integer, Integer, Integer> {
  public Integer call(Integer a, Integer b) { return a + b; }
}

JavaRDD<String> lines = sc.textFile("data.txt");
JavaRDD<Integer> lineLengths = lines.map(new GetLength());
int totalLength = lineLengths.reduce(new Sum());
~~~

Spark 也支持键值对的操作，这在分组和聚合操作时候用得到。定义一个键值对对象时，需要自定义该对象的 equals() 和 hashCode() 方法。

在 Scala 中有一个 [Tuple2](http://www.scala-lang.org/api/2.10.4/index.html#scala.Tuple2) 对象表示键值对，这是一个内置的对象，通过 `(a,b)` 就可以创建一个 Tuple2 对象。在你的程序中，通过导入 `org.apache.spark.SparkContext._` 就可以对 Tuple2 进行操作。对键值对的操作方法，可以查看 [PairRDDFunctions](http://spark.apache.org/docs/latest/api/scala/index.html#org.apache.spark.rdd.PairRDDFunctions)

下面是一个用 scala 统计单词出现次数的例子：

~~~scala
val lines = sc.textFile("data.txt")
val pairs = lines.map(s => (s, 1))
val counts = pairs.reduceByKey((a, b) => a + b)
~~~

接下来，你还可以执行 `counts.sortByKey()`、`counts.collect()` 等操作。

如果用 Java 统计，则代码如下：

~~~java
JavaRDD<String> lines = sc.textFile("data.txt");
JavaPairRDD<String, Integer> pairs = lines.mapToPair(s -> new Tuple2(s, 1));
JavaPairRDD<String, Integer> counts = pairs.reduceByKey((a, b) -> a + b);
~~~

用 Python 统计，代码如下：

~~~python
lines = sc.textFile("data.txt")
pairs = lines.map(lambda s: (s, 1))
counts = pairs.reduceByKey(lambda a, b: a + b)
~~~

### 测试

现在来结合上面的例子实现一个完整的例子。下面，我们来 [分析 Nginx 日志中状态码出现次数](http://segmentfault.com/blog/whuwb/1190000000723037)，并且将结果按照状态码从小到大排序。

先将测试数据上传到 hdfs:

~~~bash
$ hadoop fs -put access.log
~~~

然后，编写一个 python 文件，保存为 SimpleApp.py：

~~~python
from pyspark import SparkContext

logFile = "access.log"

sc = SparkContext("local", "Simple App")

rdd = sc.textFile(logFile).cache()

counts = rdd.map(lambda line: line.split()[8]).map(lambda word: (word, 1)).reduceByKey(lambda a, b: a + b).sortByKey(lambda x: x) 

# This is just a demo on how to bring all the sorted data back to a single node.  
# In reality, we wouldn't want to collect all the data to the driver node.
output = counts.collect()  
for (word, count) in output:  
    print "%s: %i" % (word, count)  

counts.saveAsTextFile("/data/result")

sc.stop()
~~~

接下来，运行下面代码：

~~~bash
$ spark-submit  --master local[4]   SimpleApp.py
~~~

运行成功之后，你会在终端看到以下输出：

~~~java
200: 6827
206: 120
301: 7
304: 10
403: 38
404: 125
416: 1
~~~

并且，在hdfs 上 /user/spark/spark_results/part-00000 内容如下：

~~~python
(u'200', 6827)
(u'206', 120)
(u'301', 7)
(u'304', 10)
(u'403', 38)
(u'404', 125)
(u'416', 1)
~~~

其实，这个例子和官方提供的例子很相像，具体请看 [wordcount.py](https://github.com/apache/spark/blob/master/examples/src/main/python/wordcount.py)。

如果用 scala 来实现，代码如下：

~~~scala
rdd = sc.textFile("access.log").cache()
rdd.flatMap(_.split(' ')).map( (_,1)).reduceByKey(_+_).sortByKey(true).saveAsTextFile("/data/result")

sc.stop()
~~~

如果想要对结果按照次数进行排序，则代码如下：

~~~scala
rdd = sc.textFile("access.log").cache()
rdd.flatMap(_.split(' ')).map( (_,1)).reduceByKey(_+_).map( x => (x._2,x._1)).sortByKey(false).map( x => (x._2,x._1) ).saveAsTextFile("/data/resultSorted")

sc.stop()
~~~

### 常见的转换

|转换 |含义|
|:---|:---|
|`map(func)`| 每一个输入元素经过func函数转换后输出一个元素|
|`filter(func)` | 返回经过 func 函数计算后返回值为 true 的输入元素组成的一个新数据集|
|`flatMap(func)`| 类似于 map，但是每一个输入元素可以被映射为0或多个输出元素，因此 func 应该返回一个序列|
|`mapPartitions(func)`| 类似于 map，但独立地在 RDD 的每一个分块上运行，因此在类型为 T 的 RDD 上运行时，func 的函数类型必须是 `Iterator[T] ⇒ Iterator[U]`|
|`mapPartitionsWithSplit(func)`|类似于 mapPartitions, 但 func 带有一个整数参数表示分块的索引值。因此在类型为 T的RDD上运行时，func 的函数类型必须是 `(Int, Iterator[T]) ⇒ Iterator[U]`|
|`sample(withReplacement,fraction, seed)`|根据 fraction 指定的比例，对数据进行采样，可以选择是否用随机数进行替换，seed 用于指定随机数生成器种子|
|`union(otherDataset)`|返回一个新的数据集，新数据集是由源数据集和参数数据集联合而成|
|`distinct([numTasks])) `|返回一个包含源数据集中所有不重复元素的新数据集|
|`groupByKey([numTasks]) `|在一个键值对的数据集上调用，返回一个`(K，Seq[V])`对的数据集 。注意：默认情况下，只有8个并行任务来做操作，但是你可以传入一个可选的 numTasks 参数来改变它|
|`reduceByKey(func, [numTasks]) `|在一个键值对的数据集上调用时，返回一个键值对的数据集，使用指定的 reduce 函数，将相同 key 的值聚合到一起。类似 groupByKey，reduce 任务个数是可以通过第二个可选参数来配置的|
|`sortByKey([ascending], [numTasks]) `|在一个键值对的数据集上调用，K 必须实现 `Ordered` 接口，返回一个按照 Key 进行排序的键值对数据集。升序或降序由 ascending 布尔参数决定|
|`join(otherDataset, [numTasks]) `|在类型为（K,V)和（K,W) 类型的数据集上调用时，返回一个相同key对应的所有元素对在一起的 `(K, (V, W))` 数据集|
|`cogroup(otherDataset, [numTasks])`|在类型为（K,V)和（K,W) 的数据集上调用，返回一个 `(K, Seq[V], Seq[W])` 元组的数据集。这个操作也可以称之为 groupwith|
|`cartesian(otherDataset)` |笛卡尔积，在类型为 T 和 U 类型的数据集上调用时，返回一个 (T, U) 对数据集(两两的元素对)|
|`pipe(command, [envVars])` |对 RDD 进行管道操作 |
|`coalesce(numPartitions)` | 减少 RDD 的分区数到指定值。在过滤大量数据之后，可以执行此操作|
|`repartition(numPartitions)` | 重新给 RDD 分区|
|`repartitionAndSortWithinPartitions(partitioner)` | 重新给 RDD 分区，并且每个分区内以记录的 key 排序|

### 常见的动作

常见的动作列表：

|动作 |含义|
|:---|:---|
|`reduce(func)`| 通过函数 func 聚集数据集中的所有元素。这个功能必须可交换且可关联的，从而可以正确的被并行执行。|
|`collect()`| 在驱动程序中，以数组的形式，返回数据集的所有元素。这通常会在使用 filter 或者其它操作并返回一个足够小的数据子集后再使用会比较有用。|
|`count()` | 返回数据集的元素的个数。|
|`first()`|返回数据集的第一个元素，类似于 `take(1)`|
|`take(n)` |返回一个由数据集的前 n 个元素组成的数组。注意，这个操作目前并非并行执行，而是由驱动程序计算所有的元素|
|`takeSample(withReplacement,num, seed)` |返回一个数组，在数据集中随机采样 num 个元素组成，可以选择是否用随机数替换不足的部分，seed 用于指定的随机数生成器种子|
|`takeOrdered(n, [ordering]) ` | 返回自然顺序或者自定义顺序的前 n 个元素|
|`saveAsTextFile(path)`|将数据集的元素，以 textfile 的形式，保存到本地文件系统，HDFS或者任何其它 hadoop 支持的文件系统。对于每个元素，Spark 将会调用 `toString` 方法，将它转换为文件中的文本行|
|`saveAsSequenceFile(path)` (Java and Scala)|将数据集的元素，以 Hadoop sequencefile 的格式保存到指定的目录下|
|`saveAsObjectFile(path)` (Java and Scala)|将数据集的元素，以 Java 序列化的方式保存到指定的目录下|
|`countByKey()`| 对(K,V)类型的 RDD 有效，返回一个 (K，Int) 对的 Map，表示每一个key对应的元素个数|
|`foreach(func)`|在数据集的每一个元素上，运行函数 func 进行更新。这通常用于边缘效果，例如更新一个累加器，或者和外部存储系统进行交互，例如 HBase|

## 4.4 RDD持久化

Spark 的一个重要功能就是在将数据集持久化（或缓存）到内存中以便在多个操作中重复使用。当我们持久化一个 RDD 是，每一个节点将这个RDD的每一个分片计算并保存到内存中以便在下次对这个数据集（或者这个数据集衍生的数据集）的计算中可以复用。这使得接下来的计算过程速度能够加快（经常能加快超过十倍的速度）。缓存是加快迭代算法和快速交互过程速度的关键工具。

你可以通过调用`persist`或`cache`方法来标记一个想要持久化的 RDD。在第一次被计算产生之后，它就会始终停留在节点的内存中。Spark 的缓存是具有容错性的——如果 RDD 的任意一个分片丢失了，Spark 就会依照这个 RDD 产生的转化过程自动重算一遍。

另外，每一个持久化的 RDD 都有一个可变的存储级别，这个级别使得用户可以改变 RDD 持久化的储存位置。比如，你可以将数据集持久化到硬盘上，也可以将它以序列化的 Java 对象形式（节省空间）持久化到内存中，还可以将这个数据集在节点之间复制，或者使用 Tachyon 将它储存到堆外。这些存储级别都是通过向 `persist()` 传递一个 StorageLevel 对象（Scala, Java, Python）来设置的。

>注意：在Python中，储存的对象永远是通过 Pickle 库序列化过的，所以设不设置序列化级别不会产生影响。

Spark 还会在 shuffle 操作（比如 reduceByKey）中自动储存中间数据，即使用户没有调用 persist。这是为了防止在 shuffle 过程中某个节点出错而导致的全盘重算。不过如果用户打算复用某些结果 RDD，我们仍然建议用户对结果 RDD 手动调用 persist，而不是依赖自动持久化机制。

使用以下两种方法可以标记要缓存的 RDD：

~~~scala
lineLengths.persist()  
lineLengths.cache() 
~~~

取消缓存则用：

~~~scala
lineLengths.unpersist()
~~~

每一个 RDD 都可以用不同的保存级别进行保存，通过将一个 `org.apache.spark.storage.StorageLevel` 对象传递给 `persist(self, storageLevel)` 可以控制 RDD 持久化到磁盘、内存或者是跨节点复制等等。`cache()` 方法是使用默认存储级别的快捷方法，也就是 `StorageLevel.MEMORY_ONLY`。 完整的可选存储级别如下：

|存储级别| 意义|
|:---|:---|
|`MEMORY_ONLY`|默认的级别， 将 RDD 作为反序列化的的对象存储在 JVM 中。如果不能被内存装下，一些分区将不会被缓存，并且在需要的时候被重新计算|
|`MEMORY_AND_DISK`| 将 RDD 作为反序列化的的对象存储在 JVM 中。如果不能被与内存装下，超出的分区将被保存在硬盘上，并且在需要时被读取|
|`MEMORY_ONLY_SER`| 将 RDD 作为序列化的的对象进行存储（每一分区占用一个字节数组）。通常来说，这比将对象反序列化的空间利用率更高，尤其当使用fast serializer,但在读取时会比较占用CPU|
|`MEMORY_AND_DISK_SER` |与 `MEMORY_ONLY_SER` 相似，但是把超出内存的分区将存储在硬盘上而不是在每次需要的时候重新计算
|`DISK_ONLY` |只将 RDD 分区存储在硬盘上|
|`MEMORY_ONLY_2`、`MEMORY_AND_DISK_2`等|与上述的存储级别一样，但是将每一个分区都复制到两个集群结点上|
|`OFF_HEAP`|开发中|

Spark 的不同存储级别，旨在满足内存使用和 CPU 效率权衡上的不同需求。我们建议通过以下的步骤来进行选择：

- 如果你的 RDD 可以很好的与默认的存储级别契合，就不需要做任何修改了。这已经是 CPU 使用效率最高的选项，它使得 RDD的操作尽可能的快。
- 如果不行，试着使用 `MEMORY_ONLY_SER` 并且选择一个快速序列化的库使得对象在有比较高的空间使用率的情况下，依然可以较快被访问。
- 尽可能不要存储到硬盘上，除非计算数据集的函数，计算量特别大，或者它们过滤了大量的数据。否则，重新计算一个分区的速度，和与从硬盘中读取基本差不多快。
- 如果你想有快速故障恢复能力，使用复制存储级别。例如：用 Spark 来响应web应用的请求。所有的存储级别都有通过重新计算丢失数据恢复错误的容错机制，但是复制存储级别可以让你在 RDD 上持续的运行任务，而不需要等待丢失的分区被重新计算。
- 如果你想要定义你自己的存储级别，比如复制因子为3而不是2，可以使用 `StorageLevel` 单例对象的 `apply()`方法。

# 5. 共享变量

通常情况下，当一个函数传递给一个在远程集群节点上运行的Spark操作（比如map和reduce）时，Spark会对涉及到的变量的所有副本执行这个函数。这些变量会被复制到每个机器上，而且这个过程不会被反馈给驱动程序。通常情况下，在任务之间读写共享变量是很低效的。但是，Spark仍然提供了有限的两种共享变量类型用于常见的使用场景：`广播变量`和`累加器`。

## 广播变量

广播变量允许程序员在每台机器上保持一个只读变量的缓存而不是将一个变量的拷贝传递给各个任务。它们可以被使用，比如，给每一个节点传递一份大输入数据集的拷贝是很低效的。Spark 试图使用高效的广播算法来分布广播变量，以此来降低通信花销。
可以通过 `SparkContext.broadcast(v)` 来从变量 v 创建一个广播变量。这个广播变量是 v 的一个包装，同时它的值可以功过调用 value 方法来获得。以下的代码展示了这一点：

~~~python
broadcastVar = sc.broadcast([1, 2, 3])
<pyspark.broadcast.Broadcast object at 0x102789f10>

>>> broadcastVar.value
[1, 2, 3]
~~~

在广播变量被创建之后，在所有函数中都应当使用它来代替原来的变量v，这样就可以保证v在节点之间只被传递一次。另外，v变量在被广播之后不应该再被修改了，这样可以确保每一个节点上储存的广播变量的一致性（如果这个变量后来又被传输给一个新的节点）。

## 累加器

累加器是在一个相关过程中只能被”累加”的变量，对这个变量的操作可以有效地被并行化。它们可以被用于实现计数器（就像在MapReduce过程中）或求和运算。Spark原生支持对数字类型的累加器，程序员也可以为其他新的类型添加支持。累加器被以一个名字创建之后，会在Spark的UI中显示出来。这有助于了解计算的累进过程（注意：目前Python中不支持这个特性）。

可以通过`SparkContext.accumulator(v)`来从变量v创建一个累加器。在集群中运行的任务随后可以使用add方法或`+=`操作符（在Scala和Python中）来向这个累加器中累加值。但是，他们不能读取累加器中的值。只有驱动程序可以读取累加器中的值，通过累加器的value方法。

以下的代码展示了向一个累加器中累加数组元素的过程：

~~~python
accum = sc.accumulator(0)
Accumulator<id=0, value=0>

>>> sc.parallelize([1, 2, 3, 4]).foreach(lambda x: accum.add(x))
...
10/09/29 18:41:08 INFO SparkContext: Tasks finished in 0.317106 s

scala> accum.value
10
~~~

这段代码利用了累加器对 int 类型的内建支持，程序员可以通过继承 `AccumulatorParam` 类来创建自己想要的类型支持。AccumulatorParam 的接口提供了两个方法：`zero` 用于为你的数据类型提供零值；`addInPlace` 用于计算两个值得和。比如，假设我们有一个 `Vector`类表示数学中的向量，我们可以这样写：

~~~python
class VectorAccumulatorParam(AccumulatorParam):
    def zero(self, initialValue):
        return Vector.zeros(initialValue.size)

    def addInPlace(self, v1, v2):
        v1 += v2
        return v1

# Then, create an Accumulator of this type:
vecAccum = sc.accumulator(Vector(...), VectorAccumulatorParam())
~~~

累加器的更新操作只会被运行一次，Spark 提供了保证，每个任务中对累加器的更新操作都只会被运行一次。比如，重启一个任务不会再次更新累加器。在转化过程中，用户应该留意每个任务的更新操作在任务或作业重新运算时是否被执行了超过一次。

累加器不会该别 Spark 的惰性求值模型。如果累加器在对RDD的操作中被更新了，它们的值只会在启动操作中作为 RDD 计算过程中的一部分被更新。所以，在一个懒惰的转化操作中调用累加器的更新，并没法保证会被及时运行。下面的代码段展示了这一点：

~~~python
accum = sc.accumulator(0)
data.map(lambda x => acc.add(x); f(x))
~~~ 

# 6. 参考文章

- <http://spark.apache.org/docs/latest/programming-guide.html>
- <http://rdc.taobao.org/?p=2024>
- <http://blog.csdn.net/u011391905/article/details/37929731>
- <http://segmentfault.com/blog/whuwb/1190000000723037>
- [[翻译]Spark编程指南(Python版)](http://cholerae.com/2015/04/11/-%E7%BF%BB%E8%AF%91-Spark%E7%BC%96%E7%A8%8B%E6%8C%87%E5%8D%97-Python%E7%89%88/)

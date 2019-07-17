---
layout: post

title: 如何将Avro数据加载到Spark

category: spark

tags: [ avro,spark ]

description: 这是一篇翻译，主要讲述如何将 Avro 格式的数据加载到 Spark 中。

published: true

---

这是一篇翻译，原文来自：[How to load some Avro data into Spark](http://www.bigdatatidbits.cc/2015/01/how-to-load-some-avro-data-into-spark.html)。

# 首先，为什么使用 Avro ？

最基本的格式是 CSV ，其廉价并且不需要顶一个一个 schema 和数据关联。

随后流行起来的一个通用的格式是 XML，其有一个 schema 和 数据关联，XML 广泛的使用于 Web Services 和 SOA 架构中。不幸的是，其非常冗长，并且解析 XML 需要消耗内存。

另外一种格式是 JSON，其非常流行易于使用因为它非常方便易于理解。

这些格式在 Big Data 环境中都是不可拆分的，这使得他们难于使用。在他们之上使用一个压缩机制（Snappy，Gzip）并不能解决这个问题。

因此不同的数据格式出现了。Avro 作为一种序列化平台被广泛使用，因为它能跨语言，提供了一个小巧紧凑的快速的二进制格式，支持动态 schema 发现（通过它的泛型）和 schema 演变，并且是可压缩和拆分的。它还提供了复杂的数据结构，例如嵌套类型。

# 例子

让我们来看一个例子，创建一个 Avro schema 并生成一些数据。在一个真实案例的例子中，组织机构通常有一些更加普通的格式，例如 XML，的数据，并且他们需要通过一些工具例如  [JAXB](http://www.infoq.com/articles/AVROSchemaJAXB) 将他们的数据转换成 Avro。我们来使用[这个例子](http://www.michael-noll.com/blog/images/03/17/reading-and-writing-avro-files-from-the-command-line/)，其中 twitter.avsc 如下：

~~~json
{
   "type" : "record",
   "name" : "twitter_schema",
   "namespace" : "com.miguno.avro",
   "fields" : [
        {     "name" : "username",
               "type" : "string",
              "doc"  : "Name of the user account on Twitter.com"   },
         {
             "name" : "tweet",
             "type" : "string",
             "doc"  : "The content of the user's Twitter message"   },
         {
             "name" : "timestamp",
             "type" : "long",
             "doc"  : "Unix epoch time in seconds"   } 
    ],
   "doc:" : "A basic schema for storing Twitter messages" 
}
~~~

twitter.json 中有一些数据：

~~~json
{"username":"miguno","tweet":"Rock: Nerf paper, scissors is fine.","timestamp": 1366150681 } 
{"username":"BlizzardCS","tweet":"Works as intended.  Terran is IMBA.","timestamp": 1366154481 }
~~~

我们将这些数据转换成二进制的 Avro 格式：

~~~bash
$ java -jar ~/avro-tools-1.7.7.jar fromjson --schema-file twitter.avsc twitter.json > twitter.avro
~~~

然后，我们将 Avro 数据转换为 Java：

~~~bash
$ java -jar /app/avro/avro-tools-1.7.7.jar compile schema /app/avro/data/twitter.avsc /app/avro/data/
~~~

现在，我们编译这些类并将其打包：

~~~bash
$ CLASSPATH=/app/avro/avro-1.7.7-javadoc.jar:/app/avro/avro-mapred-1.7.7-hadoop1.jar:/app/avro/avro-tools-1.7.7.jar
$ javac -classpath $CLASSPATH /app/avro/data/com/miguno/avro/twitter_schema.java
$ jar cvf Twitter.jar com/miguno/avro/*.class
~~~

我们启动 Spark，并将上面创建的 Jar 和一些需要的库（Hadoop 和 Avro）传递给 Spark 程序：

~~~bash
$ ./bin-shell --jars /app/avro/avro-mapred-1.7.7-hadoop1.jar,/avro/avro-1.7.7.jar,/app/avro/data/Twitter.jar
~~~

在 REPL 中，我们获取数据并创建一个 RDD：

~~~
scala>
import com.miguno.avro.twitter_schema
import org.apache.avro.file.DataFileReader;
import org.apache.avro.file.DataFileWriter;
import org.apache.avro.io.DatumReader;
import org.apache.avro.io.DatumWriter;
import org.apache.avro.specific.SpecificDatumReader;
import org.apache.avro.mapreduce.AvroKeyInputFormat
import org.apache.avro.mapred.AvroKey
import org.apache.hadoop.io.NullWritable
import org.apache.avro.mapred.AvroInputFormat
import org.apache.avro.mapred.AvroWrapper
import org.apache.avro.generic.GenericRecord
import org.apache.avro.mapred.{AvroInputFormat, AvroWrapper}
import org.apache.hadoop.io.NullWritable


val path = "/app/avro/data/twitter.avro"
val avroRDD = sc.hadoopFile[AvroWrapper[GenericRecord], NullWritable, AvroInputFormat[GenericRecord]](path)
avroRDD.map(l => new String(l._1.datum.get("username").toString() ) ).first
~~~

返回结果：

~~~
res2: String = miguno
~~~

一些注意事项：

- 我们在使用 MR1 的类，但是 MR2的类同样能够运行。
- 我们使用GenericRecord 而不是 Specific ，因为我们生成了 Avro schema（并且导入了它）。更多内容参见 <http://avro.apache.org/docs/current/gettingstartedjava.html>
- 注意到即使 Avro 类是用 Java 编译的，你还是可以在 Spark 中导入他们，因为 Scala 也是运行在 JVM 之上。
- Avro 允许你定义一个可选的方式去定义 schema 中每个节点的反序列化类型，即通过 key/value 的键值对，这是方式非常方便。参考 <http://stackoverflow.com/questions/27827649/trying-to-deserialize-avro-in-spark-with-specific-type/27859980?noredirect=1%23comment44240726_27859980> 。
- 还有大量的其他方式来实现这个功能，一种是使用 Kryo，另一种是使用 Spark SQL。然而，这需要你创建一个 Spark SQL 的上下文（见 <https://github.com/databricks-avro> ），而不是一个纯粹的 Spark/Scala  方式。然而，也许这在将来会是一种最佳方式？

翻译结束。

-------

接下来，我将上述过程在 CDH 5.3 集群中测试一遍。

# 验证

首先，在集群一个节点创建 twitter.avsc 和 twitter.json 两个文件。

然后，使用 avro-tools 将这些数据转换成二进制的 Avro 格式：

~~~
$ java -jar /usr/lib/avro/avro-tools.jar fromjson --schema-file twitter.avsc twitter.json > twitter.avro
~~~

这时候会生成 avro 文件：

~~~ bash
$ ll
总用量 12
-rw-r--r-- 1 root root 543  3月 25 15:13 twitter.avro
-rw-r--r-- 1 root root 590  3月 25 15:12 twitter.avsc
-rw-r--r-- 1 root root 191  3月 25 15:12 twitter.json
~~~

将 Avro 数据转换为 Java：

~~~
$ java -jar /usr/lib/avro/avro-tools.jar compile schema twitter.avsc .
~~~

这时候会生成 twitter_schema.java 文件：

~~~bash
$ tree
.
├── com
│   └── miguno
│       └── avro
│           └── twitter_schema.java
├── twitter.avro
├── twitter.avsc
└── twitter.json
~~~

这时候会生成一个 Twitter.jar 的 jar 包。

编译这些类并将其打包：

~~~bash
$ CLASSPATH=/usr/lib/avro/avro-mapred-hadoop2.jar:/usr/lib/avro/avro-tools.jar
$ javac -classpath $CLASSPATH com/miguno/avro/twitter_schema.java
$ jar cvf Twitter.jar com/miguno/avro/*.class
~~~

在当前目录，运行 spark-shell:

~~~bash
spark-shell --jars /usr/lib/avro/avro-mapred-hadoop2.jar,/usr/lib/avro/avro.jar,Twitter.jar
~~~

将 twitter.avro 上传到 hdfs:

~~~bash
hadoop fs -put twitter.avro
~~~

在 REPL 中，我们创建一个 RDD 并查看结果是否和上面一致：

~~~
scala>
import com.miguno.avro.twitter_schema;
import org.apache.avro.file.DataFileReader;
import org.apache.avro.file.DataFileWriter;
import org.apache.avro.io.DatumReader;
import org.apache.avro.io.DatumWriter;
import org.apache.avro.specific.SpecificDatumReader;
import org.apache.avro.mapreduce.AvroKeyInputFormat
import org.apache.avro.mapred.AvroKey
import org.apache.hadoop.io.NullWritable
import org.apache.avro.mapred.AvroInputFormat
import org.apache.avro.mapred.AvroWrapper
import org.apache.avro.generic.GenericRecord
import org.apache.avro.mapred.{AvroInputFormat, AvroWrapper}
import org.apache.hadoop.io.NullWritable


val path = "twitter.avro"
val avroRDD = sc.hadoopFile[AvroWrapper[GenericRecord], NullWritable, AvroInputFormat[GenericRecord]](path)
avroRDD.map(l => new String(l._1.datum.get("username").toString() ) ).first
~~~

更多的 Avro Tools 用法，可以参考 [Avro 介绍](/2015/03/20/about-avro.html)。


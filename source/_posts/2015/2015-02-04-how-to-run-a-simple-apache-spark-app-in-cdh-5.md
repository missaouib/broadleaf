---
layout: post

title: 如何在CDH5上运行Spark应用

category: spark

tags: [ spark ]

description: 本文主要记录在 CDH5 集群环境上如何创建一个 maven 工程并且编写、编译和运行一个简单的 Spark 程序。

published: true

---

>这篇文章参考 [How-to: Run a Simple Apache Spark App in CDH 5](http://blog.cloudera.com/blog/2014/04/how-to-run-a-simple-apache-spark-app-in-cdh-5/) 编写而成，没有完全参照原文翻译，而是重新进行了整理，例如：spark 版本改为 `1.3.0`，添加了 Python 版的程序。

# 创建 maven 工程

使用下面命令创建一个普通的 maven 工程：

~~~bash
$ mvn archetype:generate -DgroupId=com.cloudera.sparkwordcount -DartifactId=sparkwordcount -DarchetypeArtifactId=maven-archetype-quickstart -DinteractiveMode=false
~~~

在 sparkwordcount 目录下添加 scala 源文件目录和相应的包目录：

~~~bash
$ mkdir -p sparkwordcount/src/main/scala/com/clouderawordcount
~~~

修改 pom.xml 添加 scala 和 spark 依赖：

~~~xml
  <dependencies>
    <dependency>
      <groupId>org.scala-lang</groupId>
      <artifactId>scala-library</artifactId>
      <version>2.10.4</version>
    </dependency>
    <dependency>
      <groupId>org.apache.spark</groupId>
      <artifactId>spark-core_2.10</artifactId>
      <version>1.3.0</version>
    </dependency>
    <dependency>
      <groupId>org.apache.spark</groupId>
      <artifactId>spark-sql_2.10</artifactId>
      <version>1.3.0</version>
    </dependency>
  </dependencies>
~~~


添加编译 scala 的插件：

~~~xml
 <plugin>
  <groupId>org.scala-tools</groupId>
      <artifactId>maven-scala-plugin</artifactId>
      <executions>
        <execution>
          <goals>
            <goal>compile</goal>
            <goal>testCompile</goal>
          </goals>
        </execution>
      </executions>
</plugin>
~~~

添加 scala 编译插件需要的仓库：

~~~xml
<pluginRepositories>
  <pluginRepository>
    <id>scala-tools.org</id>
    <name>Scala-tools Maven2 Repository</name>
    <url>http://scala-tools.org/repo-releases</url>
  </pluginRepository>
</pluginRepositories>
~~~

另外，添加 cdh hadoop 的仓库：

~~~xml
  <repositories>
    <repository>
      <id>scala-tools.org</id>
      <name>Scala-tools Maven2 Repository</name>
      <url>http://scala-tools.org/repo-releases</url>
    </repository>
    <repository>
      <id>maven-hadoop</id>
      <name>Hadoop Releases</name>
      <url>https://repository.cloudera.com/content/repositories/releases/</url>
    </repository>
    <repository>
      <id>cloudera-repos</id>
      <name>Cloudera Repos</name>
      <url>https://repository.cloudera.com/artifactory/cloudera-repos/</url>
    </repository>
  </repositories>
~~~

运行下面命令检查工程是否能够成功编译：

~~~bash
mvn package
~~~

# 编写示例代码

以 [WordCount](http://wiki.apache.org/hadoop/WordCount) 为例，该程序需要完成以下逻辑：

- 读一个输入文件
- 统计每个单词出现次数
- 过滤少于一定次数的单词
- 对剩下的单词统计每个字母出现次数

在 MapReduce 中，上面的逻辑需要两个 MapReduce 任务，而在 Spark 中，只需要一个简单的任务，并且代码量会少 90%。

编写Scala 程序如下：

~~~scala
import org.apache.spark.SparkContext
import org.apache.spark.SparkContext._
import org.apache.spark.SparkConf
 
object SparkWordCount {
  def main(args: Array[String]) {
    val sc = new SparkContext(new SparkConf().setAppName("Spark Count"))
    val threshold = args(1).toInt
 
    // split each document into words
    val tokenized = sc.textFile(args(0)).flatMap(_.split(" "))
 
    // count the occurrence of each word
    val wordCounts = tokenized.map((_, 1)).reduceByKey(_ + _)
 
    // filter out words with less than threshold occurrences
    val filtered = wordCounts.filter(_._2 &gt;= threshold)
 
    // count characters
    val charCounts = filtered.flatMap(_._1.toCharArray).map((_, 1)).reduceByKey(_ + _)
 
    System.out.println(charCounts.collect().mkString(", "))
  }
}
~~~

Spark 使用懒执行的策略，意味着只有当`动作`执行的时候，`转换`才会运行。上面例子中的`动作`操作是 `collect` 和 `saveAsTextFile`，前者是将数据推送给客户端，后者是将数据保存到 HDFS。

作为对比，Java 版的程序如下：

~~~java
import java.util.ArrayList;
import java.util.Arrays;
import org.apache.spark.api.java.*;
import org.apache.spark.api.java.function.*;
import org.apache.spark.SparkConf;
import scala.Tuple2;
 
public class JavaWordCount {
  public static void main(String[] args) {
    JavaSparkContext sc = new JavaSparkContext(new SparkConf().setAppName("Spark Count"));
    final int threshold = Integer.parseInt(args[1]);
 
    // split each document into words
    JavaRDD tokenized = sc.textFile(args[0]).flatMap(
      new FlatMapFunction() {
        public Iterable call(String s) {
          return Arrays.asList(s.split(" "));
        }
      }
    );
 
    // count the occurrence of each word
    JavaPairRDD counts = tokenized.mapToPair(
      new PairFunction() {
        public Tuple2 call(String s) {
          return new Tuple2(s, 1);
        }
      }
    ).reduceByKey(
      new Function2() {
        public Integer call(Integer i1, Integer i2) {
          return i1 + i2;
        }
      }
    );
 
    // filter out words with less than threshold occurrences
    JavaPairRDD filtered = counts.filter(
      new Function, Boolean>() {
        public Boolean call(Tuple2 tup) {
          return tup._2 >= threshold;
        }
      }
    );
 
    // count characters
    JavaPairRDD charCounts = filtered.flatMap(
      new FlatMapFunction, Character>() {
        public Iterable call(Tuple2 s) {
          ArrayList chars = new ArrayList(s._1.length());
          for (char c : s._1.toCharArray()) {
            chars.add(c);
          }
          return chars;
        }
      }
    ).mapToPair(
      new PairFunction() {
        public Tuple2 call(Character c) {
          return new Tuple2(c, 1);
        }
      }
    ).reduceByKey(
      new Function2() {
        public Integer call(Integer i1, Integer i2) {
          return i1 + i2;
        }
      }
    );
 
    System.out.println(charCounts.collect());
  }
}
~~~


另外，Python 版的程序如下：

~~~python
import sys

from pyspark import SparkContext

file="inputfile.txt"
count=2

if __name__ == "__main__":
    sc = SparkContext(appName="PythonWordCount")
    lines = sc.textFile(file, 1)
    counts = lines.flatMap(lambda x: x.split(' ')) \
                  .map(lambda x: (x, 1))  \
                  .reduceByKey(lambda a, b: a + b)  \
                  .filter(lambda (a, b) : b >= count)  \
                  .flatMap(lambda (a, b): list(a))  \
                  .map(lambda x: (x, 1))  \
                  .reduceByKey(lambda a, b: a + b)

    print ",".join(str(t) for t in counts.collect())
    sc.stop()
~~~

# 编译

运行下面命令生成 jar：

~~~bash
$ mvn package
~~~

运行成功之后，会在 target 目录生成 sparkwordcount-0.0.1-SNAPSHOT.jar 文件。

# 运行

首先，将测试文件 [inputfile.txt](https://github.com/sryza/simplesparkapp/blob/master/data/inputfile.txt) 上传到 HDFS 上；

~~~bash
$ wget https://github.com/sryza/simplesparkapp/blob/master/data/inputfile.txt
$ hadoop fs -put inputfile.txt
~~~

其次，将 sparkwordcount-0.0.1-SNAPSHOT.jar 上传到集群中的一个节点；然后，使用 spark-submit 脚本运行 Scala 版的程序：

~~~bash
$ spark-submit --class com.cloudera.sparkwordcount.SparkWordCount --master local sparkwordcount-0.0.1-SNAPSHOT.jar inputfile.txt 2
~~~

或者，运行 Java 版本的程序：

~~~bash
$ spark-submit --class com.cloudera.sparkwordcount.JavaWordCount --master local sparkwordcount-0.0.1-SNAPSHOT.jar inputfile.txt 2
~~~

对于 Python 版的程序，运行脚本为：

~~~bash
$ spark-submit  --master local PythonWordCount.py
~~~ 

如果，你的集群部署的是 standalone 模式，则你可以替换 master 参数的值为 `spark://<master host>:<master port>`，也可以以 Yarn 的模式运行。

最后的 Python 版的程序运行输出结果如下：

~~~
(u'a', 4),(u'c', 1),(u'b', 1),(u'e', 6),(u'f', 1),(u'i', 1),(u'h', 1),(u'l', 1),(u'o', 2),(u'n', 4),(u'p', 2),(u'r', 2),(u'u', 1),(u't', 2),(u'v', 1)
~~~

完整的代码在：<https://github.com/sryza/simplesparkapp>

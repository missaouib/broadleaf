---
layout: post

title: HBase实现简单聚合计算
date: 2014-06-12T08:00:00+08:00

description: 本文主要记录如何通过打补丁的方式将“hbase中实现简单聚合计算”的特性引入hbase源代码中，并介绍通过命令行和java代码的使用方法。

keywords: HBase实现简单聚合计算

categories: [ hbase ]

tags: [hbase]

published: true

---

本文主要记录如何通过打补丁的方式将“hbase中实现简单聚合计算”的特性引入hbase源代码中，并介绍通过命令行和java代码的使用方法。

支持的简单聚合计算，包括：

- rowcount
- min
- max
- sum
- std
- avg
- median

1、 下载并编译hbase源代码

我这里使用的HBase源代码版本是：cdh4-0.94.6_4.3.0，如果你使用其他版本，有可能patch打不上。

2、 引入patch

基于提交日志[add-aggregate-support-in-hbase-shell](https://github.com/javachen/hbase/commit/94e61f28d60cac40f2b499b8530dd1989adf76d3)生成patch文件，然后打patch，或者也可以使用其他方法：

~~~
$ git apply add-aggregate-in-hbase-shell.patch
~~~

该patch所做修改包括如下文件：

~~~
src/main/java/org/apache/hadoop/hbase/client/coprocessor/AbstractDoubleColumnInterpreter.java
src/main/java/org/apache/hadoop/hbase/client/coprocessor/AbstractLongColumnInterpreter.java
src/main/java/org/apache/hadoop/hbase/client/coprocessor/CompositeDoubleStrColumnInterpreter.java
src/main/java/org/apache/hadoop/hbase/client/coprocessor/CompositeLongStrColumnInterpreter.java
src/main/java/org/apache/hadoop/hbase/client/coprocessor/DoubleColumnInterpreter.java
src/main/java/org/apache/hadoop/hbase/client/coprocessor/DoubleStrColumnInterpreter.java
src/main/java/org/apache/hadoop/hbase/client/coprocessor/LongColumnInterpreter.java
src/main/java/org/apache/hadoop/hbase/client/coprocessor/LongStrColumnInterpreter.java
src/main/ruby/hbase.rb
src/main/ruby/hbase/coprocessor.rb
src/main/ruby/hbase/hbase.rb
src/main/ruby/shell.rb
src/main/ruby/shell/commands.rb
src/main/ruby/shell/commands/aggregate.rb
~~~

3、 编译源代码

为了使编译花费时间不会太长，请运行如下命令编译代码，你也可以自己修改下面命令：

~~~
$ MAVEN_OPTS="-Xmx2g" mvn clean install  -DskipTests -Prelease,security -Drat.numUnapprovedLicenses=200 -Dhadoop.profile=2.0
~~~

4、测试

然后将target目录下生成的jar包拷贝到集群中每个hbase节点的/usr/lib/hbase目录。

修改hbase-site.xml配置文件，添加如下配置：

~~~xml
<property>
  <name>hbase.coprocessor.region.classes</name>
  <value>org.apache.hadoop.hbase.coprocessor.AggregateImplementation</value>
</property>
~~~

重启hbase服务：

~~~
$ /etc/init.d/hbase-master restart
$ /etc/init.d/hbase-regionserver restart
~~~

a）运行hbase shell进行测试

首先创建表并插入几条记录：

~~~sql
create 't','f'
 
put 't','1','f:id','1'
put 't','2','f:id','2'
put 't','2','f:id','3'
put 't','3','f:id','4'
~~~

在hbase shell命令行中输入agg并按tab键自动提示：

~~~
hbase(main):004:0> aggregate
~~~

什么参数不输入，提示如下：

~~~sql
hbase(main):004:0> aggregate
 
ERROR: wrong number of arguments (0 for 2)
 
Here is some help for this command:
Execute a Coprocessor aggregation function; pass aggregation function name, table name, column name, column interpreter and optionally a dictionary of aggregation specifications. Aggregation specifications may include STARTROW, STOPROW or FILTER. For a cross-site big table, if no clusters are specified, all clusters will be counted for aggregation.
Usage: aggregate 'subcommand','table','column',[{COLUMN_INTERPRETER => org.apache.hadoop.hbase.client.coprocessor.LongColumnInterpreter.new, STARTROW => 'abc', STOPROW => 'def', FILTER => org.apache.hadoop.hbase.filter.ColumnPaginationFilter.new(1, 0)}]
Available subcommands:
rowcount
min
max
sum
std
avg
median
Available COLUMN_INTERPRETER:
org.apache.hadoop.hbase.client.coprocessor.LongColumnInterpreter.new
org.apache.hadoop.hbase.client.coprocessor.LongStrColumnInterpreter.new
org.apache.hadoop.hbase.client.coprocessor.CompositeLongStrColumnInterpreter.new(",", 0)
The default COLUMN_INTERPRETER is org.apache.hadoop.hbase.client.coprocessor.LongStrColumnInterpreter.new.
 
Some examples:
 
hbase> aggregate 'min','t1','f1:c1'
hbase> aggregate 'sum','t1','f1:c1','f1:c2'
hbase> aggregate 'rowcount','t1','f1:c1' ,{COLUMN_INTERPRETER => org.apache.hadoop.hbase.client.coprocessor.CompositeLongStrColumnInterpreter.new(",", 0)}
hbase> aggregate 'min','t1','f1:c1',{STARTROW => 'abc', STOPROW => 'def'}
~~~

从上可以看到aggregate的帮助说明。

接下来进行测试，例如求id列的最小值：

~~~
hbase(main):005:0> aggregate 'min','t','f:id'
The result of min for table t is 1
0 row(s) in 0.0170 seconds
 
hbase(main):006:0> aggregate 'avg','t','f:id'
The result of avg for table t is 2.5
0 row(s) in 0.0170 seconds
~~~

正确输出结果，表明测试成功。

b）通过hbase client测试

创建AggregateTest.java类并添加如下代码：

~~~java
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.hbase.HBaseConfiguration;
import org.apache.hadoop.hbase.client.Scan;
import org.apache.hadoop.hbase.client.coprocessor.AggregationClient;
import org.apache.hadoop.hbase.client.coprocessor.LongStrColumnInterpreter;
import org.apache.hadoop.hbase.coprocessor.ColumnInterpreter;
import org.apache.hadoop.hbase.util.Bytes;
public class AggregateTest {
  public static void main(String[] args) {
    Configuration conf = HBaseConfiguration.create();
    conf.setInt("hbase.client.retries.number", 1);
    conf.setInt("ipc.client.connect.max.retries", 1);
     
    byte[] table = Bytes.toBytes("t");
    Scan scan = new Scan();
    scan.addColumn(Bytes.toBytes("f"), Bytes.toBytes("id"));
    final ColumnInterpreter<Long, Long> columnInterpreter = new LongStrColumnInterpreter();
    try {
      AggregationClient aClient = new AggregationClient(conf);
      Long rowCount = aClient.min(table, columnInterpreter, scan);
      System.out.println("The result is " + rowCount);
    } catch (Throwable e) {
      e.printStackTrace();
    }
  }
}
~~~

运行该类并查看输出结果。

以上源代码及所做的修改我已提交到我github仓库上hbase的cdh4-0.94.15_4.7.0分支，见提交日志[add-aggregate-support-in-hbase-shell](https://github.com/javachen/hbase/commit/94e61f28d60cac40f2b499b8530dd1989adf76d3)。

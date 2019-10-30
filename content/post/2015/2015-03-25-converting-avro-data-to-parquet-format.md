---
layout: post

title: 将Avro数据转换为Parquet格式
date: 2015-03-25T08:00:00+08:00

categories: [ hadoop ]

tags: [ avro,parquet ]

description: 本文主要测试将Avro数据转换为Parquet格式的过程并查看 Parquet 文件的 schema 和元数据。

published: true

---

本文主要测试将Avro数据转换为Parquet格式的过程并查看 Parquet 文件的 schema 和元数据。

# 准备

将文本数据转换为 Parquet 格式并读取内容，可以参考 Cloudera 的 MapReduce 例子：<https://github.com/cloudera/parquet-examples>。

准备文本数据 a.txt 为 CSV 格式：

~~~
1,2
3,4
4,5
~~~

准备 Avro 测试数据，可以参考 [将Avro数据加载到Spark](/2015/03/25/how-to-load-some-avro-data-into-spark.html) 一文。

本文测试环境为：CDH 5.2，并且 Avro、Parquet 组件已经通过 YUM 源安装。

# 将 CSV 转换为 Parquet

在 Hive 中创建一个表并导入数据：

~~~sql
create table mycsvtable (x int, y int)
row format delimited
FIELDS TERMINATED BY ','
STORED AS TEXTFILE;

LOAD DATA LOCAL INPATH 'a.txt' OVERWRITE INTO TABLE mycsvtable;
~~~

创建 Parquet 表并转换数据：

~~~sql
create table myparquettable (a INT, b INT)
STORED AS PARQUET
LOCATION '/tmp/data';

insert overwrite table myparquettable select * from mycsvtable;
~~~

查看 hdfs 上生成的 myparquettable 表的数据：

~~~
$ hadoop fs -ls /tmp/data
Found 1 items
-rwxrwxrwx   3 hive hadoop        331 2015-03-25 15:50 /tmp/data/000000_0
~~~

在 hive 中查看 myparquettable 表的数据：

~~~sql
hive (default)> select * from myparquettable;
OK
myparquettable.a  myparquettable.b
1 2
3 4
4 5
Time taken: 0.149 seconds, Fetched: 3 row(s)
~~~

查看 /tmp/data/000000_0 文件的 schema ：

~~~bash
$ hadoop parquet.tools.Main schema /tmp/data/000000_0
message hive_schema {
  optional int32 a;
  optional int32 b;
}
~~~

查看 /tmp/data/000000_0 文件的元数据：

~~~bash
$ hadoop parquet.tools.Main meta /tmp/data/000000_0
creator:     parquet-mr version 1.5.0-cdh5.2.0 (build 8e266e052e423af5 [more]...

file schema: hive_schema
--------------------------------------------------------------------------------
a:           OPTIONAL INT32 R:0 D:1
b:           OPTIONAL INT32 R:0 D:1

row group 1: RC:3 TS:102
--------------------------------------------------------------------------------
a:            INT32 UNCOMPRESSED DO:0 FPO:4 SZ:51/51/1.00 VC:3 ENC:BIT [more]...
b:            INT32 UNCOMPRESSED DO:0 FPO:55 SZ:51/51/1.00 VC:3 ENC:BI [more]...
~~~

# 将 Avro 转换为 Parquet

使用 [将Avro数据加载到Spark](/2015/03/25/how-to-load-some-avro-data-into-spark.html)  中的 schema 和 json 数据，从 json 数据生成 avro 数据：

~~~bash
$ java -jar /usr/lib/avro/avro-tools.jar fromjson --schema-file twitter.avsc twitter.json > twitter.avro
~~~

将 twitter.avsc 和 twitter.avro 上传到 hdfs：

~~~bash
$ hadoop fs -put twitter.avsc
$ hadoop fs -put twitter.avro
~~~

使用 https://github.com/laserson/avro2parquet 将 avro 转换为 parquet 格式：

~~~bash
$ hadoop jar avro2parquet.jar twitter.avsc  twitter.avro /tmp/out
~~~

然后，在 hive 中创建表并导入数据：

~~~sql
create table tweets_parquet (username string, tweet string, timestamp bigint) 
STORED AS PARQUET;

load data inpath '/tmp/out/part-m-00000.snappy.parquet' overwrite into table tweets_parquet;
~~~

接下来，可以查询数据并查看 parquet 文件的 schema 和元数据，方法同上文。

# 参考文章

- [Converting Avro data to Parquet format in Hadoop](http://www.bigdatatidbits.cc/2015/03/converting-avro-data-to-parquet-format.html)

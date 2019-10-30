---
layout: post

title: Useful Hadoop Commands
date: 2015-02-10T08:00:00+08:00

categories: [ hadoop ]

tags: [ hadoop ]

description: Hadoop 中的一些常见有用的命令，后期会不停地更新。

published: true

---

## hadoop

解压 gz 文件到文本文件

~~~bash
$ hadoop fs -text /hdfs_path/compressed_file.gz | hadoop fs -put - /tmp/uncompressed-file.txt
~~~

解压本地文件 gz 文件并上传到 hdfs

~~~bash
$ gunzip -c filename.txt.gz | hadoop fs -put - /tmp/filename.txt
~~~

使用 awk 处理 csv 文件，参考 [Using awk and friends with Hadoop](http://grepalex.com/images/01/17/awk-with-hadoop-streaming/):

~~~bash
$ hadoop fs -cat people.txt | awk -F"," '{ print $1","$2","$3$4$5 }' | hadoop fs -put - people-coalesed.txt
~~~

创建 lzo 文件、上传到 hdfs 并添加索引：

~~~bash
$ lzop -Uf data.txt
$ hadoop fs -moveFromLocal data.txt.lzo /tmp/
# 1. 单机
$ hadoop jar /usr/lib/hadoop/lib/hadoop-lzo.jar com.hadoop.compression.lzo.LzoIndexer /tmp/data.txt.lzo

# 2. 运行 mr
$ hadoop jar /usr/lib/hadoop/lib/hadoop-lzo.jar com.hadoop.compression.lzo.DistributedLzoIndexer /tmp/data.txt.lzo
~~~

如果 people.txt 通过 lzo 压缩了，则可以使用下面命令解压缩、处理数据、压缩文件：

~~~bash
$ hadoop fs -cat people.txt.lzo | lzop -dc | awk -F"," '{ print $1","$2","$3$4$5 }' | lzop -c | hadoop fs -put - people-coalesed.txt.lzo
~~~

## hive

后台运行：

~~~bash
$ nohup hive -f sample.hql > output.out 2>&1 & 

$ nohup hive --database "default" -e "select * from tablename;" > output.out 2>&1 & 
~~~

替换分隔符：

~~~bash
$ hive --database "default" -f query.hql  2> err.txt | sed 's/[\t]/,/g' 1> output.txt 
~~~

打印表头：

~~~bash
$ hive --database "default" -e "SHOW COLUMNS FROM table_name;" | tr '[:lower:]' '[:upper:]' | tr '\n' ',' 1> headers.txt

$ hive --database "default" -e "SET hive.cli.print.header=true; select * from table_name limit 0;" | tr '[:lower:]' '[:upper:]' | sed 's/[\t]/,/g'  1> headers.txt
~~~

查看执行时间：

~~~bash
$ hive -e "select * from tablename;"  2> err.txt  1> out.txt 
$ cat err.txt | grep "Time taken:" | awk '{print $3,$6}'
~~~

hive 中如何避免用科学计数法表示浮点数？参考 <http://www.zhihu.com/question/28887115> ：

~~~sql
SELECT java_method("String", "format", "%f", my_column) FROM mytable LIMIT 1
~~~

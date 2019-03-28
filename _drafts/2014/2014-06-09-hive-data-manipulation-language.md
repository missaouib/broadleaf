---
layout: post

title: Hive中数据的加载和导出

description: 记录 hive 的DML语法，并以实际的例子演示如何加载和导出数据

keywords: Hive中数据的导入和导出

category: hive

tags: [hive,mapreduce]

published: true

---

关于 Hive DML 语法，你可以参考 apache 官方文档的说明:[Hive Data Manipulation Language](https://cwiki.apache.org/confluence/display/Hive/LanguageManual+DML)。

apache的hive版本现在应该是 0.13.0，而我使用的 hadoop 版本是 CDH5.0.1，其对应的 hive 版本是 0.12.0。故只能参考apache官方文档来看 cdh5.0.1 实现了哪些特性。

因为 hive 版本会持续升级，故本篇文章不一定会和最新版本保持一致。

# 1. 准备测试数据

首先创建普通表：

~~~sql
create table test(id int, name string) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' STORED AS TEXTFILE;
~~~

创建分区表：

~~~sql
CREATE EXTERNAL TABLE test_p(
id int,
name string 
)
partitioned by (date STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\,' LINES TERMINATED BY '\n' 
STORED AS TEXTFILE;
~~~

准备数据文件：

~~~bash
[/tmp]# cat test.txt 
1,a
2,b
3,c
4,d
~~~

# 2.加载数据

语法如下：

~~~sql
LOAD DATA [LOCAL] INPATH 'filepath' [OVERWRITE] INTO TABLE tablename [PARTITION (partcol1=val1, partcol2=val2 ...)]
~~~

说明：

- filepath 可能是：
 - 一个相对路径
 - 一个绝对路径，例如：`/root/project/data1 `
 - 一个url地址，可选的可以带上授权信息，例如：`hdfs://namenode:9000/user/hive/project/data1` 
- 目标可能是一个表或者分区，如果该表是分区，则必须制定分区列。
- filepath 可以是一个文件也可以是目录
- 如果指定了 `LOCAL`，则：
 - `load` 命令会在本地查找 filepath。如果 filepath 是相对路径，则相对于当前路径，也可以指定一个 url 或者本地文件，例如：`file:///user/hive/project/data1`
- 如果没有指定 `LOCAL` ，则hive会使用全路径的url，url 中如果没有制定 schema，则默认使用 `fs.default.name`的值；如果该路径不是绝对路径，则会相对于 `/user/<username> `
- 如果使用 `OVERWRITE` ，则会删除原来的数据，然后导入新的数据，否则，就是追加数据。

需要注意的：
 
- `filepath` 中不能包括子目录
- 如果没有指定 `LOCAL`，则 `filepath` 指向目标表或者分区所在的文件系统。
- 如果需要压缩，则参考 [ CompressedStorage](https://cwiki.apache.org/confluence/display/Hive/CompressedStorage)

## 2.1 测试

### 2.1.1 加载本地文件

a) 加载到普通表中

~~~sql
hive> load data local inpath '/tmp/test.txt' into table test;                              
Copying data from file:/tmp/test.txt
Copying file: file:/tmp/test.txt
Loading data to table default.test
Table default.test stats: [num_partitions: 0, num_files: 1, num_rows: 0, total_size: 16, raw_data_size: 0]
OK
Time taken: 0.572 seconds
~~~

查看hdfs上的数据：

~~~
$ hadoop fs -ls /user/hive/warehouse/test
Found 1 items
-rwxrwxrwt   3 hive hadoop         16 2014-06-09 18:36 /user/hive/warehouse/test/test.txt
~~~

查看表中数据：

~~~sql
hive> select * from test;
OK
1	a
2	b
3	c
4	d
Time taken: 0.562 seconds, Fetched: 4 row(s)
~~~

b) 加载文件到分区表

通常是直接使用 load 命令加载：

~~~
LOAD DATA LOCAL INPATH "/tmp/test.txt" INTO TABLE test_p PARTITION (date=20140722)
~~~

> 注意：如果没有加上 `overwrite` 关键字，则加载相同文件最后会存在多个文件

还有一种方法是：创建分区目录，手动上传文件，最后再添加新的分区，代码如下：

~~~
hadoop fs -mkdir  /user/hive/warehouse/test/date=20140320
ALTER TABLE test_p ADD IF NOT EXISTS PARTITION (date=20140320);

hive hadoop fs -rm /user/hive/warehouse/test/date=20140320/test.txt
hadoop fs -put /tmp/test.txt  /user/hive/warehouse/test/date=20140320
~~~

同样，你也可以查看 hdfs 和表中的数据。

### 2.1.2 加载hdfs上的文件

拷贝 test.txt 为test_1.txt 并将其上传到 `/user/hive/warehouse`:

~~~
$ cp test.txt test_1.txt
$ sudo -u hive hadoop fs -put test_1.txt /user/hive/warehouse
~~~

然后将 `/user/hive/warehouse/test_1.txt` 导入到test表中：

~~~sql
hive> load data inpath '/user/hive/warehouse/test_1.txt' into table test; 
Loading data to table default.test
Table default.test stats: [num_partitions: 0, num_files: 1, num_rows: 0, total_size: 16, raw_data_size: 0]
OK
Time taken: 2.941 seconds
~~~

查看hdfs上的数据：

~~~
$ hadoop fs -ls /user/hive/warehouse/test
Found 2 items
-rwxr-xr-x   3 hive hadoop         16 2014-06-09 18:48 /user/hive/warehouse/test/test.txt
-rwxr-xr-x   3 hive hadoop         16 2014-06-09 18:45 /user/hive/warehouse/test/test_1.txt
~~~

查看表中数据：

~~~sql
hive> select * from test;                                                 
OK
1	a
2	b
3	c
4	d
1	a
2	b
3	c
4	d
Time taken: 0.302 seconds, Fetched: 8 row(s)
~~~

# 3. 插入数据

标准语法：

~~~sql
INSERT OVERWRITE TABLE tablename1 [PARTITION (partcol1=val1, partcol2=val2 ...) [IF NOT EXISTS]] select_statement1 FROM from_statement;

INSERT INTO TABLE tablename1 [PARTITION (partcol1=val1, partcol2=val2 ...)] select_statement1 FROM from_statement;
~~~

扩展语法（多个insert）：

~~~sql
FROM from_statement
INSERT OVERWRITE TABLE tablename1 [PARTITION (partcol1=val1, partcol2=val2 ...) [IF NOT EXISTS]] select_statement1
[INSERT OVERWRITE TABLE tablename2 [PARTITION ... [IF NOT EXISTS]] select_statement2]
[INSERT INTO TABLE tablename2 [PARTITION ...] select_statement2] ...;

FROM from_statement
INSERT INTO TABLE tablename1 [PARTITION (partcol1=val1, partcol2=val2 ...)] select_statement1
[INSERT INTO TABLE tablename2 [PARTITION ...] select_statement2]
[INSERT OVERWRITE TABLE tablename2 [PARTITION ... [IF NOT EXISTS]] select_statement2] ...;
~~~

扩展语法（动态分区insert）：

~~~sql
INSERT OVERWRITE TABLE tablename PARTITION (partcol1[=val1], partcol2[=val2] ...) select_statement FROM from_statement;

INSERT INTO TABLE tablename PARTITION (partcol1[=val1], partcol2[=val2] ...) select_statement FROM from_statement;
~~~

说明：

- INSERT OVERWRITE 会覆盖存在的数据
- 输出的格式和序列化类取决于表的元数据
- [hive 0.13.0](https://issues.apache.org/jira/browse/HIVE-1180)之后，select语句可以使用 CTEs 表达式，语法请参考 [ SELECT syntax](https://cwiki.apache.org/confluence/display/Hive/LanguageManual+Select#LanguageManualSelect-SelectSyntax)，示例见 [Common Table Expression](https://cwiki.apache.org/confluence/display/Hive/Common+Table+Expression#CommonTableExpression-CTEinViews,CTAS,andInsertStatements)

**Dynamic Partition Inserts**

dynamic partition inserts在hive 0.6.0中引入。相关的配置参数有：

~~~
hive.exec.dynamic.partition
hive.exec.dynamic.partition.mode
hive.exec.max.dynamic.partitions.pernode
hive.exec.max.dynamic.partitions
hive.exec.max.created.files
hive.error.on.empty.partition
~~~

一个示例：

~~~sql
FROM page_view_stg pvs
INSERT OVERWRITE TABLE page_view PARTITION(dt='2008-06-08', country)
       SELECT pvs.viewTime, pvs.userid, pvs.page_url, pvs.referrer_url, null, null, pvs.ip, pvs.cnt
~~~

# 4. 导出数据

标准语法：

~~~
INSERT OVERWRITE [LOCAL] DIRECTORY directory1
  [ROW FORMAT row_format] [STORED AS file_format] (Note: Only available starting with Hive 0.11.0)
  SELECT ... FROM ...
~~~

扩展语法（多个insert）：

~~~~~~
FROM from_statement
INSERT OVERWRITE [LOCAL] DIRECTORY directory1 select_statement1
[INSERT OVERWRITE [LOCAL] DIRECTORY directory2 select_statement2] ...
~~~

row_format相关语法：

~~~sql
DELIMITED [FIELDS TERMINATED BY char [ESCAPED BY char]] [COLLECTION ITEMS TERMINATED BY char]
        [MAP KEYS TERMINATED BY char] [LINES TERMINATED BY char]
        [NULL DEFINED AS char](Note: Only available starting with Hive 0.13)
~~~

说明：

- Directory 可以是一个全路径的 url。
- 如果指定 `LOCAL`，则会将数据写到本地文件系统。
- 输出的数据序列化为 text 格式，分隔符为 `^A`，行于行之间通过换行符连接。如果存在不是基本类型的列，则这些列将被序列化为 JSON 格式。
- 在 Hive 0.11.0 可以输出字段的分隔符，之前版本的默认为 `^A`。

## 4.1 测试;

### 4.1.1 导出到本地文件系统

~~~
hive> insert overwrite local directory '/tmp/test' select * from test;
Total MapReduce jobs = 1
Launching Job 1 out of 1
Number of reduce tasks is set to 0 since there's no reduce operator
Starting Job = job_1402248601715_0016, Tracking URL = http://cdh1:8088/proxy/application_1402248601715_0016/
Kill Command = /usr/lib/hadoop/bin/hadoop job  -kill job_1402248601715_0016
Hadoop job information for Stage-1: number of mappers: 1; number of reducers: 0
2014-06-09 19:25:12,896 Stage-1 map = 0%,  reduce = 0%
2014-06-09 19:25:20,380 Stage-1 map = 100%,  reduce = 0%, Cumulative CPU 0.99 sec
2014-06-09 19:25:21,433 Stage-1 map = 100%,  reduce = 0%, Cumulative CPU 0.99 sec
MapReduce Total cumulative CPU time: 990 msec
Ended Job = job_1402248601715_0016
Copying data to local directory /tmp/test
Copying data to local directory /tmp/test
MapReduce Jobs Launched: 
Job 0: Map: 1   Cumulative CPU: 0.99 sec   HDFS Read: 305 HDFS Write: 32 SUCCESS
Total MapReduce CPU Time Spent: 990 msec
OK
Time taken: 18.438 seconds
~~~

导出后的数据预览如下：

~~~
[/tmp]# vim test/000000_0 
1^Aa
2^Ab
3^Ac
4^Ad
1^Aa
2^Ab
3^Ac
4^Ad
~~~

可以看到数据中的列与列之间的分隔符是`^A`(ascii码是`\00001`)，如果想修改分隔符，可以做如下修改：

~~~sql
hive> insert overwrite local directory '/tmp/test' row format delimited fields terminated by ',' select * from test;
~~~

再来查看数据：

~~~
vim test/000000_3 
1,a
2,b
3,c
4,d
1,a
2,b
3,c
4,d
~~~

### 4.1.2 导出到 HDFS 中

~~~
hive> insert overwrite  directory '/user/hive/tmp' select * from test;
~~~

注意：

和导出文件到本地文件系统的HQL少一个local，数据的存放路径不一样了。

### 4.1.3 导出到Hive的另一个表中

在实际情况中，表的输出结果可能太多，不适于显示在控制台上，这时候，将Hive的查询输出结果直接存在一个新的表中是非常方便的，我们称这种情况为CTAS（ `create table .. as select`）如下：

~~~
hive> create table test2 as select * from test;
~~~

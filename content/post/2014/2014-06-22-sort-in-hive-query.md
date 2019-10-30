---
layout: post

title:  Hive中的排序语法
date: 2014-06-22T08:00:00+08:00

description: 测试hive中各种排序语法。

keywords:  

categories: [ hive ]

tags: [hive]

published: true

---

# ORDER BY 

hive中的ORDER BY语句和关系数据库中的sql语法相似。他会对查询结果做全局排序，这意味着所有的数据会传送到一个Reduce任务上，这样会导致在大数量的情况下，花费大量时间。

与数据库中 ORDER BY 的区别在于在`hive.mapred.mode = strict`模式下，必须指定 limit 否则执行会报错。

~~~sql
hive> set hive.mapred.mode=strict;
hive> select * from test order by id;
FAILED: SemanticException 1:28 In strict mode, if ORDER BY is specified, LIMIT must also be specified. Error encountered near token 'id'
~~~

例子：

~~~
hive> set hive.mapred.mode=unstrict;
hive> select * from test order BY id ;
MapReduce Jobs Launched: 
Job 0: Map: 1  Reduce: 1   Cumulative CPU: 1.88 sec   HDFS Read: 305 HDFS Write: 32 SUCCESS
Total MapReduce CPU Time Spent: 1 seconds 880 msec
OK
1	a
1	a
2	b
2	b
3	c
3	c
4	d
4	d
Time taken: 24.609 seconds, Fetched: 8 row(s)
~~~

从上面的日志可以看到：启动了一个reduce进行全局排序。

# SORT BY

SORT BY不是全局排序，其在数据进入reducer前完成排序，因此在有多个reduce任务情况下，SORT BY只能保证每个reduce的输出有序，而不能保证全局有序。

> 注意：SORT BY 不受 `hive.mapred.mode` 参数的影响

你可以通过设置`mapred.reduce.tasks`的值来控制reduce的数，然后对reduce输出的结果做二次排序。

例子：

~~~sql
hive> set mapred.reduce.tasks=3;
hive> select * from test sort BY id ; 
MapReduce Jobs Launched: 
Job 0: Map: 1  Reduce: 3   Cumulative CPU: 4.48 sec   HDFS Read: 305 HDFS Write: 32 SUCCESS
Total MapReduce CPU Time Spent: 4 seconds 480 msec
OK
1	a
2	b
3	c
4	d
2	b
3	c
4	d
1	a
Time taken: 29.574 seconds, Fetched: 8 row(s)
~~~

从上面的日志可以看到：启动了三个reduce分别排序，最后的结果不是有序的。


# DISTRIBUTE BY with SORT BY

DISTRIBUTE BY能够控制map的输出在reduce中如何划分。其可以按照指定的字段对数据进行划分到不同的输出reduce/文件中。

DISTRIBUTE BY和GROUP BY有点类似，DISTRIBUTE BY控制reduce如何处理数据，而SORT BY控制reduce中的数据如何排序。

> 注意：hive要求DISTRIBUTE BY语句出现在SORT BY语句之前。

例子：

~~~sql
hive> select * from test distribute BY id sort by id asc;  
Job 0: Map: 1  Reduce: 3   Cumulative CPU: 4.24 sec   HDFS Read: 305 HDFS Write: 32 SUCCESS
Total MapReduce CPU Time Spent: 4 seconds 240 msec
OK
3	c
3	c
1	a
1	a
4	d
4	d
2	b
2	b
Time taken: 29.89 seconds, Fetched: 8 row(s)
~~~

从上面的日志可以看到：启动了三个reduce分别排序，最后的结果不是有序的。

# CLUSTER BY来代替

当DISTRIBUTE BY的字段和SORT BY的字段相同时，可以用CLUSTER BY来代替 DISTRIBUTE BY with SORT BY。

> 注意：CLUSTER BY不能添加desc或者asc。

例子：

~~~sql 
hive> select * from test cluster by id asc;              
FAILED: ParseException line 1:33 extraneous input 'asc' expecting EOF near '<EOF>'
~~~

~~~sql
hive> select * from test cluster by id ;
MapReduce Jobs Launched: 
Job 0: Map: 1  Reduce: 3   Cumulative CPU: 4.58 sec   HDFS Read: 305 HDFS Write: 32 SUCCESS
Total MapReduce CPU Time Spent: 4 seconds 580 msec
OK
3	c
3	c
1	a
1	a
4	d
4	d
2	b
2	b
Time taken: 30.646 seconds, Fetched: 8 row(s)
~~~ 

从上面的日志可以看到：启动了三个reduce分别排序，最后的结果不是有序的。

**怎样让最后的结果是有序的呢？**

可以这样做：

~~~sql
hive> select a.* from (select * from test cluster by id ) a order by a.id ;
MapReduce Jobs Launched: 
Job 0: Map: 1  Reduce: 3   Cumulative CPU: 4.5 sec   HDFS Read: 305 HDFS Write: 448 SUCCESS
Job 1: Map: 1  Reduce: 1   Cumulative CPU: 1.96 sec   HDFS Read: 1232 HDFS Write: 32 SUCCESS
Total MapReduce CPU Time Spent: 6 seconds 460 msec
OK
1	a
1	a
2	b
2	b
3	c
3	c
4	d
4	d
Time taken: 118.261 seconds, Fetched: 8 row(s)
~~~ 

# 总结

- ORDER BY是全局排序，但在数据量大的情况下，花费时间会很长
- SORT BY是将reduce的单个输出进行排序，不能保证全局有序
- DISTRIBUTE BY可以按指定字段将数据划分到不同的reduce中
- 当DISTRIBUTE BY的字段和SORT BY的字段相同时，可以用CLUSTER BY来代替 DISTRIBUTE BY with SORT BY。

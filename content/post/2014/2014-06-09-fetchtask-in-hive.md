---
layout: post

title: Hive中的FetchTask任务
date: 2014-06-09T08:00:00+08:00

description: Hive中有各种各样的Task任务，其中FetchTask算是最简单的一种了。FetchTask不同于MapReduce任务，它不会启动mapreduce，而是直接读取文件，输出结果。当你执行简单的`select * with limit`语句的时候，其不会运行mapreduce任务。

keywords: Hive中的FetchTask任务

categories: [ hive ]

tags: [hive,mapreduce]

published: true

---

Hive中有各种各样的Task任务，其中FetchTask算是最简单的一种了。FetchTask不同于MapReduce任务，它不会启动mapreduce，而是直接读取文件，输出结果。当你执行简单的`select * with limit`语句的时候，其不会运行mapreduce任务。

例如，运行下面语句不会出现mapreduce任务（说明：t表有一个字段，id为int类型，该表没有数据）：

~~~sql
hive> select * from t limit 1;            
OK
Time taken: 2.466 seconds
~~~

去掉limit语句，再执行一次，结果如下：

~~~sql
hive> select * from t ;       
OK
Time taken: 0.097 seconds
~~~

从结果来看，这种查询应该是有个默认的limit限制吧。

如果修改查询语句，只查询某一些列呢？

~~~sql
hive> select id from t ;                 
Total MapReduce jobs = 1
Launching Job 1 out of 1
Number of reduce tasks is set to 0 since there is no reduce operator
Starting Job = job_1402248601715_0004, Tracking URL = http://cdh1:8088/proxy/application_1402248601715_0004/
Kill Command = /usr/lib/hadoop/bin/hadoop job  -kill job_1402248601715_0004
Hadoop job information for Stage-1: number of mappers: 1; number of reducers: 0
2014-06-09 11:12:54,817 Stage-1 map = 0%,  reduce = 0%
2014-06-09 11:13:15,790 Stage-1 map = 100%,  reduce = 0%, Cumulative CPU 2.96 sec
2014-06-09 11:13:16,982 Stage-1 map = 100%,  reduce = 0%, Cumulative CPU 2.96 sec
MapReduce Total cumulative CPU time: 2 seconds 960 msec
Ended Job = job_1402248601715_0004
MapReduce Jobs Launched: 
Job 0: Map: 1   Cumulative CPU: 2.96 sec   HDFS Read: 257 HDFS Write: 0 SUCCESS
Total MapReduce CPU Time Spent: 2 seconds 960 msec
OK
Time taken: 51.496 seconds
~~~

查看上面运行日志，可以看到该次查询启动了mapreduce任务，mapper数为1，没有reducer任务。有没有一种方法，让上面语句也不允许mapreduce任务呢？

答案是肯定的！这就要用到 `hive.fetch.task.conversion` 参数：

~~~xml
<property>
  <name>hive.fetch.task.conversion</name>
  <value>minimal</value>
  <description>
    Some select queries can be converted to single FETCH task 
    minimizing latency.Currently the query should be single 
    sourced not having any subquery and should not have
    any aggregations or distincts (which incurrs RS), 
    lateral views and joins.
    1. minimal : SELECT STAR, FILTER on partition columns, LIMIT only
    2. more    : SELECT, FILTER, LIMIT only (+TABLESAMPLE, virtual columns)
  </description>
</property>
~~~

该参数默认值为minimal，表示运行“select * ”并带有limit查询时候，会将其转换为FetchTask；如果参数值为more，则select某一些列并带有limit条件时，也会将其转换为FetchTask任务。当然，还有前天条件：单一数据源，即输入来源一个表或者分区；没有子查询；没有聚合运算和distinct；不能用于视图和join。

测试一下，先讲其参数值设为more，再运行：

~~~sql
hive> set hive.fetch.task.conversion=more;
hive> select id from t limit 1;           
OK
Time taken: 0.242 seconds
hive> select id from t ;                  
OK
Time taken: 0.496 seconds
~~~

最后，在hive源码中搜索一下`hive.fetch.task.conversion`，可以找到下面代码(来自SimpleFetchOptimizer类):

~~~java
// returns non-null FetchTask instance when succeeded
  @SuppressWarnings("unchecked")
  private FetchTask optimize(ParseContext pctx, String alias, TableScanOperator source)
      throws HiveException {
    String mode = HiveConf.getVar(
        pctx.getConf(), HiveConf.ConfVars.HIVEFETCHTASKCONVERSION);

    boolean aggressive = "more".equals(mode);
    FetchData fetch = checkTree(aggressive, pctx, alias, source);
    if (fetch != null) {
      int limit = pctx.getQB().getParseInfo().getOuterQueryLimit();
      FetchWork fetchWork = fetch.convertToWork();
      FetchTask fetchTask = (FetchTask) TaskFactory.get(fetchWork, pctx.getConf());
      fetchWork.setSink(fetch.completed(pctx, fetchWork));
      fetchWork.setSource(source);
      fetchWork.setLimit(limit);
      return fetchTask;
    }
    return null;
  }
~~~

从源码中，简单分析可以知道，hive优化器在做FetchTask优化的时候，如果`hive.fetch.task.conversion`为more，则会做一些优化。


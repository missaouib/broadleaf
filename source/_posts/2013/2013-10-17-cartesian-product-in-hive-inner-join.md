---
layout: post
title: Hive连接产生笛卡尔集
description: 工作中遇到一个一场，是关于hive连接产生笛卡尔集
category: hive
tags: [hive]
---

在使用hive过程中遇到这样的一个异常：

~~~
FAILED: ParseException line 1:18 Failed to recognize predicate 'a'. Failed rule: 'kwInner' in join type specifier
~~~

执行的hql语句如下：

~~~
[root@javachen.com ~]# hive -e 'select a.* from t a, t b where a.id=b.id'
~~~

从异常信息中很难看出出错原因，hive.log中也没有打印出详细的异常对战信息。改用jdbc连接hive-server2，可以看到hive-server2中提示如下异常信息：

~~~
13/10/17 09:57:48 ERROR ql.Driver: FAILED: ParseException line 1:18 Failed to recognize predicate 'a'. Failed rule: 'kwInner' in join type specifier

org.apache.hadoop.hive.ql.parse.ParseException: line 1:18 Failed to recognize predicate 'a'. Failed rule: 'kwInner' in join type specifier

	at org.apache.hadoop.hive.ql.parse.ParseDriver.parse(ParseDriver.java:446)
	at org.apache.hadoop.hive.ql.Driver.compile(Driver.java:441)
	at org.apache.hadoop.hive.ql.Driver.compile(Driver.java:349)
	at org.apache.hadoop.hive.ql.Driver.compileAndRespond(Driver.java:355)
	at org.apache.hive.service.cli.operation.SQLOperation.prepare(SQLOperation.java:95)
	at org.apache.hive.service.cli.operation.SQLOperation.prepare(SQLOperation.java:76)
	at org.apache.hive.service.cli.operation.SQLOperation.run(SQLOperation.java:114)
	at org.apache.hive.service.cli.session.HiveSessionImpl.executeStatement(HiveSessionImpl.java:194)
	at org.apache.hive.service.cli.CLIService.executeStatement(CLIService.java:155)
	at org.apache.hive.service.cli.thrift.ThriftCLIService.ExecuteStatement(ThriftCLIService.java:191)
	at org.apache.hive.service.cli.thrift.TCLIService$Processor$ExecuteStatement.getResult(TCLIService.java:1193)
	at org.apache.hive.service.cli.thrift.TCLIService$Processor$ExecuteStatement.getResult(TCLIService.java:1)
	at org.apache.thrift.ProcessFunction.process(ProcessFunction.java:39)
	at org.apache.thrift.TBaseProcessor.process(TBaseProcessor.java:39)
	at org.apache.hive.service.cli.thrift.TSetIpAddressProcessor.process(TSetIpAddressProcessor.java:38)
	at org.apache.thrift.server.TThreadPoolServer$WorkerProcess.run(TThreadPoolServer.java:206)
	at java.util.concurrent.ThreadPoolExecutor$Worker.runTask(ThreadPoolExecutor.java:886)
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:908)
	at java.lang.Thread.run(Thread.java:662)
~~~

<!-- more -->

从异常信息可以看到是在编译hql语句进行语法解析时出现了错误，到底为什么会出现`Failed rule: 'kwInner' in join type specifier`这样的异常信息呢？

在eclipse中查找关键字并没有找到相应代码，在[Hive.g](http://svn.apache.org/repos/asf/hive/tags/release-0.10.0/ql/src/java/org/apache/hadoop/hive/ql/parse/Hive.g) 中查找关键字“kwInner”，可以看到如下内容：

~~~
joinToken
@init { msgs.push("join type specifier"); }
@after { msgs.pop(); }
    :
      KW_JOIN                     -> TOK_JOIN
    | kwInner  KW_JOIN            -> TOK_JOIN
    | KW_CROSS KW_JOIN            -> TOK_CROSSJOIN
    | KW_LEFT  KW_OUTER KW_JOIN   -> TOK_LEFTOUTERJOIN
    | KW_RIGHT KW_OUTER KW_JOIN   -> TOK_RIGHTOUTERJOIN
    | KW_FULL  KW_OUTER KW_JOIN   -> TOK_FULLOUTERJOIN
    | KW_LEFT  KW_SEMI  KW_JOIN   -> TOK_LEFTSEMIJOIN
    ;
~~~

从上面可以看出hive支持的连接包括：

- join
- inner join
- cross join (as of Hive 0.10)
- left outer join
- right outer join
- full outer join
- left semi join

kwInner为什么是小写呢，其含义是什么呢？搜索关键字，找到如下代码：

~~~
kwInner
:
{input.LT(1).getText().equalsIgnoreCase("inner")}? Identifier;
~~~

上面的大概意思是找到输入左边的内容并判断其值在忽略大小写情况下是否等于inner，大概意思是hql语句中缺少inner关键字吧？修改下hql语句如下，然后执行：

~~~
[root@javachen.com ~]#  hive -e 'select a.* from t a inner join t b where a.id=b.id'
~~~

修改后的hql语句能够正常运行，并且变成了内连接。`在JION接连查询中没有ON连接key而通过WHERE条件语句会产生笛卡尔集。`

Hive本身是不支持笛卡尔集的，不能用`select T1.*, T2.* from table1, table2`这种语法。但有时候确实需要用到笛卡尔集的时候，可以用下面的语法来实现同样的效果：

~~~
select T1.*, T2.* from table1 T1 join table2 T2 where 1=1;
~~~

注意在Hive的Strict模式下不能用这种语法，因为这样会产生笛卡尔集，而这种模式禁止产生笛卡尔集。需要先用`set hive.mapred.mode=nonstrict;`设为非strict模式就可以用了，或者将where改为on连接。

~~~
select T1.*, T2.* from table1 T1 join table2 T2 on  T1.id=T2.id;
~~~


# 关于Strict Mode

Hive中的严格模式可以防止用户发出（可以有问题）的查询无意中造成不良的影响。 将`hive.mapred.mode`设置成strict可以禁止三种类型的查询： 

1）、在一个分区表上，如果没有在WHERE条件中指明具体的分区，那么这是不允许的，换句话说，不允许在分区表上全表扫描。这种限制的原因是分区表通常会持非常大的数据集并且可能数据增长迅速，对这样的一个大表做全表扫描会消耗大量资源，必须要再WHERE过滤条件中具体指明分区才可以执行成功的查询。

2）、第二种是禁止执行有ORDER BY的排序要求但没有LIMIT语句的HiveQL查询。因为ORDER BY全局查询会导致有一个单一的reducer对所有的查询结果排序，如果对大数据集做排序，这将导致不可预期的执行时间，必须要加上limit条件才可以执行成功的查询。

3）、第三种是禁止产生笛卡尔集。在JION接连查询中没有ON连接key而通过WHERE条件语句会产生笛卡尔集，需要改为JOIN...ON语句。

# 参考文章

- [1] [深入学习《Programing Hive》：Tuning](http://flyingdutchman.iteye.com/blog/1871983)
- [2] [Hive Tips](http://blog.hesey.net/2012/04/hive-tips.html)


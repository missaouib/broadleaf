---
layout: post

title:  MapReduce任务运行过程

description: 记录MapReduce任务运行过程。

keywords:  

category: mapreduce

tags: [mapreduce]

published: true

---

下图是MapReduce任务运行过程的一个图：

![](http://zhaomingtai.u.qiniudn.com/mapredurce1.png)

Map-Reduce的处理过程主要涉及以下四个部分：

- 客户端Client：用于提交Map-reduce任务job
- JobTracker：协调整个job的运行，其为一个Java进程，其main class为JobTracker
- TaskTracker：运行此job的task，处理input split，其为一个Java进程，其main class为TaskTracker
- HDFS：hadoop分布式文件系统，用于在各个进程间共享Job相关的文件

上图中主要包括以下过程：

- 提交作业
- 作业初始化
- 任务分配
- 执行任务
- 进度和状态更新
- 完成作业

# 1. 提交作业

## 运行Shell命令

使用hadoop提供的命令行或者通过编程接口提交任务，命令行方式如下：

~~~bash
$ HADOOP_HOME/bin/hadoop jar job.jar \  
    -D mapred.job.name="task-job" \  
    -D mapred.reduce.tasks=3 \  
    -files=blacklist.txt,whitelist.xml \  
    -libjars=aaa.jar \  
    -archives=bbb.zip \  
    -input /test/input \  
    -output /test/output 
~~~

当用户按上述命令格式提交作业后，命令行脚本会调用JobClient.runJob()方法提交作业

## 作业文件上传

JobClient将作业提交到JobTracker节点上之前，需要作业写初始化工作。初始化工作由 `JobClient.submitJobInternal(job)` 实现，这些初始化包括获取作业的jobId、创建HDFS目录、上传作业以及生成所有的InputSplit分片的相关信息等。
 
MapReduce的作业文件的上传和下载都是由DistributedCache透明完成的，它是Hadoop专门开发的数据分发工具。

JobClient上传文件时可以修改文件副本数（通过参数 `mapred.submit.replication` 指定，默认值为10），这样的话可以分摊负载以避免产生访问热点。

## 产生InputSplit文件

作业提交后，JobClient会调用InputFormat的getSplits()方法生成相关的split分片信息，该信息包括InputSplit元数据信息和原始的InputSplit信息，其中元数据信息被JobTracker使用，第二部分在Map Task初始化时由Mapper使用来获取自己要处理的数据，这两部分数据被保存到job.split文件和job.splitmetainfo文件中。 

## 作业提交到JobTracker

调用JobTracker的submitJob()方法将作业提交。在这一阶段会依次进行如下操作： 

 - 1）、为作业创建JobInProgress对象。JobTracker会为用户提交的每一个作业创建一个JobInProgress对象，这个对象维护了作业的运行时信息，主要用于跟踪正在运行的作业的状态和进度； 
 - 2）、检查用户是否具有指定队列的作业提交权限。Hadoop以队列为单位来管理作业和资源，每个队列分配有一定亮的资源，管理严可以为每个队列指定哪些用户有权限提交作业； 
 - 3）、检查作业配置的内存使用量是否合理。用户在提交作业时，可已分别通过参数 `mapred.job.map.memory.mb` 和`mapred.job.reduce.memory.mb` 指定Map Task和Reduce Task的内存使用量，而管理员可以给集群中的Map Task和Reduce Task分别设置中的内存使用量，一旦用户配置的内存使用量超过总的内存限制，作业就会提交失败； 
 - 4）、JobTracker收到提交的作业后，并不会马上对其进行初始化，而是会交给TaskScheduler调度器，由他按照一定的策略对作业做初始化操作。

JobTracker采用了观察者模式将“提交新作业”这一事件告诉TaskScheduler

提交任务后，runJob每隔一秒钟轮询一次job的进度，将进度返回到命令行，直到任务运行完毕。

# 2. 作业初始化

调度器调用JobTracker.initJob()方法来对新作业做初始化的。Hadoop将每个作业分节成4中类型的任务：Setup Task，Map Task，Reduce Task和Cleanup Task，它们的运行时信息由TaskInProgress维护，因此，从某个方面将，创建这些任务就是创建TaskInProgress对象。 

- `Setup Task`。作业初始化标志性任务，它进行一些很简单的作业初始化工作。该类型任务又分为Map Setup Task和Reduce Setup Task两种，并且只能运行一次。 
- `Map Task`。Map阶段的数据处理任务。 其数目及对应的处理数据分片由应用程序中的InputFormat中间确定。
- `Reduce Task`。Reduce阶段的处理数据的任务。其数目可以由用户通过参数 `mapred.reduce.tasks` 指定。Hadoop刚开始的时候只会调度Map Task任务，直到Map Task完成数目达到由参数 `mapred.reduce.slowstart.completed.maps`指定的百分比（默认值为0.05，即百分之5）后，才开始调度Reduce Task。 
- `Cleanup Task`。作业结束的标志性任务，主要是做一些作业清理的工作，比如删除作业在运行中产生的一些零食目录和数据等信息。

说明：可以通过参数 `mapred.committer.job.setup.cleanup.needed` 配置是否为作业创建Setup/Cleanup Task，以避免他们拖慢作业执行进度且降低作业的可靠性。

# 3. 任务分配

Tasktracker 和 JobTracker 通过心跳通信分配一个任务

TaskTracker 定期发送心跳，告知 JobTracker, tasktracker 是否还存活，并充当两者之间的消息通道。

TaskTracker 主动向 JobTracker 询问是否有作业。若自己有空闲的 solt,就可在心跳阶段得到 JobTracker 发送过来的 Map 任务或 Reduce 任务。对于 map 任务和 task 任务，TaskTracker 有固定数量的任务槽，准确数量由 tasktracker 核的个数核内存的大小来确定。默认调度器在处理 reduce 任务槽之前，会填充满空闲的 map 任务槽，因此，如果 tasktracker 至少有一个空闲的 map 任务槽，tasktracker 会为它选择一个 map 任务，否则选择一个 reduce 任务。选择 map 任务时，jobTracker 会考虑数据本地化（任务运行在输入分片所在的节点），而 reduce 任务不考虑数据本地化。任务还可能是机架本地化。

# 4. 执行任务

tasktracker 执行任务大致步骤：

- 被分配到一个任务后，从共享文件中把作业的jar复制到本地，并将程序执行需要的全部文件（配置信息、数据分片）复制到本地
- 为任务新建一个本地工作目录
- 内部类TaskRunner实例启动一个新的jvm运行任务

# 5. 进度和状态更新

- 状态包括：作业或认为的状态（成功，失败，运行中）、map 和 reduce 的进度、作业计数器的值、状态消息或描述
- task 运行时，将自己的状态发送给 TaskTracker,由 TaskTracker 心跳机制向 JobTracker 汇报
- 状态进度由计数器实现

![](http://zhaomingtai.u.qiniudn.com/updateStatusMapredurce.png)

# 6. 完成作业

当JobTracker获得最后一个task的运行成功的报告后，将job得状态改为成功。

当JobClient从JobTracker轮询的时候，发现此job已经成功结束，则向用户打印消息，从runJob函数中返回。

# 7. 总结

以上过程通过时序图来表达过程如下：

# 8. 参考资料

- [1] [Hadoop MapReduce 工作机制](http://kangfoo.u.qiniudn.com/article/images/03/hadoop-mapreduce--gong-zuo-ji-zhi/)

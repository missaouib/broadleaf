---
layout: post
title:  Hive源码分析：Driver类运行过程
description: 记录hive Driver类运行过程，本文的源码分析基于hive-0.12.0-cdh5.0.1。
category: hive
tags: [hadoop, hive]
---

说明：

本文的源码分析基于hive-0.12.0-cdh5.0.1。

# 概括

从《[hive cli的入口类](/images/08/21/hive-CliDriver.html)》中可以知道hive中处理hive命令的处理器一共有以下几种：

~~~
（1）set       SetProcessor，设置修改参数,设置到SessionState的HiveConf里。 
（2）dfs       DfsProcessor，使用hadoop的FsShell运行hadoop的命令。 
（3）add       AddResourceProcessor，添加到SessionState的resource_map里，运行提交job的时候会写入Hadoop的Distributed Cache。 
（4）delete    DeleteResourceProcessor，从SessionState的resource_map里删除。
（5）reset     RestResourceProcessor，重置终端输出
（6）其他命令   Driver 
~~~

Driver类的主要作用是用来编译并执行hive命令，然后返回执行结果。这里主要分析Driver类的运行逻辑，其时序图如下：

![hive-driver](/images/Hive-Driver-sequence.jpg)

从时序图上可以看出有以下步骤：

- run方法调用内部方法runInternal
- 在runInternal方法内部先，调用HiveDriverRunHookContext的preDriverRun方法
- 调用compileInternal方法
- compileInternal方法内部调用compile方法
- compile方法内，先调用HiveSemanticAnalyzerHookContext的preAnalyze方法
- 再进行语法分析，调用BaseSemanticAnalyzer的analyze方法
- 调用HiveSemanticAnalyzerHookContext的postAnalyze方法
- 再进行语法校验，调用BaseSemanticAnalyzer的validate方法
- compileInternal方法运行完成之后，调用checkConcurrency方法
- 再来运行execute方法，该方法用于运行任务
- 最后，调用HiveDriverRunHookContext的postDriverRun方法

# Driver初始化

在继续分析之前，需要弄清楚Driver类初始化时做了什么事情。

在CliDriver的`processCmd(String cmd)`方法中可以看到proc是在CommandProcessorFactory类中new出来的并调用了init方法。

~~~java
} else { // local mode
      CommandProcessor proc = CommandProcessorFactory.get(tokens[0], (HiveConf) conf);
      ret = processLocalCmd(cmd, proc, ss);
}
~~~

CommandProcessorFactory.get方法代码片段：

~~~java
if (conf == null) {
return new Driver();
}

Driver drv = mapDrivers.get(conf);
if (drv == null) {
drv = new Driver();
mapDrivers.put(conf, drv);
}
drv.init();
~~~

init方法和构造方法代码如下：

~~~java
public void init() {
	Operator.resetId();
}

public Driver() {
    if (SessionState.get() != null) {
      conf = SessionState.get().getConf();
    }
  }
~~~

从上可以看出仅仅是初始化了conf属性和重置了Operator的id。

## run方法过程

1、调用runInternal方法，根据该方法返回值判断是否出错。

2、runInternal方法内，运行HiveDriverRunHook的前置方法preDriverRun

3、判断是否需要编译，如果需要，则运行`compileInternal(command)`方法，并根据返回值判断是否该释放Hive锁。hive中可以配置`hive.support.concurrency`值为true并设置zookeeper的服务器地址和端口，基于zookeeper实现分布式锁以支持hive的多并发访问。这部分内容不是本文重点故不做介绍。

> `compileInternal(command)`方法内部代码说明见下文。

4、判断是否需要对Task加锁。如果需要，则调用checkConcurrency方法。

5、调用execute()方法执行任务。

- 执行计划开始：`plan.setStarted();`
- 先运行ExecuteWithHookContext的前置hook方法，ExecuteWithHookContext类型有三种：前置、运行失败、后置。
- 然后创建DriverContext用于维护正在运行的task任务，正在运行的task任务会添加到队列runnable中去。
- 其次，在while循环中遍历队列中的任务，然后启动任务让其执行，并且轮训任务执行结果，如果任务运行完成，则将其从running中删除并将当前任务的子任务加入队列中；如果运行失败，则会启动备份的任务，并运行失败的hook。

~~~java
while (runnable.peek() != null && running.size() < maxthreads) {
  Task<? extends Serializable> tsk = runnable.remove();
  launchTask(tsk, queryId, noName, running, jobname, jobs, driverCxt);
}
~~~

- 在launchTask方法中，先判断是否支持并发执行，如果支持则调用TaskRunner的start()方法，否则调用`tskRun.runSequential()`方法顺序执行，只有当是MapReduce任务时，才执行并发执行：

~~~java
	public void launchTask(Task<? extends Serializable> tsk, String queryId, boolean noName,
      Map<TaskResult, TaskRunner> running, String jobname, int jobs, DriverContext cxt) {

    if (SessionState.get() != null) {
      SessionState.get().getHiveHistory().startTask(queryId, tsk, tsk.getClass().getName());
    }
    if (tsk.isMapRedTask() && !(tsk instanceof ConditionalTask)) {
      if (noName) {
        conf.setVar(HiveConf.ConfVars.HADOOPJOBNAME, jobname + "(" + tsk.getId() + ")");
      }
      cxt.incCurJobNo(1);
      console.printInfo("Launching Job " + cxt.getCurJobNo() + " out of " + jobs);
    }
    tsk.initialize(conf, plan, cxt);
    TaskResult tskRes = new TaskResult();
    TaskRunner tskRun = new TaskRunner(tsk, tskRes);

    // Launch Task
    if (HiveConf.getBoolVar(conf, HiveConf.ConfVars.EXECPARALLEL) && tsk.isMapRedTask()) {
      // Launch it in the parallel mode, as a separate thread only for MR tasks
      tskRun.start();
    } else {
      tskRun.runSequential();
    }
    running.put(tskRes, tskRun);
    return;
  }
~~~

最后任务的执行情况，就要看具体的`Task<? extends Serializable>`的实现类的逻辑了。

- 执行计划完成：`plan.setDone();`

6、运行HiveDriverRunHook的后置方法postDriverRun

## compileInternal方法过程

1、保存当前查询状态

~~~java
QueryState queryState = new QueryState();

if (plan != null) {
  close();
  plan = null;
}

if (resetTaskIds) {
  TaskFactory.resetId();
}
saveSession(queryState);
~~~

QueryState中保存了HiveOperation以及当前查询语句或者命令。

2、创建Context上下文

~~~java
command = new VariableSubstitution().substitute(conf,command);
ctx = new Context(conf);
ctx.setTryCount(getTryCount());
ctx.setCmd(command);
ctx.setHDFSCleanup(true);
~~~

3、创建ParseDriver对象，然后解析命令、生成AST树。语法和词法分析内容，不是本文重点故不做介绍。

~~~java
ParseDriver pd = new ParseDriver();
ASTNode tree = pd.parse(command, ctx);
tree = ParseUtils.findRootNonNullToken(tree);
~~~

简单归纳来说，解析程包括如下：

- 词法分析，生成AST树，ParseDriver完成。 
- 分析AST树，AST拆分成查询子块，信息记录在QB，这个QB在下面几个阶段都需要用到，SemanticAnalyzer.doPhase1完成。 
- 从metastore中获取表的信息，SemanticAnalyzer.getMetaData完成。 
- 生成逻辑执行计划，SemanticAnalyzer.genPlan完成。 
- 优化逻辑执行计划，Optimizer完成，ParseContext作为上下文信息进行传递。 
- 生成物理执行计划，SemanticAnalyzer.genMapRedTasks完成。 
- 物理计划优化，PhysicalOptimizer完成，PhysicalContext作为上下文信息进行传递。

4、读取环境变量，如果配置了语法分析的hook，参数为：`hive.semantic.analyzer.hook`，则:先用反射得到`AbstractSemanticAnalyzerHook`的集合，调用`hook.preAnalyze(hookCtx, tree)`方法,然后再调用`sem.analyze(tree, ctx)`方法，该方法才是用来作语法分析的,最后再调用`hook.postAnalyze(hookCtx, tree)`方法执行一些用户定义的后置操作；

否则，直接调用`sem.analyze(tree, ctx)`进行语法分析。

~~~java
  BaseSemanticAnalyzer sem = SemanticAnalyzerFactory.get(conf, tree);
  List<AbstractSemanticAnalyzerHook> saHooks =
      getHooks(HiveConf.ConfVars.SEMANTIC_ANALYZER_HOOK,
               AbstractSemanticAnalyzerHook.class);

  // Do semantic analysis and plan generation
  if (saHooks != null) {
    HiveSemanticAnalyzerHookContext hookCtx = new HiveSemanticAnalyzerHookContextImpl();
    hookCtx.setConf(conf);
    hookCtx.setUserName(userName);
    for (AbstractSemanticAnalyzerHook hook : saHooks) {
      tree = hook.preAnalyze(hookCtx, tree);
    }
    sem.analyze(tree, ctx);
    hookCtx.update(sem);
    for (AbstractSemanticAnalyzerHook hook : saHooks) {
      hook.postAnalyze(hookCtx, sem.getRootTasks());
    }
  } else {
    sem.analyze(tree, ctx);
  }
~~~

5、校验执行计划：`sem.validate()`

6、创建查询计划QueryPlan。

~~~java
plan = new QueryPlan(command, sem, perfLogger.getStartTime(PerfLogger.DRIVER_RUN),
           SessionState.get().getCommandType());
~~~

7、初始化FetchTask。

~~~java
if (plan.getFetchTask() != null) {
   plan.getFetchTask().initialize(conf, plan, null);
}
~~~

8、得到schema

~~~java
schema = getSchema(sem, conf);
~~~

9、授权校验工作。

## hive中支持的hook

上面分析中，提到了hive的hook机制，hive中一共存在以下几种hook。

~~~
hive.semantic.analyzer.hook
hive.exec.filter.hook
hive.exec.driver.run.hooks
hive.server2.session.hook
hive.exec.pre.hooks
hive.exec.post.hooks
hive.exec.failure.hooks
hive.client.stats.publishers
hive.metastore.ds.connection.url.hook
hive.metastore.init.hooks
~~~

通过hook机制，可以在运行前后做一些用户想做的事情。如：你可以在语法分析的hook中对hive的操作做一些超级管理员级别的权限判断；你可以对hive-server2做一些session级别的控制。

cloudera的github仓库[access](https://github.com/cloudera/access)中关于hive的访问控制就是使用了hive的hook机制。

twitter的mapreduce可视化项目监控项目[ambrose](https://github.com/twitter/ambrose)也利用了hive的hook机制，有兴趣的话，你可以去看看其是如何使用hive的hook并且你也可以扩增hook做些自己想做的事情。

# 总结

本文主要介绍了hive运行过程，包括hive语法词法解析以及hook机制，任务的最后运行过程取决于具体的`Task<? extends Serializable>`的实现类的逻辑。关于hive语法词法解析，这一部分没有做详细的解释。

hive Driver类的执行过程如下（该图是根据hive-0.11版本画出来的）：

![hive-driver](/images/hive-driver.jpg)


# 参考文章

1. [hive 初始化运行流程](http://www.cnblogs.com/end/archive/2012/12/19/2825320.html)
2. [Cloudera access](https://github.com/cloudera/access)
3. [twitter ambrose](https://github.com/twitter/ambrose)


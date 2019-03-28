---
layout: post
title: Kettle运行作业之前的初始化过程
category: pentaho
tags: [kettle,pentaho]
keywords: kettle, pentaho
description: 本文主要描述Kettle是如何通过GUI调用代码启动线程执行作业的
---

本文主要描述Kettle是如何通过GUI调用代码启动线程执行作业的。

之前用英文写了一篇文章《<a href="/2012/02/the-execution-process-of-kettles-job/" target="_blank">The execution process of kettle’s job</a>》 ，这篇文章只是用于英语写技术博客的一个尝试。由于很久没有使用英语写作了，故那篇文章只是简单的通过UML的序列图描述kettle运行job的一个java类调用过程。将上篇文章的序列图和这篇文章联系起来，会更加容易理解本文。

在Spoon界面点击运行按钮，Spoon GUI会调用Spoon.runFile()方法，这可以从xul文件（ui/menubar.xul）中的描述看出来。关于kettle中的xul的使用，不是本文重点故不在此说明。

<pre lang="java">
public void runFile() {
	executeFile(true, false, false, false, false, null, false);
}

public void executeFile(boolean local, boolean remote, boolean cluster,
		boolean preview, boolean debug, Date replayDate, boolean safe) {
	TransMeta transMeta = getActiveTransformation();
	if (transMeta != null)
		executeTransformation(transMeta, local, remote, cluster, preview,
				debug, replayDate, safe);

	JobMeta jobMeta = getActiveJob();
	if (jobMeta != null)
		executeJob(jobMeta, local, remote, replayDate, safe, null, 0);
}

public void executeJob(JobMeta jobMeta, boolean local, boolean remote,
		Date replayDate, boolean safe, String startCopyName, int startCopyNr) {
	try {
		delegates.jobs.executeJob(jobMeta, local, remote, replayDate, safe,
				startCopyName, startCopyNr);
	} catch (Exception e) {
		new ErrorDialog(shell, "Execute job",
				"There was an error during job execution", e);
	}
}
</pre>

runFile()方法内部调用executeFile()方法，executeFile方法有以下几个参数：
- local：是否本地运行
- remote：是否远程运行
- cluster：是否集群环境运行
- preview：是否预览
- debug：是否调试
- replayDate：回放时间
- safe：是否安全模式

executeFile方法会先获取当前激活的转换，如果获取结果不为空，则执行该转换；否则获取当前激活的作业，执行该作业。 本文主要讨论作业的执行过程，关于转换的执行过程，之后单独一篇文章进行讨论。

executeJob委托SpoonJobDelegate执行其内部的executeJob方法，注意，其将JobMeta传递给了executeJob方法。SpoonJobDelegate还保存着对Spoon的引用。

SpoonJobDelegate的executeJob方法主要完成以下操作：

- 1.设置Spoon的执行配置JobExecutionConfiguration类，该类设置变量、仓库、是否执行安全模式、日志等级等等。
- 2.获得当前Job对应的图形类JobGraph。
- 3.将执行配置类JobExecutionConfiguration的变量、参数、命令行参数设置给jobMeta。
- 4.如果本地执行，则调用jobGraph.startJob(executionConfiguration)，如果远程执行，则委托给SpoonSlaveDelegate执行。

JobExecutionConfiguration类是保存job执行过程中的一些配置，该类会在Spoon、JobGraph类之间传递。

本文只讨论本地执行的情况，故往下查看jobGraph.startJob(executionConfiguration)方法。该方法被synchronized关键字修饰。

JobGraph类包含当前Spoon类的引用、以及对Job的引用。初始情况，Job的引用应该为null。该类会做以下操作：

- 1.如果job为空或者没有运行或者没有激活，则先保存，然后往下执行作业。
- 2.在仓库不为空的时候，通过仓库加载Job获得一个运行时的JobMeta对象，名称为runJobMeta；否则，通过文件名称直接new一个JobMeta对象，名称也为runJobMeta。
- 3.通过仓库和runJobMeta对象构建一个Job对象，并将jobMeta对象（此对象通过JobGraph构造方法传入）的变量、参数共享给Job对象。
- 4.Job对象添加JobEntry监听器、Job监听器。
- 5.调用Job的start方法，启动线程开始执行一个job。

Job继承自Thread类，该类的run方法内部会递归执行该作业内部的作业项，限于篇幅，本文不做深究。

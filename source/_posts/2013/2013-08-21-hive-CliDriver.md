---
layout: post
title:  Hive源码分析：CLI入口类
description: 理解Hive CLI的入口类，本文的源码分析基于hive-0.10.0-cdh4.3.0。
category: hive
tags: [hadoop, hive]
---

说明：

本文的源码分析基于hive-0.10.0-cdh4.3.0。

# 启动脚本

从shell脚本`/usr/lib/hive/bin/ext/cli.sh`可以看到hive cli的入口类为`org.apache.hadoop.hive.cli.CliDriver`

~~~bash
	cli () {
	  CLASS=org.apache.hadoop.hive.cli.CliDriver
	  execHiveCmd $CLASS "$@"
	}
	cli_help () {
	  CLASS=org.apache.hadoop.hive.cli.CliDriver
	  execHiveCmd $CLASS "--help"
	}
~~~

# 入口类
java中的类如果有main方法就能运行，故直接查找`org.apache.hadoop.hive.cli.CliDriver`中的main方法即可。

CliDriver类中的方法有：

![](/images/Hive-CliDriver-method.jpg)

main方法代码如下：

~~~java
	public static void main(String[] args) throws Exception {
	    int ret = run(args);
	    System.exit(ret);
	}
~~~

阅读run函数可以看到，主要做了以下几件事情：

- 读取main方法的参数
- 重置默认的log4j配置并为hive重新初始化log4j，注意，在这里是读取hive-log4j.properties来初始化log4j。
- 创建CliSessionState，并初始化in、out、info、error等stream流。CliSessionState是一次命令行操作的session会话，其继承了SessionState。
- 重命令行参数中读取参数并设置到CliSessionState中。
- 启动SessionState并连接到hive server
- 如果cli是本地模式运行，则加载`hive.aux.jars.path`参数配置的jar包到classpath
- 创建一个CliDriver对象，并设置当前选择的数据库。可以在命令行参数添加`-database database`来选择连接那个数据库，默认为default数据库。
- 加载初始化文件`.hiverc`，该文件位于当前用户主目录下，读取该文件内容后，然后调用processFile方法处理文件内容。
- 如果命令行中有-e参数，则运行指定的sql语句；如果有-f参数，则读取该文件内容并运行。注意：不能同时指定这两个参数。

~~~bash
	hive -e 'show tables'
	hive -f /root/hive.sql
~~~

- 如果没有指定上面两个参数，则从当前用户主目录读取`.hivehistory`文件，如果不存在则创建。该文件保存了当前用户所有运行的hive命令。
- 在while循环里不断读取控制台的输入内容，每次读取一行，如果行末有分号，则调用CliDriver的processLine方法运行读取到的内容。
- 每次调用processLine方法时，都会创建SignalHandler用于捕捉用户的输入，当用户输入Ctrl+C时，会kill当前正在运行的任务以及kill掉当前进程。kill当前正在运行的job的代码如下.

~~~java
	HadoopJobExecHelper.killRunningJobs();
~~~

- 处理hive命令。


## 处理hive命令过程
如果输入的是quit或者exit,则程序退出。

如果命令开头是source，则会读取source 后面文件内容，然后执行该文件内容。通过这种方式，你可以在hive命令行模式运行一个文件中的hive命令。

如果命令开头是感叹号，执行操作系统命令（如`!ls`，列出当前目录的文件信息）。通过以下代码来运行：

~~~java
	Process executor = Runtime.getRuntime().exec(shell_cmd);
	StreamPrinter outPrinter = new StreamPrinter(executor.getInputStream(), null, ss.out);
	StreamPrinter errPrinter = new StreamPrinter(executor.getErrorStream(), null, ss.err);

	outPrinter.start();
	errPrinter.start();

	ret = executor.waitFor();
	if (ret != 0) {
	  console.printError("Command failed with exit code = " + ret);
	}
~~~

shell_cmd的内容大概如下：

~~~java
	shell_cmd = "/bin/bash -c \'" + shell_cmd + "\'"
~~~

如果命令开头是list，列出jar/file/archive

如果是远程模式运行命令行，则通过HiveClient来运行命令；否则，调用processLocalCmd方法运行本地命令。

以本地模式运行时，会通过CommandProcessorFactory工厂解析输入的语句来获得一个CommandProcessor，CommandProcessor接口的实现类见下图：

![](/images/CommandProcessor-implements.jpg)

从上图可以看到指定的命令(`set/dfs/add/delete/reset`)交给指定的CommandProcessor处理，其余的(指hql语句)交给Driver类来处理。

故，`org.apache.hadoop.hive.ql.Driver`类是hql查询的起点，而run()方法会先后调用compile()和execute()两个函数来完成查询，所以一个command的查询分为compile和execute两个阶段。

# 总结

作为尝试，第一次使用思维导图分析代码逻辑，简单整理了一下CliDriver类的运行逻辑，如下图。以后还需要加强画图和表达能力。

![hive-cli-clidriver](/images/hive-cli-clidriver.jpg)

# 参考文章

- [hive 初始化运行流程](http://www.cnblogs.com/end/archive/2012/12/19/2825320.html)



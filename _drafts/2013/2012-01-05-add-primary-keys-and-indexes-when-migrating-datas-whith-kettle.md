---
layout: post
title: 使用Kettle数据迁移添加主键和索引
category: pentaho
tags: [kettle,pentaho]
description: Kettle是一款国外开源的etl工具，纯java编写，绿色无需安装，主要用于<strong>数据抽取、转换、装载</strong>。kettle兼容了市面上几十种数据库，故用kettle来做数据库的迁移视乎是个不错的选择。kettle的数据抽取主要在于抽取数据，而没有考虑数据库的<strong>函数、存储过程、视图、表结构以及索引、约束</strong>等等，而这些东西恰恰都是数据迁移需要考虑的事情。当然，如果在不考虑数据库中的函数、存储过程、视图的情况下，使用kettle进行数据的迁移还算是一个可行的方案。
---

Kettle是一款国外开源的etl工具，纯java编写，绿色无需安装，主要用于<strong>数据抽取、转换、装载</strong>。kettle兼容了市面上几十种数据库，故用kettle来做数据库的迁移视乎是个不错的选择。

kettle的数据抽取主要在于抽取数据，而没有考虑数据库的<strong>函数、存储过程、视图、表结构以及索引、约束</strong>等等，而这些东西恰恰都是数据迁移需要考虑的事情。当然，如果在不考虑数据库中的函数、存储过程、视图的情况下，使用kettle进行数据的迁移还算是一个可行的方案。

这篇文章主要是讲述在使用kettle进行数据库的迁移的时候如何迁移主键和索引，为什么要迁移主键和索引？异构数据库之间的迁移很难无缝的实现自定义函数、存储过程、视图、表结构、索引、约束以及数据的迁移，所以多数情况下只需要异构数据库之间类型兼容、数据一致就可以了。但是在有些情况下需要对输出表进行查询以及数据比对的时候，<strong>需要有主键和索引方便对比和加快查询速度</strong>。
先来看看kettle中的一些组件。

下图是kettle中的一个表输出组件。

<img src="http://7xnrdo.com1.z0.glb.clouddn.com/2012/01/kettle-table-out.png" alt="kettle中的表输出组件"  />

在该组件里可以指定表名、字段等信息，并且还可以建表的sql语句。打开建表的sql语句，你可以看到该语句里只指定了字段名称和类型，没有指定主外键、约束、和索引。显然，该组件只是完成了数据的输出并没有将表的主键迁移过去。
<!--more-->
下图是kettle中纬度更新/查询的组件。

<img src="http://7xnrdo.com1.z0.glb.clouddn.com/2012/01/kettle-look-up.png" alt="kettle中纬度更新/查询的组件" />

该组件可以指定输出表名、映射字段、纬度字段、并且指定主键（图中翻译为关键字段），该组件比表输出组件多了一个功能，即指定主键。
从上面两个组件中可以看出，kettle实际上预留了设置主键的接口，具体的接口说明需要查看api或者源代码，只是kettle没有智能的查处输入表的主键字段，而是需要用户在kettle ui界面指定一个主键名称。

如果现在想使用kettle实现<strong>异构数据库的数据以及主键和索引的迁移</strong>，有没有一个完整方便的解决方案呢？我能想到的解决方案如下：
<strong>1.</strong>使用kettle向导中的多表复制菜单进行数据库的迁移，这只能实现数据的迁移还需要额外的方法添加主键和索引，你可以手动执行一些脚步添加约束。
<strong>2.</strong>针对源数据库中的每一张表创建一个转换，转换中使用纬度更新/查询组件，在该主键中指定主键。创建完所有的转换之后，创建一个作业将这些转换串联起来即可。
<strong>3.</strong>扩展kettle向导中的多表复制菜单里的功能，在该功能创建的作业中添加一些节点用于添加输出表的主键和索引。这些节点可以是执行sql语句的主键，故只需要通过jdbc代码获取添加主键和索引的sql语句。

方案1需要单独执行脚步实现添加主键和索引，创建或生成这些脚步需要些时间；方案2需要针对每个表认为的指定主键，工作量大，而且无法实现添加索引；方案3最容易实现和扩展。

<strong>下面是方案3的具体的实现。</strong>

首先需要在每一个表的建表语句节点和复制数据节点之后添加一个执行sql语句的节点，该节点用于添加主键和索引。
多表复制向导的核心代码在src-db/org.pentaho.di.ui.spoon.delegates.SpoonJobDelegate.java的public void ripDBWizard()方法中。该方法如下：

	public void ripDBWizard(final int no) {
		final List databases = spoon.getActiveDatabases();
		if (databases.size() == 0)
			return;</pre>

		final RipDatabaseWizardPage1 page1 = new RipDatabaseWizardPage1("1",
				databases);
		final RipDatabaseWizardPage2 page2 = new RipDatabaseWizardPage2("2");
		final RipDatabaseWizardPage3 page3 = new RipDatabaseWizardPage3("3",
				spoon.getRepository());
		Wizard wizard = new Wizard() {
			public boolean performFinish() {
				try {
					JobMeta jobMeta = ripDBByNo(no, databases,
						page3.getJobname(), page3.getRepositoryDirectory(),
						page3.getDirectory(), page1.getSourceDatabase(),
						page1.getTargetDatabase(), page2.getSelection());

					if (jobMeta == null)
						return false;

					if (page3.getRepositoryDirectory() != null) {
						spoon.saveToRepository(jobMeta, false);
					} else {
						spoon.saveToFile(jobMeta);
					}

					addJobGraph(jobMeta);
					return true;
				} catch (Exception e) {
					new ErrorDialog(spoon.getShell(), "Error",
							"An unexpected error occurred!", e);
					return false;
				}
			}

			public boolean canFinish() {
				return page3.canFinish();
			}
		};

		wizard.addPage(page1);
		wizard.addPage(page2);
		wizard.addPage(page3);

		WizardDialog wd = new WizardDialog(spoon.getShell(), wizard);
		WizardDialog.setDefaultImage(GUIResource.getInstance().getImageWizard());
		wd.setMinimumPageSize(700, 400);
		wd.updateSize();
		wd.open();
	}

该方法主要是创建一个向导，该向导中包括三个向导页，第一个向导页用于<strong>选择数据库连接</strong>：源数据库和目标数据库连接；第二个向导页用于<strong>选表</strong>；第三个向导页用于<strong>指定作业保存路径</strong>。在向导完成的时候，即performFinish()方法里，会根据选择的数据源和表生成一个作业，即JobMeta对象。
创建Jobmeta的方法为：

	public JobMeta ripDB(final List databases,final String jobname, final
	    RepositoryDirectoryInterface repdir,final String directory, final DatabaseMeta
	    sourceDbInfo,final DatabaseMeta targetDbInfo, final String[] tables){
	 //此处省略若干代码
	}

该方法主要逻辑在下面代码内：

	IRunnableWithProgress op = new IRunnableWithProgress() {
		public void run(IProgressMonitor monitor)
		 throws InvocationTargetException, InterruptedException {
		   //此处省略若干代码
		}
	}

上面代码中有以下代码用于遍历所选择的表生成作业中的一些节点：

	for (int i = 0; i &lt; tables.length &amp;&amp; !monitor.isCanceled(); i++) {
	    //此处省略若干代码
	}

针对每一张表先会创建一个JobEntrySQL节点，然后创建一个转换JobEntryTrans，可以在创建转换之后再创建一个JobEntrySQL节点，该节点用于添加主键和索引。
这部分的代码如下：

	String pksql = JdbcDataMetaUtil.exportPkAndIndex(
			sourceDbInfo, sourceCon, tables[i],
			targetDbInfo, targetCon, tables[i]);
	if (!Const.isEmpty(pksql)) {
		location.x += 300;
		JobEntrySQL jesql = new JobEntrySQL(
			BaseMessages.getString(PKG,"Spoon.RipDB.AddPkAndIndex")
				+ tables[i] + "]");
		jesql.setDatabase(targetDbInfo);
		jesql.setSQL(pksql);
		jesql.setDescription(BaseMessages.getString(PKG,
				"Spoon.RipDB.AddPkAndIndex")
				+ tables[i]
				+ "]");
		JobEntryCopy jecsql = new JobEntryCopy();
		jecsql.setEntry(jesql);
		jecsql.setLocation(new Point(location.x, location.y));
		jecsql.setDrawn();
		jobMeta.addJobEntry(jecsql);
		// Add the hop too...
		JobHopMeta jhi = new JobHopMeta(previous, jecsql);
		jobMeta.addJobHop(jhi);
		previous = jecsql;
	}

获取添加主键和索引的sql语句，主要是采用jdbc的方式读取两个数据库，判断源数据库的表中是否存在主键和索引，如果有则返回添加主键或索引的sql语句。这部分代码封装在JdbcDataMetaUtil类中。
该代码见：<a href="https://gist.github.com/1564353.js" target="_blank">https://gist.github.com/1564353.js</a>

最后的效果图如下：

<img src="http://7xnrdo.com1.z0.glb.clouddn.com/2012/01/kettle-add-primary-key-and-indexes.png"  />

<div class="infor">说明：
1.以上代码使用的是jdbc的方法获取主键或索引，不同的数据库的jdbc驱动实现可能不同而且不同数据库的语法可能不同，故上面代码可能有待完善。
2.如果一个数据库中存在多库并且这多个库中有相同的表，使用上面的代码针对一个表名会查出多个主键或索引。这一点也是可以改善的</div>

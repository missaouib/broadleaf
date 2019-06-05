---
layout: post
title: 如何在Kettle4.2上面实现cassandra的输入与输出
category: pentaho
tags: [kettle, cassandra, pentaho ]
keywords: kettle, cassandra, pentaho
description: 这是在QQ群里有人问到的一个问题。如何在pdi-ce-4.2.X-stable上面实现cassandra的输入与输出,或是实现hadoop,hbase,mapreduce,mongondb的输入输出?
---

这是在QQ群里有人问到的一个问题。

如何在pdi-ce-4.2.X-stable上面实现cassandra的输入与输出,或是实现hadoop,hbase,mapreduce,mongondb的输入输出?

在kettle中实现cassandra的输入与输出有以下两种方式:

* 第一种方式:自己编写cassandra输入输出组件
* 第二种方式:使用别人编写好的插件,将其集成进来

当然还有第三种方法,直接使用4.3版本的pdi.

第一种方法需要对cassandra很熟悉编写插件才可以做到,第二种方法可以通过拷贝pdi-ce-big-data-4.3.0-preview中的文件来完成.

在pdi-ce-big-data-4.3.0-preview<a href="http://ci.pentaho.com/job/pentaho-big-data-plugin/lastSuccessfulBuild/artifact/pentaho-big-data-plugin/dist/" target="_blank">(下载页面</a>)版本中可以看到kettle开始支持cassandra的输入和输出.

故我们可以将4.3版本中的cassandra相关文件拷贝到4.2.1中.我使用的是pdi-ce-4.2.1-stable.

在pdi-ce-big-data-4.3.0-preview/plugins目录下有以下目录或文件:

	.
	|-- databases
	|-- hour-partitioner.jar
	|-- jobentries
	|-- kettle-gpload-plugin
	|-- kettle-hl7-plugin
	|-- kettle-palo-plugin
	|-- pentaho-big-data-plugin
	|-- repositories
	|-- spoon
	|-- steps
	`-- versioncheck

pentaho-big-data-plugin目录是kettle对大数据的集成与支持,我们只需要将该目录拷贝到pdi-ce-4.2.1-stable/plugins目录下即可.最后的结构如下

	.
	|-- databases
	|-- hour-partitioner.jar
	|-- jobentries
	|   `-- DummyJob
	|       |-- DPL.png
	|       |-- dummyjob.jar
	|       `-- plugin.xml
	|-- pentaho-big-data-plugin
	|   |-- lib
	|   |   |-- apache-cassandra-1.0.0.jar
	|   |   |-- apache-cassandra-thrift-1.0.0.jar
	|   |   |-- aws-java-sdk-1.0.008.jar
	|   |   |-- commons-cli-1.2.jar
	|   |   |-- guava-r08.jar
	|   |   |-- hbase-comparators-TRUNK-SNAPSHOT.jar
	|   |   |-- jline-0.9.94.jar
	|   |   |-- libthrift-0.6.jar
	|   |   |-- mongo-java-driver-2.7.2.jar
	|   |   |-- pig-0.8.1.jar
	|   |   |-- xpp3_min-1.1.4c.jar
	|   |   `-- xstream-1.3.1.jar
	|   `-- pentaho-big-data-plugin-TRUNK-SNAPSHOT.jar
	|-- repositories
	|-- spoon
	|-- steps
	|   |-- DummyPlugin
	|   |   |-- DPL.png
	|   |   |-- dummy.jar
	|   |   `-- plugin.xml
	|   |-- S3CsvInput
	|   |   |-- jets3t-0.7.0.jar
	|   |   |-- plugin.xml
	|   |   |-- S3CIN.png
	|   |   `-- s3csvinput.jar
	|   `-- ShapeFileReader3
	|       |-- plugin.xml
	|       |-- SFR.png
	|       `-- shapefilereader3.jar
	`-- versioncheck
	    |-- kettle-version-checker-0.2.0.jar
	    `-- lib
		`-- pentaho-versionchecker.jar

	13 directories, 29 files

启动pdi-ce-4.2.1-stable之后,打开一个转换,在核心对象窗口就可以看到Big Data步骤目录了.
<div class="pic">
<a href="http://ww4.sinaimg.cn/mw600/48e24b4cjw1dr9zaa66nbj.jpg" target="_blank">
<img alt="" src="http://ww4.sinaimg.cn/mw600/48e24b4cjw1dr9zaa66nbj.jpg" title="pdi big data plugin in kette 4.2" class="aligncenter" width="600" height="375" />
</a>
</div>

<strong>获取pentaho-big-data-plugin源码</strong>
如果想在eclipse中查看或修改pentaho-big-data-plugin源码,该怎么做呢?
你可以从<a href="http://ci.pentaho.com/job/pentaho-big-data-plugin/lastSuccessfulBuild/artifact/pentaho-big-data-plugin/dist/pentaho-big-data-plugin-TRUNK-SNAPSHOT-sources.zip" target="_blank">这里</a>下载到源码,然后将src下的文件拷贝到你的pdi-ce-4.2.1-stable源码工程中.

然后,需要在kettle-steps.xml中注册步骤节点
例如,下面是MongoDbInput步骤的注册方法,请针对不同插件的不同类路径加以修改.

	<step id="MongoDbInput">
	<description>i18n:org.pentaho.di.trans.step:BaseStep.TypeLongDesc.MongoDbInput
	<classname>org.pentaho.di.trans.steps.mongodbinput.MongoDbInputMeta
	<category>i18n:org.pentaho.di.trans.step:BaseStep.Category.Input
	<tooltip>i18n:org.pentaho.di.trans.step:BaseStep.TypeTooltipDesc.MongoDbInput
	<iconfile>ui/images/mongodb-input.png
	</iconfile></tooltip>
	</category>
	</classname>
	</description>
	</step>

<div class="note">
<h>注意:
由于pdi-ce-4.2.1-stable中存在hive组件,故添加pentaho-big-data-plugin插件之后有可能会出现找不到类的情况,这是由于jar重复版本不一致导致的,按照异常信息,找到重复的jar并按情况删除一个jar包即可.
</h></div>

<strong>扩展阅读:</strong>

- Pentaho Big Data Plugin <a href="http://wiki.pentaho.com/display/BAD/Getting+Started+for+Java+Developers" target="_blank">http://wiki.pentaho.com/display/BAD/Getting+Started+for+Java+Developers</a>
- pentaho-big-data-plugin ci
<a href="http://ci.pentaho.com/job/pentaho-big-data-plugin/lastSuccessfulBuild/artifact/pentaho-big-data-plugin/dist/" target="_blank">http://- - ci.pentaho.com/job/pentaho-big-data-plugin/lastSuccessfulBuild/artifact/pentaho-big-data-plugin/dist/</a>
- Pentaho Community Edition (CE) downloads <a href="http://wiki.pentaho.com/display/BAD/Downloads" target="_blank">http://wiki.pentaho.com/display/BAD/Downloads</a>

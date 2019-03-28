---
layout: post

title: Nutch介绍及使用

description: Nutch起源于ApacheLucene项目，已经是一个高度可扩展和可伸缩的开源网络爬虫软件项目。现在Nutch分为两个版本，1.x和2.x。1.x最新版本为1.7，2.x最新版本为2.2.1。两个版本的主要区别在于底层的存储不同。1.x版本是基于Hadoop架构的，底层存储使用的是HDFS，而2.x通过使用Apache Gora，使得Nutch可以访问HBase、Accumulo、Cassandra、MySQL、DataFileAvroStore、AvroStore等NoSQL。

keywords: Nutch

category: search-engine

tags: [nutch,solr]

---

# 1. Nutch介绍

Nutch是一个开源的网络爬虫项目，更具体些是一个爬虫软件，可以直接用于抓取网页内容。

现在Nutch分为两个版本，1.x和2.x。1.x最新版本为1.7，2.x最新版本为2.2.1。两个版本的主要区别在于底层的存储不同。

1.x版本是基于Hadoop架构的，底层存储使用的是HDFS，而2.x通过使用Apache Gora，使得Nutch可以访问HBase、Accumulo、Cassandra、MySQL、DataFileAvroStore、AvroStore等NoSQL。

# 2. 编译Nutch

Nutch1.x从1.7版本开始不再提供完整的部署文件，只提供源代码文件及相关的build.xml文件,这就要求用户自己编译Nutch，而整个Nutch2.x版本都不提供编译完成的文件，所以想要学习Nutch2.2.1的功能，就必须自己手动编译文件。

## 2.1 下载解压

~~~bash
$ wget http://archive.apache.org/dist/nutch/2.2.1/apache-nutch-2.2.1-src.tar.gz
$ tar zxf apache-nutch-2.2.1-src.tar.gz
~~~

## 2.2 编译

~~~bash
$ cd apache-nutch-2.2.1
$ ant
~~~

有可能你会得到如下错误：

~~~
Trying to override old definition of task javac
  [taskdef] Could not load definitions from resource org/sonar/ant/antlib.xml. It could not be found.

ivy-probe-antlib:

ivy-download:
  [taskdef] Could not load definitions from resource org/sonar/ant/antlib.xml. It could not be found.
~~~

解决办法：

1. 下载sonar-ant-task-2.1.jar，将其拷贝到apache-nutch-2.2.1目录下面
2. 修改build.xml，引入上面添加的jar包：

~~~xml
<!-- Define the Sonar task if this hasn't been done in a common script -->
<taskdef uri="antlib:org.sonar.ant" resource="org/sonar/ant/antlib.xml">
	<classpath path="${ant.library.dir}" />
	<classpath path="${mysql.library.dir}" />
	<classpath><fileset dir="." includes="sonar*.jar" /></classpath>
</taskdef>
~~~

Nutch使用ivy进行构建，故编译需要很长时间，如果编译时间过长，建议修改maven仓库地址，修改方法：

通过用`http://mirrors.ibiblio.org/maven2/`替换`ivy/下ivysettings.xml`中的`http://repo1.maven.org/maven2/`来解决。代码位置为：

~~~xml
<property name="repo.maven.org" value="http://repo1.maven.org/maven2/" override="false"/>
~~~

编译之后的目录如下：

~~~
➜  apache-nutch-2.2.1  tree -L 1
.
├── CHANGES.txt
├── LICENSE.txt
├── NOTICE.txt
├── README.txt
├── build
├── build.xml
├── conf
├── default.properties
├── docs
├── ivy
├── lib
├── runtime
├── sonar-ant-task-2.1.jar
└── src

7 directories, 7 files
~~~

可以看到编译之后多了两个目录：build和runtime

# 3. 修改配置文件

由于Nutch2.x版本存储采用Gora访问Cassandra、HBase、Accumulo、Avro等，需要在该文件中制定Gora属性，比如指定默认的存储方式`gora.datastore.default= org.apache.gora.hbase.store.HBaseStore`，该属性的值可以在nutch-default.xml中查找`storage.data.store.class`属性取得，在不做gora.properties文件修改的情况下，存储类为`org.apache.gora.memory.store.MemStore`，该类将数据存储在内存中，仅用于测试目的。

这里，将其存储方式改为HBase,请参考 <http://wiki.apache.org/nutch/Nutch2Tutorial>。

修改 `conf/nutch-site.xml`

~~~xml
<property>
  <name>storage.data.store.class</name>
  <value>org.apache.gora.hbase.store.HBaseStore</value>
  <description>Default class for storing data</description>
</property>
~~~

修改 `ivy/ivy.xml`

~~~xml
<!-- Uncomment this to use HBase as Gora backend. -->
<dependency org="org.apache.gora" name="gora-hbase" rev="0.3" conf="*->default" />
~~~

修改 `conf/gora.properties`，确保HBaseStore被设置为默认的存储，

~~~
gora.datastore.default=org.apache.gora.hbase.store.HBaseStore
~~~

因为这里用到了HBase，故还需要一个HBase环境，你可以使用Standalone模式搭建一个HBase环境，请参考 [HBase Quick Start](http://hbase.apache.org/book/quickstart.html)。需要说明的时，**目前HBase的版本要求为 hbase-0.90.4。**

# 4. 集成Solr

由于建索引的时候需要使用Solr，因此我们需要安装并启动一个Solr服务器。

# 4.1 下载，解压

~~~bash
$ wget http://mirrors.cnnic.cn/apache/lucene/solr/4.8.0/solr-4.8.0.tgz 
$ tar -zxf solr-4.8.0.tgz
~~~

# 4.2 运行Solr

~~~bash
$ cd solr-4.8.0/example
$ java -jar start.jar
~~~

验证是否启动成功

用浏览器打开 <http://localhost:8983/solr/admin/>，如果能看到页面，说明启动成功。

# 4.3 修改Solr配置文件

将`apache-nutch-2.2.1/conf/schema-solr4.xml`拷贝到`solr-4.8.0/solr/collection1/conf/schema.xml`，并在`<fields>...</fields>`最后添加一行:

~~~xml
<field name="_version_" type="long" indexed="true" stored="true" multiValued="false"/>
~~~

重启Solr，

~~~bash
# Ctrl+C to stop Solr
$ java -jar start.jar
~~~

# 5. 抓取数据

编译后的脚本在 runtime/local/bin 目录下，可以运行命令查看使用方法：

crawl命令：

~~~bash
$ cd runtime/local/bin 
$ ./crawl 
Missing seedDir : crawl <seedDir> <crawlID> <solrURL> <numberOfRounds>
~~~

nutch命令：

~~~bash
$ ./nutch 
Usage: nutch COMMAND
where COMMAND is one of:
 inject		inject new urls into the database
 hostinject     creates or updates an existing host table from a text file
 generate 	generate new batches to fetch from crawl db
 fetch 		fetch URLs marked during generate
 parse 		parse URLs marked during fetch
 updatedb 	update web table after parsing
 updatehostdb   update host table after parsing
 readdb 	read/dump records from page database
 readhostdb     display entries from the hostDB
 elasticindex   run the elasticsearch indexer
 solrindex 	run the solr indexer on parsed batches
 solrdedup 	remove duplicates from solr
 parsechecker   check the parser for a given url
 indexchecker   check the indexing filters for a given url
 plugin 	load a plugin and run one of its classes main()
 nutchserver    run a (local) Nutch server on a user defined port
 junit         	runs the given JUnit test
 or
 CLASSNAME 	run the class named CLASSNAME
Most commands print help when invoked w/o parameters.
~~~

接下来可以抓取网页了。

# 6. 参考文章

- [Nutch-2.2.1学习](http://blog.csdn.net/skywalker_only/article/category/1842591)
- [Nutch 快速入门(Nutch 2.2.1)](http://cn.soulmachine.me/blog/20140201/)

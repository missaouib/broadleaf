---
layout: post

title:  采集日志到Hive
date: 2014-07-25T08:00:00+08:00

description: 我们现在的需求是需要将线上的日志以小时为单位采集并存储到 hive 数据库中，方便以后使用  mapreduce 或者 impala 做数据分析。为了实现这个目标调研了 flume 如何采集数据到 hive，其他的日志采集框架尚未做调研。

keywords:  hive

categories: [  hive ]

tags: [hive,flume]

published: true

---


我们现在的需求是需要将线上的日志以小时为单位采集并存储到 hive 数据库中，方便以后使用  mapreduce 或者 impala 做数据分析。为了实现这个目标调研了 flume 如何采集数据到 hive，其他的日志采集框架尚未做调研。

# 日志压缩

flume中有个 HdfsSink 组件，其可以压缩日志进行保存，故首先想到我们的日志应该以压缩的方式进行保存，遂选择了 lzo 的压缩格式，HdfsSink 的配置如下:

~~~properties
agent-1.sinks.sink_hdfs.channel = ch-1
agent-1.sinks.sink_hdfs.type = hdfs
agent-1.sinks.sink_hdfs.hdfs.path = hdfs://cdh1:8020/user/root/events/%Y-%m-%d
agent-1.sinks.sink_hdfs.hdfs.filePrefix = logs
agent-1.sinks.sink_hdfs.hdfs.inUsePrefix = .
agent-1.sinks.sink_hdfs.hdfs.rollInterval = 30
agent-1.sinks.sink_hdfs.hdfs.rollSize = 0
agent-1.sinks.sink_hdfs.hdfs.rollCount = 0
agent-1.sinks.sink_hdfs.hdfs.batchSize = 1000
agent-1.sinks.sink_hdfs.hdfs.fileType = CompressedStream
agent-1.sinks.sink_hdfs.hdfs.codeC = lzop
~~~

hive 目前是支持 lzo 压缩的，但是要想在 mapreduce 中 lzo 文件可以拆分，需要通过 hadoop 的 api 进行手动创建索引：

~~~bash 
$ lzop a.txt
$ hadoop fs -put a.txt.lzo /log/dw_srclog/sp_visit_log/ptd_ymd=20140720
​$ hadoop jar /usr/lib/hadoop/lib/hadoop-lzo.jar com.hadoop.compression.lzo.LzoIndexer /log/sp_visit_log/ptd_ymd=20140720/a.txt.lzo
~~~

impala 目前也是在支持 lzo 压缩格式的文件的，故采用 lzo 压缩方式存储日志文件似乎是个可行方案。

# 自定义分隔符

Hive默认创建的表字段分隔符为：`\001(ctrl-A)`，也可以通过 `ROW FORMAT DELIMITED FIELDS TERMINATED BY` 指定其他字符，但是该语法只支持单个字符。

目前，我们的日志中几乎任何单个字符都被使用了，故没法使用单个字符作为 hive 表字段的分隔符，只能使用多个字符，例如：“|||”。
使用多字符来分隔字段，则需要你自定义InputFormat来实现。

~~~java
package org.apache.hadoop.mapred;

import java.io.IOException;

import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapred.FileSplit;
import org.apache.hadoop.mapred.InputSplit;
import org.apache.hadoop.mapred.JobConf;
import org.apache.hadoop.mapred.LineRecordReader;
import org.apache.hadoop.mapred.RecordReader;
import org.apache.hadoop.mapred.Reporter;
import org.apache.hadoop.mapred.TextInputFormat;

public class MyDemoInputFormat extends TextInputFormat {

	@Override
	public RecordReader<LongWritable, Text> getRecordReader(
			InputSplit genericSplit, JobConf job, Reporter reporter)
			throws IOException {
		reporter.setStatus(genericSplit.toString());
		MyDemoRecordReader reader = new MyDemoRecordReader(
				new LineRecordReader(job, (FileSplit) genericSplit));
		return reader;
	}

	public static class MyDemoRecordReader implements
			RecordReader<LongWritable, Text> {

		LineRecordReader reader;
		Text text;

		public MyDemoRecordReader(LineRecordReader reader) {
			this.reader = reader;
			text = reader.createValue();
		}

		@Override
		public void close() throws IOException {
			reader.close();
		}

		@Override
		public LongWritable createKey() {
			return reader.createKey();
		}

		@Override
		public Text createValue() {
			return new Text();
		}

		@Override
		public long getPos() throws IOException {
			return reader.getPos();
		}

		@Override
		public float getProgress() throws IOException {
			return reader.getProgress();
		}

		@Override
		public boolean next(LongWritable key, Text value) throws IOException {
			Text txtReplace;
			while (reader.next(key, text)) {
				txtReplace = new Text();
				txtReplace.set(text.toString().toLowerCase().replaceAll("\\|\\|\\|", "\001"));
				value.set(txtReplace.getBytes(), 0, txtReplace.getLength());
				return true;

			}
			return false;
		}
	}
}
~~~

这时候的建表语句是：

~~~sql
create external table IF NOT EXISTS  test(
id string,
name string
)partitioned by (day string) 
STORED AS INPUTFORMAT  
  'org.apache.hadoop.mapred.MyDemoInputFormat'  
OUTPUTFORMAT  
  'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION '/log/dw_srclog/test';
~~~

但是，这样建表的话，是不能识别 lzo 压缩文件的，需要去扩展 lzo 的 DeprecatedLzoTextInputFormat 类，但是如何扩展，没有找到合适方法。

所以，在自定义分隔符的情况下，想支持 lzo 压缩文件，需要另外想办法。例如，使用 `SERDE` 的方式：

~~~sql
create external table IF NOT EXISTS  test(
id string,
name string
)partitioned by (day string) 
ROW FORMAT  
SERDE 'org.apache.hadoop.hive.contrib.serde2.RegexSerDe'  
WITH SERDEPROPERTIES  
( 'input.regex' = '([^ ]*)\\|\\|\\|([^ ]*)',  
'output.format.string' = '%1$s %2$s') 
STORED AS INPUTFORMAT  
  'com.hadoop.mapred.DeprecatedLzoTextInputFormat'  
OUTPUTFORMAT  
  'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION '/log/dw_srclog/test';
~~~

要想使用SERDE，必须添加 hive-contrib-XXXX.jar 到 classpath，在 hive-env.sh 中添加下面代码;

~~~bash
$ export HIVE_AUX_JARS_PATH=/usr/lib/hive/lib/hive-contrib-0.10.0-cdh4.7.0.jar
~~~

**注意：** 

- 使用 SERDE  时，字段类型只能为 string。
- 这种方式建表，flume 可以将日志存储为 lzo 并且 hive 能够识别出数据，但是 impala 中却不支持 `SERDE` 的语法，故只能放弃该方法。

最后，只能放弃 lzo 压缩文件的想法，改为不做压缩。flume 中 HdfsSink 配置参数 hdfs.fileType 目前只有三种可选值：CompressedStream
、DataStream、SequenceFile，为了保持向后兼容便于扩展，这里使用了 DataStream 的方式，不做数据压缩。


## Update

**注意：**

最后又经过测试，发现 impala 不支持 hive 的自定义文件格式，详细说明请参考：[SQL Differences Between Impala and Hive](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Installing-and-Using-Impala/ciiu_langref_unsupported.html?scroll=langref_unsupported)

# 日志采集

使用 flume 来采集日志，只需要在应用程序服务器上安装一个 agent 就可以监听文件或者目录的改变来搜集日志，但是实际情况你不一定有权限访问应用服务器，更多的方式是应用服务器将日志推送到一个中央的日志集中存储服务器。你只有权限去从该服务器收集数据，并且该服务器对外提供 ftp 的接口供你访问。

日志采集有 pull 和 push 的两种方式，关于两种方式的一些说明，可以参考这篇文章：[大规模日志收集处理项目的技术总结](http://sdjcw.iteye.com/blog/1814703)。

对于当前情况而言，只能从 ftp 服务器轮询文件然后下载文件到本地，最后再将其导入到 hive 中去。以前，使用 kettle 做过这种事情，现在为了简单只是写了个 python 脚本来做这件事情，一个示例代码，请参考 <https://gist.github.com/javachen/6f7d14aae138c7a284e6#file-fetch-py>。

该脚本会再 crontab 中每隔5分钟执行一次。

执行该脚本会往 mongodb 中记录一些状态信息，并往 logs 目录以天为单位记录日志。

**暂时没有使用 flume 的原因：**

1. 对 flume 的测试于调研程度还不够
2. flume 中无法对数据去重
3. 只能停止 flume 进程，才可以升级 flume，这样会丢失数据

等日志采集实时性要求变高，以及对 flume 的熟悉程度变深之后，会考虑使用 flume。

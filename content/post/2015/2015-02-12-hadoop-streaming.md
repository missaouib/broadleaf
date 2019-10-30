---
layout: post

title: Hadoop Streaming 原理
date: 2015-02-12T08:00:00+08:00

categories: [ hadoop ]

tags: [ hadoop,mapreduce,streaming ]

description: Hadoop Streaming 是 Hadoop 提供的一个 MapReduce 编程工具，它允许用户使用任何可执行文件、脚本语言或其他编程语言来实现 Mapper 和 Reducer，从而充分利用 Hadoop 并行计算框架的优势和能力，来处理大数据。

published: true

---

# 简介 

Hadoop Streaming 是 Hadoop 提供的一个 MapReduce 编程工具，它允许用户使用任何可执行文件、脚本语言或其他编程语言来实现 Mapper 和 Reducer，从而充分利用 Hadoop 并行计算框架的优势和能力，来处理大数据。

一个简单的示例，以 shell 脚本为例：

~~~
hadoop jar hadoop-streaming.jar \
    -input myInputDirs \
    -output myOutputDir \
    -mapper /bin/cat \
    -reducer /usr/bin/wc
~~~

Streaming 方式是 `基于 Unix 系统的标准输入输出` 来进行 MapReduce Job 的运行，它区别与 Pipes 的地方主要是通信协议，Pipes 使用的是 Socket 通信，是对使用 C++ 语言来实现 MapReduce Job 并通过 Socket 通信来与 Hadopp 平台通信，完成 Job 的执行。

任何支持标准输入输出特性的编程语言都可以使用 Streaming 方式来实现 MapReduce Job，基本原理就是输入从 Unix 系统标准输入，输出使用 Unix 系统的标准输出。

Hadoop 是使用 Java 语言编写的，所以最直接的方式的就是使用 Java 语言来实现 Mapper 和 Reducer，然后配置 MapReduce Job，提交到集群计算环境来完成计算。但是很多开发者可能对 Java 并不熟悉，而是对一些具有脚本特性的语言，如 C++、Shell、Python、 Ruby、PHP、Perl 有实际开发经验，Hadoop Streaming 为这一类开发者提供了使用 Hadoop 集群来进行处理数据的工具，即工具包 hadoop-streaming.jar。

在标准的输入输出中，Key 和 Value 是以 Tab 作为分隔符，并且在 Reducer 的标准输入中，Hadoop 框架保证了输入的数据是经过了按 Key 排序的。

# 原理 

Hadoop Streaming 使用了 Unix 的标准输入输出作为 Hadoop 和其他编程语言的开发接口，因此在其他的编程语言所写的程序中，只需要将标准输入作为程序的输入，将标准输出作为程序的输出就可以了。

mapper 和 reducer 会从标准输入中读取用户数据，一行一行处理后发送给标准输出。Streaming 工具会创建 MapReduce 作业，发送给各个 tasktracker，同时监控整个作业的执行过程。

如果一个文件（可执行或者脚本）作为 mapper，mapper 初始化时，每一个 mapper 任务会把该文件作为一个单独进程启动，mapper 任务运行时，它把输入切分成行并把每一行提供给可执行文件进程的标准输入。 同时，mapper 收集可执行文件进程标准输出的内容，并把收到的每一行内容转化成 key/value 对，作为 mapper 的输出。 默认情况下，一行中第一个 tab 之前的部分作为 key，之后的（不包括tab）作为 value。如果没有 tab，整行作为 key 值，value 值为 null。

对于 reducer，类似。

以上是 Map/Reduce 框架和 streaming mapper/reducer 之间的基本通信协议。

用户可以定义 `stream.non.zero.exit.is.failure` 参数为 true 或者 false 以定义一个以非0状态退出的 streaming 的任务是失败还是成功。默认情况下，以非0状态退出的任务都任务是失败的。

# 用法

命令如下：

~~~bash
hadoop jar hadoop-streaming.jar [genericOptions] [streamingOptions]
~~~

## streaming 参数

以 Hadoop 2.6.0 为例，可选的 streaming 参数如下：

|参数|   是否可选  | 描述|
|:---|:---|:---|
|`-input directoryname or filename`   | Required |   mapper的输入路径 |
|`-output directoryname` |  Required   | reducer输出路径 |
|`-mapper executable or JavaClassName` | Required   | Mapper可执行程序或 Java 类名 |
|`-reducer executable or JavaClassName`  |  Required  |  Reducer 可执行程序或 Java 类名 |
|`-file filename` | Optional   | mapper, reducer 或 combiner 依赖的文件 |
|`-inputformat JavaClassName` | Optional   |  key/value 输入格式，默认为 TextInputFormat  |
|`-outputformat JavaClassName` | Optional  |  key/value 输出格式，默认为  TextOutputformat |
|`-partitioner JavaClassName`  | Optional  |  Class that determines which reduce a key is sent to |
|`-combiner streamingCommand or JavaClassName` | Optional  |  map 输出结果执行 Combiner 的命令或者类名 |
|`-cmdenv name=value`  | Optional  |  环境变量 |
|`-inputreader`  |  Optional   | 向后兼容，定义输入的 Reader 类，用于取代输出格式 |
|`-verbose`  |  Optional   | 输出日志 |
|`-lazyOutput` | Optional   | 延时输出  |
|`-numReduceTasks` | Optional  |  定义 reduce 数量 |
|`-mapdebug`  | Optional   |  map 任务运行失败时候，执行的脚本 |
|`-reducedebug`  |  Optional   |  reduce 任务运行失败时候，执行的脚本  |

定义 Java 类作为 mapper 和 reducer：

~~~bash
hadoop jar hadoop-streaming.jar \
    -input myInputDirs \
    -output myOutputDir \
    -inputformat org.apache.hadoop.mapred.KeyValueTextInputFormat \
    -mapper org.apache.hadoop.mapred.lib.IdentityMapper \
    -reducer /usr/bin/wc
~~~

如果 mapper 和 reducer 的可执行文件在集群上不存在，则可以通过  `-file` 参数将其提交到集群上去：

~~~bash
hadoop jar hadoop-streaming.jar \
    -input myInputDirs \
    -output myOutputDir \
    -mapper myPythonScript.py \
    -reducer /usr/bin/wc \
    -file myPythonScript.py
~~~

你也可以将 mapper 和 reducer 的可执行文件用到的文件和配置上传到集群上：

~~~bash
hadoop jar hadoop-streaming.jar \
    -input myInputDirs \
    -output myOutputDir \
    -mapper myPythonScript.py \
    -reducer /usr/bin/wc \
    -file myPythonScript.py \
    -file myDictionary.txt
~~~

你也可以定义其他参数：

~~~bash
-inputformat JavaClassName
-outputformat JavaClassName
-partitioner JavaClassName
-combiner streamingCommand or JavaClassName
~~~

定义一个环境变量：

~~~bash
-cmdenv EXAMPLE_DIR=/home/example/dictionaries/   
~~~

## 通用参数

|参数|   是否可选  | 描述|
|:---|:---|:---|
|`-conf configuration_file` |   Optional  |  定义应用的配置文件 |
|`-D property=value` |   Optional   | 定义参数 |
|`-fs host:port or local` | Optional   | 定义 namenode 地址 |
|`-files`  | Optional  |  定义需要拷贝到 Map/Reduce 集群的文件，多个文件以逗号分隔 |
|`-libjars` |   Optional  |  定义需要引入到 classpath 的 jar 文件，多个文件以逗号分隔 |
|`-archives`  | Optional   | 定义需要解压到计算节点的压缩文件，多个文件以逗号分隔 |

定义参数：

~~~bash
-D mapred.local.dir=/tmp/local
-D mapred.system.dir=/tmp/system
-D mapred.temp.dir=/tmp/temp
~~~

定义 reduce 个数：

~~~bash
-D mapreduce.job.reduces=0
~~~

你也可以使用 `-D stream.reduce.output.field.separator=SEP` 和 `-D stream.num.reduce.output.fields=NUM` 自定义 mapper 输出的分隔符为SEP，并且按 SEP 分隔之后的前 NUM 部分内容作为 key，如果分隔符少于 NUM，则整行作为 key。例如，下面的例子指定分隔符为 `....`：

~~~bash
hadoop jar hadoop-streaming.jar \
    -D stream.map.output.field.separator=. \
    -D stream.num.map.output.key.fields=4 \
    -input myInputDirs \
    -output myOutputDir \
    -mapper /bin/cat \
    -reducer /bin/cat
~~~

hadoop 提供配置供用户自主设置分隔符：

`-D stream.map.output.field.separator` ：设置 map 输出中 key 和 value 的分隔符 
`-D stream.num.map.output.key.fields` ：设置 map 程序分隔符的位置，该位置之前的部分作为 key，之后的部分作为 value 
`-D map.output.key.field.separator` : 设置 map 输出分区时 key 内部的分割符
`-D mapreduce.partition.keypartitioner.options` : 指定分桶时，key 按照分隔符切割后，其中用于分桶 key 所占的列数（配合 `-partitioner org.apache.hadoop.mapred.lib.KeyFieldBasedPartitioner` 使用）
`-D stream.reduce.output.field.separator`：设置 reduce 输出中 key 和 value 的分隔符 
`-D stream.num.reduce.output.key.fields`：设置 reduce 程序分隔符的位置

定义解压文件：

~~~bash
$ ls test_jar/
cache.txt  cache2.txt

$ jar cvf cachedir.jar -C test_jar/ .
added manifest
adding: cache.txt(in = 30) (out= 29)(deflated 3%)
adding: cache2.txt(in = 37) (out= 35)(deflated 5%)

$ hdfs dfs -put cachedir.jar samples/cachefile

$ hdfs dfs -cat /user/root/samples/cachefile/input.txt
cachedir.jar/cache.txt
cachedir.jar/cache2.txt

$ cat test_jar/cache.txt
This is just the cache string

$ cat test_jar/cache2.txt
This is just the second cache string

$ hadoop jar hadoop-streaming.jar \
                  -archives 'hdfs://hadoop-nn1.example.com/user/root/samples/cachefile/cachedir.jar' \
                  -D mapreduce.job.maps=1 \
                  -D mapreduce.job.reduces=1 \
                  -D mapreduce.job.name="Experiment" \
                  -input "/user/root/samples/cachefile/input.txt" \
                  -output "/user/root/samples/cachefile/out" \
                  -mapper "xargs cat" \
                  -reducer "cat"

$ hdfs dfs -ls /user/root/samples/cachefile/out
Found 2 items
-rw-r--r--   1 root supergroup        0 2013-11-14 17:00 /user/root/samples/cachefile/out/_SUCCESS
-rw-r--r--   1 root supergroup       69 2013-11-14 17:00 /user/root/samples/cachefile/out/part-00000

$ hdfs dfs -cat /user/root/samples/cachefile/out/part-00000
This is just the cache string
This is just the second cache string
~~~

## 复杂的例子

### Hadoop Partitioner Class

Hadoop 中有一个类 [KeyFieldBasedPartitioner](http://hadoop.apache.org/docs/r2.6.0/api/org/apache/hadoop/mapred/lib/KeyFieldBasedPartitioner.html)，可以将 map 输出的内容按照分隔后的一定列，而不是整个 key 内容进行分区，例如：

~~~bash
hadoop jar hadoop-streaming.jar \
    -D stream.map.output.field.separator=. \
    -D stream.num.map.output.key.fields=4 \
    -D map.output.key.field.separator=. \
    -D mapreduce.partition.keypartitioner.options=-k1,2 \
    -D mapreduce.job.reduces=12 \
    -input myInputDirs \
    -output myOutputDir \
    -mapper /bin/cat \
    -reducer /bin/cat \
    -partitioner org.apache.hadoop.mapred.lib.KeyFieldBasedPartitioner
~~~

关键参数说明：

- `map.output.key.field.separator=.`：设置 map 输出分区时 key 内部的分割符为 `.`
- `mapreduce.partition.keypartitioner.options=-k1,2`：设置按前两个字段分区
- `mapreduce.job.reduces=12`：reduce 数为12

假设 map 的输出为：

~~~
11.12.1.2
11.14.2.3
11.11.4.1
11.12.1.1
11.14.2.2
~~~

按照前两个字段进行分区，则会分为三个分区：

~~~
11.11.4.1
-----------
11.12.1.2
11.12.1.1
-----------
11.14.2.3
11.14.2.2
~~~

在每个分区内对整行内容排序后为：

~~~
11.11.4.1
-----------
11.12.1.1
11.12.1.2
-----------
11.14.2.2
11.14.2.3
~~~

### Hadoop Comparator Class

Hadoop 中有一个类 [KeyFieldBasedComparator](http://hadoop.apache.org/docs/r2.6.0/api/org/apache/hadoop/mapreduce/lib/partition/KeyFieldBasedComparator.html)，提供了 Unix/GNU 中排序的一部分特性。

~~~bash
hadoop jar hadoop-streaming.jar \
    -D mapreduce.job.output.key.comparator.class=org.apache.hadoop.mapreduce.lib.partition.KeyFieldBasedComparator \
    -D stream.map.output.field.separator=. \
    -D stream.num.map.output.key.fields=4 \
    -D mapreduce.map.output.key.field.separator=. \
    -D mapreduce.partition.keycomparator.options=-k2,2nr \
    -D mapreduce.job.reduces=1 \
    -input myInputDirs \
    -output myOutputDir \
    -mapper /bin/cat \
    -reducer /bin/cat
~~~

关键参数说明：

- `mapreduce.partition.keycomparator.options=-k2,2nr`：指定第二个字段为排序字段，`-n` 是指按自然顺序排序，`-r` 指倒叙排序。

假设 map 的输出为：

~~~
11.12.1.2
11.14.2.3
11.11.4.1
11.12.1.1
11.14.2.2
~~~

则 reduce 输出结果为：

~~~
11.14.2.3
11.14.2.2
11.12.1.2
11.12.1.1
11.11.4.1
~~~

### Hadoop Aggregate Package

Hadoop 中有一个类 [Aggregate](http://hadoop.apache.org/docs/r2.6.0/org/apache/hadoop/mapred/lib/aggregate/package-summary.html)，Aggregate 提供了一个特定的 reduce 类和 combiner 类，以及一些对 reduce 输出的聚合函数，例如 sum、min、max 等等。

为了使用 Aggregate，只需要定义 `-reducer aggregate`：

~~~bash
hadoop jar hadoop-streaming.jar \
    -input myInputDirs \
    -output myOutputDir \
    -mapper myAggregatorForKeyCount.py \
    -reducer aggregate \
    -file myAggregatorForKeyCount.py \
~~~

myAggregatorForKeyCount.py  文件大概内容如下：

~~~python
#!/usr/bin/python

import sys;

def generateLongCountToken(id):
    return "LongValueSum:" + id + "\t" + "1"

def main(argv):
    line = sys.stdin.readline();
    try:
        while line:
            line = line[:-1];
            fields = line.split("\t");
            print generateLongCountToken(fields[0]);
            line = sys.stdin.readline();
    except "end of file":
        return None
if __name__ == "__main__":
     main(sys.argv)
~~~

### Hadoop Field Selection Class

Hadoop 中有一个类 [FieldSelectionMapReduce](http://hadoop.apache.org/docs/r2.6.0/api/org/apache/hadoop/mapred/lib/FieldSelectionMapReduce.html)，运行你像 unix 中的 cut 命令一样处理文本。

例子：

~~~bash
hadoop jar hadoop-streaming.jar \
    -D mapreduce.map.output.key.field.separator=. \
    -D mapreduce.partition.keypartitioner.options=-k1,2 \
    -D mapreduce.fieldsel.data.field.separator=. \
    -D mapreduce.fieldsel.map.output.key.value.fields.spec=6,5,1-3:0- \
    -D mapreduce.fieldsel.reduce.output.key.value.fields.spec=0-2:5- \
    -D mapreduce.map.output.key.class=org.apache.hadoop.io.Text \
    -D mapreduce.job.reduces=12 \
    -input myInputDirs \
    -output myOutputDir \
    -mapper org.apache.hadoop.mapred.lib.FieldSelectionMapReduce \
    -reducer org.apache.hadoop.mapred.lib.FieldSelectionMapReduce \
    -partitioner org.apache.hadoop.mapred.lib.KeyFieldBasedPartitioner
~~~

关键参数说明：

- `mapreduce.fieldsel.map.output.key.value.fields.spec=6,5,1-3:0-`：意思是 map 的输出中 key 部分包括分隔后的第 6、5、1、2、3列，而 value 部分包括分隔后的所有的列
- `mapreduce.fieldsel.reduce.output.key.value.fields.spec=0-2:5-`：意思是 map 的输出中 key 部分包括分隔后的第 0、1、2列，而 value 部分包括分隔后的从第5列开始的所有列

# 测试

上面讲了 Hadoop Streaming 的原理和一些用法，现在来运行一些例子做测试。关于如何用 Python 来编写 Hadoop Streaming 程序，可以参考 [Writing an Hadoop MapReduce Program in Python](http://www.michael-noll.com/tutorials/writing-an-hadoop-mapreduce-program-in-python/)，中文翻译在 [这里](http://www.tianjun.ml/essays/19/)，其他非 Java 的语言，都可以参照这篇文章。

下面以 word count 为例做测试。

## 准备测试数据

同 [Writing an Hadoop MapReduce Program in Python](http://www.michael-noll.com/tutorials/writing-an-hadoop-mapreduce-program-in-python/)，我们使用古腾堡项目中的三本电子书作为测试：

- [The Outline of Science, Vol. 1 (of 4) by J. Arthur Thomson](http://www.gutenberg.org/etext/20417)
- [The Notebooks of Leonardo Da Vinci](http://www.gutenberg.org/etext/5000)
- [Ulysses by James Joyce](http://www.gutenberg.org/etext/4300)

下载这些电子书的 txt格式，并将其上传到 hdfs：

~~~bash
$ mkdir /tmp/gutenberg/ && cd /tmp/gutenberg/

$ wget http://www.gutenberg.org/files/20417/20417.txt
$ wget http://www.gutenberg.org/cache/epub/5000/pg5000.txt
$ wget http://www.gutenberg.org/files/4300/4300.txt

$ hadoop fs -copyFromLocal /tmp/gutenberg gutenberg

$ hadoop fs -ls gutenberg
Found 4 items
-rw-r--r--   3 hive hive     674762 2015-02-11 17:34 gutenberg/20417.txt
-rw-r--r--   3 hive hive    1573079 2015-02-11 17:34 gutenberg/4300.txt
-rw-r--r--   3 hive hive    1423803 2015-02-11 17:34 gutenberg/pg5000.txt
~~~

## 编写 Shell 版程序

mapper.sh 如下：

~~~bash
#! /bin/bash

while read LINE; do
  for word in $LINE
  do
    echo "$word 1"
  done
done
~~~

reducer.sh 程序如下：

~~~bash
#! /bin/bash

count=0
started=0
word=""
while read LINE;do
  newword=`echo $LINE | cut -d ' '  -f 1`
  if [ "$word" != "$newword" ];then
    [ $started -ne 0 ] && echo -e "$word\t$count"
    word=$newword
    count=1
    started=1
  else
    count=$(( $count + 1 ))
  fi
done
echo -e "$word\t$count"
~~~

在本机以脚本方式测试：

~~~bash
$ echo "foo foo quux labs foo bar quux" | sh mapper.sh  |sort -k1,1| sh reducer.sh
bar 1
foo 3
labs    1
quux    2
~~~

以 Hadoop Streaming 方式运行：

~~~bash
$ hadoop  jar /usr/lib/hadoop-mapreduce/hadoop-streaming.jar \
    -D mapred.reduce.tasks=6 \
    -input gutenberg/* \
    -output gutenberg-output \
    -mapper mapper.sh\
    -reducer reducer.sh\
    -file mapper.sh \
    -file reducer.sh

15/02/11 17:50:59 INFO mapreduce.Job:  map 0% reduce 0%
15/02/11 17:51:18 INFO mapreduce.Job:  map 17% reduce 0%
15/02/11 17:51:52 INFO mapreduce.Job:  map 17% reduce 6%
15/02/11 17:51:53 INFO mapreduce.Job:  map 33% reduce 6%
15/02/11 17:51:55 INFO mapreduce.Job:  map 60% reduce 17%
15/02/11 17:51:56 INFO mapreduce.Job:  map 100% reduce 17%
15/02/11 17:51:59 INFO mapreduce.Job:  map 100% reduce 67%
15/02/11 17:53:11 INFO mapreduce.Job:  map 100% reduce 68%
15/02/11 17:54:49 INFO mapreduce.Job:  map 100% reduce 69%
15/02/11 17:57:12 INFO mapreduce.Job:  map 100% reduce 70%
15/02/11 17:58:45 INFO mapreduce.Job:  map 100% reduce 71%
15/02/11 17:58:55 INFO mapreduce.Job:  map 100% reduce 81%
15/02/11 17:59:05 INFO mapreduce.Job:  map 100% reduce 100%
15/02/11 17:59:08 INFO streaming.StreamJob: Job complete: job_1421752803837_5736
15/02/11 17:59:09 INFO streaming.StreamJob: Output: /user/root/gutenberg-output
~~~

## 编写 Python 版程序

mapper.py 程序如下：

~~~python
#!/usr/bin/env python
"""A more advanced Mapper, using Python iterators and generators."""

import sys

def read_input(file):
    for line in file:
        # split the line into words
        yield line.split()

def main(separator='\t'):
    # input comes from STDIN (standard input)
    data = read_input(sys.stdin)
    for words in data:
        # write the results to STDOUT (standard output);
        # what we output here will be the input for the
        # Reduce step, i.e. the input for reducer.py
        #
        # tab-delimited; the trivial word count is 1
        for word in words:
            print '%s%s%d' % (word, separator, 1)

if __name__ == "__main__":
    main()
~~~

reducer.py 程序如下：

~~~python
#!/usr/bin/env python
"""A more advanced Reducer, using Python iterators and generators."""

from itertools import groupby
from operator import itemgetter
import sys

def read_mapper_output(file, separator='\t'):
    for line in file:
        yield line.rstrip().split(separator, 1)

def main(separator='\t'):
    # input comes from STDIN (standard input)
    data = read_mapper_output(sys.stdin, separator=separator)
    # groupby groups multiple word-count pairs by word,
    # and creates an iterator that returns consecutive keys and their group:
    #   current_word - string containing a word (the key)
    #   group - iterator yielding all ["&lt;current_word&gt;", "&lt;count&gt;"] items
    for current_word, group in groupby(data, itemgetter(0)):
        try:
            total_count = sum(int(count) for current_word, count in group)
            print "%s%s%d" % (current_word, separator, total_count)
        except ValueError:
            # count was not a number, so silently discard this item
            pass

if __name__ == "__main__":
    main()
~~~

关于 Java 的一些例子，这个需要单独创建一个 maven 工程，然后做一些测试。

# 注意事项

### mapper 中不能使用 shell 的别名，但可以使用变量

~~~bash
$ hdfs dfs -cat /user/me/samples/student_marks
alice   50
bruce   70
charlie 80
dan     75

$ c2='cut -f2'; hadoop jar hadoop-streaming-2.6.0.jar \
    -D mapreduce.job.name='Experiment' \
    -input /user/me/samples/student_marks \
    -output /user/me/samples/student_out \
    -mapper "$c2" -reducer 'cat'

$ hdfs dfs -cat /user/me/samples/student_out/part-00000
50
70
75
80
~~~

### mapper 中不能使用 unix 的管道

`-mapper` 中使用 "cut -f1 | sed s/foo/bar/g"，会出现 `java.io.IOException: Broken pipe` 异常

### 指定 streaming 临时空间

~~~bash
-D stream.tmpdir=/export/bigspace/...
~~~

### 指定多个输入文件

~~~bash
hadoop jar hadoop-streaming-2.6.0.jar \
    -input '/user/foo/dir1' -input '/user/foo/dir2' \
    (rest of the command)
~~~

### 处理 XML

~~~bash
hadoop jar hadoop-streaming-2.6.0.jar \
    -inputreader "StreamXmlRecord,begin=BEGIN_STRING,end=END_STRING" \
    (rest of the command)
~~~

BEGIN_STRING 和 END_STRING 之前的内容会被认为是 map 任务的一条记录。

# 参考文章

- [Hadoop Streaming](http://hadoop.apache.org/docs/r2.6.0/hadoop-mapreduce-client/hadoop-mapreduce-client-core/HadoopStreaming.html#More_Usage_Examples)
- [Hadoop Streaming 编程](http://dongxicheng.org/mapreduce/hadoop-streaming-programming/)
- [Writing an Hadoop MapReduce Program in Python](http://www.michael-noll.com/tutorials/writing-an-hadoop-mapreduce-program-in-python/)

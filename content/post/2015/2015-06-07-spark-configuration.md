---
layout: post

title: Spark配置参数
date: 2015-06-07T08:00:00+08:00

categories: [ spark ]

tags: [spark]

description: 本文主要整理Spark的相关配置参数，便于查询和方便调优。

published: true

---

以下是整理的Spark中的一些配置参数，官方文档请参考[Spark Configuration](https:/.apache.org/docs/latest/configuration.html)。

Spark提供三个位置用来配置系统：

- Spark属性：控制大部分的应用程序参数，可以用SparkConf对象或者Java系统属性设置
- 环境变量：可以通过每个节点的` conf-env.sh`脚本设置。例如IP地址、端口等信息
- 日志配置：可以通过log4j.properties配置

# Spark属性

Spark属性控制大部分的应用程序设置，并且为每个应用程序分别配置它。这些属性可以直接在[SparkConf](http:/.apache.org/docs/latest/api/scala/index.html#org.apache.spark.SparkConf)上配置，然后传递给`SparkContext`。`SparkConf`
允许你配置一些通用的属性（如master URL、应用程序名称等等）以及通过`set()`方法设置的任意键值对。例如，我们可以用如下方式创建一个拥有两个线程的应用程序。

~~~scala
val conf = new SparkConf()
             .setMaster("local[2]")
             .setAppName("CountingSheep")
             .set("spark.executor.memory", "1g")
val sc = new SparkContext(conf)
~~~

## 动态加载Spark属性

在一些情况下，你可能想在`SparkConf`中避免硬编码确定的配置。例如，你想用不同的master或者不同的内存数运行相同的应用程序。Spark允许你简单地创建一个空conf。

~~~scala
val sc = new SparkContext(new SparkConf())
~~~

然后你在运行时设置变量：

~~~bash
./bin-submit --name "My app" --master local[4] --conf spark.shuffle.spill=false
  --conf "spark.executor.extraJavaOptions=-XX:+PrintGCDetails -XX:+PrintGCTimeStamps" myApp.jar
~~~

Spark shell和`spark-submit`工具支持两种方式动态加载配置。第一种方式是命令行选项，例如`--master`，如上面shell显示的那样。`spark-submit`可以接受任何Spark属性，用`--conf`参数表示。但是那些参与Spark应用程序启动的属性要用特定的参数表示。运行`./bin-submit --help`将会显示选项的整个列表。

`bin-submit`也会从`conf-defaults.conf`中读取配置选项，这个配置文件中，每一行都包含一对以`空格`或者`等号`分开的键和值。例如：

~~~
spark.master            spark://5.6.7.8:7077
spark.executor.memory   512m
spark.eventLog.enabled  true
spark.serializer        org.apache.spark.serializer.KryoSerializer
~~~

任何标签指定的值或者在配置文件中的值将会传递给应用程序，并且通过`SparkConf`合并这些值。在`SparkConf`上设置的属性具有最高的优先级，其次是传递给`spark-submit`或者`spark-shell`的属性值，最后是`spark-defaults.conf`文件中的属性值。

优先级顺序：

~~~
SparkConf > CLI > spark-defaults.conf
~~~

## 查看Spark属性

在`http://<driver>:4040`上的应用程序Web UI在`Environment`标签中列出了所有的Spark属性。这对你确保设置的属性的正确性是很有用的。

注意：`只有通过spark-defaults.conf, SparkConf以及命令行直接指定的值才会显示`。对于其它的配置属性，你可以认为程序用到了默认的值。

## 可用的属性

控制内部设置的大部分属性都有合理的默认值，一些最通用的选项设置如下：

### 应用程序属性

属性名称| 默认值 | 含义
--- | --- | ---
spark.app.name | (none) | 你的应用程序的名字。这将在UI和日志数据中出现
spark.driver.cores |  1 |  driver程序运行需要的cpu内核数
spark.driver.maxResultSize | 1g | 每个Spark action(如collect)所有分区的序列化结果的总大小限制。设置的值应该不小于1m，0代表没有限制。如果总大小超过这个限制，程序将会终止。大的限制值可能导致driver出现内存溢出错误（依赖于`spark.driver.memory`和JVM中对象的内存消耗）。
spark.driver.memory | 512m | driver进程使用的内存数
spark.executor.memory | 512m | 每个executor进程使用的内存数。和JVM内存串拥有相同的格式（如512m,2g）
spark.extraListeners  | (none) | 注册监听器，需要实现SparkListener
spark.local.dir | /tmp | Spark中暂存空间的使用目录。在Spark1.0以及更高的版本中，这个属性被SPARK_LOCAL_DIRS(Standalone, Mesos)和LOCAL_DIRS(YARN)环境变量覆盖。
spark.logConf | false | 当SparkContext启动时，将有效的SparkConf记录为INFO。
spark.master | (none) | 集群管理器连接的地方

### 运行环境

属性名称| 默认值 | 含义
--- | --- | ---
spark.driver.extraClassPath | (none) | 附加到driver的classpath的额外的classpath实体。
spark.driver.extraJavaOptions | (none) | 传递给driver的JVM选项字符串。例如GC设置或者其它日志设置。注意，`在这个选项中设置Spark属性或者堆大小是不合法的`。Spark属性需要用`--driver-class-path`设置。
spark.driver.extraLibraryPath | (none) | 指定启动driver的JVM时用到的库路径
spark.driver.userClassPathFirst | false  | (实验性)当在driver中加载类时，是否用户添加的jar比Spark自己的jar优先级高。这个属性可以降低Spark依赖和用户依赖的冲突。它现在还是一个实验性的特征。
spark.executor.extraClassPath | (none) | 附加到executors的classpath的额外的classpath实体。这个设置存在的主要目的是Spark与旧版本的向后兼容问题。用户一般不用设置这个选项
spark.executor.extraJavaOptions | (none) | 传递给executors的JVM选项字符串。例如GC设置或者其它日志设置。注意，`在这个选项中设置Spark属性或者堆大小是不合法的`。Spark属性需要用SparkConf对象或者`spark-submit`脚本用到的`spark-defaults.conf`文件设置。堆内存可以通过`spark.executor.memory`设置
spark.executor.extraLibraryPath | (none) | 指定启动executor的JVM时用到的库路径
spark.executor.logs.rolling.maxRetainedFiles | (none) | 设置被系统保留的最近滚动日志文件的数量。更老的日志文件将被删除。默认没有开启。
spark.executor.logs.rolling.size.maxBytes | (none) | executor日志的最大滚动大小。默认情况下没有开启。值设置为字节
spark.executor.logs.rolling.strategy | (none) | 设置executor日志的滚动(rolling)策略。默认情况下没有开启。可以配置为`time`和`size`。对于`time`，用`spark.executor.logs.rolling.time.interval`设置滚动间隔；对于`size`，用`spark.executor.logs.rolling.size.maxBytes`设置最大的滚动大小
spark.executor.logs.rolling.time.interval | daily | executor日志滚动的时间间隔。默认情况下没有开启。合法的值是`daily`, `hourly`, `minutely`以及任意的秒。
spark.files.userClassPathFirst | false | (实验性)当在Executors中加载类时，是否用户添加的jar比Spark自己的jar优先级高。这个属性可以降低Spark依赖和用户依赖的冲突。它现在还是一个实验性的特征。
spark.python.worker.memory | 512m | 在聚合期间，每个python worker进程使用的内存数。在聚合期间，如果内存超过了这个限制，它将会将数据塞进磁盘中
spark.python.profile | false | 在Python worker中开启profiling。通过`sc.show_profiles()`展示分析结果。或者在driver退出前展示分析结果。可以通过`sc.dump_profiles(path)`将结果dump到磁盘中。如果一些分析结果已经手动展示，那么在driver退出前，它们再不会自动展示
spark.python.profile.dump | (none) | driver退出前保存分析结果的dump文件的目录。每个RDD都会分别dump一个文件。可以通过`ptats.Stats()`加载这些文件。如果指定了这个属性，分析结果不会自动展示
spark.python.worker.reuse | true | 是否重用python worker。如果是，它将使用固定数量的Python workers，而不需要为每个任务`fork()`一个Python进程。如果有一个非常大的广播，这个设置将非常有用。因为，广播不需要为每个任务从JVM到Python worker传递一次
spark.executorEnv.[EnvironmentVariableName] | (none) | 通过`EnvironmentVariableName`添加指定的环境变量到executor进程。用户可以指定多个`EnvironmentVariableName`，设置多个环境变量
spark.mesos.executor.home | driver side SPARK_HOME | 设置安装在Mesos的executor上的Spark的目录。默认情况下，executors将使用driver的Spark本地（home）目录，这个目录对它们不可见。注意，如果没有通过` spark.executor.uri`指定Spark的二进制包，这个设置才起作用
spark.mesos.executor.memoryOverhead | executor memory * 0.07, 最小384m | 这个值是`spark.executor.memory`的补充。它用来计算mesos任务的总内存。另外，有一个7%的硬编码设置。最后的值将选择`spark.mesos.executor.memoryOverhead`或者`spark.executor.memory`的7%二者之间的大者

### Shuffle行为

属性名称| 默认值 | 含义
--- | --- | ---
spark.reducer.maxMbInFlight | 48 | 从递归任务中同时获取的map输出数据的最大大小（mb）。因为每一个输出都需要我们创建一个缓存用来接收，这个设置代表每个任务固定的内存上限，所以除非你有更大的内存，将其设置小一点
spark.shuffle.blockTransferService | netty | 实现用来在executor直接传递shuffle和缓存块。有两种可用的实现：`netty`和`nio`。基于netty的块传递在具有相同的效率情况下更简单
spark.shuffle.compress | true | 是否压缩map操作的输出文件。一般情况下，这是一个好的选择。
spark.shuffle.consolidateFiles | false | 如果设置为"true"，在shuffle期间，合并的中间文件将会被创建。创建更少的文件可以提供文件系统的shuffle的效率。这些shuffle都伴随着大量递归任务。当用ext4和dfs文件系统时，推荐设置为"true"。在ext3中，因为文件系统的限制，这个选项可能机器（大于8核）降低效率
spark.shuffle.file.buffer.kb | 32 | 每个shuffle文件输出流内存内缓存的大小，单位是kb。这个缓存减少了创建只中间shuffle文件中磁盘搜索和系统访问的数量
spark.shuffle.io.maxRetries | 3 |  Netty only，自动重试次数
spark.shuffle.io.numConnectionsPerPeer |  1 | Netty only
spark.shuffle.io.preferDirectBufs | true | Netty only
spark.shuffle.io.retryWait | 5 | Netty only
spark.shuffle.manager | sort | 它的实现用于shuffle数据。有两种可用的实现：`sort`和`hash`。基于sort的shuffle有更高的内存使用率
spark.shuffle.memoryFraction | 0.2 | 如果`spark.shuffle.spill`为true，shuffle中聚合和合并组操作使用的java堆内存占总内存的比重。在任何时候，shuffles使用的所有内存内maps的集合大小都受这个限制的约束。超过这个限制，spilling数据将会保存到磁盘上。如果spilling太过频繁，考虑增大这个值
spark.shuffle.sort.bypassMergeThreshold | 200 | (Advanced) In the sort-based shuffle manager, avoid merge-sorting data if there is no map-side aggregation and there are at most this many reduce partitions
spark.shuffle.spill | true | 如果设置为"true"，通过将多出的数据写入磁盘来限制内存数。通过`spark.shuffle.memoryFraction`来指定spilling的阈值
spark.shuffle.spill.compress | true | 在shuffle时，是否将spilling的数据压缩。压缩算法通过`spark.io.compression.codec`指定。

### Spark UI

属性名称| 默认值 | 含义
--- | --- | ---
spark.eventLog.compress | false | 是否压缩事件日志。需要`spark.eventLog.enabled`为true
spark.eventLog.dir | file:///tmp-events | Spark事件日志记录的基本目录。在这个基本目录下，Spark为每个应用程序创建一个子目录。各个应用程序记录日志到直到的目录。用户可能想设置这为统一的地点，像HDFS一样，所以历史文件可以通过历史服务器读取
spark.eventLog.enabled | false | 是否记录Spark的事件日志。这在应用程序完成后，重新构造web UI是有用的
spark.ui.killEnabled | true | 运行在web UI中杀死stage和相应的job
spark.ui.port | 4040 | 你的应用程序dashboard的端口。显示内存和工作量数据
spark.ui.retainedJobs | 1000 | 在垃圾回收之前，Spark UI和状态API记住的job数
spark.ui.retainedStages | 1000 | 在垃圾回收之前，Spark UI和状态API记住的stage数

### 压缩和序列化

属性名称| 默认值 | 含义 |
--- | --- | --- |
spark.broadcast.compress | true | 在发送广播变量之前是否压缩它 |
spark.closure.serializer | org.apache.spark.serializer.JavaSerializer | 闭包用到的序列化类。目前只支持java序列化器 |
spark.io.compression.codec | snappy | 压缩诸如RDD分区、广播变量、shuffle输出等内部数据的编码解码器。默认情况下，Spark提供了三种选择：lz4、lzf和snappy，你也可以用完整的类名来制定。 |
spark.io.compression.lz4.block.size | 32768 | LZ4压缩中用到的块大小。降低这个块的大小也会降低shuffle内存使用率 |
spark.io.compression.snappy.block.size | 32768 | Snappy压缩中用到的块大小。降低这个块的大小也会降低shuffle内存使用率 |
spark.kryo.classesToRegister | (none) | 如果你用Kryo序列化，给定的用逗号分隔的自定义类名列表表示要注册的类
spark.kryo.referenceTracking | true | 当用Kryo序列化时，跟踪是否引用同一对象。如果你的对象图有环，这是必须的设置。如果他们包含相同对象的多个副本，这个设置对效率是有用的。如果你知道不在这两个场景，那么可以禁用它以提高效率 |
spark.kryo.registrationRequired | false | 是否需要注册为Kyro可用。如果设置为true，然后如果一个没有注册的类序列化，Kyro会抛出异常。如果设置为false，Kryo将会同时写每个对象和其非注册类名。写类名可能造成显著地性能瓶颈。|
spark.kryo.registrator | (none) | 如果你用Kryo序列化，设置这个类去注册你的自定义类。如果你需要用自定义的方式注册你的类，那么这个属性是有用的。否则`spark.kryo.classesToRegister`会更简单。它应该设置一个继承自[KryoRegistrator](http:/.apache.org/docs/latest/api/scala/index.html#org.apache.spark.serializer.KryoRegistrator)的类
spark.kryoserializer.buffer.max.mb | 64 | Kryo序列化缓存允许的最大值。这个值必须大于你尝试序列化的对象 |
spark.kryoserializer.buffer.mb | 0.064 | Kyro序列化缓存的大小。这样worker上的每个核都有一个缓存。如果有需要，缓存会涨到`spark.kryoserializer.buffer.max.mb`设置的值那么大。|
spark.rdd.compress | true | 是否压缩序列化的RDD分区。在花费一些额外的CPU时间的同时节省大量的空间 |
spark.serializer | org.apache.spark.serializer.JavaSerializer | 序列化对象使用的类。默认的Java序列化类可以序列化任何可序列化的java对象但是它很慢。所有我们建议用[org.apache.spark.serializer.KryoSerializer](http:/.apache.org/docs/latest/tuning.html)
spark.serializer.objectStreamReset | 100 | 当用`org.apache.spark.serializer.JavaSerializer`序列化时，序列化器通过缓存对象防止写多余的数据，然而这会造成这些对象的垃圾回收停止。通过请求'reset'，你从序列化器中flush这些信息并允许收集老的数据。为了关闭这个周期性的reset，你可以将值设为-1。默认情况下，每一百个对象reset一次 |

### 运行时行为

属性名称| 默认值 | 含义
--- | --- | ---
spark.broadcast.blockSize | 4096 | TorrentBroadcastFactory传输的块大小，太大值会降低并发，太小的值会出现性能瓶颈 
spark.broadcast.factory | org.apache.spark.broadcast.TorrentBroadcastFactory | broadcast实现类
spark.cleaner.ttl | (infinite) |  spark记录任何元数据（stages生成、task生成等）的持续时间。定期清理可以确保将超期的元数据丢弃，这在运行长时间任务是很有用的，如运行7*24的sparkstreaming任务。RDD持久化在内存中的超期数据也会被清理
spark.default.parallelism | 本地模式：机器核数；Mesos：8；其他：`max(executor的core，2)`|如果用户不设置，系统使用集群中运行shuffle操作的默认任务数（groupByKey、 reduceByKey等）
spark.executor.heartbeatInterval | 10000 | executor 向 the driver 汇报心跳的时间间隔，单位毫秒 
spark.files.fetchTimeout  | 60 | driver 程序获取通过`SparkContext.addFile()`添加的文件时的超时时间，单位秒
spark.files.useFetchCache | true  | 获取文件时是否使用本地缓存
spark.files.overwrite | false | 调用`SparkContext.addFile()`时候是否覆盖文件
spark.hadoop.cloneConf  | false | 每个task是否克隆一份hadoop的配置文件
spark.hadoop.validateOutputSpecs  | true | 是否校验输出
spark.storage.memoryFraction | 0.6 | Spark内存缓存的堆大小占用总内存比例，该值不能大于老年代内存大小，默认值为0.6，但是，如果你手动设置老年代大小，你可以增加该值
spark.storage.memoryMapThreshold  | 2097152 | 内存块大小
spark.storage.unrollFraction | 0.2|  Fraction of spark.storage.memoryFraction to use for unrolling blocks in memory. 
spark.tachyonStore.baseDir  |System.getProperty("java.io.tmpdir")  | Tachyon File System临时目录
spark.tachyonStore.url  | tachyon://localhost:19998 | Tachyon File System URL

### 网络

属性名称| 默认值 | 含义
--- | --- | ---
spark.driver.host | (local hostname) | driver监听的主机名或者IP地址。这用于和executors以及独立的master通信
spark.driver.port | (random) | driver监听的接口。这用于和executors以及独立的master通信
spark.fileserver.port | (random) | driver的文件服务器监听的端口
spark.broadcast.port | (random) | driver的HTTP广播服务器监听的端口
spark.replClassServer.port | (random) | driver的HTTP类服务器监听的端口
spark.blockManager.port | (random) | 块管理器监听的端口。这些同时存在于driver和executors
spark.executor.port | (random) | executor监听的端口。用于与driver通信
spark.port.maxRetries | 16 | 当绑定到一个端口，在放弃前重试的最大次数
spark.akka.frameSize | 10 | 在"control plane"通信中允许的最大消息大小。如果你的任务需要发送大的结果到driver中，调大这个值
spark.akka.threads | 4 | 通信的actor线程数。当driver有很多CPU核时，调大它是有用的
spark.akka.timeout | 100 | Spark节点之间的通信超时。单位是秒
spark.akka.heartbeat.pauses | 6000 | This is set to a larger value to disable failure detector that comes inbuilt akka. It can be enabled again, if you plan to use this feature (Not recommended). Acceptable heart beat pause in seconds for akka. This can be used to control sensitivity to gc pauses. Tune this in combination of `spark.akka.heartbeat.interval` and `spark.akka.failure-detector.threshold` if you need to.
spark.akka.failure-detector.threshold | 300.0 | This is set to a larger value to disable failure detector that comes inbuilt akka. It can be enabled again, if you plan to use this feature (Not recommended). This maps to akka's `akka.remote.transport-failure-detector.threshold`. Tune this in combination of `spark.akka.heartbeat.pauses` and `spark.akka.heartbeat.interval` if you need to.
spark.akka.heartbeat.interval | 1000 | This is set to a larger value to disable failure detector that comes inbuilt akka. It can be enabled again, if you plan to use this feature (Not recommended). A larger interval value in seconds reduces network overhead and a smaller value ( ~ 1 s) might be more informative for akka's failure detector. Tune this in combination of `spark.akka.heartbeat.pauses` and `spark.akka.failure-detector.threshold` if you need to. Only positive use case for using failure detector can be, a sensistive failure detector can help evict rogue executors really quick. However this is usually not the case as gc pauses and network lags are expected in a real Spark cluster. Apart from that enabling this leads to a lot of exchanges of heart beats between nodes leading to flooding the network with those.

### 调度相关属性

属性名称| 默认值 | 含义
--- | --- | ---
spark.task.cpus | 1 | 为每个任务分配的内核数
spark.task.maxFailures | 4 | Task的最大重试次数
spark.scheduler.mode | FIFO | Spark的任务调度模式，还有一种Fair模式
spark.cores.max  |  | 当应用程序运行在Standalone集群或者粗粒度共享模式Mesos集群时，应用程序向集群请求的最大CPU内核总数（不是指每台机器，而是整个集群）。如果不设置，对于Standalone集群将使用spark.deploy.defaultCores中数值，而Mesos将使用集群中可用的内核
spark.mesos.coarse | False | 如果设置为true，在Mesos集群中运行时使用粗粒度共享模式
spark.speculation  | False  | 以下几个参数是关于Spark推测执行机制的相关参数。此参数设定是否使用推测执行机制，如果设置为true则spark使用推测执行机制，对于Stage中拖后腿的Task在其他节点中重新启动，并将最先完成的Task的计算结果最为最终结果
spark.speculation.interval   | 100 | Spark多长时间进行检查task运行状态用以推测，以毫秒为单位
spark.speculation.quantile  |  | 推测启动前，Stage必须要完成总Task的百分比
spark.speculation.multiplier | 1.5  | 比已完成Task的运行速度中位数慢多少倍才启用推测
spark.locality.wait | 3000 | 以下几个参数是关于Spark数据本地性的。本参数是以毫秒为单位启动本地数据task的等待时间，如果超出就启动下一本地优先级别的task。该设置同样可以应用到各优先级别的本地性之间（本地进程 -> 本地节点 -> 本地机架 -> 任意节点 ），当然，也可以通过spark.locality.wait.node等参数设置不同优先级别的本地性
spark.locality.wait.process  |  spark.locality.wait | 本地进程级别的本地等待时间
spark.locality.wait.node | spark.locality.wait | 本地节点级别的本地等待时间
spark.locality.wait.rack | spark.locality.wait | 本地机架级别的本地等待时间
spark.scheduler.revive.interval | 1000 | 复活重新获取资源的Task的最长时间间隔（毫秒），发生在Task因为本地资源不足而将资源分配给其他Task运行后进入等待时间，如果这个等待时间内重新获取足够的资源就继续计算

### Dynamic Allocation

属性名称| 默认值 | 含义
--- | --- | ---
spark.dynamicAllocation.enabled |false|是否开启动态资源搜集
spark.dynamicAllocation.executorIdleTimeout |600|
spark.dynamicAllocation.initialExecutors  |spark.dynamicAllocation.minExecutors|
spark.dynamicAllocation.maxExecutors  |Integer.MAX_VALUE|
spark.dynamicAllocation.minExecutors | 0|
spark.dynamicAllocation.schedulerBacklogTimeout |5|
spark.dynamicAllocation.sustainedSchedulerBacklogTimeout | schedulerBacklogTimeout|

### 安全

属性名称| 默认值 | 含义
--- | --- | ---
spark.authenticate | false | 是否Spark验证其内部连接。如果不是运行在YARN上，请看`spark.authenticate.secret`
spark.authenticate.secret | None | 设置Spark两个组件之间的密匙验证。如果不是运行在YARN上，但是需要验证，这个选项必须设置
spark.core.connection.auth.wait.timeout | 30 | 连接时等待验证的实际。单位为秒
spark.core.connection.ack.wait.timeout | 60 | 连接等待回答的时间。单位为秒。为了避免不希望的超时，你可以设置更大的值
spark.ui.filters | None | 应用到Spark web UI的用于过滤类名的逗号分隔的列表。过滤器必须是标准的[javax servlet Filter](http://docs.oracle.com/javaee/6/api/javax/servlet/Filter.html)。通过设置java系统属性也可以指定每个过滤器的参数。`spark.<class name of filter>.params='param1=value1,param2=value2'`。例如`-Dspark.ui.filters=com.test.filter1`、`-Dspark.com.test.filter1.params='param1=foo,param2=testing'`
spark.acls.enable | false | 是否开启Spark acls。如果开启了，它检查用户是否有权限去查看或修改job。UI利用使用过滤器验证和设置用户
spark.ui.view.acls | empty | 逗号分隔的用户列表，列表中的用户有查看Spark web UI的权限。默认情况下，只有启动Spark job的用户有查看权限
spark.modify.acls | empty | 逗号分隔的用户列表，列表中的用户有修改Spark job的权限。默认情况下，只有启动Spark job的用户有修改权限
spark.admin.acls | empty | 逗号分隔的用户或者管理员列表，列表中的用户或管理员有查看和修改所有Spark job的权限。如果你运行在一个共享集群，有一组管理员或开发者帮助debug，这个选项有用

### 加密

属性名称| 默认值 | 含义
--- | --- | ---
spark.ssl.enabled | false | 是否开启ssl|
spark.ssl.enabledAlgorithms | Empty | JVM支持的加密算法列表，逗号分隔|
spark.ssl.keyPassword | None | |
spark.ssl.keyStore  |None|
spark.ssl.keyStorePassword  |None|
spark.ssl.protocol  |None|
spark.ssl.trustStore |  None |
spark.ssl.trustStorePassword  |None|

### Spark Streaming

属性名称| 默认值 | 含义
--- | --- | ---
spark.streaming.blockInterval | 200 | 在这个时间间隔（ms）内，通过Spark Streaming receivers接收的数据在保存到Spark之前，chunk为数据块。推荐的最小值为50ms
spark.streaming.receiver.maxRate | infinite | 每秒钟每个receiver将接收的数据的最大记录数。有效的情况下，每个流将消耗至少这个数目的记录。设置这个配置为0或者-1将会不作限制
spark.streaming.receiver.writeAheadLogs.enable | false | Enable write ahead logs for receivers. All the input data received through receivers will be saved to write ahead logs that will allow it to be recovered after driver failures
spark.streaming.unpersist | true | 强制通过Spark Streaming生成并持久化的RDD自动从Spark内存中非持久化。通过Spark Streaming接收的原始输入数据也将清除。设置这个属性为false允许流应用程序访问原始数据和持久化RDD，因为它们没有被自动清除。但是它会造成更高的内存花费

### 集群管理

#### Spark On YARN

属性名称| 默认值 | 含义
--- | --- | ---
spark.yarn.am.memory  |  512m | client 模式时，am的内存大小；cluster模式时，使用`spark.driver.memory`变量
spark.driver.cores  |  1 | claster模式时，driver使用的cpu核数，这时候driver运行在am中，其实也就是am和核数；client模式时，使用`spark.yarn.am.cores`变量
spark.yarn.am.cores |  1 | client 模式时，am的cpu核数
spark.yarn.am.waitTime   | 100000 | 启动时等待时间
spark.yarn.submit.file.replication | 3 | 应用程序上传到HDFS的文件的副本数
spark.yarn.preserve.staging.files | False | 若为true，在job结束后，将stage相关的文件保留而不是删除
spark.yarn.scheduler.heartbeat.interval-ms | 5000 | Spark AppMaster发送心跳信息给YARN RM的时间间隔
spark.yarn.max.executor.failures | 2倍于executor数，最小值3 | 导致应用程序宣告失败的最大executor失败次数
spark.yarn.applicationMaster.waitTries |10 | RM等待Spark AppMaster启动重试次数，也就是SparkContext初始化次数。超过这个数值，启动失败
spark.yarn.historyServer.address | |Spark history server的地址（不要加 `http://`）。这个地址会在Spark应用程序完成后提交给YARN RM，然后RM将信息从RM UI写到history server UI上。
spark.yarn.dist.archives  |  (none) | 
spark.yarn.dist.files |  (none) | 
spark.executor.instances  |  2 | executor实例个数
spark.yarn.executor.memoryOverhead   | executorMemory * 0.07, with minimum of 384 | executor的堆内存大小设置
spark.yarn.driver.memoryOverhead   | driverMemory * 0.07, with minimum of 384 | driver的堆内存大小设置
spark.yarn.am.memoryOverhead   | AM memory * 0.07, with minimum of 384 | am的堆内存大小设置，在client模式时设置
spark.yarn.queue  |  default | 使用yarn的队列
spark.yarn.jar  |  (none) | 
spark.yarn.access.namenodes |  (none) | 
spark.yarn.appMasterEnv.[EnvironmentVariableName]  | (none) | 设置am的环境变量
spark.yarn.containerLauncherMaxThreads |   25 | am启动executor的最大线程数
spark.yarn.am.extraJavaOptions  |  (none) | 
spark.yarn.maxAppAttempts  | yarn.resourcemanager.am.max-attempts in YARN | am重试次数

### Spark on Mesos

使用较少，参考[Running Spark on Mesos](https:/.apache.org/docs/latest/running-on-mesos.html#configuration)。

### Spark Standalone Mode

参考[Spark Standalone Mode](https:/.apache.org/docs/latest-standalone.html#cluster-launch-scripts)。

### Spark History Server

当你运行Spark Standalone Mode或者Spark on Mesos模式时，你可以通过Spark History Server来查看job运行情况。

Spark History Server的环境变量：

属性名称| 含义
--- | --- | 
SPARK_DAEMON_MEMORY | Memory to allocate to the history server (default: 512m).
SPARK_DAEMON_JAVA_OPTS  | JVM options for the history server (default: none).
SPARK_PUBLIC_DNS  |  |
SPARK_HISTORY_OPTS  | 配置 spark.history.* 属性

Spark History Server的属性：

| 属性名称  |  默认 |  含义| 
| :---- |:---- | :---- | 
| spark.history.provider | org.apache.spark.deploy.history.FsHistoryProvide|应用历史后端实现的类名。 目前只有一个实现, 由Spark提供, 它查看存储在文件系统里面的应用日志 | 
| spark.history.fs.logDirectory | file:/tmp-events| | 
|  spark.history.updateInterval  | 10 | 以秒为单位，多长时间Spark history server显示的信息进行更新。每次更新都会检查持久层事件日志的任何变化。| 
|  spark.history.retainedApplications |  50 |  在Spark history server上显示的最大应用程序数量，如果超过这个值，旧的应用程序信息将被删除。| 
|  spark.history.ui.port  |  18080 |  官方版本中，Spark history server的默认访问端口| 
|  spark.history.kerberos.enabled |  false  | 是否使用kerberos方式登录访问history server，对于持久层位于安全集群的HDFS上是有用的。如果设置为true，就要配置下面的两个属性。| 
|  spark.history.kerberos.principal |  空  | 用于Spark history server的kerberos主体名称| 
|  spark.history.kerberos.keytab  |  空 |  用于Spark history server的kerberos keytab文件位置| 
|  spark.history.ui.acls.enable |  false|   授权用户查看应用程序信息的时候是否检查acl。如果启用，只有应用程序所有者和`spark.ui.view.acls`指定的用户可以查看应用程序信息;如果禁用，不做任何检查。| 

## 环境变量

通过环境变量配置确定的Spark设置。环境变量从Spark安装目录下的`conf-env.sh`脚本读取（或者windows的`conf-env.cmd`）。在独立的或者Mesos模式下，这个文件可以给机器确定的信息，如主机名。当运行本地应用程序或者提交脚本时，它也起作用。

注意，当Spark安装时，`conf-env.sh`默认是不存在的。你可以复制`conf-env.sh.template`创建它。

可以在`spark-env.sh`中设置如下变量：

环境变量 | 含义
--- | ---
JAVA_HOME | Java安装的路径
PYSPARK_PYTHON | PySpark用到的Python二进制执行文件路径
SPARK_LOCAL_IP | 机器绑定的IP地址
SPARK_PUBLIC_DNS | 你Spark应用程序通知给其他机器的主机名

除了以上这些，Spark [standalone cluster scripts](http:/.apache.org/docs/latest-standalone.html#cluster-launch-scripts)也可以设置一些选项。例如每台机器使用的核数以及最大内存。

因为`spark-env.sh`是shell脚本，其中的一些可以以编程方式设置。例如，你可以通过特定的网络接口计算`SPARK_LOCAL_IP`。

## 配置日志

Spark用[log4j](http://logging.apache.org/log4j/) logging。你可以通过在conf目录下添加`log4j.properties`文件来配置。一种方法是复制`log4j.properties.template`文件。

---
layout: post

title: 安装和测试Kafka
date: 2015-03-17T08:00:00+08:00

categories: [ hadoop ]

tags: [ kafka ]

description: 本文主要介绍如何在单节点上安装 Kafka 并测试 broker、producer 和 consumer 功能。

published: true

---

本文主要介绍如何在单节点上安装 Kafka 并测试 broker、producer 和 consumer 功能。

# 下载

进入下载页面：<http://kafka.apache.org/downloads.html> ，选择 Binary downloads下载 （Source download需要编译才能使用），这里我下载 `kafka_2.11-0.8.2.1`，其对应的 Scala 版本为 `2.11`：

~~~bash
$ wget http://apache.fayea.com/kafka/0.8.2.1/kafka_2.11-0.8.2.1.tgz
~~~

解压并进入目录：

~~~bash
$ tar -xzvf kafka_2.11-0.8.2.1.tgz
$ cd kafka_2.11-0.8.2.1
~~~

查看目录结构：

~~~
tree -L 2
.
├── bin
│   ├── kafka-console-consumer.sh
│   ├── kafka-console-producer.sh
│   ├── kafka-consumer-offset-checker.sh
│   ├── kafka-consumer-perf-test.sh
│   ├── kafka-mirror-maker.sh
│   ├── kafka-preferred-replica-election.sh
│   ├── kafka-producer-perf-test.sh
│   ├── kafka-reassign-partitions.sh
│   ├── kafka-replay-log-producer.sh
│   ├── kafka-replica-verification.sh
│   ├── kafka-run-class.sh
│   ├── kafka-server-start.sh
│   ├── kafka-server-stop.sh
│   ├── kafka-simple-consumer-shell.sh
│   ├── kafka-topics.sh
│   ├── windows
│   ├── zookeeper-server-start.sh
│   ├── zookeeper-server-stop.sh
│   └── zookeeper-shell.sh
├── config
│   ├── consumer.properties
│   ├── log4j.properties
│   ├── producer.properties
│   ├── server.properties
│   ├── test-log4j.properties
│   ├── tools-log4j.properties
│   └── zookeeper.properties
├── libs
│   ├── jopt-simple-3.2.jar
│   ├── kafka_2.11-0.8.2.1.jar
│   ├── kafka_2.11-0.8.2.1-javadoc.jar
│   ├── kafka_2.11-0.8.2.1-scaladoc.jar
│   ├── kafka_2.11-0.8.2.1-sources.jar
│   ├── kafka_2.11-0.8.2.1-test.jar
│   ├── kafka-clients-0.8.2.1.jar
│   ├── log4j-1.2.16.jar
│   ├── lz4-1.2.0.jar
│   ├── metrics-core-2.2.0.jar
│   ├── scala-library-2.11.5.jar
│   ├── scala-parser-combinators_2.11-1.0.2.jar
│   ├── scala-xml_2.11-1.0.2.jar
│   ├── slf4j-api-1.7.6.jar
│   ├── slf4j-log4j12-1.6.1.jar
│   ├── snappy-java-1.1.1.6.jar
│   ├── zkclient-0.3.jar
│   └── zookeeper-3.4.6.jar
├── LICENSE
└── NOTICE

4 directories, 45 files
~~~

# 启动和停止

运行 kafka ，需要依赖 zookeeper，你可以使用已有的 zookeeper 集群或者利用 kafka 提供的脚本启动一个 zookeeper 实例：

~~~bash
$ bin/zookeeper-server-start.sh config/zookeeper.properties &  
~~~

默认的，zookeeper 会监听在 `*:2181/tcp`。

停止刚才启动的 zookeeper 实例：

~~~bash
$ bin/zookeeper-server-stop.sh  
~~~

启动Kafka server: 

~~~bash
$ bin/kafka-server-start.sh config/server.properties &  
~~~

config/server.properties 中有一些默认的配置参数，这里仅仅列出参数，不做解释：

~~~properties
broker.id=0

port=9092

#host.name=localhost

#advertised.host.name=<hostname routable by clients>

#advertised.port=<port accessible by clients>

num.network.threads=3

num.io.threads=8

socket.send.buffer.bytes=102400

socket.receive.buffer.bytes=102400

socket.request.max.bytes=104857600

log.dirs=/tmp/kafka-logs

num.partitions=1

num.recovery.threads.per.data.dir=1

#log.flush.interval.messages=10000

#log.flush.interval.ms=1000

log.retention.hours=168

#log.retention.bytes=1073741824

log.segment.bytes=1073741824

log.retention.check.interval.ms=300000

log.cleaner.enable=false

zookeeper.connect=localhost:2181

zookeeper.connection.timeout.ms=6000
~~~

如果你像我一样是在虚拟机中测试 kafka，那么你需要修改 kafka 启动参数中 JVM 内存大小。查看 kafka-server-start.sh 脚本，修改 `KAFKA_HEAP_OPTS` 处 `-Xmx` 和 `-Xms` 的值。

启动成功之后，会看到如下日志：

~~~
[2015-03-17 11:19:30,528] INFO Starting log flusher with a default period of 9223372036854775807 ms. (kafka.log.LogManager)
[2015-03-17 11:19:30,604] INFO Awaiting socket connections on 0.0.0.0:9092. (kafka.network.Acceptor)
[2015-03-17 11:19:30,605] INFO [Socket Server on Broker 0], Started (kafka.network.SocketServer)
[2015-03-17 11:19:30,687] INFO Will not load MX4J, mx4j-tools.jar is not in the classpath (kafka.utils.Mx4jLoader$)
[2015-03-17 11:19:30,756] INFO 0 successfully elected as leader (kafka.server.ZookeeperLeaderElector)
[2015-03-17 11:19:30,887] INFO Registered broker 0 at path  /brokers/ids/0 with address cdh1:9092. (kafka.utils.ZkUtils$)
[2015-03-17 11:19:30,928] INFO [Kafka Server 0], started (kafka.server.KafkaServer)
[2015-03-17 11:19:31,048] INFO New leader is 0 (kafka.server.ZookeeperLeaderElector$LeaderChangeListener)
~~~

从日志可以看到：

- log flusher 有一个默认的周期值
- kafka server 监听在9092端口
- 在 cdh1:9092 上注册了一个 broker 0 ，路径为 /brokers/ids/0

停止 Kafka server :

~~~bash
$ bin/kafka-server-stop.sh
~~~

# 单 broker 测试

在启动  kafka-server 之后启动，运行producer：

~~~bash
$ bin/kafka-console-producer.sh --broker-list localhost:9092 --topic test  
~~~

在另一个终端运行 consumer： 

~~~bash
$ bin/kafka-console-consumer.sh --zookeeper localhost:2181 --topic test --from-beginning  
~~~

在 producer 端输入字符串并回车，查看 consumer 端是否显示。 

# 多 broker 测试

## 配置和启动 Kafka broker

接下来参考 [Running a Multi-Broker Apache Kafka 0.8 Cluster on a Single Node](http://www.michael-noll.com/blog/images/03/13/running-a-multi-broker-apache-kafka-cluster-on-a-single-node/) 这篇文章，基于 config/server.properties 配置文件创建多个 broker 的 kafka 集群。

创建第一个 broker：

~~~bash
$ cp config/server.properties config/server1.properties
~~~

编写 config/server1.properties 并修改下面配置：

~~~properties
broker.id=1
port=9092
log.dir=/tmp/kafka-logs-1
~~~

创建第二个 broker：

~~~bash
$ cp config/server.properties config/server2.properties
~~~

编写 config/server2.properties 并修改下面配置：

~~~properties
broker.id=2
port=9093
log.dir=/tmp/kafka-logs-2
~~~

创建第三个 broker：

~~~bash
$ cp config/server.properties config/server3.properties
~~~

编写 config/server3.properties 并修改下面配置：

~~~properties
broker.id=3
port=9094
log.dir=/tmp/kafka-logs-3
~~~

接下来分别启动这三个 broker：

~~~bash
$ JMX_PORT=9999  ; nohup bin/kafka-server-start.sh config/server1.properties &
$ JMX_PORT=10000  ; nohup bin/kafka-server-start.sh config/server2.properties &
$ JMX_PORT=10001  ; nohup bin/kafka-server-start.sh config/server3.properties &
~~~

下面是三个 broker 监听的网络接口和端口列表：

~~~
        Broker 1     Broker 2      Broker 3
----------------------------------------------
Kafka   *:9092/tcp   *:9093/tcp    *:9094/tcp
JMX     *:9999/tcp   *:10000/tcp   *:10001/tcp
~~~

## 创建 Kafka topic

在 Kafka 0.8 中有两种方式创建一个新的 topic：

- 在 broker 上开启 `auto.create.topics.enable` 参数，当 broker 接收到一个新的 topic 上的消息时候，会通过 `num.partitions` 和 `default.replication.factor` 两个参数自动创建 topic。
- 使用 `bin/kafka-topics.sh` 命令

创建一个名称为 `zerg.hydra`  的 topic：

~~~bash
$ bin/kafka-topics.sh --zookeeper localhost:2181 --create --topic zerg.hydra --partitions 3 --replication-factor 2
~~~

使用下面查看创建的 topic:

~~~bash
$ bin/kafka-topics.sh --zookeeper localhost:2181 --list
test
zerg.hydra
~~~

还可以查看更详细的信息：

~~~bash
$ bin/kafka-topics.sh --zookeeper localhost:2181 --describe --topic zerg.hydra
Topic:zerg.hydra    PartitionCount:3    ReplicationFactor:2 Configs:
    Topic: zerg.hydra   Partition: 0    Leader: 2   Replicas: 2,3   Isr: 2,3
    Topic: zerg.hydra   Partition: 1    Leader: 3   Replicas: 3,0   Isr: 3,0
    Topic: zerg.hydra   Partition: 2    Leader: 0   Replicas: 0,2   Isr: 0,2
~~~

默认的，Kafka 持久化 topic 到 `log.dir` 参数定义的目录。

~~~bash
$ tree /tmp/kafka-logs-{1,2,3}
/tmp/kafka-logs-1                   # first broker (broker.id = 1)
├── zerg.hydra-0                    # replica of partition 0 of topic "zerg.hydra" (this broker is leader)
│   ├── 00000000000000000000.index
│   └── 00000000000000000000.log
├── zerg.hydra-2                    # replica of partition 2 of topic "zerg.hydra"
│   ├── 00000000000000000000.index
│   └── 00000000000000000000.log
└── replication-offset-checkpoint

/tmp/kafka-logs-2                   # second broker (broker.id = 2)
├── zerg.hydra-0                    # replica of partition 0 of topic "zerg.hydra"
│   ├── 00000000000000000000.index
│   └── 00000000000000000000.log
├── zerg.hydra-1                    # replica of partition 1 of topic "zerg.hydra" (this broker is leader)
│   ├── 00000000000000000000.index
│   └── 00000000000000000000.log
└── replication-offset-checkpoint

/tmp/kafka-logs-3                   # third broker (broker.id = 3)
├── zerg.hydra-1                    # replica of partition 1 of topic "zerg.hydra"
│   ├── 00000000000000000000.index
│   └── 00000000000000000000.log
├── zerg.hydra-2                    # replica of partition 2 of topic "zerg.hydra" (this broker is leader)
│   ├── 00000000000000000000.index
│   └── 00000000000000000000.log
└── replication-offset-checkpoint

6 directories, 15 files
~~~

## 启动一个 producer

以 `sync` 模式启动一个 producer：

~~~bash
$ bin/kafka-console-producer.sh --broker-list localhost:9092,localhost:9093,localhost:9094 --sync --topic zerg.hydra
~~~

然后，输入以下内容：

~~~
Hello, world!
Rock: Nerf Paper. Scissors is fine.
~~~

## 启动一个 consumer

在另一个终端运行：

~~~bash
$ bin/kafka-console-consumer.sh --zookeeper localhost:2181 --topic zerg.hydra --from-beginning
~~~

注意，生产环境通常不会添加 `--from-beginning` 参数。

观察输出，你会看到下面内容：

~~~
Hello, world!
Rock: Nerf Paper. Scissors is fine.
~~~

把 consumer 停掉再启动，你还会看到相同的输出结果。

# 将日志推送到 kafka

例如，将 apache 或者 nginx 或者 tomcat 等产生的日志 push 到 kafka，只需要执行下面代码即可：

~~~bash
$ tail -n 0 -f  /var/log/nginx/access.log | bin/kafka-console-producer.sh --broker-list localhost:9092,localhost:9093,localhost:9094 --sync --topic zerg.hydra
~~~

# 参考文章

- [Running a Multi-Broker Apache Kafka 0.8 Cluster on a Single Node](http://www.michael-noll.com/blog/images/03/13/running-a-multi-broker-apache-kafka-cluster-on-a-single-node/)
- [spark读取 kafka nginx网站日志消息 并写入HDFS中](http://yangqijun.com/archives/227)

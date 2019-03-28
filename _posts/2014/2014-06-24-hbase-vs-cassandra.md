---
layout: post

title:  HBase和Cassandra比较

description: 本文对HBase和Cassandra进行了多方面的特点分析，描述两者之间的区别。

keywords:  

category: hbase

tags: [hbase,cassandra,nosql]

published: true

---

HBase是一个开源的分布式存储系统。他可以看作是Google的Bigtable的开源实现。如同Google的Bigtable使用Google File System一样，HBase构建于和Google File System类似的Hadoop HDFS之上。  

Cassandra可以看作是Amazon Dynamo的开源实现。和Dynamo不同之处在于，Cassandra结合了Google   Bigtable的ColumnFamily的数据模型。可以简单地认为，Cassandra是一个P2P的，高可靠性并具有丰富的数据模型的分布式文件系统。

# HBase vs Cassandra

||HBase|Cassandra|
|:---|:---|:---|
|语言|Java|Java|
|出发点|BigTable|BigTable and Dynamo|
|License|Apache|Apache|
|Protocol|HTTP/REST (also Thrift)|Custom, binary (Thrift)|
|数据分布|表划分为多个region存在不同region server上|改进的一致性哈希（虚拟节点）|
|存储目标|大文件|小文件|
|一致性|强一致性|最终一致性，Quorum NRW策略|
|架构|master/slave|p2p|
|高可用性|NameNode是HDFS的单点故障点|P2P和去中心化设计，不会出现单点故障|
|伸缩性|Region Server扩容，通过将自身发布到Master，Master均匀分布Region|扩容需在Hash Ring上多个节点间调整数据分布|
|读写性能|数据读写定位可能要通过最多6次的网络RPC，性能较低。|数据读写定位非常快|
|数据冲突处理|乐观并发控制（optimistic concurrency control）|向量时钟|
|临时故障处理|Region Server宕机，重做HLog|数据回传机制：某节点宕机，hash到该节点的新数据自动路由到下一节点做 hinted handoff，源节点恢复后，推送回源节点。|
|永久故障恢复|Region Server恢复，master重新给其分配region|Merkle 哈希树，通过Gossip协议同步Merkle Tree，维护集群节点间的数据一致性|
|成员通信及错误检测|Zookeeper|基于Gossip|
|CAP|1，强一致性，0数据丢失。2，可用性低。3，扩容方便。|1，弱一致性，数据可能丢失。2，可用性高。3，扩容方便。|

# facebook为什么放弃Cassandra？

参考：<http://www.zhihu.com/question/19593207>:

> Facebook开发Cassandra初衷是用于Inbox Search，但是后来的Message System则使用了HBase，Facebook对此给出的解释是Cassandra的`最终一致性模型`不适合Message System，HBase具有更简单的一致性模型，当然还有其他的原因。HBase更加的成熟，成功的案例也比较多等等。Twitter和Digg都曾经很高调的选用Cassandra，但是最后也都放弃了，当然Twitter还有部分项目也还在使用Cassandra，但是主要的Tweet已经不是了。

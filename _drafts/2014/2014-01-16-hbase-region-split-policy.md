---
layout: post
title: HBase笔记：Region拆分策略
description: 新生成hbase的一个表的时候，整个集群中就只有一个新表的region分区，随着存储的数据增多，一个region就会水平分割为大小相等的2个region，这一过程是由HRegion Server自动处理的，期间不需要HMaster Server的参与。
category: hbase
tags: [hbase,hadoop]
---

# Region 概念

Region是表获取和分布的基本元素，由每个列族的一个Store组成。对象层级图如下：

~~~
Table       (HBase table)
    Region       (Regions for the table)
         Store          (Store per ColumnFamily for each Region for the table)
              MemStore        (MemStore for each Store for each Region for the table)
              StoreFile       (StoreFiles for each Store for each Region for the table)
                    Block     (Blocks within a StoreFile within a Store for each Region for the table)
~~~

# Region 大小

Region的大小是一个棘手的问题，需要考量如下几个因素。

- Region是HBase中分布式存储和负载均衡的最小单元。不同Region分布到不同RegionServer上，但并不是存储的最小单元。
- Region由一个或者多个Store组成，每个store保存一个columns family，每个Strore又由一个memStore和0至多个StoreFile 组成。memStore存储在内存中， StoreFile存储在HDFS上。
- HBase通过将region切分在许多机器上实现分布式。也就是说，你如果有16GB的数据，只分了2个region， 你却有20台机器，有18台就浪费了。
- region数目太多就会造成性能下降，现在比以前好多了。但是对于同样大小的数据，700个region比3000个要好。
- region数目太少就会妨碍可扩展性，降低并行能力。有的时候导致压力不够分散。这就是为什么，你向一个10节点的HBase集群导入200MB的数据，大部分的节点是idle的。
- RegionServer中1个region和10个region索引需要的内存量没有太多的差别。


最好是使用默认的配置，可以把热的表配小一点(或者受到split热点的region把压力分散到集群中)。如果你的cell的大小比较大(100KB或更大)，就可以把region的大小调到1GB。region的最大大小在hbase配置文件中定义：

~~~xml
 <property>
    <name>hbase.hregion.max.filesize</name>
    <value>10 * 1024 * 1024 * 1024</value>
  </property>
~~~

*说明：*

1. 当region中的StoreFile大小超过了上面配置的值的时候，该region就会被拆分，具体的拆分策略见下文。
2. 上面的值也可以针对每个表单独设置，例如在hbase shell中设置：

~~~sql
create 't','f'
disable 't'
alter 't', METHOD => 'table_att', MAX_FILESIZE => '134217728'
enable 't'
~~~

# Region 拆分策略

Region的分割操作是不可见的，因为Master不会参与其中。RegionServer拆分region的步骤是，先将该region下线，然后拆分，将其子region加入到META元信息中，再将他们加入到原本的RegionServer中，最后汇报Master。

*执行split的线程是CompactSplitThread。*

## 自定义拆分策略

可以通过设置`RegionSplitPolicy`的实现类来指定拆分策略，RegionSplitPolicy类的实现类有：

~~~
ConstantSizeRegionSplitPolicy
	IncreasingToUpperBoundRegionSplitPolicy
		DelimitedKeyPrefixRegionSplitPolicy
		KeyPrefixRegionSplitPolicy
~~~

对于split，并不是设置了`hbase.hregion.max.filesize`（默认10G）为很大就保证不split了，需要有以下的算法：

- IncreasingToUpperBoundRegionSplitPolicy，**0.94.0默认region split策略**。根据公式min(r^2*flushSize，maxFileSize)确定split的maxFileSize，其中r为在线region个数，maxFileSize由`hbase.hregion.max.filesize`指定。
- ConstantSizeRegionSplitPolicy，仅仅当region大小超过常量值（`hbase.hregion.max.filesize`大小）时，才进行拆分。
- DelimitedKeyPrefixRegionSplitPolicy，保证以分隔符前面的前缀为splitPoint，保证相同RowKey前缀的数据在一个Region中
- KeyPrefixRegionSplitPolicy，保证具有相同前缀的row在一个region中（要求设计中前缀具有同样长度）。指定rowkey前缀位数划分region，通过读取`table的prefix_split_key_policy.prefix_length`属性，该属性为数字类型，表示前缀长度，在进行split时，按此长度对splitPoint进行截取。此种策略比较适合固定前缀的rowkey。当table中没有设置该属性，或其属性不为Integer类型时，指定此策略效果等同与使用IncreasingToUpperBoundRegionSplitPolicy。


### IncreasingToUpperBoundRegionSplitPolicy

这是**0.94.0默认region split策略**。根据根据公式min(r^2*flushSize，maxFileSize)确定split的maxFileSize，这里假设flushSize为128M：

~~~
第一次拆分大小为：min(10G，1*1*128M)=128M
第二次拆分大小为：min(10G，3*3*128M)=1152M
第三次拆分大小为：min(10G，5*5*128M)=3200M
第四次拆分大小为：min(10G，7*7*128M)=6272M
第五次拆分大小为：min(10G，9*9*128M)=10G
第五次拆分大小为：min(10G，11*11*128M)=10G
~~~

可以看到，只有在第四次之后的拆分大小才为10G

## 配置拆分策略

你可以在hbase配置文件中定义全局的拆分策略，设置`hbase.regionserver.region.split.policy`的值即可，也可以在创建和修改表时候指定：

~~~java
// 更新现有表的split策略
HBaseAdmin admin = new HBaseAdmin( conf);
HTable hTable = new HTable( conf, "test" );
HTableDescriptor htd = hTable.getTableDescriptor();
HTableDescriptor newHtd = new HTableDescriptor(htd);
newHtd.setValue(HTableDescriptor. SPLIT_POLICY, KeyPrefixRegionSplitPolicy.class .getName());// 指定策略
newHtd.setValue("prefix_split_key_policy.prefix_length", "2");
newHtd.setValue("MEMSTORE_FLUSHSIZE", "5242880"); // 5M
admin.disableTable( "test");
admin.modifyTable(Bytes. toBytes("test"), newHtd);
admin.enableTable( "test");
~~~

*说明：*

1. 上面的不同策略可以在不同的业务场景下使用，特别是第三种和第四种一般关注和使用的比较少。
2. 如果想关闭自动拆分改为手动拆分，建议同时修改`hbase.hregion.max.filesize`和`hbase.regionserver.region.split.policy`值。


# 参考文章

- [1] [HBase的Compact和Split源码分析与应用--基于0.94.5](http://blog.csdn.net/doliu6/article/details/13505319)
- [2] [HBase源码分析之org.apache.hadoop.hbase.regionserver包](http://blog.csdn.net/yangbutao/article/details/8930126)
- [3] [HBase 官方文档中文版](http://abloz.com/hbase/book.html)
- [4] [hbase region split策略](http://blog.toby941.sinaapp.com/hbase-region-split.html)

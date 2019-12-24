---
layout: post

title:  编译Dubbo源码并测试
date: 2014-09-24T08:00:00+08:00

description:  Dubbo 是阿里巴巴内部的 SOA 服务化治理方案的核心框架，本文主要记录编译 Dubbo 源码和测试的过程。

keywords:  dubbo

categories: [  java ]

tags: [dubbo]

---

Dubbo是阿里巴巴内部的SOA服务化治理方案的核心框架，每天为2000+ 个服务提供3,000,000,000+ 次访问量支持，并被广泛应用于阿里巴巴集团的各成员站点。Dubbo自2011年开源后，已被许多非阿里系公司使用。 

- 项目主页：<http://alibaba.github.io/dubbo-doc-static/Home-zh.htm> 
- 项目源码：<https://github.com/alibaba/dubbo>

# 1. 安装

首先从 github 下载源代码并阅读 readme.md ，参考该文档，首先下载 [opensesame](https://github.com/alibaba/opensesame)，并编译：

~~~
$ git clone git@github.com:alibaba/opensesame.git
$ cd opensesame
$ mvn install
~~~

然后，下载 dubbo 并编译：

~~~bash
$ git clone git@github.com:alibaba/dubbo.git
$ cd dubbo
$ mvn clean install -Dmaven.test.skip
~~~

编译成功之后，生成 idea 相关配置文件：

~~~bash
$ mvn idea:idea
~~~

接下来，将代码通过 maven 的方式导入到 idea ide 中。


# 2. 测试

安装之后，现在来搭一个测试环境。搭建一个测试环境，需要下面三个角色：

- **消息提供者**，示例工程见：dubbo-demo-provider
- **消息注册中心**，有四种类型：multicast、zookeeper、redis、dubbo
- **消息消费者**，示例工程见：dubbo-demo-consumer

作为测试，这里消息注册中心使用 Multicast 注册中心，以下操作是在 idea 中运行。

首先，修改 Dubbo/dubbo-demo/dubbo-demo-provider/src/test/resources/dubbo.properties 文件如下：

~~~properties
dubbo.container=log4j,spring
dubbo.application.name=demo-provider
dubbo.application.owner=
dubbo.registry.address=multicast://224.5.6.7:1234?unicast=false
#dubbo.registry.address=zookeeper://127.0.0.1:2181
#dubbo.registry.address=redis://127.0.0.1:6379
#dubbo.registry.address=dubbo://10.1.19.41:20880
#dubbo.monitor.protocol=registry
dubbo.protocol.name=dubbo
dubbo.protocol.port=20880
dubbo.service.loadbalance=roundrobin
#dubbo.log4j.file=logs/dubbo-demo-consumer.log
#dubbo.log4j.level=WARN
~~~

>注意：
>
> **消息提供者和消息消费者建议在不同机器上运行**，如果在同一机器上，需设置 unicast=false：即：`multicast://224.5.6.7:1234?unicast=false`，否则发给消费者的单播消息可能被提供者抢占，两个消费者在同一台机器也一样，只有 multicast 注册中心有此问题。

然后，修改 Dubbo/dubbo-demo/dubbo-demo-consumer/src/test/resources/dubbo.properties 文件如下：

~~~properties
dubbo.container=log4j,spring
dubbo.application.name=demo-consumer
dubbo.application.owner=
dubbo.registry.address=multicast://224.5.6.7:1234?unicast=false
#dubbo.registry.address=zookeeper://127.0.0.1:2181
#dubbo.registry.address=redis://127.0.0.1:6379
#dubbo.registry.address=dubbo://10.1.19.41:20880
dubbo.monitor.protocol=registry
#dubbo.log4j.file=logs/dubbo-demo-consumer.log
#dubbo.log4j.level=WARN
~~~

接下来，就可以运行 dubbo-demo-provider 和 dubbo-demo-consumer 了。

在 idea 中右键运行 Dubbo/dubbo-demo/dubbo-demo-provider/src/test/java/com/alibaba/dubbo/demo/provider/DemoProvider.java 类，以启动 dubbo-demo-provider 。

在 idea 中右键运行 Dubbo/dubbo-demo/dubbo-demo-consumer/src/test/java/com/alibaba/dubbo/demo/consumer/DemoConsumer.java 类，以启动 dubbo-demo-consumer 。

最后，观察终端输出的日志，dubbo-demo-provider 中输出如下内容：

~~~
[17:13:19] Hello world458, request from consumer: /10.1.19.41:57319, cookie:iamsorry
[17:13:21] Hello world459, request from consumer: /10.1.19.41:57319, cookie:iamsorry
[17:13:23] Hello world460, request from consumer: /10.1.19.41:57319, cookie:iamsorry
[17:13:25] Hello world461, request from consumer: /10.1.19.41:57319, cookie:iamsorry
~~~

而 dubbo-demo-consumer 中输出如下内容

~~~
[17:13:17] Hello world458, response form provider: 10.1.19.41:20880
cookie->iamsorry
abc->17:13:19
Key 1->1
Key 2->2
codec->neg
output->135
[17:13:20] Hello world459, response form provider: 10.1.19.41:20880
cookie->iamsorry
abc->17:13:21
Key 1->1
Key 2->2
codec->neg
output->135
~~~

接下来，你可以试试使用其他的消息注册方式。

使用类似的方式，你也可以启动 dubbo-admin 和 dubbo-monitor-simple，需要注意的是，**如果你是在一台机器上启动这两个服务，则需要修改 dubbo.properties 中的端口以避免端口冲突**。

# 3. 其他

简单谈谈个人对 dubbo 项目的看法：

- 1. 项目导入到 IDE 之后，使用的是 jdk 1.5 进行编译，需要手动一个一个地修改为 1.6。
- 2. 项目没有使用统一的 code-template ，代码风格不统一。
- 3. 文档不够规范，缺少一些能够快速上手的用户文档。
- 4. dubbo 是获取第一个网卡的 ip 地址，当有多个网卡或者使用 VPN 时候会存在问题。
- 5. dubbo 依赖的 Spring 和 Netty 版本都较低
- 6. 有些类和注解中的属性过多，显得比较臃肿，当然，这是强迫性症了。

以上仅仅代表个人意见。







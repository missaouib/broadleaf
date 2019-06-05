---
layout: post

title: Apache Sentry架构介绍

category: hadoop

tags: [ sentry,hive,impala ]

description:  Apache Sentry是Cloudera公司发布的一个Hadoop开源组件，截止目前还是Apache的孵化项目，它提供了细粒度级、基于角色的授权以及多租户的管理模式。Sentry当前可以和Hive/Hcatalog、Apache Solr 和Cloudera Impala集成，未来会扩展到其他的Hadoop组件，例如HDFS和HBase。

published: true

---

# 介绍

[Apache Sentry](https://sentry.incubator.apache.org/)是Cloudera公司发布的一个Hadoop开源组件，截止目前还是Apache的孵化项目，它提供了细粒度级、基于角色的授权以及多租户的管理模式。Sentry当前可以和Hive/Hcatalog、Apache Solr 和Cloudera Impala集成，未来会扩展到其他的Hadoop组件，例如HDFS和HBase。

# 特性

Apache Sentry为Hadoop使用者提供了以下便利：

- 能够在Hadoop中存储更敏感的数据
- 使更多的终端用户拥有Hadoop数据访问权
- 创建更多的Hadoop使用案例
- 构建多用户应用程序
- 符合规范（例如SOX，PCI，HIPAA，EAL3）

在Sentry诞生之前，对于授权有两种备选解决方案：`粗粒度级的HDFS授权`和`咨询授权`，但它们并不符合典型的规范和数据安全需求，原因如下：

- `粗粒度级的HDFS授权`：安全访问和授权的基本机制被HDFS文件模型的粒度所限制。五级授权是粗粒度的，因为没有对文件内数据的访问控制：用户要么可以访问整个文件，要么什么都看不到。另外，HDFS权限模式不允许多个组对同一数据集有不同级别的访问权限。
- `咨询授权`：咨询授权在Hive中是一个很少使用的机制，旨在使用户能够自我监管，以防止意外删除或重写数据。这是一种“自服务”模式，因为用户可以为自己授予任何权限。因此，一旦恶意用户通过认证，它不能阻止其对敏感数据的访问。

通过引进Sentry，Hadoop目前可在以下方面满足企业和政府用户的RBAC需求：

- `安全授权`：Sentry可以控制数据访问，并对已通过验证的用户提供数据访问特权。
- `细粒度访问控制`：Sentry支持细粒度的Hadoop数据和元数据访问控制。在Hive和Impala中Sentry的最初发行版本中，Sentry在服务器、数据库、表和视图范围提供了不同特权级别的访问控制，包括查找、插入等，允许管理员使用视图限制对行或列的访问。管理员也可以通过Sentry和带选择语句的视图或UDF，根据需要在文件内屏蔽数据。
- `基于角色的管理`：Sentry通过基于角色的授权简化了管理，你可以轻易将访问同一数据集的不同特权级别授予多个组。
- `多租户管理`：Sentry允许为委派给不同管理员的不同数据集设置权限。在Hive/Impala的情况下，Sentry可以在数据库/schema级别进行权限管理。
- `统一平台`：Sentry为确保数据安全，提供了一个统一平台，使用现有的Hadoop Kerberos实现安全认证。同时，通过Hive或Impala访问数据时可以使用同样的Sentry协议。未来，Sentry协议会被扩展到其它组件。

# 如何工作

Apache Sentry的目标是实现授权管理，它是一个策略引擎，被数据处理工具用来验证访问权限。它也是一个高度扩展的模块，可以支持任何的数据模型。当前，它支持Apache Hive和Cloudera Impala的关系数据模型，以及Apache中的有继承关系的数据模型。

Sentry提供了定义和持久化访问资源的策略的方法。目前，这些策略可以存储在文件里或者是能使用RPC服务访问的数据库后端存储里。数据访问工具，例如Hive，以一定的模式辨认用户访问数据的请求，例如从一个表读一行数据或者删除一个表。这个工具请求Sentry验证访问是否合理。Sentry构建请求用户被允许的权限的映射并判断给定的请求是否允许访问。请求工具这时候根据Sentry的判断结果来允许或者禁止用户的访问请求。

Sentry授权包括以下几种角色：

- `资源`。可能是`Server`、`Database`、`Table`、或者`URL`（例如：HDFS或者本地路径）。Sentry1.5中支持对`列`进行授权。
- `权限`。授权访问某一个资源的规则。
- `角色`。角色是一系列权限的集合。
- `用户和组`。一个组是一系列用户的集合。Sentry 的组映射是可以扩展的。默认情况下，Sentry使用Hadoop的组映射（可以是操作系统组或者LDAP中的组）。Sentry允许你将用户和组进行关联，你可以将一系列的用户放入到一个组中。Sentry不能直接给一个用户或组授权，需要将权限授权给角色，角色可以授权给一个组而不是一个用户。

# 架构

下面是Sentry架构图，图片来自《[Apache Sentry architecture overview](http://developer.51cto.com/art/201502/465091.htm)》。

![](https://blogs.apache.org/sentry/mediaresource/c07e8094-e79a-4c97-aa9e-cbb2b18fe9b2)

Sentry的体系结构中有三个重要的组件：一是Binding；二是Policy Engine；三是Policy Provider。

## Binding

Binding实现了对不同的查询引擎授权，Sentry将自己的Hook函数插入到各SQL引擎的编译、执行的不同阶段。这些Hook函数起两大作用：一是起过滤器的作用，只放行具有相应数据对象访问权限的SQL查询；二是起授权接管的作用，使用了Sentry之后，grant/revoke管理的权限完全被Sentry接管，grant/revoke的执行也完全在Sentry中实现；对于所有引擎的授权信息也存储在由Sentry设定的统一的数据库中。这样所有引擎的权限就实现了集中管理。

## Policy Engine

这是Sentry授权的核心组件。Policy Engine判定从binding层获取的输入的权限要求与服务提供层已保存的权限描述是否匹配。

## Policy Provider

Policy Provider负责从文件或者数据库中读取出原先设定的访问权限。Policy Engine以及Policy Provider其实对于任何授权体系来说都是必须的，因此是公共模块，后续还可服务于别的查询引擎。

基于文件的提供者使用的是ini格式的文件保存元数据信息，这个文件可以是一个本地文件或者HDFS文件。下面是一个例子：

~~~ini
[groups]
# Assigns each Hadoop group to its set of roles
manager = analyst_role, junior_analyst_role
analyst = analyst_role

admin = admin_role
[roles]
analyst_role = server=server1->db=analyst1, \
   server=server1->db=jranalyst1->table=*->action=select, \
   server=server1->uri=hdfs://ha-nn-uri/landing/analyst1, \
   server=server1->db=default->table=tab2
# Implies everything on server1.
admin_role = server=server1
~~~

基于文件的方式不易于使用程序修改，在修改过程中会存在资源竞争，不利于维护。Hive和Impala需要提供工业标准的SQL接口来管理授权策略，要求能够使用编程的方式进行管理。

Sentry策略存储和服务将角色和权限以及组合角色的映射持久化到一个关系数据库并提供编程的API接口方便创建、查询、更新和删除。这允许Sentry的客户端并行和安全地获取和修改权限。

![](https://blogs.apache.org/sentry/mediaresource/d9cc7fbc-dbf0-4dcb-a065-3f4d95878c00)

Sentry策略存储可以使用很多后端的数据库，例如MySQL、Postgres等等，它使用ORM库DataNucleus来完成持久化操作。Sentry支持kerberos认证，也可以扩展代码支持其他认证方式。

# 使用

## 和Hive集成

Sentry策略引擎通过hook的方式插入到hive中，hiveserver2在查询成功编译之后执行这个hook。

![](https://blogs.apache.org/sentry/mediaresource/c7680848-aa39-46cc-8165-0fc27b8b12db)

这个hook获得这个查询需要以读和写的方式访问的对象，然后Sentry的Hive binding基于SQL授权模型将他们转换为授权的请求。

策略维护：

![](https://blogs.apache.org/sentry/mediaresource/6b3b87ce-5054-40ab-90a2-0711dda06678)

策略维护包括两个步骤。在查询编译期间，hive调用Sentry的授权任务工厂来生产会在查询过程中执行的Sentry的特定任务行。这个任务调用Sentry存储客户端发送RPC请求给Sentry服务要求改变授权策略。

## 和HCatalog集成

![](https://blogs.apache.org/sentry/mediaresource/eb8c8249-189f-404a-a348-8f5722b4d1ed)

Sentry通过pre-listener hook集成到Hive Metastore。metastore在执行metadata维护请求之前执行这个hook。metastore binding为提交给metastore和HCatalog客户端的metadata修改请求创建一个Sentry授权请求。

网上关于sentry配置和使用的例子：

- [Securing Impala for analysts](http://blog.evernote.com/tech/2014/06/09/securing-impala-for-analysts/)
- [安装和配置Sentry](/2015/04/30/install-and-config-sentry.html)
- [测试Hive集成Sentry](/2015/04/30/test-hive-with-sentry.html)
- [配置安全的Hive集群集成Sentry](/2014/11/14/config-secured-hive-with-sentry.html)
- [配置安全的Impala集群集成Sentry](/2014/11/14/config-secured-impala-with-sentry.html)

# 参考文章

- [Apache Sentry architecture overview](https://blogs.apache.org/sentry/tags/architecture)
- [为什么Cloudera要创建Hadoop安全组件Sentry？](http://developer.51cto.com/art/201502/465091.htm)
- [Cloudera发布Hadoop开源组件Sentry：提供细粒度基于角色的安全控制](http://www.csdn.net/article/2013-08-14/2816575-with-sentry-cloudera-fills-hadoops-enterprise-security-gap)

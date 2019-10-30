---
layout: post
title:  BroadLeaf项目集成SolrCloud
date: 2014-03-14T08:00:00+08:00
description: 主要介绍 BroadLeaf 项目如何集成 SolrCloud 集群
categories: [ search-engine ]
tags: [solr, solrcloud, broadleaf] 
---

这篇文章主要介绍 BroadLeaf 项目如何集成 SolrCloud 集群。

# 1、SolrCloud环境搭建

参考 《[Apache SolrCloud安装](/2014/03/10/how-to-install-solrcloud.html)》，搭建Solr集群环境，将 Demosite 所用的 Solr 配置文件 solrconfig.xml 和 schema.xml 上传到 zookeeper 集群中，保证成功启动 Solr 集群。

# 2、扩展SearcheService类

扩展SearchService类的步骤与单节点集成一致，此处不再叙述。

# 3、修改Solr相关配置文件

a) 删除site模块中的site/src/main/webapp/WEB-INF/applicationContext.xml中的以下代码：

~~~xml
<bean id="solrEmbedded" class="java.lang.String">
          <constructor-arg value="solrhome"/>
</bean>
<bean id="blSearchService" class="org.broadleafcommerce.core.search.service.solr.SolrSearchServiceImpl">
        <constructor-arg name="solrServer" ref="${solr.source}" />
        <constructor-arg name="reindexServer" ref="${solr.source.reindex}" />
</bean>
~~~

b)删除site模块的site/src/main/resources/runtime-properties/common.properties中以下代码：

~~~properties
solr.source=solrEmbedded
solr.source.reindex=solrEmbedded
~~~

c)在core模块中core/src/main/resources/applicationContext.xml添加如下代码：

~~~xml
<bean id="solrServer" class="org.apache.solr.client.solrj.impl.CloudSolrServer">
        <constructor-arg value="${solr.url}"/>
        <property name="defaultCollection" value="product" />
        <property name="zkClientTimeout" value="20000" />
        <property name="zkConnectTimeout" value="1000" />
</bean>
<bean id="solrReindexServer" class="org.apache.solr.client.solrj.impl.CloudSolrServer">
        <constructor-arg value="${solr.url.reindex}" />
        <property name="defaultCollection" value="product" />
        <property name="zkClientTimeout" value="20000" />
        <property name="zkConnectTimeout" value="1000" />
</bean>
<bean id="blSearchService"         class="org.broadleafcommerce.core.search.service.solr.ExtSolrSearchServiceImpl">
        <constructor-arg name="solrServer" ref="${solr.source}" />
        <constructor-arg name="reindexServer" ref="${solr.source.reindex}"/>
</bean>
~~~

> 注：上述配置中的defaultCollection的值product对应solr集群的collection名字，根据实际情况修改此处的值。

d) 在 core模块中core/src/main/resources/runtime-properties/common-shared.properties添加如下代码：

~~~properties
solr.url=192.168.56.121\:2181,192.168.56.122\:2181,1192.168.56.123\:2181
solr.url.reindex=192.168.56.121\:2181,192.168.56.122\:2181,1192.168.56.123\:2181
solr.source=solrServer
solr.source.reindex=solrReindexServer
~~~

# 4、重写rebuildIndex方法

在core模块的org.broadleafcommerce.core.search.service.solr包下添加LLSolrIndexServiceImpl，重写源码broadleaf-framework/SolrIndexServiceImpl中的rebuildIndex()方法，屏蔽如下代码：

~~~java
//      // Swap the active and the reindex cores
//      shs.swapActiveCores();
//      // If we are not in single core mode, we delete the documents for the unused core after swapping
//      if (!SolrContext.isSingleCoreMode()) {
//          deleteAllDocuments();
//      }
~~~ 

# 5、修改定时任务

 web系统启动时候，会查询数据库中商品，然后重建索引。该功能在applicationContext.xml中已经定义了定时任务，修改rebuildIndexJobDetail中的targetObject，对应rebuildIndex所在的服务类，如下：

 ~~~xml
<bean id="rebuildIndexJobDetail" class="org.springframework.scheduling.quartz.MethodInvokingJobDetailFactoryBean">
        <property name="targetObject" ref="llSolrIndexService" />
        <property name="targetMethod" value="rebuildIndex" />
    </bean> 
~~~

如果需要手动创建索引，则需要取消applicationContext.xml中定义的定时任务，步骤如下：

  a）去掉如下代码：

~~~xml  
<bean id="rebuildIndexJobDetail" class="org.springframework.scheduling.quartz.MethodInvokingJobDetailFactoryBean">
    <property name="targetObject" ref="blSearchService" />
    <property name="targetMethod" value="rebuildIndex" />
</bean>
<bean id="rebuildIndexTrigger" class="org.springframework.scheduling.quartz.SimpleTriggerBean">
    <property name="jobDetail" ref="rebuildIndexJobDetail" />
    <property name="startDelay" value="${solr.index.start.delay}" />
    <property name="repeatInterval" value="${solr.index.repeat.interval}" />
</bean>
<bean class="org.springframework.scheduling.quartz.SchedulerFactoryBean">
    <property name="triggers">
     <list>
        <ref bean="rebuildIndexTrigger" />
     </list>
    </property>
</bean>
~~~

b）编写main方法，打成jar包，然后编写shell脚本，用于手动重建索引或者设置定时任务。该类需要获取一个名称为blSearchService的bean，然后调用该bean的rebuildIndex方法，主要代码如下：

~~~java
@Resource(name = "blSearchService")
private SearchService extSolrSe earchService;
public void doRebuild(){
    extSolrSearchService.rebuildIndex();
}
~~~

6、扩展CatalogService

添加如下代码：

~~~java
@Resource(name = "blSearchService")
private ExtSolrSearchService extSolrSearchService;
~~~

修改该类的saveProduct方法如下：

~~~java
@Override
@Transactional("blTransactionManager")
public Product saveProduct(Product product) {
    Product dbProduct = catalogService.saveProduct(product);
    try {
        extSolrSearchService.addProductIndex(dbProduct);
    } catch (ServiceException e) {
        e.printStackTrace();
        throw new RuntimeException(e);
    } catch (IOException e) {
        e.printStackTrace();
        throw new RuntimeException(e);
    }
    return dbProduct;
}
~~~


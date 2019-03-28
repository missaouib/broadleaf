---
layout: post
title: BroadLeaf项目搜索功能改进
description: 如果你在用BroadLeaf开源项目定制开发自己的电子商务网站并使用了其自带的Solr搜索引起功能，那么这篇文章会对你有所帮助。
category: search-engine
tags: [solr, solrcloud, broadleaf]
---

Broadleaf Commerce 是一个开源的Java电子商务平台，基于Spring框架开发，提供一个可靠、可扩展的架构，可进行深度的定制和快速开发。


# 关于Solr

Broadleaf项目中关于商品的搜索使用了嵌入式的Solr服务器，这个从配置文件中可以看出来。

- 项目主页： [http://www.broadleafcommerce.com/](http://www.broadleafcommerce.com/)
- 示例网站： [http://demo.broadleafcommerce.org/](http://demo.broadleafcommerce.org/)
- 示例网站源代码： [https://github.com/BroadleafCommerce/DemoSite](https://github.com/BroadleafCommerce/DemoSite)

从示例网站源代码的[applicationContext.xml文件](https://github.com/BroadleafCommerce/DemoSite/blob/master/site/src/main/webapp/WEB-INF/applicationContext.xml)中可以看到关于solr的配置：

~~~xml
 	<bean id="solrEmbedded" class="java.lang.String">
        <constructor-arg value="solrhome"/>
    </bean>

   <bean id="blSearchService" class="org.broadleafcommerce.core.search.service.solr.SolrSearchServiceImpl">
        <constructor-arg name="solrServer" ref="${solr.source}" />
        <constructor-arg name="reindexServer" ref="${solr.source.reindex}" />
    </bean> 
    <bean id="rebuildIndexJobDetail" class="org.springframework.scheduling.quartz.MethodInvokingJobDetailFactoryBean">
        <property name="targetObject" ref="blSearchService" />
        <property name="targetMethod" value="rebuildIndex" />
    </bean> 
    <bean id="rebuildIndexTrigger" class="org.springframework.scheduling.quartz.SimpleTriggerFactoryBean">
        <property name="jobDetail" ref="rebuildIndexJobDetail" />
        <property name="startDelay" value="${solr.index.start.delay}" />
        <property name="repeatInterval" value="${solr.index.repeat.interval}" />
    </bean>
    <bean class="org.springframework.scheduling.quartz.SchedulerFactoryBean">
        <property name="triggers">
            <list>
                <ref bean="rebuildIndexTrigger" />
                <!--<ref bean="purgeCartTrigger" />-->
                <!--<ref bean="purgeCustomerTrigger" />-->
            </list>
        </property>
    </bean>
~~~

资源配置文件在[common.properties](https://github.com/BroadleafCommerce/DemoSite/blob/master/site/src/main/resources/runtime-properties/common.properties):

~~~
web.defaultPageSize=15
web.maxPageSize=100

solr.source=solrEmbedded
solr.source.reindex=solrEmbedded
solr.index.start.delay=5000
solr.index.repeat.interval=3600000
~~~

从上可以看出使用的Solr是嵌入式服务，Solr配置文件（schema.xml和solrconfig.xml）在 <https://github.com/BroadleafCommerce/DemoSite/tree/master/site/src/main/resources> 目录下。

从源代码SolrSearchServiceImpl.java中可以看出,一共启动了两个Solr服务，分别对应primary和reindex两个solrcore，primary用于查询，reindex用于重建索引。

# 改进搜索引擎

## 改进目标

本篇文章只是将嵌入式Solr服务换成独立运行的Solr服务，你还可以更进一步换成SolrCloud集群。

- 单独搭建搜素引擎服务器
- 支持增量更新索引
- 支持手动重建索引

## 设计思路

- 1.修改原系统中的嵌入式搜索引擎为独立部署的搜索引擎，安装方法见下文。
- 2.扩展原系统中的SolrSearchServiceImpl类，添加增加索引的方法。
- 3.修改原来系统中商品的service类（我这里调用的是LLCatalogServiceImpl，该类是新添加的），在saveProduct方法中添加往搜索引擎添加索引的方法。
- 4.修改原系统中solr相关的配置文件。
- 5.修改原系统中的重建索引的定时任务，以支持手动重建索引。

## 实现方法

### 1、搭建独立运行的solr服务器

你可以参考：[Apache Solr介绍及安装](/2014/02/26/how-to-install-solr.html)

关键在于solr/home的定义，以及在该目录下创建两个目录，分别为primary和reindex，两个目录下的配置文件都一样，solr/home目录结构如下：

~~~
➜  solrhome-solr  tree -L 3
.
├── primary
│   └── conf
│       ├── schema.xml
│       └── solrconfig.xml
├── reindex
│   └── conf
│       ├── schema.xml
│       └── solrconfig.xml
└── solr.xml

4 directories, 5 files
~~~

solr.xml文件内容如下：

~~~xml
<?xml version="1.0" encoding="UTF-8" ?>
<solr persistent="true">
  <cores defaultCoreName="primary" adminPath="/admin/cores">
    <core instanceDir="reindex" name="reindex"/>
    <core instanceDir="primary" name="primary"/>
  </cores>
</solr>
~~~

schema.xml内容和[原来的](https://github.com/BroadleafCommerce/DemoSite/blob/master/site/src/main/resources/schema.xml)基本一样，只是添加了一行：

~~~xml
<field name="_version_" type="long" indexed="true" stored="true" multiValued="false"/>
~~~

solrconfig.xml内容如下：

~~~xml
<?xml version="1.0" encoding="UTF-8" ?>
<config>
  <luceneMatchVersion>4.4</luceneMatchVersion>
  <directoryFactory name="DirectoryFactory" class="${solr.directoryFactory:solr.StandardDirectoryFactory}"/>

  <schemaFactory class="ClassicIndexSchemaFactory"/>

  <updateHandler class="solr.DirectUpdateHandler2">
	<autoCommit>
		<maxDocs>2</maxDocs>
		<maxTime>3000</maxTime>
	</autoCommit>
  </updateHandler>

  <requestHandler name="/get" class="solr.RealTimeGetHandler">
    <lst name="defaults">
      <str name="omitHeader">true</str>
    </lst>
  </requestHandler>
  
  <requestHandler name="/replication" class="solr.ReplicationHandler" startup="lazy" /> 

  <requestDispatcher handleSelect="true" >
    <requestParsers enableRemoteStreaming="false" multipartUploadLimitInKB="2048" formdataUploadLimitInKB="2048" />
    <httpCaching never304="true" />
  </requestDispatcher>
  
  <requestHandler name="standard" class="solr.StandardRequestHandler" default="true" />
  <requestHandler name="/analysis/field" startup="lazy" class="solr.FieldAnalysisRequestHandler" />
  <requestHandler name="/update" class="solr.UpdateRequestHandler"  />
  <requestHandler name="/update/csv" class="solr.CSVRequestHandler" startup="lazy" />
  <requestHandler name="/update/json" class="solr.JsonUpdateRequestHandler" startup="lazy" />
  <requestHandler name="/admin/" class="org.apache.solr.handler.admin.AdminHandlers" />

  <requestHandler name="/admin/ping" class="solr.PingRequestHandler">
    <lst name="invariants">
      <str name="q">solrpingquery</str>
    </lst>
    <lst name="defaults">
      <str name="echoParams">all</str>
    </lst>
  </requestHandler>

  <queryResponseWriter name="json" class="solr.JSONResponseWriter">
        <str name="content-type">text/plain; charset=UTF-8</str>
  </queryResponseWriter>

  <!-- config for the admin interface --> 
  <admin>
    <defaultQuery>solr</defaultQuery>
  </admin>
</config>
~~~

### 2、扩展SolrSearchServiceImpl类

在core模块创建org.broadleafcommerce.core.search.service.solr.ExtSolrSearchService接口，该接口定义如下：

~~~java
package org.broadleafcommerce.core.search.service.solr;
import java.io.IOException;
import org.broadleafcommerce.common.exception.ServiceException;
import org.broadleafcommerce.core.catalog.domain.Product;
import org.broadleafcommerce.core.search.service.SearchService;
 
public interface ExtSolrSearchService extends SearchService {
    public void addProductIndex(Product product) throws ServiceException,
            IOException;
}
~~~

然后，创建其实现类org.broadleafcommerce.core.search.service.solr.ExtSolrSearchServiceImpl，该实现类定义如下：

~~~java
package org.broadleafcommerce.core.search.service.solr;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import javax.annotation.Resource;
import javax.xml.parsers.ParserConfigurationException;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.apache.solr.client.solrj.SolrServer;
import org.apache.solr.client.solrj.SolrServerException;
import org.apache.solr.client.solrj.response.QueryResponse;
import org.apache.solr.common.SolrDocument;
import org.apache.solr.common.SolrDocumentList;
import org.apache.solr.common.SolrInputDocument;
import org.broadleafcommerce.common.exception.ServiceException;
import org.broadleafcommerce.common.locale.domain.Locale;
import org.broadleafcommerce.common.util.StopWatch;
import org.broadleafcommerce.common.util.TransactionUtils;
import org.broadleafcommerce.core.catalog.domain.Product;
import org.broadleafcommerce.core.search.domain.Field;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.TransactionStatus;
import org.xml.sax.SAXException;
 
public class ExtSolrSearchServiceImpl extends SolrSearchServiceImpl implements
        ExtSolrSearchService {
    private static final Log LOG = LogFactory
            .getLog(ExtSolrSearchServiceImpl.class);
    @Resource(name = "blSolrIndexService")
    protected SolrIndexServiceImpl solrIndexServiceImpl;
    public ExtSolrSearchServiceImpl(SolrServer solrServer,
            SolrServer reindexServer) {
        super(solrServer, reindexServer);
    }
    public ExtSolrSearchServiceImpl(SolrServer solrServer) {
        super(solrServer);
    }
    public ExtSolrSearchServiceImpl(String solrServer, String reindexServer)
            throws IOException, ParserConfigurationException, SAXException {
        super(solrServer, reindexServer);
    }
    public ExtSolrSearchServiceImpl(String solrServer) throws IOException,
            ParserConfigurationException, SAXException {
        super(solrServer);
    }
    public void addProductIndex(Product product) throws ServiceException,
            IOException {
        TransactionStatus status = TransactionUtils.createTransaction(
                "saveProduct", TransactionDefinition.PROPAGATION_REQUIRED,
                solrIndexServiceImpl.transactionManager, true);
        StopWatch s = new StopWatch();
        try {
            List<Field> fields = fieldDao.readAllProductFields();
            List<Locale> locales = solrIndexServiceImpl.getAllLocales();
            SolrInputDocument document = solrIndexServiceImpl.buildDocument(
                    product, fields, locales);
            if (LOG.isTraceEnabled()) {
                LOG.trace(document);
            }
            SolrContext.getServer().add(document);
            SolrContext.getServer().commit();
            TransactionUtils.finalizeTransaction(status,
                    solrIndexServiceImpl.transactionManager, false);
        } catch (SolrServerException e) {
            TransactionUtils.finalizeTransaction(status,
                    solrIndexServiceImpl.transactionManager, true);
            throw new ServiceException("Could not rebuild index", e);
        } catch (IOException e) {
            TransactionUtils.finalizeTransaction(status,
                    solrIndexServiceImpl.transactionManager, true);
            throw new ServiceException("Could not rebuild index", e);
        } catch (RuntimeException e) {
            TransactionUtils.finalizeTransaction(status,
                    solrIndexServiceImpl.transactionManager, true);
            throw e;
        }
        LOG.info(String.format("Finished adding index in %s", s.toLapString()));
    }
    protected List<Product> getProducts(QueryResponse response) {
        final List<Long> productIds = new ArrayList<Long>();
        SolrDocumentList docs = response.getResults();
        for (SolrDocument doc : docs) {
            productIds
                    .add((Long) doc.getFieldValue(shs.getProductIdFieldName()));
        }
        /**
         * TODO 请添加缓存相关代码
         */
        List<Product> products = productDao.readProductsByIds(productIds);
        // We have to sort the products list by the order of the productIds list
        // to maintain sortability in the UI
        if (products != null) {
            Collections.sort(products, new Comparator<Product>() {
                public int compare(Product o1, Product o2) {
                    return new Integer(productIds.indexOf(o1.getId()))
                            .compareTo(productIds.indexOf(o2.getId()));
                }
            });
        }
        return products;
    }
}
~~~

### 3、 修改solr相关配置文件

a. 删除web模块中/web/src/main/webapp/WEB-INF/applicationContext.xml的以下代码：

~~~xml
<bean id="blSearchService" class="org.broadleafcommerce.core.search.service.solr.SolrSearchServiceImpl">
    <constructor-arg name="solrServer" ref="${solr.source}" />
    <constructor-arg name="reindexServer" ref="${solr.source.reindex}" />
</bean>
~~~

b.删除web模块中web/src/main/resources/runtime-properties/common.properties的以下代码：

~~~
solr.source=solrEmbedded
solr.source.reindex=solrEmbedded
~~~

c. 在core模块中core/src/main/resources/applicationContext.xml添加如下代码：

~~~xml
<bean id="solrServer" class="org.apache.solr.client.solrj.impl.HttpSolrServer">
    <constructor-arg value="${solr.url}" />
</bean>
<bean id="solrReindexServer" class="org.apache.solr.client.solrj.impl.HttpSolrServer">
    <constructor-arg value="${solr.url.reindex}" />
</bean>
<bean id="blSearchService"
    class="org.broadleafcommerce.core.search.service.solr.ExtSolrSearchServiceImpl">
    <constructor-arg name="solrServer" ref="${solr.source}" />
    <constructor-arg name="reindexServer" ref="${solr.source.reindex}" />
</bean>
~~~

d. 在core模块中core/src/main/resources/runtime-properties/common-shared.properties添加如下代码：

~~~
solr.url=http://localhost:8080/solr
solr.url.reindex=http://localhost:8080/solr/reindex
solr.source=solrServer
solr.source.reindex=solrReindexServer
~~~

### 4、 修改LLCatalogServiceImpl类

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

### 5、 修改定时任务

a. web系统启动时候，会查询数据库中商品，然后重建索引。该功能在applicationContext.xml中已经定义了定时任务，建议取消该定时任务。去掉以下代码：

~~~xml
<bean id="rebuildIndexJobDetail"
    class="org.springframework.scheduling.quartz.MethodInvokingJobDetailFactoryBean">
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

b. 编写main方法，打成jar包，然后编写shell脚本，用于手动重建索引或者设置定时任务。该类需要获取一个名称为blSearchService的bean，然后调用该bean的rebuildIndex方法,主要代码如下。

~~~java
@Resource(name = "blSearchService")
private SearchService extSolrSearchService;
 
public void doRebuild(){
    extSolrSearchService.rebuildIndex();
}
~~~

### 6、单节点集成创建索引问题

a、创建索引异常
如果单节点Solr安装过程中有多个core，则创建索引的过程使用的是reindex的core，如果没有reindex这个core可能在启动项目时抛出如下异常：

~~~
Caused by: org.apache.solr.client.solrj.impl.HttpSolrServer$RemoteSolrException: Server at http://localhost:8780/solr/reindex returned non ok status:404, message:Not Found
~~~

解决办法：

修改Solrhome中的配置文件solr.xml，确保配置solr中的core包含reindex，并且在solrhome目录下有reindex的目录以及配置文件，如下所示：

~~~xml
<core name="reindex" instanceDir="reindex" />
~~~

b、solr查询异常

如果单节点solr中多个core，默认的core为primary，查询使用的是primary，而创建索引使用的是reindex，此时访问web查询到的还是原来primary的数据，而不是创建的索引数据。

解决办法：将创建索引的core作为默认使用的，修改solrhome/solr.xml如下：

~~~xml
<cores defaultCoreName="reindex" adminPath="/admin/cores">
~~~

c、启动项目创建索引，solr中查询不到

完成单节点集成，启动项目进行测试，启动完成，索引创建完成后，在solr的单节点中进行query，发现docs中没有添加索引。

解决办法：

经过debug调试添加索引的过程，发现如下代码导致添加索引的docs被删除。原因是solr中配置的core是多个，则执行deleteAllDocuments方法，所以添加的索引都被删除，在solr中多个core的情况下，要屏蔽如下代码。

~~~java
//      // Swap the active and the reindex cores
//      shs.swapActiveCores();
//      // If we are not in single core mode, we delete the documents for the
//      // unused core after swapping
//      if (!SolrContext.isSingleCoreMode()) {
//        deleteAllDocuments();
//      }
~~~


---
layout: post

title: MyBatis源码分析：Configuration

category: mybatis

tags: [mybatis]

description: MyBatis的最基础和常用的是Configuration类，它负责保存MyBatis的一些设置参数。

published: true

---

MyBatis依赖的jar不多，而且代码行数也没多少，其中使用了大量的设计模式，值得好好学习。下图是MyBatis的一张架构图，来自[Java框架篇---Mybatis 入门](http://www.imooc.com/article/1291)。

![](http://img.mukewang.com/55b1dbbd00016b6407090390.png)

Mybatis的功能架构分为三层：

- API接口层：提供给外部使用的接口API，开发人员通过这些本地API来操纵数据库。接口层一接收到调用请求就会调用数据处理层来完成具体的数据处理。
- 数据处理层：负责具体的SQL查找、SQL解析、SQL执行和执行结果映射处理等。它主要的目的是根据调用的请求完成一次数据库操作。
- 基础支撑层：负责最基础的功能支撑，包括连接管理、事务管理、配置加载和缓存处理，这些都是共用的东西，将他们抽取出来作为最基础的组件。为上层的数据处理层提供最基础的支撑。

MyBatis整个项目的包结构如下：

~~~
.
└── org
    └── apache
        └── ibatis
            ├── annotations
            ├── binding
            ├── builder
            ├── cache
            ├── cursor
            ├── datasource
            ├── exceptions
            ├── executor
            ├── io
            ├── jdbc
            ├── logging
            ├── mapping
            ├── parsing
            ├── plugin
            ├── reflection
            ├── scripting
            ├── session
            ├── transaction
            └── type
~~~

MyBatis的最基础和常用的是Configuration类，它负责保存MyBatis的一些设置参数，它依赖或者相关的包有：

- mapping：通过Environment设置应用环境，Environment依赖datasource和transaction包
- transaction：事务
- logging：设置日志
- type：管理type注册器，默认添加了很多常用类的注册器
- reflection：反射相关基础类
- cache：管理缓存
- scripting：运行脚本
- plugin：管理插件
- execution：获取execution

Configuration类的所有属性都是protected，其中一些属性是final的，主要提供了两个构造方法：

~~~java
public Configuration(Environment environment) {
  this();
  this.environment = environment;
}

public Configuration() {
  typeAliasRegistry.registerAlias("JDBC", JdbcTransactionFactory.class);
  typeAliasRegistry.registerAlias("MANAGED", ManagedTransactionFactory.class);

  typeAliasRegistry.registerAlias("JNDI", JndiDataSourceFactory.class);
  typeAliasRegistry.registerAlias("POOLED", PooledDataSourceFactory.class);
  typeAliasRegistry.registerAlias("UNPOOLED", UnpooledDataSourceFactory.class);

  typeAliasRegistry.registerAlias("PERPETUAL", PerpetualCache.class);
  typeAliasRegistry.registerAlias("FIFO", FifoCache.class);
  typeAliasRegistry.registerAlias("LRU", LruCache.class);
  typeAliasRegistry.registerAlias("SOFT", SoftCache.class);
  typeAliasRegistry.registerAlias("WEAK", WeakCache.class);

  typeAliasRegistry.registerAlias("DB_VENDOR", VendorDatabaseIdProvider.class);

  typeAliasRegistry.registerAlias("XML", XMLLanguageDriver.class);
  typeAliasRegistry.registerAlias("RAW", RawLanguageDriver.class);

  typeAliasRegistry.registerAlias("SLF4J", Slf4jImpl.class);
  typeAliasRegistry.registerAlias("COMMONS_LOGGING", JakartaCommonsLoggingImpl.class);
  typeAliasRegistry.registerAlias("LOG4J", Log4jImpl.class);
  typeAliasRegistry.registerAlias("LOG4J2", Log4j2Impl.class);
  typeAliasRegistry.registerAlias("JDK_LOGGING", Jdk14LoggingImpl.class);
  typeAliasRegistry.registerAlias("STDOUT_LOGGING", StdOutImpl.class);
  typeAliasRegistry.registerAlias("NO_LOGGING", NoLoggingImpl.class);

  typeAliasRegistry.registerAlias("CGLIB", CglibProxyFactory.class);
  typeAliasRegistry.registerAlias("JAVASSIST", JavassistProxyFactory.class);

  languageRegistry.setDefaultDriverClass(XMLLanguageDriver.class);
  languageRegistry.register(RawLanguageDriver.class);
}
~~~

说明：

- 第一个构造方法是通过Environment进行初始化，并调用第二个构造方法，Environment封装了数据源和事务，不同Environment下使用的数据源和事务不一样，例如，实际使用中会有生产和测试环境。
- 第二个构造方法，主要是注册一些别名并设置默认的语言驱动。

Configuration内部维护了以下几种注册器：

- `MapperRegistry`：管理Mapper接口
- `TypeHandlerRegistry`：管理类型处理器
- `TypeAliasRegistry`：注册别名，别名都是用的大写
- `LanguageDriverRegistry`：管理语言驱动

这些注册器内部都会维护一个或多个map，然后提供注册`register`的方法，并且他们都是需要实例化才能使用的，而不是单例的。在一个MyBatis应用的整个生命周期中，只会存在一个Configuration实例。

Configuration内部有一些Map类型的属性：

~~~java
protected final Map<String, MappedStatement> mappedStatements = new StrictMap<MappedStatement>("Mapped Statements collection");
protected final Map<String, Cache> caches = new StrictMap<Cache>("Caches collection");
protected final Map<String, ResultMap> resultMaps = new StrictMap<ResultMap>("Result Maps collection");
protected final Map<String, ParameterMap> parameterMaps = new StrictMap<ParameterMap>("Parameter Maps collection");
protected final Map<String, KeyGenerator> keyGenerators = new StrictMap<KeyGenerator>("Key Generators collection");

protected final Map<String, XNode> sqlFragments = new StrictMap<XNode>("XML fragments parsed from previous mappers");
~~~

可以看到，实际上是使用的`StrictMap`。每一个`StrictMap`都有一个名称，`put`和`get`操作时需要判断`key`是否为空，如果为空，则抛出异常。

Configuration内部有一些Collection类型的属性：

~~~java
protected final Collection<XMLStatementBuilder> incompleteStatements = new LinkedList<XMLStatementBuilder>();
protected final Collection<CacheRefResolver> incompleteCacheRefs = new LinkedList<CacheRefResolver>();
protected final Collection<ResultMapResolver> incompleteResultMaps = new LinkedList<ResultMapResolver>();
protected final Collection<MethodResolver> incompleteMethods = new LinkedList<MethodResolver>();
~~~

>为什么接口使用的是Collection而不是List？为什么实现类使用的是LinkedList而不是ArrayList？

更多的配置参数说明，见[XML 映射配置文件](http://www.mybatis.org/mybatis-3/zh/configuration.html)。

Configuration使用的一个例子：

~~~java
DataSource dataSource = ...;
TransactionFactory transactionFactory = new JdbcTransactionFactory();
Environment environment = new Environment("Production", transactionFactory, dataSource);
Configuration configuration = new Configuration(environment);
configuration.setLazyLoadingEnabled(true);
configuration.getTypeAliasRegistry().registerAlias(Blog.class);
configuration.addMapper(BlogMapper.class);
SqlSessionFactory sqlSessionFactory = new SqlSessionFactoryBuilder().build(configuration);
~~~

总结：

Configuration类保存着MyBatis的所有配置参数，并以此为入口为其他服务，如缓存、执行器等等，提供了一些接口，这样方便集中管理和维护代码，但似乎又违背了单一原则？所有配置参数都可以通过Configuration来设置，意味着所有的配置都是可替代的，这样就非常灵活了。


# 参考文章

- [Java框架篇---Mybatis 入门](http://www.imooc.com/article/1291)
- [【mybatis源码解析】整体架构解析](http://sukerz.scse.cn/index.php/2016/02/01/mybatis-framework/)

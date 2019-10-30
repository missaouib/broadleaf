---
layout: post

title: MyBatis源码分析：如何解析配置文件
date: 2016-04-21T08:00:00+08:00

categories: [ mybatis ]

tags: [mybatis]

keywords: mybatis

description: MyBatis可以使用xml或者注解的方式进行配置，不管是哪种方式，最终会将获取到的配置参数设置到Configuration类中，例如，SqlSessionFactoryBuilder类中就是通过解析XML来创建Configuration。

published: true

---

MyBatis可以使用xml或者注解的方式进行配置，不管是哪种方式，最终会将获取到的配置参数设置到`Configuration`类中，例如，`SqlSessionFactoryBuilder`类中就是通过解析XML来创建`Configuration`。

~~~java
public SqlSessionFactory build(InputStream inputStream, String environment, Properties properties) {
  try {
    XMLConfigBuilder parser = new XMLConfigBuilder(inputStream, environment, properties);
    return build(parser.parse());
  } catch (Exception e) {
    throw ExceptionFactory.wrapException("Error building SqlSession.", e);
  } finally {
    ErrorContext.instance().reset();
    try {
      inputStream.close();
    } catch (IOException e) {
      // Intentionally ignore. Prefer previous error.
    }
  }
}
~~~

MyBatis通过SqlSessionFactoryBuilder作为入口，通过传入配置文件，使用了BaseBuilder实现类进行配置文件解析，具体实现类是`XMLConfigBuilder`，在这里MyBatis对配置的项进行了全面解析，只不过不是所有的解析都放在了XMLConfigBuilder，XMLConfigBuilder解析了二级节点，并作为一个总入口，还有另外几个类继承了`BaseBuilder`，用于解析不同的配置。而解析到的配置项信息，基本都保存在了Configuration这个类，可以看到多处地方依赖到它。

XMLConfigBuilder类位于`org.apache.ibatis.builder`中，我们来看看该包下有哪些类及每个类实现过程。

XMLConfigBuilder是继承BaseBuilder的，BaseBuilder是一个抽象类，提供了一些protected的方法和三个属性：

- `Configuration`
- `TypeAliasRegistry`：从Configuration中获取
- `TypeHandlerRegistry`：从Configuration中获取

`BaseBuilder`的子类有：

- `XMLConfigBuilder`：解析MyBatis config文件
- `XMLMapperBuilder`：解析`SqlMap`映射文件
- `XMLStatementBuilder`：解析sql语句
- `SqlSourceBuilder`：
- `MapperAnnotationBuilder`：解析注解
- `MapperBuilderAssistant`：负责解析配置和`mapping`包下的接口交换

这里为什么不使用接口呢？

XMLConfigBuilder是用于解析XML配置文件，解析XML用的是`sax`方式，相关代码在`org.apache.ibatis.parsing`包下面，该包下面代码比较独立，可以复用到自己的项目中去，你懂的。

XMLConfigBuilder提供了几个构造方法，主要是为了初始化`XPathParser`。真正开始解析文件从下面代码开始：

~~~java
public Configuration parse() {
  if (parsed) {
    throw new BuilderException("Each XMLConfigBuilder can only be used once.");
  }
  parsed = true;
  parseConfiguration(parser.evalNode("/configuration"));
  return configuration;
}
~~~

该方法是调用`parseConfiguration`方法开始解析`/configuration`节点。

~~~java
private void parseConfiguration(XNode root) {
  try {
    Properties settings = settingsAsPropertiess(root.evalNode("settings"));
    //issue #117 read properties first
    propertiesElement(root.evalNode("properties"));
    loadCustomVfs(settings);
    typeAliasesElement(root.evalNode("typeAliases"));
    pluginElement(root.evalNode("plugins"));
    objectFactoryElement(root.evalNode("objectFactory"));
    objectWrapperFactoryElement(root.evalNode("objectWrapperFactory"));
    reflectionFactoryElement(root.evalNode("reflectionFactory"));
    settingsElement(settings);
    // read it after objectFactory and objectWrapperFactory issue #631
    environmentsElement(root.evalNode("environments"));
    databaseIdProviderElement(root.evalNode("databaseIdProvider"));
    typeHandlerElement(root.evalNode("typeHandlers"));
    mapperElement(root.evalNode("mappers"));
  } catch (Exception e) {
    throw new BuilderException("Error parsing SQL Mapper Configuration. Cause: " + e, e);
  }
}
~~~

该方法包括以下几个步骤：

- 解析settings节点
- 解析properties
- 解析typeAliases
- 解析plugins
- 解析objectFactory
- 解析objectWrapperFactory
- 解析environments
- 解析databaseIdProvider
- 解析typeHandlers
- 解析mappers，调用XMLMapperBuilder进行解析

其中，最复杂的是解析mappers：

~~~java
private void mapperElement(XNode parent) throws Exception {
  if (parent != null) {
    for (XNode child : parent.getChildren()) {
      if ("package".equals(child.getName())) {
        String mapperPackage = child.getStringAttribute("name");
        //添加包下面的mapper
        configuration.addMappers(mapperPackage);
      } else {
        String resource = child.getStringAttribute("resource");
        String url = child.getStringAttribute("url");
        String mapperClass = child.getStringAttribute("class");
        //三个参数只能设置一个
        if (resource != null && url == null && mapperClass == null) {
          ErrorContext.instance().resource(resource);
          InputStream inputStream = Resources.getResourceAsStream(resource);
          XMLMapperBuilder mapperParser = new XMLMapperBuilder(inputStream, configuration, resource, configuration.getSqlFragments());
          mapperParser.parse();
        } else if (resource == null && url != null && mapperClass == null) {
          ErrorContext.instance().resource(url);
          InputStream inputStream = Resources.getUrlAsStream(url);
          XMLMapperBuilder mapperParser = new XMLMapperBuilder(inputStream, configuration, url, configuration.getSqlFragments());
          mapperParser.parse();
        } else if (resource == null && url == null && mapperClass != null) {
          Class<?> mapperInterface = Resources.classForName(mapperClass);
          configuration.addMapper(mapperInterface);
        } else {
          throw new BuilderException("A mapper element may only specify a url, resource or class, but not more than one.");
        }
      }
    }
  }
}
~~~


分析XMLMapperBuilder：

~~~java
private XPathParser parser;
private MapperBuilderAssistant builderAssistant;
private Map<String, XNode> sqlFragments;
private String resource;
~~~

XMLMapperBuilder有四个属性，一个XMLMapperBuilder对应一个资源文件，需要一个XPath解析器和一个Mapper构建的帮助类，并保存sql片段。

提供了几个构造方法类初始化属性：

~~~java
@Deprecated
public XMLMapperBuilder(Reader reader, Configuration configuration, String resource, Map<String, XNode> sqlFragments, String namespace) {
  this(reader, configuration, resource, sqlFragments);
  this.builderAssistant.setCurrentNamespace(namespace);
}

@Deprecated
public XMLMapperBuilder(Reader reader, Configuration configuration, String resource, Map<String, XNode> sqlFragments) {
  this(new XPathParser(reader, true, configuration.getVariables(), new XMLMapperEntityResolver()),
      configuration, resource, sqlFragments);
}

public XMLMapperBuilder(InputStream inputStream, Configuration configuration, String resource, Map<String, XNode> sqlFragments, String namespace) {
  this(inputStream, configuration, resource, sqlFragments);
  this.builderAssistant.setCurrentNamespace(namespace);
}

public XMLMapperBuilder(InputStream inputStream, Configuration configuration, String resource, Map<String, XNode> sqlFragments) {
  this(new XPathParser(inputStream, true, configuration.getVariables(), new XMLMapperEntityResolver()),
      configuration, resource, sqlFragments);
}

private XMLMapperBuilder(XPathParser parser, Configuration configuration, String resource, Map<String, XNode> sqlFragments) {
  super(configuration);
  this.builderAssistant = new MapperBuilderAssistant(configuration, resource);
  this.parser = parser;
  this.sqlFragments = sqlFragments;
  this.resource = resource;
}
~~~

XMLMapperBuilder真正开始解析是在`parse`方法：

~~~java
public void parse() {
  //先判断文件是否加载
  if (!configuration.isResourceLoaded(resource)) {
    //解析/mapper节点
    configurationElement(parser.evalNode("/mapper"));
    configuration.addLoadedResource(resource);
    //绑定mapper到命名空间
    bindMapperForNamespace();
  }

  parsePendingResultMaps();
  parsePendingChacheRefs();
  parsePendingStatements();
}
~~~

`configurationElement`方法如下：

~~~java
private void configurationElement(XNode context) {
  try {
    //设置命名空间

    String namespace = context.getStringAttribute("namespace");
    if (namespace == null || namespace.equals("")) {
      throw new BuilderException("Mapper's namespace cannot be empty");
    }
    builderAssistant.setCurrentNamespace(namespace);
    //cache-ref节点
    cacheRefElement(context.evalNode("cache-ref"));
    //cache节点
    cacheElement(context.evalNode("cache"));
    //parameterMap节点
    parameterMapElement(context.evalNodes("/mapper/parameterMap"));
    //resultMap节点
    resultMapElements(context.evalNodes("/mapper/resultMap"));
    //sql节点
    sqlElement(context.evalNodes("/mapper/sql"));
    //select|insert|update|delete节点
    buildStatementFromContext(context.evalNodes("select|insert|update|delete"));
  } catch (Exception e) {
    throw new BuilderException("Error parsing Mapper XML. Cause: " + e, e);
  }
~~~

从上面例子可以看出`mapper`下面一共有以下几种节点：

- cache-ref
- cache
- parameterMap
- resultMap
- sql
- select
- insert
- update
- delete

每个节点的解析过程请看具体的某一个方法，这里不做说明。


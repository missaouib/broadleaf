---
layout: post

title: MyBatis源码分析：SqlSession
date: 2016-04-21T08:00:00+08:00

categories: [ mybatis ]

tags: [mybatis]

keywords: mybatis

description: 了解MyBatis中SqlSession类的实现过程。

published: true

---

从这段代码中可以看到MyBatis的初始化过程：

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

在创建了Configuration之后，通过`SqlSessionFactoryBuilder`来构建一个SqlSessionFactory。SqlSessionFactoryBuilder是构建SqlSessionFactory的一个工具类，但其不是被声明为静态或者单例的，而是需要通过new实例化。

SqlSessionFactoryBuilder类重载了以下几个`build`方法，每个build方法其实最终会调用`build(Configuration config)`方法：

~~~java
public SqlSessionFactory build(Reader reader)
public SqlSessionFactory build(Reader reader, String environment)
public SqlSessionFactory build(Reader reader, Properties properties)
public SqlSessionFactory build(Reader reader, String environment, Properties properties)
public SqlSessionFactory build(InputStream inputStream)
public SqlSessionFactory build(InputStream inputStream, String environment)
public SqlSessionFactory build(InputStream inputStream, Properties properties)
public SqlSessionFactory build(InputStream inputStream, String environment, Properties properties)
public SqlSessionFactory build(Configuration config)
~~~

MyBatis通过SqlSessionFactoryBuilder作为入口，通过传入配置文件，使用了BaseBuilder实现类进行配置文件解析，具体实现类是XMLConfigBuilder，在这里mybatis对配置的项进行了全面解析，只不过不是所有的解析都放在了XMLConfigBuilder，XMLConfigBuilder解析了二级节点，并作为一个总入口，还有另外几个类继承了BaseBuilder，用于解析不同的配置。而解析到的配置项信息，基本都保存在了Configuration这个类，可以看到多处地方依赖到它。

从源码可以看出，`SqlSessionFactoryBuilder`的作用是完成从`输入流`、`environment`、`Properties`实例化一个`Configuration`，最终调用`new DefaultSqlSessionFactory(config)`来构建一个SqlSessionFactory的实例。

~~~java
public SqlSessionFactory build(Configuration config) {
  return new DefaultSqlSessionFactory(config);
}
~~~

`DefaultSqlSessionFactory`只有一个构造方法：

~~~java
public class DefaultSqlSessionFactory implements SqlSessionFactory {

  private final Configuration configuration;

  public DefaultSqlSessionFactory(Configuration configuration) {
    this.configuration = configuration;
  }
}
~~~

如果是我实现DefaultSqlSessionFactory该类的逻辑，可能就会重载多个构造方法，事实上以前也是这样想的，例如：

~~~java
public DefaultSqlSessionFactory(Reader reader)
public DefaultSqlSessionFactory(Reader reader, String environment)
public DefaultSqlSessionFactory(Reader reader, Properties properties)
public DefaultSqlSessionFactory(Reader reader, String environment, Properties properties)
public DefaultSqlSessionFactory(InputStream inputStream)
public DefaultSqlSessionFactory(InputStream inputStream, String environment)
public DefaultSqlSessionFactory(InputStream inputStream, Properties properties)
public DefaultSqlSessionFactory(InputStream inputStream, String environment, Properties properties)
public DefaultSqlSessionFactory(Configuration config)
~~~

这样的话，DefaultSqlSessionFactory的构造方法就会比较臃肿，DefaultSqlSessionFactory实际上只需要和Configuration打交道即可，故可以将从`Reader`、`InputStream`、`environment`、`Properties`生成Configuration的逻辑移到另外一个类中，从而减少DefaultSqlSessionFactory类干的事情，让其只和Configuration产生依赖。这样每个类的职责更加分明，SqlSessionFactoryBuilder负责构建SqlSessionFactory，DefaultSqlSessionFactory只负责生产SqlSession。

SqlSessionFactory是从一个连接或者数据源创建一个SqlSession，一个SqlSession代表一次会话，会话结束之后，连接和数据源并不会关闭。

~~~java
public interface SqlSessionFactory {

  SqlSession openSession();

  SqlSession openSession(boolean autoCommit);
  SqlSession openSession(Connection connection);
  SqlSession openSession(TransactionIsolationLevel level);

  SqlSession openSession(ExecutorType execType);
  SqlSession openSession(ExecutorType execType, boolean autoCommit);
  SqlSession openSession(ExecutorType execType, TransactionIsolationLevel level);
  SqlSession openSession(ExecutorType execType, Connection connection);

  Configuration getConfiguration();

}
~~~

DefaultSqlSessionFactory是MyBatis提供的SqlSessionFactory接口的默认实现类，其主要逻辑如下：

~~~java
private SqlSession openSessionFromDataSource(ExecutorType execType, TransactionIsolationLevel level, boolean autoCommit) {
  Transaction tx = null;
  try {
    final Environment environment = configuration.getEnvironment();
    final TransactionFactory transactionFactory = getTransactionFactoryFromEnvironment(environment);
    tx = transactionFactory.newTransaction(environment.getDataSource(), level, autoCommit);
    final Executor executor = configuration.newExecutor(tx, execType);
    return new DefaultSqlSession(configuration, executor, autoCommit);
  } catch (Exception e) {
    closeTransaction(tx); // may have fetched a connection so lets call close()
    throw ExceptionFactory.wrapException("Error opening session.  Cause: " + e, e);
  } finally {
    ErrorContext.instance().reset();
  }
}
~~~

其主要逻辑如下：

- 从configuration获取environment
- 从environment获取事务工厂类`TransactionFactory`，并由工厂类创建事务。
- 通过事务和执行类型来创建执行类`Executor`
- 通过执行类Executor来创建默认的`DefaultSqlSession`，可以想象的到DefaultSqlSession的主要逻辑都是委托给执行类`Executor`来执行。

DefaultSqlSession主要实现了SqlSession接口定义的方法：

~~~java
<T> T selectOne(String statement);
<T> T selectOne(String statement, Object parameter);
<E> List<E> selectList(String statement);
<E> List<E> selectList(String statement, Object parameter);
<E> List<E> selectList(String statement, Object parameter, RowBounds rowBounds);
<K, V> Map<K, V> selectMap(String statement, String mapKey);
<K, V> Map<K, V> selectMap(String statement, Object parameter, String mapKey);
<K, V> Map<K, V> selectMap(String statement, Object parameter, String mapKey, RowBounds rowBounds);
<T> Cursor<T> selectCursor(String statement);
<T> Cursor<T> selectCursor(String statement, Object parameter);
<T> Cursor<T> selectCursor(String statement, Object parameter, RowBounds rowBounds);
void select(String statement, Object parameter, ResultHandler handler);
void select(String statement, ResultHandler handler);
void select(String statement, Object parameter, RowBounds rowBounds, ResultHandler handler);
int insert(String statement);
int insert(String statement, Object parameter);
int update(String statement);
int update(String statement, Object parameter);
int delete(String statement);
int delete(String statement, Object parameter);
void commit();
void commit(boolean force);
void rollback();
void rollback(boolean force);
List<BatchResult> flushStatements();
void close();
void clearCache();
Configuration getConfiguration();
<T> T getMapper(Class<T> type);
Connection getConnection();
~~~

`SqlSession提供了对数据库连接、事务、缓存以及对数据的增删改查的操作`。默认的实现类DefaultSqlSession，其实是将这些操作委托给了Executor来执行。例如，`selectList`方法：

~~~java
@Override
public <E> List<E> selectList(String statement, Object parameter, RowBounds rowBounds) {
  try {
    MappedStatement ms = configuration.getMappedStatement(statement);
    return executor.query(ms, wrapCollection(parameter), rowBounds, Executor.NO_RESULT_HANDLER);
  } catch (Exception e) {
    throw ExceptionFactory.wrapException("Error querying database.  Cause: " + e, e);
  } finally {
    ErrorContext.instance().reset();
  }
}
~~~

主要逻辑是：

- 在configuration类中获取sql语句对应的`MappedStatement`
- `executor.query`需要四个参数：`mappedStatement`、`parameter`、`rowBounds`、`resultHandler`。
- 对于传入的参数`parameter`进行处理：

~~~java
private Object wrapCollection(final Object object) {
  if (object instanceof Collection) {
    StrictMap<Object> map = new StrictMap<Object>();
    map.put("collection", object);
    if (object instanceof List) {
      map.put("list", object);
    }
    return map;
  } else if (object != null && object.getClass().isArray()) {
    StrictMap<Object> map = new StrictMap<Object>();
    map.put("array", object);
    return map;
  }
  return object;
}
~~~

- 最后清除`ErrorContext`

SqlSessionManager用于管理SqlSession，其实现了SqlSessionFactory, SqlSession接口，内部分别维护了SqlSessionFactory, SqlSession实例。

~~~java
public class SqlSessionManager implements SqlSessionFactory, SqlSession {

  private final SqlSessionFactory sqlSessionFactory;
  private final SqlSession sqlSessionProxy;

  private ThreadLocal<SqlSession> localSqlSession = new ThreadLocal<SqlSession>();

  private SqlSessionManager(SqlSessionFactory sqlSessionFactory) {
    this.sqlSessionFactory = sqlSessionFactory;
    this.sqlSessionProxy = (SqlSession) Proxy.newProxyInstance(
        SqlSessionFactory.class.getClassLoader(),
        new Class[]{SqlSession.class},
        new SqlSessionInterceptor());
  }
}
~~~

说明：

- sqlSessionFactory主要是用于创建SqlSession
- `localSqlSession`保存的是受管理的SqlSession，可以通过`startManagedSession()`方法创建受管理的SqlSession并将其放置到`ThreadLocal`里面；

~~~java
public void startManagedSession() {
  this.localSqlSession.set(openSession());
}

public void startManagedSession(boolean autoCommit) {
  this.localSqlSession.set(openSession(autoCommit));
}

public void startManagedSession(Connection connection) {
  this.localSqlSession.set(openSession(connection));
}

public void startManagedSession(TransactionIsolationLevel level) {
  this.localSqlSession.set(openSession(level));
}

public void startManagedSession(ExecutorType execType) {
  this.localSqlSession.set(openSession(execType));
}

public void startManagedSession(ExecutorType execType, boolean autoCommit) {
  this.localSqlSession.set(openSession(execType, autoCommit));
}

public void startManagedSession(ExecutorType execType, TransactionIsolationLevel level) {
  this.localSqlSession.set(openSession(execType, level));
}

public void startManagedSession(ExecutorType execType, Connection connection) {
  this.localSqlSession.set(openSession(execType, connection));
}

public boolean isManagedSessionStarted() {
  return this.localSqlSession.get() != null;
}
~~~

创建SqlSession使用了动态代理，调用增删改查接口时，实际上调用的`sqlSessionProxy`类，代理逻辑是：先判断是否存在受管理的SqlSession，如果有，则从ThreadLocal取出SqlSession并调用被代理的方法，返回结果；否则，使用sqlSessionFactory创建一个默认的SqlSession，调用被代理的方法，并提交事务，返回结果。

`SqlSessionManager`提供了静态方法`newInstance`来实例化一个SqlSessionManager，但SqlSessionManager类并不是单例的。既然不是单例的，其和直接使用构造方法进行重载应该没什么区别吧？

~~~java
public static SqlSessionManager newInstance(Reader reader) {
  return new SqlSessionManager(new SqlSessionFactoryBuilder().build(reader, null, null));
}

public static SqlSessionManager newInstance(Reader reader, String environment) {
  return new SqlSessionManager(new SqlSessionFactoryBuilder().build(reader, environment, null));
}

public static SqlSessionManager newInstance(Reader reader, Properties properties) {
  return new SqlSessionManager(new SqlSessionFactoryBuilder().build(reader, null, properties));
}

public static SqlSessionManager newInstance(InputStream inputStream) {
  return new SqlSessionManager(new SqlSessionFactoryBuilder().build(inputStream, null, null));
}

public static SqlSessionManager newInstance(InputStream inputStream, String environment) {
  return new SqlSessionManager(new SqlSessionFactoryBuilder().build(inputStream, environment, null));
}

public static SqlSessionManager newInstance(InputStream inputStream, Properties properties) {
  return new SqlSessionManager(new SqlSessionFactoryBuilder().build(inputStream, null, properties));
}

public static SqlSessionManager newInstance(SqlSessionFactory sqlSessionFactory) {
  return new SqlSessionManager(sqlSessionFactory);
}
~~~

总结起来就是，SqlSessionManager提供了两种方式管理SqlSession，你可以启动一个你自己创建的SqlSession或者使用动态代理创建一个SqlSession，相应的方法并提交事务。这里使用代理的原因是，在执行完方法之后，需要提交事务，如果执行失败，还需要回滚事务，最后还需要关闭会话。

如果你直接调用`SqlSessionManager`的`getConnection`、`clearCache`、`commit`、`rollback`、`flushStatements`、`close`，最终会调用`ThreadLocal`里的，即受管理的`SqlSession`，如果其为空，则会抛出异常，例如：

~~~java
@Override
public void commit(boolean force) {
  final SqlSession sqlSession = localSqlSession.get();
  if (sqlSession == null) {
    throw new SqlSessionException("Error:  Cannot commit.  No managed session is started.");
  }
  sqlSession.commit(force);
}
~~~







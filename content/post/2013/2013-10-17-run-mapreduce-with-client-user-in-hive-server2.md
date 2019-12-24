---
layout: post
title: HiveServer2中使用jdbc客户端用户运行mapreduce
date: 2013-10-17T00:00:00+08:00
description: 最近做了个web系统访问hive数据库，类似于官方自带的hwi，但是和他们的实现不一样，查询Hive语句走的不是cli而是通过jdbc连接hive-server2。为了实现mapreduce任务中资源按用户调度，需要hive查询自动绑定当前用户、将该用户传到yarn服务端并使mapreduce程序以该用户运行。本文主要是记录实现该功能过程中遇到的一些问题以及解决方法,如果你有更好的方法和建议，欢迎留言发表您的看法！
hadoop: [hive]
tags: [hive, hiveserver2,]
---

最近做了个web系统访问hive数据库，类似于官方自带的hwi、安居客的[hwi改进版](https://github.com/anjuke/hwi)和大众点评的[polestar](http://blog.csdn.net/lalaguozhe/article/details/9614061)([github地址](https://github.com/dianping/polestar))系统，但是和他们的实现不一样，查询Hive语句走的不是cli而是通过jdbc连接hive-server2。为了实现mapreduce任务中资源按用户调度，需要hive查询自动绑定当前用户、将该用户传到yarn服务端并使mapreduce程序以该用户运行。本文主要是记录实现该功能过程中遇到的一些问题以及解决方法,如果你有更好的方法和建议，欢迎留言发表您的看法！

# 说明

集群环境使用的是cdh4.3，没有开启kerberos认证。


> 写完这篇文章之后，在微博上收到[@单超eric](http://weibo.com/shanchao1?from=profile&wvr=5&loc=infdomain)的[评论](http://weibo.com/1789178264/AeMItpBRk)，发现cdh4.3中hive-server2已经实现[Impersonation](http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH4/latest/CDH4-Security-Guide/cdh4sg_topic_9_1.html#topic_9_1_unique_4)功能，再此对@单超eric的帮助表示感谢。


so，你可以完全忽略本文后面的内容，直接看cloudera的HiveServer2 Impersonation是怎么做的。

# hive-server2的启动

先从hive-server2服务的启动开始说起。

如果你是以服务的方式启动hive-server2进程，则启动hive-server2的用户为hive,运行mapreduce的用户也为hive，启动脚本如下：

~~~
/etc/init.d/hive-server2 start
~~~

如果你以命令行方式启动hive-server2进程，则启动hive-server2的用户为root,运行mapreduce的用户也为root，启动脚本如下：

~~~
hive --service hiveserver2
~~~

为什么是上面的结论？这要从hive-server2的启动过程开始说明。

<!-- more -->

查看HiveServer2.java的代码可以看到，hive-server2启动时会依次启动`cliService`和`thriftCLIService`，查看cliService的init()方法，可以看到如下代码：

~~~
public synchronized void init(HiveConf hiveConf) {
    this.hiveConf = hiveConf;

    sessionManager = new SessionManager();
    addService(sessionManager);
    try {
      HiveAuthFactory.loginFromKeytab(hiveConf);
      serverUserName = ShimLoader.getHadoopShims().
          getShortUserName(ShimLoader.getHadoopShims().getUGIForConf(hiveConf));
    } catch (IOException e) {
      throw new ServiceException("Unable to login to kerberos with given principal/keytab", e);
    } catch (LoginException e) {
      throw new ServiceException("Unable to login to kerberos with given principal/keytab", e);
    }
    super.init(hiveConf);
  }
~~~

从上面的代码可以看到在cliService初始化过程中会做登陆（从kertab中登陆）和获取用户名的操作：

~~~
ShimLoader.getHadoopShims().getUGIForConf(hiveConf)
~~~

上面代码最终会调用HadoopShimsSecure类的getUGIForConf方法：

~~~
@Override
public UserGroupInformation getUGIForConf(Configuration conf) throws IOException {
  return UserGroupInformation.getCurrentUser();
}
~~~

UserGroupInformation.getCurrentUser()代码如下：

~~~
 public synchronized
  static UserGroupInformation getCurrentUser() throws IOException {
    AccessControlContext context = AccessController.getContext();
    Subject subject = Subject.getSubject(context);
    if (subject == null || subject.getPrincipals(User.class).isEmpty()) {
      return getLoginUser();
    } else {
      return new UserGroupInformation(subject);
    }
  }
~~~

因为这时候服务刚启动，subject为空，故if分支会调用`getLoginUser()`方法，其代码如下：

~~~
  public synchronized 
  static UserGroupInformation getLoginUser() throws IOException {
    if (loginUser == null) {
      try {
        Subject subject = new Subject();
        LoginContext login;
        if (isSecurityEnabled()) {
          login = newLoginContext(HadoopConfiguration.USER_KERBEROS_CONFIG_NAME,
              subject, new HadoopConfiguration());
        } else {
          login = newLoginContext(HadoopConfiguration.SIMPLE_CONFIG_NAME, 
              subject, new HadoopConfiguration());
        }
        login.login();
        loginUser = new UserGroupInformation(subject);
        loginUser.setLogin(login);
        loginUser.setAuthenticationMethod(isSecurityEnabled() ?
                                          AuthenticationMethod.KERBEROS :
                                          AuthenticationMethod.SIMPLE);
        loginUser = new UserGroupInformation(login.getSubject());
        String fileLocation = System.getenv(HADOOP_TOKEN_FILE_LOCATION);
        if (fileLocation != null) {
          // Load the token storage file and put all of the tokens into the
          // user. Don't use the FileSystem API for reading since it has a lock
          // cycle (HADOOP-9212).
          Credentials cred = Credentials.readTokenStorageFile(
              new File(fileLocation), conf);
          loginUser.addCredentials(cred);
        }
        loginUser.spawnAutoRenewalThreadForUserCreds();
      } catch (LoginException le) {
        LOG.debug("failure to login", le);
        throw new IOException("failure to login", le);
      }
      if (LOG.isDebugEnabled()) {
        LOG.debug("UGI loginUser:"+loginUser);
      }
    }
    return loginUser;
  }
~~~

因为是第一次调用getLoginUser(),故loginUser为空，接下来会创建LoginContext并调用其login方法，login方法最终会调用HadoopLoginModule的commit()方法。

下图是从hive-server2启动到执行HadoopLoginModule的commit()方法的调用图：

![hive-server2启动过程](/images/hive-server2-invoke.png)

获取登陆用户的关键代码就在commit()，逻辑如下：

- 如果使用了kerberos，则为kerberos登陆用户。hive-server2中如何使用kerberos登陆，请查看官方文档。
- 如果kerberos用户为空并且没有开启security，则从系统环境变量中取`HADOOP_USER_NAME`的值
- 如果环境变量中没有设置`HADOOP_USER_NAME`，则使用系统用户，即启动hive-server2进程的用户。

## 小结

hive-server2启动过程中会做登陆操作并获取到登陆用户，启动之后再次调用`UserGroupInformation.getCurrentUser()`取到的用户就为登陆用户了，这样会导致所有请求到hive-server2的hql最后都会以这个用户来运行mapreduce。

# 提交hive任务

现在来看hive任务是怎么提交到yarn服务端然后运行mapreduce的。

为了调试简单，我在本机eclipse的hive源代码中配置`hive-site.xml、core-site.xml、mapred.xml、yarn-site.xml`连接测试集群,添加缺少的yarn依赖并解决hive-builtins中报错的问题，然后运行HiveServer2类的main方法。_注意_，我的电脑当前登陆用户为june，故启动hive-server2的用户为june。

然后，在运行jdbc测试类，运行一个简单的sql语句，大概如下：

~~~
public static void test() {
	try {
		Class.forName("org.apache.hive.jdbc.HiveDriver");

		Connection conn = DriverManager.getConnection(
				"jdbc:hive2://june-mint:10000/default", "", "");

		Statement stmt = conn.createStatement();

		ResultSet rs = stmt.executeQuery("select count(1) from t");

		while (rs.next())
			System.out.println(rs.getString(1));

		rs.close();
		stmt.close();
		conn.close();
	} catch (SQLException se) {
		se.printStackTrace();
	} catch (Exception e) {
		e.printStackTrace();
	}
}
~~~

查看yarn监控地址`http://192.168.56.101:8088/cluster`，可以看到提交的mapreduce任务由june用户来运行。

![yarn cluster monitor page](/images/images1017-01.png)

如何修改mapreduce任务的运行用户呢？如果了解hive提交mapreduce任务的过程的话，就应该知道hive任务会通过`org.apache.hadoop.mapred.JobClient`来提交。在JobClient的init方法中有如下代码：

~~~
  public void init(JobConf conf) throws IOException {
    setConf(conf);
    cluster = new Cluster(conf);
    clientUgi = UserGroupInformation.getCurrentUser();
  }
~~~

JobClient类中提交mapreduce任务的代码如下，见submitJobInternal方法：

~~~
Job job = clientUgi.doAs(new PrivilegedExceptionAction<Job> () {
	@Override
	public Job run() throws IOException, ClassNotFoundException, 
	  InterruptedException {
	  Job job = Job.getInstance(conf);
	  job.submit();
	  return job;
	}
});
~~~

从前面知道，hive-server2启动中会进行登陆操作并且登陆用户为june，故clientUgi对应的登陆用户也为june，故提交的mapreduce任务也通过june用户来运行。

# 如何修改源代码

从上面代码可以知道，修改clientUgi的获取方式就可以改变提交任务的用户。UserGroupInformation中存在如下静态方法：

~~~
  public static UserGroupInformation createRemoteUser(String user) {
    if (user == null || "".equals(user)) {
      throw new IllegalArgumentException("Null user");
    }
    Subject subject = new Subject();
    subject.getPrincipals().add(new User(user));
    UserGroupInformation result = new UserGroupInformation(subject);
    result.setAuthenticationMethod(AuthenticationMethod.SIMPLE);
    return result;
  }
~~~

故可以尝试使用该方法，修改JobClient的init方法如下：

~~~
 public void init(JobConf conf) throws IOException {
    setConf(conf);
    cluster = new Cluster(conf);
    if(UserGroupInformation.isSecurityEnabled()){
    	clientUgi = UserGroupInformation.getCurrentUser();
    }else{
    	String user = conf.get("myExecuteName","NoName");
    	clientUgi = UserGroupInformation.createRemoteUser(user);
    }
  }
~~~

上面代码是在没有开启security的情况下，从环境变量（myExecuteName）获取jdbc客户端指定的用户名，然后创建一个远程的UserGroupInformation。

## 为什么从环境变量中获取用户名称？

1. 在不考虑安全的情况下，可以由客户端任意指定用户。
2. 没有使用jdbc连接信息中的用户，是因为这样会导致每次获取jdbc连接的时候都要指定用户名，这样就没法使用已有的连接池。

编译代码、替换class文件，然后重新运行HiveServer2以及jdbc测试类，查看yarn监控地址`http://192.168.56.101:8088/cluster`，截图如下：

![yarn cluster monitor page](/images/images1017-02.png)

这时候mapreduce的运行用户变为NoName，这是因为从JobConf环境变量中找不到myExecuteName变量而使用默认值NoName的原因。

查看hive-server2运行日志，会发现任务运行失败，关键异常信息如下：

~~~
Caused by: org.apache.hadoop.security.AccessControlException: Permission denied: user=NoName, access=WRITE, inode="/tmp/hive-june/hive_2013-10-18_21-18-12_812_378750610917949668/_tmp.-ext-10001":june:hadoop:drwxr-xr-x
	at org.apache.hadoop.hdfs.server.namenode.FSPermissionChecker.check(FSPermissionChecker.java:224)
	at org.apache.hadoop.hdfs.server.namenode.FSPermissionChecker.check(FSPermissionChecker.java:204)
	at org.apache.hadoop.hdfs.server.namenode.FSPermissionChecker.checkPermission(FSPermissionChecker.java:149)
	at org.apache.hadoop.hdfs.server.namenode.FSNamesystem.checkPermission(FSNamesystem.java:4705)
	at org.apache.hadoop.hdfs.server.namenode.FSNamesystem.checkPermission(FSNamesystem.java:4687)
	at org.apache.hadoop.hdfs.server.namenode.FSNamesystem.checkAncestorAccess(FSNamesystem.java:4661)
	at org.apache.hadoop.hdfs.server.namenode.FSNamesystem.renameToInternal(FSNamesystem.java:2696)
	at org.apache.hadoop.hdfs.server.namenode.FSNamesystem.renameToInt(FSNamesystem.java:2663)
	at org.apache.hadoop.hdfs.server.namenode.FSNamesystem.renameTo(FSNamesystem.java:2642)
	at org.apache.hadoop.hdfs.server.namenode.NameNodeRpcServer.rename(NameNodeRpcServer.java:610)
	at org.apache.hadoop.hdfs.protocolPB.ClientNamenodeProtocolServerSideTranslatorPB.rename
~~~

出现上述异常是因为，mapreduce任务在运行过程中会生成一些临时文件，而NoName用户对临时文件没有写的权限，这些临时文件属于june用户。查看hdfs文件如下：

~~~
[root@edh1 lib]# hadoop fs -ls /tmp/
Found 6 items
drwx------   - june hadoop          0 2013-10-15 01:33 /tmp/hadoop-yarn
drwxr-xr-x   - june hadoop          0 2013-10-16 06:52 /tmp/hive-june
~~~

`/tmp/hive-june`是hive执行过程中保存在hdfs的路径，由`hive.exec.scratchdir`定义，其默认值为`/tmp/hive-${user.name}`，而且这个文件是在`org.apache.hadoop.hive.ql.Context`类的构造方法中获取并在ExecDriver类的execute(DriverContext driverContext)方法中创建的。

类似这样的权限问题还会出现在hdfs文件`重命名、删除临时目录的时候`。为了避免出现这样的异常，需要修改`hive.exec.scratchdir`为当前用户对应的临时目录路径，并使用当前登陆用户创建、重命名、删除临时目录。

修改获取`hive.exec.scratchdir`对应的临时目录代码如下，在Context类的够找方法中修改：

~~~
    String user = conf.get(myExecuteName，“”);

    if (user != null && user.trim().length() > 0) {
      nonLocalScratchPath =
          new Path("/tmp/hive-" + user, executionId);
    } else {
      nonLocalScratchPath =
          new Path(HiveConf.getVar(conf, HiveConf.ConfVars.SCRATCHDIR),
              executionId);
    }
~~~

找到这些操作对应的代码似乎太过复杂了，修改的地方也有很多，因为这里是使用的hive-server2，故在对应的jdbc代码中修改似乎会简单很多，例如修改HiveSessionImpl类的以下三个方法：

~~~
public OperationHandle executeStatement(String statement, Map<String, String> confOverlay) throws HiveSQLException{}

public void cancelOperation(final OperationHandle opHandle) throws HiveSQLException {}

public void closeOperation(final OperationHandle opHandle) throws HiveSQLException {}
~~~

第一个方法是运行sql语句，第二个方法是取消运行，第三个方法是关闭连接。

executeStatement中所做的修改如下，将`operation.run();`改为：

~~~
    if (operation instanceof SQLOperation) {
        try {
          String user = hiveConf.getVar(ConfVars.HIVE_SERVER2_MAPREDUCE_USERNAME);
          ugi = UserGroupInformation.createRemoteUser(user);
          ugi.doAs(new PrivilegedExceptionAction<CommandProcessorResponse>() {
            @Override
            public CommandProcessorResponse run() throws HiveSQLException {
              operation.run();
              return null;
            }
          });
        } catch (IOException e) {
          e.printStackTrace();
        } catch (InterruptedException e) {
          e.printStackTrace();
        }
      } else {
        operation.run();
      }
~~~

这里添加了判断，当operation操作时，才执行下面代码，这是为了保证从hive环境变量中获取myExecuteName的值不为空时才创建UserGroupInformation。

myExecuteName是新定义的hive变量，主要是用于jdbc客户端通过set语句设置myExecuteName的值为当前登陆用户名称，然后在执行sql语句。代码如下：

~~~
Statement stmt = conn.createStatement();

stmt.execute("set myExecuteName=aaaa");
ResultSet rs = stmt.executeQuery("select count(1) from t");

while (rs.next())
	System.out.println(rs.getString(1));
~~~

## 小结

上面修改的类包括：

~~~
org.apache.hadoop.mapred.JobClient //从环境变量获取从jdbc客户端传过来的用户，即myExecuteName的值，然后以该值运行mapreduce用户
org.apache.hadoop.hive.ql.Context  //修改hive.exec.scratchdir的地址为从jdbc客户端传过来的用户对应的临时目录
org.apache.hive.service.cli.session.HiveSessionImpl //修改运行sql、取消操作、关闭连接对应的方法
~~~

# 测试
是用javachen用户测试,hdfs上的临时目录如下：

~~~
[root@edh1 lib]# hadoop fs -ls /tmp/
Found 7 items
drwx------   - june         hadoop          0 2013-10-15 01:33 /tmp/hadoop-yarn
drwxr-xr-x   - javachen.space hadoop          0 2013-10-16 07:30 /tmp/hive-javachen.space
drwxr-xr-x   - june         hadoop          0 2013-10-16 06:52 /tmp/hive-june
drwxr-xr-x   - root         hadoop          0 2013-10-15 14:13 /tmp/hive-root
drwxrwxrwt   - yarn         mapred          0 2013-10-16 07:30 /tmp/logs
~~~

监控页面截图：

![yarn cluster monitor page](/images/images1017-03.png)

除了简单测试之外，还需要测试修改后的代码是否影响源代码的运行以及hive cli的运行。

# 参考文章

1. [HiveServer2 Impersonation](https://cwiki.apache.org/confluence/display/Hive/Setting+up+HiveServer2)
2. [CDH4 HiveServer2 Security Configuration](http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH4/4.3.0/CDH4-Security-Guide/cdh4sg_topic_9_1.html)

# Enjoy it ！





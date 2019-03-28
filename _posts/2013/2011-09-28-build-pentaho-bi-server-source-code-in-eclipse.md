---
layout: post
title: 在eclipse中构建Pentaho BI Server工程
category: pentaho
tags: [pentaho]
description:  在eclipse中构建Pentaho BI Server工程
---
首先需要说明的是，Pentaho BI Server源代码在<em>svn://source.pentaho.org/svnroot/bi-platform-v2/trunk/</em>，并且用ivy构建。ivy没有用过也不熟悉，故不打算从这里使用ivy构建源码。

当然，您可以参考<a href="http://wiki.pentaho.com/display/ServerDoc2x/Building+and+Debugging+Pentaho+with+Eclipse" target="_blank">官方文档</a>构建源码。

Pentaho BI Server打包后的文件存于<a href="http://sourceforge.net/projects/pentaho/files/Business%20Intelligence%20Server/" target="_blank">这里</a>，其中包括（本文使用的是3.9.0版本）：biserver-ce-3.9.0-stable.zip，bi-platform-3.9.0-stable-sources.zip，biserver-ce-3.9.0-stable-javadoc.zip。


将biserver-ce-3.9.0-stable.zip解压之后执行<em>biserver-ce/start-pentaho.bat</em>（或是再linux环境下：<em>biserver-ce/start-pentaho.sh</em>），即可成功启动biserver。现在我想将这个工程导入到eclipse然后调式跟踪代码，怎么做呢？

<strong>以下操作是在eclipse3.7+tomcat 6.20的环境中进行的。</strong>

在eclipse中创建一个web项目，名称为pentaho，然后将<em>biserver-ce/tomcat/webapps</em>下的<code>pentaho-style</code>和<code>sw-style</code>拷贝到你的tomcat 6服务器的webapps目录下，将pentaho文件下的所有文件拷贝到工程下的WebContent目录下。由于biserver需要访问pentaho-solutions下的文件，故还需要修改<code>WEB-INF/web.xml</code>文件你的以下配置，用于指定pentaho-solutions的路径：

	< context-param >
		< param-name >solution-path< /param-name>
		< param-value >/home/june.chan/opt/biserver-ce/pentaho-solutions< /param-value>
	< /context-param >

现在即可部署项目，运行<code>biserver-ce/data/start_hypersonic.bat</code>（用于启动数据库），然后启动tomcat，就可以通过<em>http://localhost:8080/pentaho</em>访问biserver。如果启动报错，需要将hsqldb-1.8.0.7.jar包，拷贝到应用路径下（<em>\tomcat-pci-test\biserver-ce\tomcat\webapps\pentaho\WEB-INF\lib</em>）。<br />
现在可以看到biserver的登录页面，但是还是没有看到biserver的源代码。

<strong>接下来，构建源代码。</strong>
在biserver-ce/tomcat/webapps/pentaho/WEB-INF/lib下面有很多名称为pentaho-bi-platform-########-3.9.0-stable.jar的jar文件，这些即是biserver源码编译之后的class文件。在bi-platform-3.9.0-stable-sources.zip压缩文件你即可以看到这些class文件的源代码。将这些src包解压然后拷贝到之前新建的pentaho工程的src目录下。

<strong><font color="red">需要注意的是：</font></strong>
1.这些src jar包你只报告java文件，不包括配置文件：log4j配置文件，hibernate配置和实体映射文件，ehcache配置文件<br />
2.上面的配置文件需要到biserver-ce/tomcat/webapps/pentaho/WEB-INF/lib目录下的pentaho-bi-platform-########-3.9.0-stable.jar文件中寻找。<br />
3.
* biserver-ce/tomcat/webapps/pentaho/WEB-INF/lib/pentaho-bi-platform-engine-security-3.9.0-stable.jar文件中有ldap的配置文件，
* biserver-ce/tomcat/webapps/pentaho/WEB-INF/lib/pentaho-bi-platform-engine-services-3.9.0-stable.jar文件中有ehcache的配置文件，
* biserver-ce/tomcat/webapps/pentaho/WEB-INF/lib/pentaho-bi-platform-plugin-actions-3.9.0-stable.jar文件中有log4j的配置文件，
* biserver-ce/tomcat/webapps/pentaho/WEB-INF/lib/pentaho-bi-platform-repository-3.9.0-stable.jar文件中有hibernate配置文件，
* biserver-ce/tomcat/webapps/pentaho/WEB-INF/lib/pentaho-bi-platform-security-userroledao-3.9.0-stable.jar文件中有hibernated的实体映射文件。

4.biserver-ce-3.9.0-stable.zip的lib（`biserver-ce/tomcat/webapps/pentaho/WEB-INF/lib`）目录下的servlete jar包的版本为2.3，版本过低需要替换为更高版本知道源码中不在有servlete编译错误


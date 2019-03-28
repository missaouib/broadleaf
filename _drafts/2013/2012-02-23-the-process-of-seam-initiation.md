---
layout: post
title: Seam的启动过程
category: java
tags: [seam,java]
keywords: seam, jboss
---

了解seam2的人知道，seam是通过在web. xml中配置监听器启动的。注意，本文中的seam是指的seam2，不是seam3. 

	<listener>
		<listenerclass>org. jboss. seam. servlet. SeamListener</listenerclass>
	</listener>

该监听器会做哪些事情呢？看看Gavin King对SeamListener类的描述。

<blockquote>Drives certain Seam functionality such as initialization and cleanup of application and session contexts from the web application lifecycle. </blockquote>

从描述中可以知道SeamListener主要完成应用以及web应用生命周期中的session上下文的初始化和清理工作。

该类实现了ServletContextListener接口，在contextInitialized(ServletContextEvent event)方法内主要初始化生命周期并完成应用的初始化，在contextDestroyed(ServletContextEvent event)方法内结束应用的生命周期。

该类实现了HttpSessionListener接口，主要是用于在生命周期中开始和结束session。

<strong>第一步</strong>，构造方法里从ServletContext获取一些路径信息：warRoot、warClassesDirectory、warLibDirectory、hotDeployDirectory。

<strong>第二步</strong>，扫描配置文件完成seam组件的初始化（Initialization的create方法）。
其中包括：添加命名空间、初始化组件、初始化Properties、初始化jndi信息。这一步，其实主要是读取一些配置文件,加载seam组件。

 1. 添加命名空间
 2. 从/WEBINF/components. xml加载组件
 3. 从/WEBINF/events. xml加载组件
 4. 从METAINF/components. xml加载组件
 5. 从ServletContext初始化Properties
 6. 从/seam. properties初始化Properties
 7. 初始化jndi Properties
 8. 从system加载Properties

<strong>第三步</strong>，seam初始化过程（Initialization的init方法）。

 1. ServletLifecycle开始初始化
 2. 设置Application上下文
 3. 添加Init组件
 4. 通过standardDeploymentStrategy的注解和xml组件扫描组件
 5. 判断jbpm是否安装
 6. 检查默认拦截器
 7. 添加特别组件
 8. 添加war root部署、热部署
 9. 安装组件
 10. 导入命名空间
 11. ServletLifecycle结束初始化。启动生命周期为APPLICATION的组件。

如果组件标注为startup，则会构造其实例进行初始化。例如seam于Hibernate的集成，就可以通过此方法初始化Hibernate，对应的组件类为org. jboss. seam. persistence. HibernateSessionFactory。


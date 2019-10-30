---
layout: post

title: Spring集成JPA2.0
date: 2014-11-24T08:00:00+08:00

categories: [ spring ]

tags: [ java,spring,jpa ]

description: JPA 全称 Java Persistence API，是Java EE 5标准之一，是一个 ORM 规范，由厂商来实现该规范。本文主要记录 Spring 框架中集成 JPA 的过程

published: true

---

JPA 全称 Java Persistence API，是Java EE 5标准之一，是一个 ORM 规范，由厂商来实现该规范，目前有 Hibernate、OpenJPA、TopLink、EclipseJPA 等实现。Spring目前提供集成Hibernate、OpenJPA、TopLink、EclipseJPA四个JPA标准实现。

# 1. 集成方式

Spring提供三种方法集成JPA：

- 1. LocalEntityManagerFactoryBean：适用于那些仅使用JPA进行数据访问的项目。
- 2. 从JNDI中获取：用于从Java EE服务器中获取指定的EntityManagerFactory，这种方式在Spring事务管理时一般要使用JTA事务管理。
- 3. LocalContainerEntityManagerFactoryBean：适用于所有环境的FactoryBean，能全面控制EntityManagerFactory配置，非常适合那种需要细粒度定制的环境。

## 1.1 LocalEntityManagerFactoryBean

仅在简单部署环境中只使用这种方式，比如独立的应用程序和集成测试。该 FactoryBean 根据 JPA PersistenceProvider自动检测配置文件进行工作，一般从 `META-INF/persistence.xml` 读取配置信息。这种方式最简单，但是不能设置 Spring 中定义的 DataSource，且不支持 Spring 管理的全局事务，甚至，持久化类的织入（字节码转换）也是特定于提供者的，经常需要在启动时指定一个特定的JVM代理。**这种方法实际上只适用于独立的应用程序和测试环境，不建议使用此方式。**

~~~xml
<bean id="entityManagerFactory" class="org.springframework.orm.jpa.LocalEntityManagerFactoryBean">
       <property name="persistenceUnitName" value="persistenceUnit"/>
</bean>
~~~

persistenceUnit 对应 META-INF/persistence.xml 中 persistence-unit 节点的 name 属性值。


## 1.2 JNDI中获取

Spring 中的配置：

~~~xml
<beans xmlns="http://www.springframework.org/schema/beans"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:jee="http://www.springframework.org/schema/jee"
    xsi:schemaLocation="
       http://www.springframework.org/schema/beans
       http://www.springframework.org/schema/beans-beans-3.0.xsd
       http://www.springframework.org/schema/jee
       http://www.springframework.org/schema/jee-jee-3.0.xsd">

  <jee:jndi-lookup id="entityManagerFactory"  jndi-name="persistence/persistenceUnit"/>

</beans>
~~~

此处需要使用 `jee` 命名标签，且使用 `<jee:jndi-lookup>` 标签进行 JNDI 查找，`jndi-name` 属性用于指定 JNDI 名字。

在标准的 Java EE 5启动过程中，Java EE服务器自动检测持久化单元（例如应用程序文件包中的 `META-INF/persistence.xml`） ，以及J ava EE 部署描述符中定义给那些持久化单元命名上下文位置的环境的 `persistence-unit-ref` 项（例如 web.xml）。

在这种情况下，整个持久化单元部署，包括持久化类的织入（字码码转换）都取决于 Java EE 服务器。 JDBC DataSource 通过在 `META-INF/persistence.xml` 文件中的 JNDI 位置进行定义；EntityManager 事务与服务器的 JTA 子系统整合。Spring 仅仅用获得的  EntityManagerFactory ，通过依赖注入将它传递给应用程序对象，并为它管理事务（一般通过 JtaTransactionManager）。

注意，如果在同一个应用程序中使用了多个持久化单元，JNDI 获取的这种持久化单元的 bean 名称 应该与应用程序用来引用它们的持久化单元名称相符（例如 `@PersistenceUnit` 和 `@PersistenceContext` 注解）。

在部署到 Java EE 5 服务器时使用该方法。关于如何将自定义 JPA 提供者部署到服务器，以及允许使用服务器提供的缺省提供者之外的 JPA 提供者，请查看服务器文档的相关说明。

## 1.3 LocalContainerEntityManagerFactoryBean

LocalContainerEntityManagerFactoryBean 提供了对JPA EntityManagerFactory 的全面控制，非常适合那种需要细粒度定制的环境。LocalContainerEntityManagerFactoryBean 将基于 persistence.xml 文件创建 PersistenceUnitInfo 类，并提供 dataSourceLookup 策略和 loadTimeWeaver。 因此它可以在JNDI之外的用户定义的数据源之上工作，并控制织入流程。

Spring 中的配置：

~~~xml
<bean id="entityManagerFactory" class="org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean">
	<property name="persistenceUnitName" value="persistenceUnit" />
	<property name="dataSource" ref="dataSource" />
	<property name="jpaVendorAdapter" ref="jpaVendorAdapter" />
</bean>
~~~

这是最为强大的JPA配置方式，允许在应用程序中灵活进行本地配置。它支持连接现有JDBC DataSource ， 支持本地事务和全局事务等等。然而，它也将需求强加到了运行时环境中，例如，如果持久化提供者需要字节码转换，则必须有织入ClassLoader的能力。

注意，这个选项可能与 Java EE 5 服务器内建的 JPA 功能相冲突。因此，当运行在完全 Java EE 5 环境中时， 要考虑从 JNDI 获取 EntityManagerFactory。另一种可以替代的方法是，在 LocalContainerEntityManagerFactoryBean 定义中通过 `persistenceXmlLocation` 指定相关位置， 例如 `META-INF/my-persistence.xml`，并且只将包含该名称的描述符放在应用程序包文件中。因为 Java EE 5 服务器将只 查找默认的 `META-INF/persistence.xml` 文件，它会忽略这种定制的持久化单元，因而避免与前面 Spring 驱动的 JPA 配置冲突。

一个配置实例：

~~~xml
<bean id="entityManagerFactory" class="org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean">
	<property name="dataSource" ref="dataSource"/>
	<property name="persistenceXmlLocation" value="test/persistence.xml"/>
	<!-- gDickens: BOTH Persistence Unit and Packages to Scan are NOT compatible, persistenceUnit will win -->
	<property name="persistenceUnitName" value="persistenceUnit"/>
	<property name="packagesToScan" value="com.javachen.example.springmvc"/>
	<property name="persistenceProvider" ref="persistenceProvider"/>
	<property name="jpaVendorAdapter" ref="jpaVendorAdapter"/>
	<property name="jpaDialect" ref="jpaDialect"/>
	<property name="jpaPropertyMap" ref="jpaPropertyMap"/>
</bean>

<util:map id="jpaPropertyMap">
	<entry key="dialect" value="${hibernate.dialect}"/>
	<entry key="hibernate.ejb.naming_strategy" value="${hibernate.ejb.naming_strategy}"/>
	<entry key="hibernate.hbm2ddl.auto" value="${hibernate.hbm2ddl.auto}"/>
	<entry key="hibernate.cache.use_second_level_cache" value="false"/>
	<entry key="hibernate.cache.use_query_cache" value="false"/>
	<entry key="hibernate.generate_statistics" value="false"/>
	<entry key="show_sql" value="${hibernate.show_sql}"/>
	<entry key="format_sql" value="${hibernate.format_sql}"/>
</util:map>

<bean id="persistenceProvider" class="org.hibernate.ejb.HibernatePersistence"/>

<bean id="jpaVendorAdapter" class="org.springframework.orm.jpa.vendor.HibernateJpaVendorAdapter">
	<property name="generateDdl" value="false" />
	<property name="showSql" value="false" />
	<property name="database" value="HSQL"/>
</bean>
<bean id="jpaDialect" class="org.springframework.orm.jpa.vendor.HibernateJpaDialect"/>
~~~

说明：

 - `LocalContainerEntityManagerFactoryBean：指定使用本地容器管理 EntityManagerFactory，从而进行细粒度控制；
 - `dataSource`：属性指定使用 Spring 定义的数据源；
 - `persistenceXmlLocation`：指定 JPA 配置文件为 test/persistence.xml，且该配置文件非常简单，具体配置完全在Spring中进行；
 - `persistenceUnitName`：指定持久化单元名字，即 JPA 配置文件中指定的;
 - `packagesToScan`：指定扫描哪个包下的类，当 persistenceUnitName 和 packagesToScan 属性同时存在时，会使用 persistenceUnitName 属性
 - `persistenceProvider`：指定 JPA 持久化提供商，此处使用 Hibernate 实现 HibernatePersistence类；
 - `jpaVendorAdapter`：指定实现厂商专用特性，即 `generateDdl= false` 表示不自动生成 DDL，`database= HSQL` 表示使用 hsqld b数据库；
 - `jpaDialect`：如果指定 jpaVendorAdapter 此属性可选，此处为 HibernateJpaDialect；
 - `jpaPropertyMap`：此处指定一些属性。

### 处理多持久化单元

对于那些依靠多个持久化单元位置(例如存放在 classpath 中的多个 jar 中)的应用程序， Spring 提供了作为中央仓库的 PersistenceUnitManager， 避免了持久化单元查找过程。缺省实现允许指定多个位置 (默认情况下 classpath 会搜索 META-INF/persistence.xml 文件)，它们会被解析然后通过持久化单元名称被获取：

~~~xml
<bean id="persistenceUnitManager" class="org.springframework.orm.jpa.persistenceunit.DefaultPersistenceUnitManager">
	<property name="persistenceXmlLocation">
	    <list>
	     <value>orgframework/orm/domain/persistence-multi.xml</value>
	     <value>classpath:/my/package/**/custom-persistence.xml</value>
	     <value>classpath*:META-INF/persistence.xml</value>
	    </list>
	</property>
	<property name="dataSources">
	   <map>
	    <entry key="localDataSource" value-ref="local-db"/>
	    <entry key="remoteDataSource" value-ref="remote-db"/>
	   </map>
	</property>
	<!-- if no datasource is specified, use this one -->
	<property name="defaultDataSource" ref="remoteDataSource"/>
</bean>

<bean id="entityManagerFactory" class="org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean">
	<property name="persistenceUnitManager" ref="persistenceUnitManager"/>
</bean>
~~~

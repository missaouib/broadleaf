---
layout: post

title: JPA的使用

category: java

tags: [ java,jpa ]

description: 本文主要对 JPA 做一个简要的介绍并记录如何使用 JPA，希望通过这篇文章能够对 JPA 有一个全面的认识。因为限于篇幅，有些地方不会做详细说明。

published: true

---

JPA，Java 持久化规范，是从EJB2.x以前的实体 Bean 分离出来的，EJB3 以后不再有实体 bean，而是将实体 bean 放到 JPA 中实现。

JPA 是 sun 提出的一个对象持久化规范，各 JavaEE 应用服务器自主选择具体实现，JPA 的设计者是 Hibernate 框架的作者，因此Hibernate作为Jboss服务器中JPA的默认实现，Oracle的Weblogic使用EclipseLink(以前叫TopLink)作为默认的JPA实现，IBM的Websphere和Sun的Glassfish默认使用OpenJPA(Apache的一个开源项目)作为其默认的JPA实现。

JPA 的底层实现是一些流行的开源 ORM 框架，因此JPA其实也就是java实体对象和关系型数据库建立起映射关系，通过面向对象编程的思想操作关系型数据库的规范。

# 1. JPA 历史

早期版本的EJB，定义持久层结合使用 `javax.ejb.EntityBean` 接口作为业务逻辑层。

- 同时引入 EJB3.0 的持久层分离，并指定为JPA1.0（Java持久性API）。这个API规范随着 JAVA EE5 对2006年5月11日使用JSR220规范发布。
- JPA2.0 的JAVA EE 6规范发布于2009年12月10日并成 Java Community Process JSR317 的一部分。
- JPA2.1 使用 JSR338 的 JAVA EE7的规范发布于2013年4月22日。

# 2. JPA 架构

下图显示了JPA核心类和JPA接口。

![](http://7xnrdo.com1.z0.glb.clouddn.com/jpa/JPA-01.png)


|类或接口|	描述|
|---|:---|
|EntityManagerFactory|	这是一个 EntityManager 的工厂类。它创建并管理多个 EntityManager 实例。|
|EntityManager|	这是一个接口，它管理的持久化操作的对象。它的工作原理类似工厂的查询实例。|
|Entity|	实体是持久性对象是存储在数据库中的记录。|
|EntityTransaction|	它与 EntityManager 是一对一的关系。对于每一个 EntityManager ，操作是由 EntityTransaction 类维护。|
|Persistence|	这个类包含静态方法来获取 EntityManagerFactory 实例。|
|Query|	该接口由每个 JPA 供应商，能够获得符合标准的关系对象。|

在上述体系结构中，类和接口之间的关系属于javax.persistence包。下图显示了它们之间的关系。

![](http://7xnrdo.com1.z0.glb.clouddn.com/jpa/JPA-02.png)

 - EntityManagerFactory 和 EntityManager 的关系是1对多。这是一个工厂类 EntityManager 实例。
 - EntityManager 和 EntityTransaction 之间的关系是1对1。对于每个 EntityManager 操作，只有一个 EntityTransaction 实例。
 - EntityManager 和 Query 之间的关系是1对多。查询数众多可以使用一个 EntityManager 实例执行。
 - EntityManager 实体之间的关系是1对多。一个 EntityManager 实例可以管理多个实体。

# 搭建 JPA 开发环境

## 创建 maven 工程
创建一个空的 maven 工程，然后编写 pom.xml 文件，添加下面配置：

~~~xml
<properties>
	<spring.version>4.1.2.RELEASE</spring.version>
	<hibernate.version>4.1.9.Final</hibernate.version>
	<hibernate-jpa.version>2.0-cr-1</hibernate-jpa.version>
</properties>

<dependencies>
	<dependency>
		<groupId>org.springframework</groupId>
		<artifactId>spring-core</artifactId>
		<version>${spring.version}</version>
	</dependency>
	<dependency>
		<groupId>org.springframework</groupId>
		<artifactId>spring-beans</artifactId>
		<version>${spring.version}</version>
	</dependency>
	<dependency>
		<groupId>org.springframework</groupId>
		<artifactId>spring-context</artifactId>
		<version>${spring.version}</version>
	</dependency>
	<dependency>
		<groupId>org.springframework</groupId>
		<artifactId>spring-aop</artifactId>
		<version>${spring.version}</version>
	</dependency>
	<dependency>
		<groupId>org.springframework</groupId>
		<artifactId>spring-context-support</artifactId>
		<version>${spring.version}</version>
	</dependency>
	<dependency>
		<groupId>org.springframework</groupId>
		<artifactId>spring-tx</artifactId>
		<version>${spring.version}</version>
	</dependency>
	<dependency>
		<groupId>org.springframework</groupId>
		<artifactId>spring-orm</artifactId>
		<version>${spring.version}</version>
	</dependency>
	<dependency>
		<groupId>org.springframework</groupId>
		<artifactId>spring-jdbc</artifactId>
		<version>${spring.version}</version>
	</dependency>

	<dependency>
		<groupId>org.hibernate.java-persistence</groupId>
		<artifactId>jpa-api</artifactId>
		<version>${hibernate-jpa.version}</version>
	</dependency>
	<dependency>
		<groupId>org.hibernate</groupId>
		<artifactId>hibernate-entitymanager</artifactId>
		<version>${hibernate.version}</version>
	</dependency>

	<dependency>
      <groupId>com.h2database</groupId>
      <artifactId>h2</artifactId>
      <version>1.3.156</version>
  </dependency>

	<dependency>
		<groupId>org.springframework</groupId>
		<artifactId>spring-test</artifactId>
		<version>${spring.version}</version>
	</dependency>

	<dependency>
		<groupId>junit</groupId>
		<artifactId>junit</artifactId>
		<version>4.11</version>
		<scope>test</scope>
	</dependency>
</dependencies>
~~~

## 创建实体

~~~java
package com.javachen.spring4.jpa.entity;

import javax.persistence.*;
import javax.validation.constraints.Max;
import javax.validation.constraints.Min;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;
import java.io.Serializable;

@Entity
@NamedQuery(query = "Select e from Person e where e.id = :id",
        name = "find person by id")
@Table(name = "T_PERSON")
public class Person implements Serializable {
    private static final long serialVersionUID = 1L;

    @Id
    @Column(name = "PERSON_ID")
    @GeneratedValue
    private Integer id;

    @Column(name = "PERSON_NAME")
    @Size(min = 1, max = 30)
    @NotNull
    private String name;

    @Column(name = "AGE")
    @Min(1)
    @Max(200)
    @NotNull
    private Integer age;

    @Column(name = "salary")
    private Double salary;

		//省略 set、get 方法

    @Override
    public String toString() {
        return "Person [id=" + id + ", name=" + name + ", age=" + age + ",salary="+salary+"]";
    }
}
~~~

## persistence.xml

在这个文件中，我们将注册数据库，并指定实体类。另外，在上述所示的包的层次结构，根据JPA的内容包含在 persistence.xml 。

在 `src/main/resources/META-INF/` 目录创建一个文件，名称为 persistence.xml，内容为：

~~~xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<persistence xmlns="http://java.sun.com/xml/ns/persistence"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="2.0"
    xsi:schemaLocation="http://java.sun.com/xml/ns/persistence http://java.sun.com/xml/ns/persistence/persistence_2_0.xsd" >
    <persistence-unit name="db1-unit"
                      transaction-type="RESOURCE_LOCAL">
        <class>com.javachen.spring4.jpa.entity.Person</class>
        <properties>
            <property name="hibernate.connection.driver_class" value="net.sf.log4jdbc.DriverSpy"/>
            <property name="hibernate.connection.url" value="jdbc:log4jdbc:h2:mem:example"/>
            <property name="hibernate.connection.username" value="sa"/>
            <property name="hibernate.connection.password" value=""/>
            <property name="hibernate.dialect" value="org.hibernate.dialect.H2Dialect"/>

            <property name="hibernate.jdbc.batch_size" value="30" />
            <property name="hibernate.use_sql_comments" value="true" />
            <property name="hibernate.hbm2ddl.auto" value="create" />
            <property name="hibernate.show_sql" value="true" />
            <property name="hibernate.ejb.naming_strategy"
                      value="org.hibernate.cfg.ImprovedNamingStrategy" />
            <property name="hibernate.connection.charSet"
                      value="UTF-8" />
            <property name="hibernate.current_session_context_class" value="thread"/>
        </properties>
    </persistence-unit>
</persistence>
~~~

如果有多个持久化单元，则可以配置多个 persistence-unit 节点。

以下是 persistence.xml 所有配置项的一个示例说明：

~~~xml
<?xml version="1.0" encoding="UTF-8"?>  

<persistence version="1.0"  
xmlns:persistence="http://java.sun.com/xml/ns/persistence"  
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"  
xsi:schemaLocation="http://java.sun.com/xml/ns/persistence persistence_1_0.xsd ">  

<!--
     Name属性用于定义持久化单元的名字 (name必选,空值也合法);
     transaction-type 指定事务类型(可选：JTA、RESOURCE_LOCAL)
-->  
<persistence-unit name="unitName" transaction-type="JTA">  

   <!-- 描述信息.(可选) -->  
   <description> </description>  

   <!-- javax.persistence.PersistenceProvider接口的一个实现类(可选) -->  
   <provider></provider>  

   <!-- Jta-data-source和 non-jta-data-source用于分别指定持久化提供商使用的JTA和/或non-JTA数据源的全局JNDI名称(可选) -->  
   <jta-data-source>java:/MySqlDS</jta-data-source>  
   <non-jta-data-source></non-jta-data-source>  

   <!-- 声明orm.xml所在位置.(可选) -->  
   <mapping-file>product.xml</mapping-file>  

   <!-- 以包含persistence.xml的jar文件为基准的相对路径,添加额外的jar文件.(可选) -->  
   <jar-file>../lib/model.jar</jar-file>  

   <!-- 显式列出实体类,在Java SE 环境中应该显式列出.(可选) -->  
   <class>com.domain.User</class>  

   <!-- 声明是否扫描jar文件中标注了@Enity类加入到上下文.若不扫描,则如下:(可选) -->  
   <exclude-unlisted-classes/>  

   <!--   厂商专有属性(可选)   -->  
   <properties>  
    <!-- hibernate.hbm2ddl.auto= create-drop / create / update -->  
    <property name="hibernate.hbm2ddl.auto" value="update" />  
    <property name="hibernate.show_sql" value="true" />  
   </properties>  

</persistence-unit>  

</persistence>
~~~

## 持久化操作

~~~java
package com.javachen.spring4.jpa.entity;

import javax.persistence.EntityManager;
import javax.persistence.EntityManagerFactory;
import javax.persistence.Persistence;
import javax.persistence.Query;
import java.util.List;

public class PersonTest {

    public static void main(String[] args) {
        EntityManagerFactory emfactory = Persistence.
                createEntityManagerFactory( "db1-unit" );
        EntityManager entitymanager = emfactory.
                createEntityManager( );
        entitymanager.getTransaction( ).begin( );

        Person person=new Person();
        person.setAge(18);
        person.setSalary(121d);
        person.setName("zhangsan");

        entitymanager.persist( person );
        entitymanager.getTransaction( ).commit( );

        entitymanager.close();
        emfactory.close( );
    }
}
~~~

在上面的代码中 `createEntityManagerFactory()` 通过提供我们在 persistent.xml 文件提供持久化单元相同唯一的名称创建一个持久性单元。 EntityManagerFactory对象将由usingcreateEntityManager()方法创建entitymanger实例。 EntityManager对象创建 entitytransactioninstance 事务管理。通过使用 EntityManager 对象，我们可以持久化实体到数据库中。

# 3. JPQL

JPQL 代表 Java 持久化查询语言。它被用来创建针对实体的查询存储在关系数据库中。 JPQL 是基于 SQL 语法的发展。但它不会直接影响到数据库。

JPQL 可以检索使用 SELECT 子句中的数据，可以使用 UPDATE 子句做批量 UPDATE 和 DELETE 子句。

## 3.1 标准查询结构

示例代码：

~~~java
EntityManagerFactory emfactory = Persistence.
                createEntityManagerFactory( "db1-unit" );
EntityManager entitymanager = emfactory.
        createEntityManager( );
entitymanager.getTransaction( ).begin( );

//Scalar function
Query query = entitymanager.
        createQuery("Select UPPER(e.name) from Person e");
List<String> list=query.getResultList();

for(String e:list){
    System.out.println("Person name :"+e);
}

//Aggregate function
Query query1 = entitymanager.
        createQuery("Select MAX(e.salary) from Person e");
Double result=(Double) query1.getSingleResult();
System.out.println("Max Person Salary :"+result);


entitymanager.close();
emfactory.close( );
~~~

## 3.2 命名查询

@NamedQuery 注解被定义为一个预定义的查询字符串，它是不可改变的查询。@NamedQuery 注解加在实体之上，例如：

~~~java
@Entity
@NamedQuery(query = "Select e from Person e where e.id = :id",
        name = "find person by id")
@Table(name = "T_PERSON")
public class Person implements Serializable {
}
~~~

命名查询使用方法：

~~~java
import java.util.List;
import javax.persistence.EntityManager;
import javax.persistence.EntityManagerFactory;
import javax.persistence.Persistence;
import javax.persistence.Query;
import com.yiibai.eclipselink.entity.Employee;

public class NamedQueries{
   public static void main( String[ ] args ){
   	EntityManagerFactory emfactory = Persistence.
   		createEntityManagerFactory( "db1-unit" );
   	EntityManager entitymanager = emfactory.
   		createEntityManager();
   	Query query = entitymanager.createNamedQuery(
   		"find person by id");
   	query.setParameter("id", 1);
   	List<Person> list = query.getResultList( );
   	for( Person e:list ){
   		System.out.print("Person ID :"+e.getId( ));
   		System.out.println("\t Person Name :"+e.getName( ));
   	}
   }
}
~~~

## 3.3 动态查询

下面使用简单的条件**动态查询**返回数据源中的实体类的所有实例。

~~~java
EntityManager em = ...;
CriteriaBuilder cb = em.getCriteriaBuilder();
CriteriaQuery<Entity class> cq = cb.createQuery(Entity.class);
Root<Entity> from = cq.from(Entity.class);
cq.select(Entity);
TypedQuery<Entity> q = em.createQuery(cq);
List<Entity> allitems = q.getResultList();
~~~

查询演示了基本的步骤来创建一个标准。

- `EntityManager` 实例被用来创建一个 CriteriaBuilder 对象。
- `CriteriaQuery` 实例是用来创建一个查询对象。这个查询对象的属性将与该查询的细节进行修改。
- `CriteriaQuery.form` 方法被调用来设置查询根。
- `CriteriaQuery.select` 被调用来设置结果列表类型。
- `TypedQuery<T>` 实例是用来准备一个查询执行和指定的查询结果的类型。
- 在 `TypedQuery<T>` 对象 getResultList 方法来执行查询。该查询返回实体的集合，结果存储在一个列表中。

# 4. 实体映射关系

## 4.1 注解

在实体中使用到的注解列表如下：

|注解|	描述|
|---|:---|
|@Entity|	声明类为实体或表。|
|@Table|	声明表名。|
|@Basic|	指定非约束明确的各个字段。|
|@Embedded|	指定类或它的值是一个可嵌入的类的实例的实体的属性。|
|@Id|	指定的类的属性，用于标识主键。|
|@GeneratedValue|	指定主键生成方式，例如自动，手动，或从序列表中获得的值。|
|@Transient|	该值永远不会存储在数据库中。|
|@Lob|	将属性持久化为 Blob 或者 Clob 类型。|
|@Column|	指定字段属性。|
|@SequenceGenerator	|指定在 `@GeneratedValue` 注解中指定的属性的值。它创建了一个序列。|
|@TableGenerator	|指定在 `@GeneratedValue` 批注指定属性的值发生器。它创造了的值生成的表。|
|@AccessType|	这种类型的注释用于设置访问类型。|
|@JoinColumn|	指定一个实体组织或实体的集合。这是用在多对一和一对多关联。|
|@UniqueConstraint|	指定的字段和用于主要或辅助表的唯一约束。|
|@ColumnResult|	参考使用 select 子句的 SQL 查询中的列名。|
|@ManyToMany	|定义了连接表之间的多对多一对多的关系。|
|@ManyToOne|	定义了连接表之间的多对一的关系。|
|@OneToMany	|定义了连接表之间存在一个一对多的关系。|
|@OneToOne|	定义了连接表之间有一个一对一的关系。|
|@NamedQueries|	指定命名查询的列表。|
|@NamedQuery|	指定使用静态名称的命名查询。|

1、 `@OneToOne`：

一对一映射注解，双向的一对一关系需要在关系维护端(owner side)的 @OneToOne 注解中添加 mappedBy 属性，建表时在关系被维护端(inverse side)建立外键指向关系维护端的主键列。

**用法：**`@OneToOne(optional=true,casecade=CasecadeType.ALL,mappedBy=”被维护端外键”)`

2、 `@OneToMany`：

一对多映射注解，双向一对多关系中，一端是关系维护端(owner side)，只能在一端添加 mapped 属性。多端是关系被维护端(inverse side)。建表时在关系被维护端(多端)建立外键指向关系维护端(一端)的主键列。

**用法：** `@OneToMany(mappedBy = "维护端(一端)主键", cascade=CascadeType.ALL)`

>**注意：**
>在Hibernate中有个术语叫做维护关系反转，即由对方维护关联关系，使用 `inverse=false` 来表示关系维护放，在JPA的注解中，mappedBy就相当于inverse=false，即由mappedBy来维护关系。

3、`＠ManyToOne`：

多对一映射注解，在双向的一对多关系中，一端一方使用 @OneToMany 注解，多端的一方使用 @ManyToOne 注解。多对一注解用法很简单，它不用维护关系。

**用法：** `@ManyToOne(optional = false, fetch = FetchType.EAGER)`

4、 `@ManyToMany`：

多对多映射，采取中间表连接的映射策略，建立的中间关系表分别引入两边的主键作为外键，形成两个多对一关系。

双向的多对多关系中，在关系维护端(owner side)的 @ManyToMany 注解中添加 mappedBy 属性，另一方是关系的被维护端(inverse side)，关系的被维护端不能加 mappedBy 属性，建表时，根据两个多端的主键生成一个中间表，中间表的外键是两个多端的主键。

**用法：**

- 关系维护端——> `@ManyToMany(mappedBy="另一方的关系引用属性")`
- 关系被维护端——> `@ManyToMany(cascade=CascadeType.ALL ,fetch = FetchType.Lazy)`

## 4.2 实体关联映射策略

### 4.2.1 一对一关联映射

**(1).一对一主键关联：**

一对一关联映射中，主键关联策略不会在两个关联实体对应的数据库表中添加外键字段，两个实体的表公用同一个主键(主键相同)，其中一个实体的主键既是主键又是外键。

**主键关联映射：**在实体关联属性或方法上添加 @OneToOne 注解的同时添加 `@PrimaryKeyJoinColumn` 注解(在一对一注解关联映射的任意一端实体添加即可)。

**(2).一对一唯一外键关联：**

一对一关联关系映射中，唯一外键关联策略会在其中一个实体对应数据库表中添加外键字段指向另一个实体表的主键，也是一对一映射关系中最常用的映射策略。

唯一外键关联：在关联属性或字段上添加 @OneToOne 注解的同时添加 `@JoinColumn(name=”数据表列名”，unique=true)` 注解。

### 4.2.2 一对多关联映射

在JPA中两个实体之间是一对多关系的称为一对多关联关系映射，如班级和学生关系。

**(1).一对多单向关联映射：**

在一对多单向关联映射中，JPA 会在数据库中自动生成公有的中间表记录关联关系的情况。在一端关联集合属性或字段上添加 @OneToMany 注解即可。

**(2).一对多双向关联映射：**

在一对多双向关联映射中，JPA 不会在数据库中生成公有中间表。在一端关联集合属性或字段上添加 @OneToMany 注解，同时指定其 mappedBy 属性。
在多端关联属性或字段上添加 @ManyToOne 注解。

**注意：**一对多关系映射中，mappedBy 只能添加在 OneToMany 注解中，即在多端生成外键。

### 4.2.3 多对多关联映射

在JPA中两个实体之间是多对多关系的称为多对多关联关系映射，如学生和教师关系。

**(1).多对多单向映射：**

在其中任意实体一方关联属性或字段上添加 @ManyToMany 注解。

**(2).多对多双向映射：**

关系维护端关联属性或字段上添加 @ManyToMany 注解，同时指定该注解的 mappedBy 属性。

关系被维护端关联属性或字段上添加 @ManyToMany 注解。

## 4.3 实体继承映射策略

在 JPA 中，**实体继承关系的映射策略共有三种：单表继承策略、Joined 策略和 TABLE_PER_CLASS 策略**。

### 4.3.1 单表继承策略：

单表继承策略，父类实体和子类实体共用一张数据库表，在表中通过一列辨别字段来区别不同类别的实体。具体做法如下：

a.在父类实体的 @Entity 注解下添加如下的注解：

~~~java
@Inheritance(Strategy=InheritanceType.SINGLE_TABLE)  
@DiscriminatorColumn(name="辨别字段列名")  
@DiscriminatorValue(父类实体辨别字段列值)  
~~~

b.在子类实体的 @Entity 注解下添加如下的注解：

~~~java
@DiscriminatorValue(子类实体辨别字段列值)  
~~~

### 4.3.2 Joined 策略：

Joined 策略，父类实体和子类实体分别对应数据库中不同的表，子类实体的表中只存在其扩展的特殊属性，父类的公共属性保存在父类实体映射表中。

具体做法：只需在父类实体的 @Entity 注解下添加如下注解：

~~~java
@Inheritance(Strategy=InheritanceType.JOINED)  
~~~

子类实体不需要特殊说明。

### 4.3.3 TABLE_PER_CLASS 策略：

TABLE_PER_CLASS 策略，父类实体和子类实体每个类分别对应一张数据库中的表，子类表中保存所有属性，包括从父类实体中继承的属性。

具体做法：只需在父类实体的 @Entity 注解下添加如下注解：

~~~java
@Inheritance(Strategy=InheritanceType.TABLE_PER_CLASS)  
~~~

子类实体不需要特殊说明。

# 5. 参考文章

- [1] [JPA教程](http://www.yiibai.com/jpa/)
- [2] [JPA学习笔记1——JPA基础](http://blog.csdn.net/chjttony/article/details/6086298)

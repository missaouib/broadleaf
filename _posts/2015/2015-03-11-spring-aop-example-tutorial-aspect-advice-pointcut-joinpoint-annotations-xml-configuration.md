---
layout: post

title: Spring AOP Example Tutorial

category:  spring

tags: [ spring,aop,java,aspect ]

description:  这是一篇网络上关于 Spring AOP 教程的翻译，希望通过翻译该文的过程，熟悉 Spring AOP 的基本概念以及常见用法。

published: true

---

>这是一篇翻译，原文：[Spring AOP Example Tutorial – Aspect, Advice, Pointcut, JoinPoint, Annotations, XML Configuration](http://www.journaldev.com/2583/spring-aop-example-tutorial-aspect-advice-pointcut-joinpoint-annotations-xml-configuration)

Spring 框架发展出了两个核心概念：[依赖注入](http://www.journaldev.com/2394/dependency-injection-design-pattern-in-java-example-tutorial) 和面向切面编程（AOP）。我们已经了解了 [Spring 的依赖注入](http://www.journaldev.com/2410/spring-dependency-injection-example-with-annotations-and-xml-configuration) 是如何实现的，今天我们来看看面向切面编程的核心概念以及 Spring 框架是如何实现它的。

# AOP 概要

大多数的企业应用都会有一些共同的对横切的关注，横切是否适用于不同的对象或者模型。一些共同关注的横切有日志、事务管理以及数据校验等等。在面向对象的编程中，应用模块是有类来实现的，然而面向切面的编程的应用模块是由切面（Aspect）来获取的，他们被配置用于切不同的类。

AOP 任务将横切任务的直接依赖从类中抽离出来，因为我们不能直接从面向对象编程的模型中获取这些依赖。例如，我们可以有一个单独的类用于记录日志，但是相同功能的类将不得不调用这些方法去获取应用的中的日志。

# AOP 核心概念

在我们深入了解 Spring 框架中 AOP 的实现方式之前，我们需要了解 AOP 中的一些核心概念。

- `Aspect`：切面，实现企业应用中多个类的共同关注点，例如事务管理。切面可以是使用 Spring XML 配置的一个普通类或者是我们使用 Spring AspectJ 定义的一个标有 @Aspect 注解的类。
- `Join Point`：连接点，一个连接点是应用程序中的一个特定的点，例如方法执行、异常处理、改变对象变量的值等等。在 Spring AOP 中，一个连接点永远是指一个方法的执行。
- `Advice`：通知，通知是指在一个特别的连接点上发生的动作。在编程中，他们是当一个连接点匹配到一个切入点时执行的方法。你可以把通知想成 Strust2 中的拦截器或者是 Servlet 中的过滤器。
- `Pointcut`：切入点，切入点是一些表达式，当匹配到连接点时决定通知是否需要执行。切入点使用不同种类型的表达式来匹配连接点，Spring 框架使用 AspectJ 表达式语法。
- `Target Object`：通知执行的目标对象。Spring AOP 是使用运行时的代理来实现的，所以该对象永远是一个代理对象。这意味着一个子类在运行期间会被创建，该类的目标方法会被覆盖并且通知会基于他们的配置被引入。
- `AOP proxy`：Spring AOP 实现使用 JDK 的动态代理来创建包含有目标类和通知调用的代理类，这些类被称为 AOP 代理类。我们也可以使用 CGLIB 代理来作为 Spring AOP 项目的依赖实现。
- `Weaving`：织入，将切面和其他用于创建被通知的代理对象的类联系起来的过程。这可以是在运行时完成，也可以是在代码加载过程中或者运行时。Spring AOP 是在运行时完成织入的过程。

# AOP 通知类型

基于通知的执行策略，这里有以下几种通知类型：

- `Before Advice`：在连接点方法执行之前运行。我们可以使用 `@Before` 注解来标记一个通知类型为 Before Advice。
- `After (finally) Advice`：在连接点方法执行完成之后运行。我们可以使用 `@After` 来创建一个 After (finally) Advice。
- `After Returning Advice`：在方法返回之后运行，通过 `@AfterReturning` 注解创建。
- `After Throwing Advice`：在方法抛出异常之后运行，通过 `@AfterThrowing` 注解创建。
- `Around Advice`：这是最重要和最强的通知。这个通知在连接点方法前后运行并且我们可以决定该通知是否运行，通过 `@Around` 注解创建。

上面提到的知识点可能会使我们困惑，但是当我们看到 Spring AOP 的实现之后，就会豁然开朗了。下面我们来创建一个 Spring AOP 的项目。Spring 支持使用 AspectJ 的注解来创建切面，为了简单，我们将直接使用这些注解。上面提到的所有 AOP 的注解都定义在 org.aspectj.lang.annotation 包中。

Spring Tool Suite 提供了对 AspectJ 的支持，所以建议你使用它来创建项目。如果你对 STS 不熟悉，可以参考我的 [Spring MVC 教程](http://www.journaldev.com/2433/spring-mvc-tutorial-for-beginners-with-spring-tool-suite) 来熟悉如何使用它。

创建一个简单的 Spring Maven 项目，通过 pom.xml 引入 Spring 的核心库。在项目创建成功之后，我们可以看到下面的目录结构：

![](http://www.journaldev.com/wp-content/uploads/2014/03/Spring-AOP-Example-Project.png)

# Spring AOP AspectJ 依赖

Spring 框架默认提供了对 AOP 的支持，既然我们需要使用 AspectJ 的注解，则需要在 pom.xml 中引入相关的依赖：

~~~xml
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <groupId>org.springframework.samples</groupId>
    <artifactId>SpringAOPExample</artifactId>
    <version>0.0.1-SNAPSHOT</version>
 
    <properties>
 
        <!-- Generic properties -->
        <java.version>1.6</java.version>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <project.reporting.outputEncoding>UTF-8</project.reporting.outputEncoding>
 
        <!-- Spring -->
        <spring-framework.version>4.0.2.RELEASE</spring-framework.version>
 
        <!-- Logging -->
        <logback.version>1.0.13</logback.version>
        <slf4j.version>1.7.5</slf4j.version>
 
        <!-- Test -->
        <junit.version>4.11</junit.version>
 
        <!-- AspectJ -->
        <aspectj.version>1.7.4</aspectj.version>
 
    </properties>
 
    <dependencies>
        <!-- Spring and Transactions -->
        <dependency>
            <groupId>org.springframework</groupId>
            <artifactId>spring-context</artifactId>
            <version>${spring-framework.version}</version>
        </dependency>
        <dependency>
            <groupId>org.springframework</groupId>
            <artifactId>spring-tx</artifactId>
            <version>${spring-framework.version}</version>
        </dependency>
 
        <!-- Logging with SLF4J & LogBack -->
        <dependency>
            <groupId>org.slf4j</groupId>
            <artifactId>slf4j-api</artifactId>
            <version>${slf4j.version}</version>
            <scope>compile</scope>
        </dependency>
        <dependency>
            <groupId>ch.qos.logback</groupId>
            <artifactId>logback-classic</artifactId>
            <version>${logback.version}</version>
            <scope>runtime</scope>
        </dependency>
 
        <!-- AspectJ dependencies -->
        <dependency>
            <groupId>org.aspectj</groupId>
            <artifactId>aspectjrt</artifactId>
            <version>${aspectj.version}</version>
            <scope>runtime</scope>
        </dependency>
        <dependency>
            <groupId>org.aspectj</groupId>
            <artifactId>aspectjtools</artifactId>
            <version>${aspectj.version}</version>
        </dependency>
    </dependencies>
</project>
~~~

需要注意的是，我在项目中添加了对 aspectjrt 和 aspectjtools （版本为 1.7.4）的依赖。并且我也把 Spring 的版本更新到了 4.0.2.RELEASE。

# 模型类

下面我们来创建一个简单的 java bean：

Employee.java

~~~java
package com.journaldev.spring.model;
 
import com.journaldev.spring.aspect.Loggable;
 
public class Employee {
 
    private String name;
     
    public String getName() {
        return name;
    }
 
    @Loggable
    public void setName(String nm) {
        this.name=nm;
    }
     
    public void throwException(){
        throw new RuntimeException("Dummy Exception");
    }
     
}
~~~

你有注意到 `setName()` 方法上定义了一个 `Loggable` 注解吗？它是一个我们项目中创建的自定义注解。我们将在后面介绍它的用法。

# 服务类

下面，我们来创建一个服务类来处理 Employee 对象：

EmployeeService.java

~~~java
package com.journaldev.spring.service;
 
import com.journaldev.spring.model.Employee;
 
public class EmployeeService {
 
    private Employee employee;
     
    public Employee getEmployee(){
        return this.employee;
    }
     
    public void setEmployee(Employee e){
        this.employee=e;
    }
}
~~~

我本来可以使用 Spring 注解来将其配置为一个 Spring 的组件，但是在该项目中我们将会使用 XML 来配置。EmployeeService 是一个非常标准的类，并提供了一个访问 Employee 的点。

# AOP 配置

我项目中的配置 spring.xml 如下：

~~~xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:aop="http://www.springframework.org/schema/aop"
    xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans-4.0.xsd
        http://www.springframework.org/schema/aop http://www.springframework.org/schema/aop/spring-aop-4.0.xsd">
 
<!-- Enable AspectJ style of Spring AOP -->
<aop:aspectj-autoproxy />
 
<!-- Configure Employee Bean and initialize it -->
<bean name="employee" class="com.journaldev.spring.model.Employee">
    <property name="name" value="Dummy Name"></property>
</bean>
 
<!-- Configure EmployeeService bean -->
<bean name="employeeService" class="com.journaldev.spring.service.EmployeeService">
    <property name="employee" ref="employee"></property>
</bean>
 
<!-- Configure Aspect Beans, without this Aspects advices wont execute -->
<bean name="employeeAspect" class="com.journaldev.spring.aspect.EmployeeAspect" />
<bean name="employeeAspectPointcut" class="com.journaldev.spring.aspect.EmployeeAspectPointcut" />
<bean name="employeeAspectJoinPoint" class="com.journaldev.spring.aspect.EmployeeAspectJoinPoint" />
<bean name="employeeAfterAspect" class="com.journaldev.spring.aspect.EmployeeAfterAspect" />
<bean name="employeeAroundAspect" class="com.journaldev.spring.aspect.EmployeeAroundAspect" />
<bean name="employeeAnnotationAspect" class="com.journaldev.spring.aspect.EmployeeAnnotationAspect" />
 
</beans>
~~~

在 Spring beans 中使用 AOP，我们需要添加：

- 申明 AOP 命名空间，如：`xmlns:aop="http://www.springframework.org/schema/aop"`。
- 添加 `aop:aspectj-autoproxy` 节点开启 Spring AspectJ 在运行时自动代理的支持。
- 配置 Aspect 类。

# Before Aspect  例子

EmployeeAspect.java：

~~~java
package com.journaldev.spring.aspect;
 
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Before;
 
@Aspect
public class EmployeeAspect {
 
    @Before("execution(public String getName())")
    public void getNameAdvice(){
        System.out.println("Executing Advice on getName()");
    }
     
    @Before("execution(* com.journaldev.spring.service.*.get*())")
    public void getAllAdvice(){
        System.out.println("Service method getter called");
    }
}
~~~

上面例子中重要的地方说明如下：

- Aspect 类需要添加 `@Aspect` 注解。
- `@Before `注解用于创建 Before advice。
- `@Before` 注解中的字符串参数是 Pointcut 表达式。
- getNameAdvice() 通知将会在任何带有 `public String getName()`` 方法签名的 Spring Bean 方法执行时执行。这点是非常重要的，如果我们使用 new 操作符来创建一个 Employee bean，该通知并不会执行，其只会在 ApplicationContext 获取该 bean 时执行。

# 切点方法和重用

有时候，我们需要在多个地方上使用相同的切点表达式，我们可以使用一个空方法的 `@Pointcut` 注解，然后在通知中将它作为表达式来使用。

EmployeeAspectPointcut.java

~~~java
package com.journaldev.spring.aspect;
 
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Before;
import org.aspectj.lang.annotation.Pointcut;
 
@Aspect
public class EmployeeAspectPointcut {
 
    @Before("getNamePointcut()")
    public void loggingAdvice(){
        System.out.println("Executing loggingAdvice on getName()");
    }
     
    @Before("getNamePointcut()")
    public void secondAdvice(){
        System.out.println("Executing secondAdvice on getName()");
    }
     
    @Pointcut("execution(public String getName())")
    public void getNamePointcut(){}
     
    @Before("allMethodsPointcut()")
    public void allServiceMethodsAdvice(){
        System.out.println("Before executing service method");
    }
     
    //Pointcut to execute on all the methods of classes in a package
    @Pointcut("within(com.journaldev.spring.service.*)")
    public void allMethodsPointcut(){}
     
}
~~~

上面的例子非常清晰，相对于表达式，我们在使用方法名称作为注解的参数。

# 连接点和通知参数

我们可以使用 JoinPoint 作为通知方法的参数并且使用他获取方法签名或者目标对象。

我们可以在连接点中使用 `args()` 表达式来匹配任何方法的任何参数。如果我们使用它，则我们需要在通知方法中使用同参数相同的名称。我们也可以在通知参数中使用泛型。

EmployeeAspectJoinPoint.java

~~~java 
package com.journaldev.spring.aspect;
 
import java.util.Arrays;
 
import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Before;
 
@Aspect
public class EmployeeAspectJoinPoint {
 
     
    @Before("execution(public void com.journaldev.spring.model..set*(*))")
    public void loggingAdvice(JoinPoint joinPoint){
        System.out.println("Before running loggingAdvice on method="+joinPoint.toString());
         
        System.out.println("Agruments Passed=" + Arrays.toString(joinPoint.getArgs()));
 
    }
     
    //Advice arguments, will be applied to bean methods with single String argument
    @Before("args(name)")
    public void logStringArguments(String name){
        System.out.println("String argument passed="+name);
    }
}
~~~

# After Advice 例子

EmployeeAfterAspect.java 如下：

~~~java
package com.journaldev.spring.aspect;
 
import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.annotation.After;
import org.aspectj.lang.annotation.AfterReturning;
import org.aspectj.lang.annotation.AfterThrowing;
import org.aspectj.lang.annotation.Aspect;
 
@Aspect
public class EmployeeAfterAspect {
 
    @After("args(name)")
    public void logStringArguments(String name){
        System.out.println("Running After Advice. String argument passed="+name);
    }
     
    @AfterThrowing("within(com.journaldev.spring.model.Employee)")
    public void logExceptions(JoinPoint joinPoint){
        System.out.println("Exception thrown in Employee Method="+joinPoint.toString());
    }
     
    @AfterReturning(pointcut="execution(* getName())", returning="returnString")
    public void getNameReturningAdvice(String returnString){
        System.out.println("getNameReturningAdvice executed. Returned String="+returnString);
    }
     
}
~~~

我们可以在切点表达式中使用 `within` 来申明该通知会在一个类的所有方法上执行。

# Around Aspect 例子

正如前面提到的，我们可以使用 Around aspect 来定义在方法前后进行执行指定的代码。

EmployeeAroundAspect.java

~~~java
package com.journaldev.spring.aspect;
 
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
 
@Aspect
public class EmployeeAroundAspect {
 
    @Around("execution(* com.journaldev.spring.model.Employee.getName())")
    public Object employeeAroundAdvice(ProceedingJoinPoint proceedingJoinPoint){
        System.out.println("Before invoking getName() method");
        Object value = null;
        try {
            value = proceedingJoinPoint.proceed();
        } catch (Throwable e) {
            e.printStackTrace();
        }
        System.out.println("After invoking getName() method. Return value="+value);
        return value;
    }
}
~~~

# 自定义的注解切点

前面提到了 `@Loggable`  注解，其定义如下：

~~~java
package com.journaldev.spring.aspect;
 
  public @interface Loggable {
 
}
~~~

我们可以创建一个切面来使用该切点，EmployeeAnnotationAspect.java 如下：

~~~java
package com.journaldev.spring.aspect;
 
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Before;
 
@Aspect
public class EmployeeAnnotationAspect {
 
    @Before("@annotation(com.journaldev.spring.aspect.Loggable)")
    public void myAdvice(){
        System.out.println("Executing myAdvice!!");
    }
}
~~~

`myAdvice()` 方法仅仅会在 `setName()` 方法执行前执行。

# Spring AOP XML Configuration

如果我们使用 Sping 的配置文件来定义切面，则定义方式如下。

EmployeeXMLConfigAspect.java

~~~java
package com.journaldev.spring.aspect;
 
import org.aspectj.lang.ProceedingJoinPoint;
 
public class EmployeeXMLConfigAspect {
 
    public Object employeeAroundAdvice(ProceedingJoinPoint proceedingJoinPoint){
        System.out.println("EmployeeXMLConfigAspect:: Before invoking getName() method");
        Object value = null;
        try {
            value = proceedingJoinPoint.proceed();
        } catch (Throwable e) {
            e.printStackTrace();
        }
        System.out.println("EmployeeXMLConfigAspect:: After invoking getName() method. Return value="+value);
        return value;
    }
}
~~~

在 配置文件中定义如下：

~~~xml
<bean name="employeeXMLConfigAspect" class="com.journaldev.spring.aspect.EmployeeXMLConfigAspect" />
 
<!-- Spring AOP XML Configuration -->
<aop:config>
<aop:aspect ref="employeeXMLConfigAspect" id="employeeXMLConfigAspectID" order="1">
    <aop:pointcut expression="execution(* com.journaldev.spring.model.Employee.getName())" id="getNamePointcut"/>
    <aop:around method="employeeAroundAdvice" pointcut-ref="getNamePointcut" arg-names="proceedingJoinPoint"/>
</aop:asp>
~~~

最后，来看看一个简单的程序来说明切面如何作用在 bean 的方法上。

~~~java
package com.journaldev.spring.main;
 
import org.springframework.context.support.ClassPathXmlApplicationContext;
 
import com.journaldev.spring.service.EmployeeService;
 
public class SpringMain {
 
    public static void main(String[] args) {
        ClassPathXmlApplicationContext ctx = new ClassPathXmlApplicationContext("spring.xml");
        EmployeeService employeeService = ctx.getBean("employeeService", EmployeeService.class);
         
        System.out.println(employeeService.getEmployee().getName());
         
        employeeService.getEmployee().setName("Pankaj");
         
        employeeService.getEmployee().throwException();
         
        ctx.close();
    }
 
}
~~~

我们将看到如下输出：

~~~
Mar 20, 2014 8:50:09 PM org.springframework.context.support.ClassPathXmlApplicationContext prepareRefresh
INFO: Refreshing org.springframework.context.support.ClassPathXmlApplicationContext@4b9af9a9: startup date [Thu Mar 20 20:50:09 PDT 2014]; root of context hierarchy
Mar 20, 2014 8:50:09 PM org.springframework.beans.factory.xml.XmlBeanDefinitionReader loadBeanDefinitions
INFO: Loading XML bean definitions from class path resource [spring.xml]
Service method getter called
Before executing service method
EmployeeXMLConfigAspect:: Before invoking getName() method
Executing Advice on getName()
Executing loggingAdvice on getName()
Executing secondAdvice on getName()
Before invoking getName() method
After invoking getName() method. Return value=Dummy Name
getNameReturningAdvice executed. Returned String=Dummy Name
EmployeeXMLConfigAspect:: After invoking getName() method. Return value=Dummy Name
Dummy Name
Service method getter called
Before executing service method
String argument passed=Pankaj
Before running loggingAdvice on method=execution(void com.journaldev.spring.model.Employee.setName(String))
Agruments Passed=[Pankaj]
Executing myAdvice!!
Running After Advice. String argument passed=Pankaj
Service method getter called
Before executing service method
Exception thrown in Employee Method=execution(void com.journaldev.spring.model.Employee.throwException())
Exception in thread "main" java.lang.RuntimeException: Dummy Exception
    at com.journaldev.spring.model.Employee.throwException(Employee.java:19)
    at com.journaldev.spring.model.Employee$$FastClassBySpringCGLIB$$da2dc051.invoke(<generated>)
    at org.springframework.cglib.proxy.MethodProxy.invoke(MethodProxy.java:204)
    at org.springframework.aop.framework.CglibAopProxy$CglibMethodInvocation.invokeJoinpoint(CglibAopProxy.java:711)
    at org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:157)
    at org.springframework.aop.aspectj.AspectJAfterThrowingAdvice.invoke(AspectJAfterThrowingAdvice.java:58)
    at org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:179)
    at org.springframework.aop.interceptor.ExposeInvocationInterceptor.invoke(ExposeInvocationInterceptor.java:92)
    at org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:179)
    at org.springframework.aop.framework.CglibAopProxy$DynamicAdvisedInterceptor.intercept(CglibAopProxy.java:644)
    at com.journaldev.spring.model.Employee$$EnhancerBySpringCGLIB$$3f881964.throwException(<generated>)
    at com.journaldev.spring.main.SpringMain.main(SpringMain.java:17)
~~~

你将会看到通知将会基于切点配置一个个的执行。你应该一个个的配置他们，以免出现混乱。

上面是 Spring AOP 教程的所有内容，我希望你理解了 Spring AOP 的基本概念并能从例子中学习到更多。你可以从下面链接下载本文中的项目代码。

[Download Spring AOP Project](http://www.journaldev.com/?wpdmact=process&did=MjAuaG90bGluaw==)


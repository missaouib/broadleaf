---
layout: post

title: 快速了解RESTEasy
date: 2015-03-10T08:00:00+08:00

categories: [  java ]

tags: [ java ]

description:  主要介绍 RESTEasy 项目的特性、配置及一些常用的注解的用法。

published: true

---

# 什么是 RESTEasy

RESTEasy 是 JBoss 的一个开源项目，提供各种框架帮助你构建 RESTful Web Services 和 RESTful Java 应用程序。它是 JAX-RS 规范的一个完整实现并通过 JCP 认证。作为一个 JBOSS 的项目，它当然能和 JBOSS 应用服务器很好地集成在一起。 但是，它也能在任何运行 JDK5 或以上版本的 Servlet 容器中运行。RESTEasy 还提供一个 RESTEasy JAX-RS 客户端调用框架，能够很方便与 EJB、Seam、Guice、Spring 和 Spring MVC 集成使用，支持在客户端与服务器端自动实现 GZIP 解压缩。

官方网站：<http://resteasy.jboss.org/>

# 特性

直接抄自官网说明：

- Fully certified JAX-RS implementation
- Portable to any app-server/Tomcat that runs on JDK 6 or higher
- Embeddedable server implementation for junit testing
- Client framework that leverages JAX-RS annotations so that you can write HTTP clients easily (JAX-RS only defines server bindings)
- Client "Browser" cache. Supports HTTP 1.1 caching semantics including cache revalidation
- Server in-memory cache. Local response cache. Automatically handles ETag generation and cache revalidation
- Rich set of providers for: XML, JSON, YAML, Fastinfoset, Multipart, XOP, Atom, etc.
- JAXB marshalling into XML, JSON, Jackson, Fastinfoset, and Atom as well as wrappers for maps, arrays, lists, and sets of JAXB Objects.
- GZIP content-encoding. Automatic GZIP compression/decompression suppport in client and server frameworks
- Asynchronous HTTP (Comet) abstractions for JBoss Web, Tomcat 6, and Servlet 3.0
- Asynchronous Job Service.
- Rich interceptor model.
- OAuth2 and Distributed SSO with JBoss AS7
- Digital Signature and encryption support with S/MIME and DOSETA
- EJB, Seam, Guice, Spring, and Spring MVC integration

# 安装和配置

如果你在 Servlet3.0 容器中使用 Resteasy，则需要添加如下依赖：

~~~xml
<dependency>
    <groupId>org.jboss.resteasy</groupId>
    <artifactId>resteasy-servlet-initializer</artifactId>
    <version>3.0.9.Final</version>
</dependency>
~~~

否则，如果你在 Servlet3.0 之前的容器中使用 Resteasy，则 WEB-INF/web.xml 中需要包括如下内容：

~~~xml
<servlet>
    <servlet-name>Resteasy</servlet-name>
    <servlet-class>
        org.jboss.resteasy.plugins.server.servlet.HttpServletDispatcher
    </servlet-class>
    <init-param>
        <param-name>javax.ws.rs.Application</param-name>
        <param-value>com.restfully.shop.services.ShoppingApplication</param-value>
    </init-param>
</servlet>

<servlet-mapping>
    <servlet-name>Resteasy</servlet-name>
    <url-pattern>/*</url-pattern>
</servlet-mapping>
~~~

另外，还可以在 `<context-param>` 节点配置如下参数：

- resteasy.servlet.mapping.prefix
- resteasy.scan
- resteasy.scan.providers
- resteasy.scan.resources
- resteasy.providers
- resteasy.use.builtin.providers
- resteasy.resources
- resteasy.jndi.resources
- javax.ws.rs.Application
- resteasy.media.type.mappings
- resteasy.language.mappings
- resteasy.document.expand.entity.references
- resteasy.document.secure.processing.feature
- resteasy.document.secure.disableDTDs
- resteasy.wider.request.matching
- resteasy.use.container.form.params

以上参数在需要使用的时候查阅官方文档的说明即可。

在 Servlet3.0 之前，你可以将 RESTEasy 配置为 ServletContextListener：

~~~xml
<listener>
  <listener-class>
     org.jboss.resteasy.plugins.server.servlet.ResteasyBootstrap
  </listener-class>
</listener>
~~~

同样，在 Servlet3.0 之前，你可以将 RESTEasy 配置为 Servlet Filter：

~~~xml
<filter>
    <filter-name>Resteasy</filter-name>
    <filter-class>
        org.jboss.resteasy.plugins.server.servlet.FilterDispatcher
    </filter-class>
    <init-param>
        <param-name>javax.ws.rs.Application</param-name>
        <param-value>com.restfully.shop.services.ShoppingApplication</param-value>
    </init-param>
</filter>

<filter-mapping>
    <filter-name>Resteasy</filter-name>
    <url-pattern>/*</url-pattern>
</filter-mapping>
~~~


# 常见的注解

##  @Path and @GET, @POST

一个示例代码：

~~~java
@Path("/library")
public class Library {

   @GET
   @Path("/books")
   public String getBooks() {...}

   @GET
   @Path("/book/{isbn}")
   public String getBook(@PathParam("isbn") String id) {
      // search my database and get a string representation and return it
   }

   @PUT
   @Path("/book/{isbn}")
   public void addBook(@PathParam("isbn") String id, @QueryParam("name") String name) {...}

   @DELETE
   @Path("/book/{id}")
   public void removeBook(@PathParam("id") String id {...}
  
}
~~~

说明：

- 类或方法是存在 @Path 注解或者 HTTP 方法的注解
- 如果方法上没有 HTTP 方法的注解，则称为 JAXRSResourceLocators
- @Path 注解支持正则表达式映射

例如：

~~~java
@Path("/resources")
public class MyResource {

   @GET
   @Path("{var:.*}/stuff")
   public String get() {...}
}
~~~

下面的 GETs 请求会映射到 get() 方法：

~~~
GET /resources/stuff
GET /resources/foo/stuff
GET /resources/on/and/on/stuff
~~~

表达式的格式是：

~~~
"{" variable-name [ ":" regular-expression ] "}"
~~~

当正则表达式不存在时，类似于：

~~~
"([]*)"
~~~

例如， `@Path("/resources/{var}/stuff")`` 将会匹配下面请求：

~~~
GET /resources/foo/stuff
GET /resources/bar/stuff
~~~

而不会匹配：

~~~
GET /resources/a/bunch/of/stuff
~~~

## @PathParam

@PathParam 是一个参数注解，可以将一个 URL 上的参数映射到方法的参数上，它可以映射到方法参数的类型有基本类型、字符串、或者任何有一个字符串作为构造方法参数的 Java 对象、或者一个有字符串作为参数的静态方法 valueOf 的 Java 对象。

例如：

~~~java
@GET
@Path("/book/{isbn}")
public String getBook(@PathParam("isbn") ISBN id) {...}


public class ISBN {
  public ISBN(String str) {...}
}
~~~

或者：

~~~java
public class ISBN {
 public static ISBN valueOf(String isbn) {...}
}
~~~

@Path 注解中可以使用 @PathParam 注解对应的参数，例如：

~~~java
@GET
@Path("/aaa{param:b+}/{many:.*}/stuff")
public String getIt(@PathParam("param") String bs, @PathParam("many") String many) {...}
~~~

对于下面的请求，对应的 param 和 many 变量如下：

|Request | param   | many |
|:----|:---|:----|
|GET /aaabb/some/stuff  | bb | some|
|GET/aaab/a/lot/of/stuff  |  b  | a/lot/of|


另外，@PathParam 注解也可以将 URL 后面的多个参数映射到内置的 javax.ws.rs.core.PathSegment 对象，该对象定义如下：

~~~java
public interface PathSegment {

    /**
     * Get the path segment.
     * <p>
     * @return the path segment
     */
    String getPath();
    /**
     * Get a map of the matrix parameters associated with the path segment
     * @return the map of matrix parameters
     */
    MultivaluedMap<String, String> getMatrixParameters();
    
}
~~~

使用 PathSegment 作为参数类型：

~~~java
@GET
@Path("/book/{id}")
public String getBook(@PathParam("id") PathSegment id) {...}
~~~

则下面请求会映射到 getBook 方法：

~~~
GET http://host.com/library/book;name=EJB 3.0;author=Bill Burke
~~~

## @QueryParam

对于下面的请求：

~~~
GET /books?num=5
~~~

可以使用 @QueryParam 注解进行映射：

~~~java
@GET
public String getBooks(@QueryParam("num") int num) {
...
}
~~~

## @HeaderParam

@HeaderParam 注解用于将 HTTP header 中参数映射到方法的调用上，例如从 http header 中获取 From 变量的值映射到 from 参数上：

~~~java
@GET
public String getBooks(@HeaderParam("From") String from) {
...
}
~~~

同 PathParam 注解一样，方法的参数类型可以是基本类型、字符串、或者任何有一个字符串作为构造方法参数的 Java 对象、或者一个有字符串作为参数的静态方法 valueOf 的 Java 对象，例如，MediaType 对象有个 valueOf() 方法：

~~~java
@PUT
public void put(@HeaderParam("Content-Type") MediaType contentType, ...)
~~~

## @MatrixParam

对于 URL 中的多参数，也可以使用 @MatrixParam 注解，例如对下面的请求，

~~~
GET http://host.com/library/book;name=EJB 3.0;author=Bill Burke
~~~

可以使用下面代码来处理：

~~~java
@GET
public String getBook(@MatrixParam("name") String name, @MatrixParam("author") String author) {...}
~~~

## @CookieParam

获取 Cookie 参数：

~~~java
@GET
public String getBooks(@CookieParam("sessionid") int id) {
...
}

@GET
publi cString getBooks(@CookieParam("sessionid") javax.ws.rs.core.Cookie id) {...}
~~~

同 PathParam 注解一样，方法的参数类型可以是基本类型、字符串、或者任何有一个字符串作为构造方法参数的 Java 对象、或者一个有字符串作为参数的静态方法 valueOf 的 Java 对象。

## @FormParam

将表单中的字段映射到方法调用上，例如，对于下面的表单：

~~~xml
<form method="POST" action="/resources/service">
First name: 
<input type="text" name="firstname">
<br>
Last name: 
<input type="text" name="lastname">
</form>
~~~

通过 post 方法提交，处理该请求的方法为：

~~~java
@Path("/")
public class NameRegistry {

    @Path("/resources/service")
    @POST
    public void addName(@FormParam("firstname") String first, @FormParam("lastname") String last) {...}
}    
~~~


你也可以添加 `application/x-www-form-urlencoded` 来反序列化 URL 中的多参数：

~~~java
@Path("/")
public class NameRegistry {

   @Path("/resources/service")
   @POST
   @Consumes("application/x-www-form-urlencoded")
   public void addName(@FormParam("firstname") String first, MultivaluedMap<String, String> form) {...}
}       
~~~

## @Form

@FormParam 只是将表单字段绑定到方法的参数上，而 @Form 可以将表单绑定到一个对象上。

例如：

~~~java
public static class Person{
   @FormParam("name")
   private String name;

   @Form(prefix = "invoice")
   private Address invoice;

   @Form(prefix = "shipping")
   private Address shipping;
}

public static class Address{

   @FormParam("street")
   private String street;
}

@Path("person")
public static class MyResource{

   @POST
   @Produces(MediaType.TEXT_PLAIN)
   @Consumes(MediaType.APPLICATION_FORM_URLENCODED)
   public String post(@Form Person p){
      return p.toString();
   }
 }
~~~    

客户端可以提交下面的参数：

~~~ 
name=bill
invoice.street=xxx
shipping.street=yyy
~~~

另外，也可以设置 prefix 参数，映射到 map 和 list：

~~~java
public static class Person {
    @Form(prefix="telephoneNumbers") List<TelephoneNumber> telephoneNumbers;
    @Form(prefix="address") Map<String, Address> addresses;
}

public static class TelephoneNumber {
    @FormParam("countryCode") private String countryCode;
    @FormParam("number") private String number;
}

public static class Address {
    @FormParam("street") private String street;
    @FormParam("houseNumber") private String houseNumber;
}

@Path("person")
public static class MyResource {

    @POST
    @Consumes(MediaType.APPLICATION_FORM_URLENCODED)
    public void post (@Form Person p) {}
}    
~~~

然后，提交下面的参数：

~~~java
request.addFormHeader("telephoneNumbers[0].countryCode", "31");
request.addFormHeader("telephoneNumbers[0].number", "0612345678");
request.addFormHeader("telephoneNumbers[1].countryCode", "91");
request.addFormHeader("telephoneNumbers[1].number", "9717738723");
request.addFormHeader("address[INVOICE].street", "Main Street");
request.addFormHeader("address[INVOICE].houseNumber", "2");
request.addFormHeader("address[SHIPPING].street", "Square One");
request.addFormHeader("address[SHIPPING].houseNumber", "13");
~~~

## @DefaultValue

用于设置默认值。

~~~java
@GET
public String getBooks(@QueryParam("num") @DefaultValue("10") int num) {...}
~~~

## @Encoded 和 @Encoding

对 @*Params  注解的参数进行编解码。

## @Context

该注解允许你将以下对象注入到一个实例：

- javax.ws.rs.core.HttpHeaders,
- javax.ws.rs.core.UriInfo
- javax.ws.rs.core.Request
- javax.servlet.HttpServletRequest
- javax.servlet.HttpServletResponse
- javax.servlet.ServletConfig
- javax.servlet.ServletContext
- javax.ws.rs.core.SecurityContext 

## @Produces 和 @Consumes 

@Consumes 注解定义对应的方法处理的  content-type 请求类型。

~~~java
@Consumes("text/*")
@Path("/library")
public class Library {

    @POST
    public String stringBook(String book) {...}

    @Consumes("text/xml")
    @POST
    public String jaxbBook(Book book) {...}
}
~~~

当客户端发送下面请求时，stringBook() 方法会调用：

~~~
 POST /library
 content-type: text/plain

 thsi sis anice book
~~~

当客户端发送下面请求时，jaxbBook() 方法会调用：

~~~
POST /library
content-type: text/xml

<book name="EJB 3.0" author="Bill Burke"/> 
~~~

@Produces 用于映射客户端的请求并匹配客户端请求的 Accept header。

例如，对下面的代码：

~~~java
@Produces("text/*")
@Path("/library")
public class Library {

    @GET
    @Produces("application/json")
    public String getJSON() {...}

    @GET
    public String get() {...}
}    
~~~

则，客户端发送下面请求时，getJSON() 会被调用。

~~~
GET /library
Accept: application/json
~~~

可以修改 web.xml 中的配置，对 Accept 和 Accept-Language 做一些映射。例如：

~~~xml
<web-app>
    <display-name>Archetype Created Web Application</display-name>
    <context-param>
        <param-name>resteasy.media.type.mappings</param-name>
        <param-value>html : text/html, json : application/json, xml : application/xml</param-value>
    </context-param>

   <context-param>
        <param-name>resteasy.language.mappings</param-name>
        <param-value>en : en-US, es : es, fr : fr</param-value>
   </context-param>

    <servlet>
        <servlet-name>Resteasy</servlet-name>
        <servlet-class>org.jboss.resteasy.plugins.server.servlet.HttpServletDispatcher</servlet-class>
    </servlet>

    <servlet-mapping>
        <servlet-name>Resteasy</servlet-name>
        <url-pattern>/*</url-pattern>
    </servlet-mapping>
</web-app>
~~~

如果你调用 /foo/bar.xml.en 的 GET 请求，则等同于发送下面的请求：

~~~
GET /foo/bar
Accept: application/xml
Accept-Language: en-US
~~~

另外，你也可以设置参数映射，通过参数指定 content-type。修改 web.xml：

~~~xml
<web-app>
    <display-name>Archetype Created Web Application</display-name>
    <context-param>
        <param-name>resteasy.media.type.param.mapping</param-name>
        <param-value>someName</param-value>
    </context-param>

    <servlet>
        <servlet-name>Resteasy</servlet-name>
        <servlet-class>org.jboss.resteasy.plugins.server.servlet.HttpServletDispatcher</servlet-class>
    </servlet>

    <servlet-mapping>
        <servlet-name>Resteasy</servlet-name>
        <url-pattern>/*</url-pattern>
    </servlet-mapping>
</web-app>
~~~

然后，可以通过调用 http://service.foo.com/resouce?someName=application/xml 来得到一个 application/xml 的返回结果。

## @GZIP

配置请求输出内容为 Gzip 压缩，例如：

~~~java
@Path("/")
public interface MyProxy {

   @Consumes("application/xml")
   @PUT
   public void put(@GZIP Order order);
}
~~~

# JAX-RS Resource Locators and Sub Resources

前面提到当方法上只有 @Path 注解没有 HTTP 方法的注解时，则该方法为资源定位器，该方法可以返回一个子资源，然后由资源来定义映射路径和对应的 HTTP 方法。

例如：

~~~java
@Path("/")
public class ShoppingStore {

   @Path("/customers/{id}")
   public Customer getCustomer(@PathParam("id") int id) {
      Customer cust = ...; // Find a customer object
      return cust;
   }
}


public class Customer {
    @GET
    public String get() {...}

    @Path("/address")
    public String getAddress() {...}

}

public class CorporateCustomer extends Customer {
   
    @Path("/businessAddress")
    public String getAddress() {...}
}
~~~

访问下面的请求时，会调用 ShoppingStore 类的 getCustomer 方法，然后调用 Customer 类的 get() 方法。

~~~
GET /customer/123
~~~

类似地，下面的请求会返回 Customer 类的 getAddress() 方法的值。

~~~
GET /customer/123/address
~~~

# CORS

在 Application 类中，注册一个单例的提供者类：

~~~java
CorsFilter filter = new CorsFilter();
filter.getAllowedOrigins().add("http://localhost");
~~~

# Content-Range Support

~~~java
@Path("/")
public class Resource {
  @GET
  @Path("file")
  @Produces("text/plain")
  public File getFile()
  {
     return file;
  }
}

Response response = client.target(generateURL("/file")).request()
      .header("Range", "1-4").get();
Assert.assertEquals(response.getStatus(), 206);
Assert.assertEquals(4, response.getLength());
System.out.println("Content-Range: " + response.getHeaderString("Content-Range"));
~~~



---
layout: post

title: Spring Boot之二：特性
date: 2015-03-13T08:00:00+08:00

categories: [ spring ]

tags: [ java,spring boot ]

description: 记录 Spring Boot 的一些特性以及如何对这些特性进行自定义配置。

published: true

---

# 1. SpringApplication

SpringApplication 类是启动 Spring Boot 应用的入口类，你可以创建一个包含 `main()` 方法的类，来运行 `SpringApplication.run` 这个静态方法：

~~~
public static void main(String[] args) {
    SpringApplication.run(MySpringConfiguration.class, args);
}
~~~

运行该类会有如下输出：

~~~
  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/
 :: Spring Boot ::   v1.5.20.RELEASE
~~~

## 1.1 自定义Banner

通过在classpath下添加一个banner.txt或设置banner.location来指定相应的文件可以改变启动过程中打印的banner。如果这个文件有特殊的编码，你可以使用banner.encoding设置它（默认为UTF-8）。

在banner.txt中可以使用如下的变量：

- `${application.version}`：MANIFEST.MF 文件中的应用版本号
- `${application.formatted-version}`
- `${spring-boot.version}`：你正在使用的 Spring Boot 版本号
- `${spring-boot.formatted-version}`

上面这些变量也可以通过 application.properties  来设置，后面再作介绍。

注：如果想以编程的方式产生一个banner，可以使用SpringBootApplication.setBanner(…)方法。使用org.springframework.boot.Banner接口，实现你自己的printBanner()方法。

## 1.2 自定义SpringApplication

如果默认的SpringApplication不符合你的口味，你可以创建一个本地的实例并自定义它。例如，关闭banner你可以这样写：

~~~java
public static void main(String[] args) {
    SpringApplication app = new SpringApplication(MySpringConfiguration.class);
    app.setShowBanner(false);
    app.run(args);
}
~~~

## 1.3 流畅的构建API

如果你需要创建一个分层的ApplicationContext（多个具有父子关系的上下文），或你只是喜欢使用流畅的构建API，你可以使用SpringApplicationBuilder。SpringApplicationBuilder允许你以链式方式调用多个方法，包括可以创建层次结构的parent和child方法。

~~~java
new SpringApplicationBuilder()
    .showBanner(false)
    .sources(Parent.class)
    .child(Application.class)
    .run(args);
~~~

## 1.4 Application事件和监听器

SpringApplication 启动过程会触发一些事件，你可以针对这些事件通过 `SpringApplication.addListeners(…​)` 添加一些监听器:

- ApplicationStartedEvent
- ApplicationEnvironmentPreparedEvent
- ApplicationPreparedEvent
- ApplicationFailedEvent

SpringApplication 会注册一个 shutdown hook 以便在应用退出的时候能够保证 `ApplicationContext` 优雅地关闭，这样能够保证所有 Spring lifecycle 的回调都会被执行，包括 DisposableBean 接口的实现类以及 `@PreDestroy` 注解。

另外，你也可以实现 `org.springframework.boot.ExitCodeGenerator` 接口来定义你自己的退出时候的逻辑。

## 1.5 Web环境

一个`SpringApplication`将尝试为你创建正确类型的`ApplicationContext`。在默认情况下，使用`AnnotationConfigApplicationContext`或`AnnotationConfigEmbeddedWebApplicationContext`取决于你正在开发的是否是web应用。

用于确定一个web环境的算法相当简单（基于是否存在某些类）。如果需要覆盖默认行为，你可以使用`setWebEnvironment(boolean webEnvironment)`。通过调用`setApplicationContextClass(…)`，你可以完全控制ApplicationContext的类型。

注：当JUnit测试里使用SpringApplication时，调用`setWebEnvironment(false)`是可取的。

## 1.6 获取应用参数

如果你想获取应用程序传递给`SpringApplication.run(…​)`的参数，你可以注入一个`org.springframework.boot.ApplicationArguments`bean，ApplicationArguments这个接口提供了方法获取可选的和非可选的String[]类型的参数。

~~~java
import org.springframework.boot.*
import org.springframework.beans.factory.annotation.*
import org.springframework.stereotype.*

@Component
public class MyBean {
    @Autowired
    public MyBean(ApplicationArguments args) {
        boolean debug = args.containsOption("debug");
        List<String> files = args.getNonOptionArgs();
        // if run with "--debug logfile.txt" debug=true, files=["logfile.txt"]
    }
}
~~~

>Spring Boot也会在`Environment`中注入一个`CommandLinePropertySource`，这允许你使用`@Value`注解注入一个应用参数。

## 1.7 使用ApplicationRunner或者CommandLineRunner

~~~java
import org.springframework.boot.*
import org.springframework.stereotype.*

@Component
public class MyBean implements CommandLineRunner {

    public void run(String... args) {
        // Do something...
    }

}
~~~

如果一些CommandLineRunner或者ApplicationRunner beans被定义必须以特定的次序调用，你可以额外实现`org.springframework.core.Ordered`接口或使用`@Order`注解。

## 1.8 程序退出

`SpringApplication`会在JVM上注册一个关闭的hook已确认ApplicationContext是否优雅的关闭。所有的标准的Spring生命周期回调（例如，`DisposableBean`接口，或者`@PreDestroy`注解）都可以使用。

另外，beans可以实现org.springframework.boot.ExitCodeGenerator接口在应用程序结束的时候返回一个错误码。

## 1.9 管理员特性

通过`spring.application.admin.enabled`开启。

# 2. 外化配置

Spring Boot允许你针对不同的环境配置不同的配置参数，你可以使用 properties文件、YAML 文件、环境变量或者命令行参数来修改应用的配置。你可以在代码中使用@Value注解来获取配置参数的值。

Spring Boot使用一个特别的`PropertySource`来按顺序加载配置，加载顺序如下：

- 命令行参数
- 来自`SPRING_APPLICATION_JSON`的属性
-  `java:comp/env` 中的 JNDI 属性
- Java系统环境变量
- 操作系统环境变量
- `RandomValuePropertySource`，随机值，使用 `random.*` 来定义
- jar 包外的 Profile 配置文件，如 application-{profile}.properties 和 YAML 文件
- jar 包内的 Profile 配置文件，如 application-{profile}.properties 和 YAML 文件
- jar 包外的 Application 配置，如 application.properties 和 application.yml 文件
- jar 包内的 Application 配置，如 application.properties 和 application.yml 文件
- 在标有 @Configuration 注解的类标有@PropertySource注解的
- 默认值，使用 `SpringApplication.setDefaultProperties` 设置的

示例代码：

~~~java
import org.springframework.stereotype.*
import org.springframework.beans.factory.annotation.*

@Component
public class MyBean {

    @Value("${name}")
    private String name;

    // ...
}
~~~

你可以在 `application.properties` 中定义一个 name 变量，或者在运行该 jar 时候，指定一个命令行参数（以 `--` 标识），例如：`java -jar app.jar --name="Spring"`

也可以使用`SPRING_APPLICATION_JSON`属性：

~~~bash
$ SPRING_APPLICATION_JSON='{"foo":{"bar":"spam"}}' 
$ java -jar myapp.jar
~~~

在这个例子中，你可以在Spring的`Environment`中通过foo.bar来引用变量。你可以在系统变量中定义`pring.application.json`：

~~~bash
$ java -Dspring.application.json='{"foo":"bar"}' -jar myapp.jar
~~~

或者使用命令行参数：

~~~bash
$ java -jar myapp.jar --spring.application.json='{"foo":"bar"}'
~~~

或者使用JNDI变量：

~~~bash
java:comp/env.application.json
~~~

## 2.1 随机变量

RandomValuePropertySource 类型变量的示例如下：

~~~properties
my.secret=${random.value}
my.number=${random.int}
my.bignumber=${random.long}
my.number.less.than.ten=${random.int(10)}
my.number.in.range=${random.int[1024,65536]}
~~~

## 2.3 应用属性文件

SpringApplication 会在以下路径查找 `application.properties` 并加载该文件：

- `/config` 目录下
- 当前目录
- classpath 中 `/config` 包下
- classpath 根路径下

另外，你也可以通过 `spring.config.location` 来指定 `application.properties` 文件的存放路径，或者通过 `spring.config.name` 指定该文件的名称，例如：

~~~bash
$ java -jar myproject.jar --spring.config.location=classpath:/default.properties,classpath:/override.properties
~~~

或者：

~~~bash
$ java -jar myproject.jar --spring.config.name=myproject
~~~

## 2.4 指定Profile配置文件

即`application-{profile}.properties`配置文件。

## 2.5 占位符

在`application.properties`文件中可以引用`Environment`中已经存在的变量。

~~~properties
app.name=MyApp
app.description=${app.name} is a Spring Boot application
~~~

# 3. Profiles

你可以使用 `@Profile` 注解来标注应用使用的环境

~~~java
@Configuration
@Profile("production")
public class ProductionConfiguration {

    // ...

}
~~~

可以使用 `spring.profiles.active` 变量来定义应用激活的 profile：

~~~properties
spring.profiles.active=dev,hsqldb
~~~

还可以通过  SpringApplication 来设置，调用 `SpringApplication.setAdditionalProfiles(…​)` 代码即可。

# 4. 日志

Spring Boot 使用 Commons Logging 作为内部记录日志，你也可以使用 Java Util Logging, Log4J, Log4J2 和 Logback 来记录日志。

默认情况下，如果你使用了 Starter POMs ，则会使用 Logback 来记录日志。

默认情况，是输出 INFO 类型的日志，你可以通过设置命令行参数`--debug`来设置：

~~~bash
$ java -jar myapp.jar --debug
~~~

如果你的终端支持 ANSI ，则日志支持彩色输出，这个可以通过 `spring.output.ansi.enabled` 设置，可配置的值有：`ALWAYS`、`DETECT`、`NEVER`。

~~~bash
%clr(%d{yyyy-MM-dd HH:mm:ss.SSS}){yellow}
~~~

可选的颜色有：

- blue
- cyan
- faint
- green
- magenta
- red
- yellow

可以通过 `logging.file` 和 `logging.path` 设置日志输出文件名称和路径。

日志级别使用 `logging.level.*=LEVEL` 来定义，例如：

~~~properties
logging.level.org.springframework.web: DEBUG
logging.level.org.hibernate: ERROR
~~~

Spring Boot 通过 `logging.config` 来定义日志的配置文件存放路径，对于不同的日志系统，配置文件的名称不同：

| Logging  | System   Customization |
|:---|:---|
| Logback | logback-spring.xml、logback-spring.groovy、logback.xml 、 logback.groovy |
| Log4j | log4j-spring.properties、log4j-spring.xml、log4j.properties 、log4j.xml |
| Log4j2 | log4j2-spring.xml、log4j2.xml |
| JDK (Java Util Logging) | logging.properties |

对于`logback-spring.xml`这类的配置，建议使用`-spring`变量来加载配置文件。

Environment中可以自定义一些属性：

| Spring Environment  | System Property | Comments|
|:---|:---|:---|
|`logging.exception-conversion-word`|`LOG_EXCEPTION_CONVERSION_WORD`||
|`logging.file`|`LOG_FILE`||
|`logging.path`|`LOG_PATH`||
|`logging.pattern.console`|`CONSOLE_LOG_PATTERN`||
|`logging.pattern.file`|`FILE_LOG_PATTERN`||
|`logging.pattern.level`|`LOG_LEVEL_PATTERN`||
|`PID`|`PID`||

# 5. 开发Web应用

## 5.1 Spring Web MVC框架

一个标准的`@RestController`例子返回JSON数据：

~~~java
@RestController
@RequestMapping(value="/users")
public class MyRestController {

    @RequestMapping(value="/{user}", method=RequestMethod.GET)
    public User getUser(@PathVariable Long user) {
        // ...
    }

    @RequestMapping(value="/{user}/customers", method=RequestMethod.GET)
    List<Customer> getUserCustomers(@PathVariable Long user) {
        // ...
    }

    @RequestMapping(value="/{user}", method=RequestMethod.DELETE)
    public User deleteUser(@PathVariable Long user) {
        // ...
    }

}
~~~

### 5.1.1 Spring MVC自动配置

Spring Boot为Spring MVC提供适用于多数应用的自动配置功能。在Spring默认基础上，自动配置添加了以下特性：

- 引入`ContentNegotiatingViewResolver``和BeanNameViewResolver` beans。
- 对静态资源的支持，包括对WebJars的支持。
- 自动注册`Converter`，`GenericConverter`，`Formatter` beans。
- 对`HttpMessageConverters`的支持。
- 自动注册`MessageCodeResolver`。
- 对静态`index.html`的支持。
- 对自定义`Favicon`的支持。
- 字段使用 `ConfigurableWebBindingInitializer` bean

如果想全面控制Spring MVC，你可以添加自己的`@Configuration`，并使用`@EnableWebMvc`对其注解。如果想保留Spring Boot MVC的特性，并只是添加其他的MVC配置(拦截器，formatters，视图控制器等)，你可以添加自己的`WebMvcConfigurerAdapter`类型的`@Bean`（不使用`@EnableWebMvc`注解）。

### 5.1.2 HttpMessageConverters

Spring MVC使用`HttpMessageConverter`接口转换HTTP请求和响应。合理的缺省值被包含的恰到好处（out of the box），例如对象可以自动转换为JSON（使用Jackson库）或XML（如果Jackson XML扩展可用则使用它，否则使用JAXB）。字符串默认使用`UTF-8`编码。

如果需要添加或自定义转换器，你可以使用Spring Boot的`HttpMessageConverters`类：

~~~java
import org.springframework.boot.autoconfigure.web.HttpMessageConverters;
import org.springframework.context.annotation.*;
import org.springframework.http.converter.*;

@Configuration
public class MyConfiguration {

    @Bean
    public HttpMessageConverters customConverters() {
        HttpMessageConverter<?> additional = ...
        HttpMessageConverter<?> another = ...
        return new HttpMessageConverters(additional, another);
    }
}
~~~

任何在上下文中出现的`HttpMessageConverter` bean将会添加到converters列表，你可以通过这种方式覆盖默认的转换器（converters）。

### 5.1.3 MessageCodesResolver

Spring MVC有一个策略，用于从绑定的errors产生用来渲染错误信息的错误码：MessageCodesResolver。如果设置`spring.mvc.message-codes-resolver.format`属性为`PREFIX_ERROR_CODE`或`POSTFIX_ERROR_CODE`（具体查看`DefaultMessageCodesResolver.Format`枚举值），Spring Boot会为你创建一个MessageCodesResolver。

### 5.1.4 静态内容

默认情况下，Spring Boot从classpath下一个叫`/static`（`/public`，`/resources`或`/META-INF/resources`）的文件夹或从`ServletContext`根目录提供静态内容。这使用了Spring MVC的`ResourceHttpRequestHandler`，所以你可以通过添加自己的`WebMvcConfigurerAdapter`并覆写`addResourceHandlers`方法来改变这个行为（加载静态文件）。

~~~java
@Configuration
class ClientResourcesConfig extends WebMvcConfigurerAdapter {

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        registry.addResourceHandler("/**")
                .addResourceLocations("/WEB-INF/resources/")
                .setCachePeriod(0);
    }
}
~~~

在一个单独的web应用中，容器默认的servlet是开启的，如果Spring决定不处理某些请求，默认的servlet作为一个回退（降级）将从ServletContext根目录加载内容。大多数时候，这不会发生（除非你修改默认的MVC配置），因为Spring总能够通过`DispatcherServlet`处理请求。

此外，上述标准的静态资源位置有个例外情况是Webjars内容。任何在`/webjars/**`路径下的资源都将从jar文件中提供，只要它们以Webjars的格式打包。

注：如果你的应用将被打包成jar，那就不要使用`src/main/webapp`文件夹。尽管该文件夹是一个共同的标准，但它仅在打包成war的情况下起作用，并且如果产生一个jar，多数构建工具都会静悄悄的忽略它。

如果你想刷新静态资源的缓存，你可以定义一个使用HASH结尾的URL，例如：`<link href="/css-2a2d595e6ed9a0b24f027f2b63b134d6.css"/>`。

为此，需要使用以下配置：

~~~properties
spring.resources.chain.strategy.content.enabled=true
spring.resources.chain.strategy.content.paths=/**
~~~

>这里使用了`ResourceUrlEncodingFilter`过滤器，对于Thymeleaf和Velocity，该过滤器已经自动配置。其他的模板引擎，可以通过`ResourceUrlProvider`来定义。

当资源文件自动加载的时候，javascript模块加载器会重命名静态文件。还有一种“固定”的策略来修改文件名称。

~~~properties
spring.resources.chain.strategy.content.enabled=true
spring.resources.chain.strategy.content.paths=/**
spring.resources.chain.strategy.fixed.enabled=true
spring.resources.chain.strategy.fixed.paths=/js/lib/
spring.resources.chain.strategy.fixed.version=v12
~~~

使用了上面的配置之后，当javascript加载`"/js/lib/"`目录下的文件时，将会使用一个固定的版本`"/v12/js/lib/mymodule.js"`，而其他的静态资源仍然使用`<link href="/css-2a2d595e6ed9a0b24f027f2b63b134d6.css"/>`。

更多说明，参考[ResourceProperties](http://github.com-projects-boot/tree/v1.3.2.RELEASE-boot-autoconfigure/src/main/java/orgframework/boot/autoconfigure/web/ResourceProperties.java)，或者阅读该偏[文章](https:/.io/blog/2014/07/24-framework-4-1-handling-static-web-resources)。

### 5.1.5 ConfigurableWebBindingInitializer

Spring MVC使用`WebBindingInitializer`来为一个特定的请求初始化`WebDataBinder`。如果你自带一个了一个`ConfigurableWebBindingInitializer` `@Bean`，Spring Boot会自动配置Spring MVC来使用它。

### 5.1.6 模板引擎

正如REST web服务，你也可以使用Spring MVC提供动态HTML内容。Spring MVC支持各种各样的模板技术，包括Velocity,FreeMarker和JSPs。很多其他的模板引擎也提供它们自己的Spring MVC集成。

Spring Boot为以下的模板引擎提供自动配置支持：

- FreeMarker
- Groovy
- Thymeleaf
- Velocity
- Mustache
 
注：如果可能的话，应该忽略JSPs，因为在内嵌的servlet容器使用它们时存在一些已知的限制。

当你使用这些引擎的任何一种，并采用默认的配置，你的模板将会从`src/main/resources/templates`目录下自动加载。

>注：IntelliJ IDEA根据你运行应用的方式会对classpath进行不同的整理。在IDE里通过main方法运行你的应用跟从Maven或Gradle或打包好的jar中运行相比会导致不同的顺序。这可能导致Spring Boot不能从classpath下成功地找到模板。如果遇到这个问题，你可以在IDE里重新对classpath进行排序，将模块的类和资源放到第一位。或者，你可以配置模块的前缀为`classpath*:/templates/`，这样会查找classpath下的所有模板目录。

### 5.1.7 错误处理

Spring Boot默认提供一个`/error`映射用来以合适的方式处理所有的错误，并且它在servlet容器中注册了一个全局的 错误页面。对于机器客户端（相对于浏览器而言，浏览器偏重于人的行为），它会产生一个具有详细错误，HTTP状态，异常信息的JSON响应。对于浏览器客户端，它会产生一个白色标签样式（whitelabel）的错误视图，该视图将以HTML格式显示同样的数据（可以添加一个解析为erro的View来自定义它）。为了完全替换默认的行为，你可以实现`ErrorController`，并注册一个该类型的bean定义，或简单地添加一个`ErrorAttributes`类型的bean以使用现存的机制，只是替换显示的内容。

如果在某些条件下需要比较多的错误页面，内嵌的servlet容器提供了一个统一的Java DSL（领域特定语言）来自定义错误处理。 示例：

~~~java
@Bean
public EmbeddedServletContainerCustomizer containerCustomizer(){
    return new MyCustomizer();
}

// ...
private static class MyCustomizer implements EmbeddedServletContainerCustomizer {
    @Override
    public void customize(ConfigurableEmbeddedServletContainer container) {
        container.addErrorPages(new ErrorPage(HttpStatus.BAD_REQUEST, "/400"));
        container.addErrorPages(new ErrorPage(HttpStatus.NOT_FOUND, "/404"));
        container.addErrorPages(new ErrorPage(HttpStatus.INTERNAL_SERVER_ERROR, "/500"));
    }
    }
}
~~~

你也可以使用常规的Spring MVC特性来处理错误，比如`@ExceptionHandler`方法和`@ControllerAdvice`。`ErrorController`将会捡起任何没有处理的异常。

N.B. 如果你为一个路径注册一个`ErrorPage`，最终被一个过滤器（Filter）处理（对于一些非Spring web框架，像Jersey和Wicket这很常见），然后过滤器需要显式注册为一个`ERROR`分发器（dispatcher）。

~~~java
@Bean
public FilterRegistrationBean myFilter() {
    FilterRegistrationBean registration = new FilterRegistrationBean();
    registration.setFilter(new MyFilter());
    ...
    registration.setDispatcherTypes(EnumSet.allOf(DispatcherType.class));
    return registration;
}
~~~

注：默认的FilterRegistrationBean没有包含ERROR分发器类型。

### 5.1.8 Spring HATEOAS

如果你正在开发一个使用超媒体的RESTful API，Spring Boot将为Spring HATEOAS提供自动配置，这在多数应用中都工作良好。自动配置替换了对使用`@EnableHypermediaSupport`的需求，并注册一定数量的beans来简化构建基于超媒体的应用，这些beans包括一个`LinkDiscoverer`和配置好的用于将响应正确编排为想要的表示的`ObjectMapper`。ObjectMapper可以根据`spring.jackson.*`属性或一个存在的`Jackson2ObjectMapperBuilder` bean进行自定义。

通过使用`@EnableHypermediaSupport`，你可以控制Spring HATEOAS的配置。注意这会禁用上述的对`ObjectMapper`的自定义。

### 5.1.9 CORS支持

你可以在方法上使用`@CrossOrigin`注解，或者配置一个全局的设置：

~~~java
@Configuration
public class MyConfiguration {

    @Bean
    public WebMvcConfigurer corsConfigurer() {
        return new WebMvcConfigurerAdapter() {
            @Override
            public void addCorsMappings(CorsRegistry registry) {
                registry.addMapping("/api/**");
            }
        };
    }
}
~~~

## 5.2 JAX-RS和Jersey

如果喜欢JAX-RS为REST端点提供的编程模型，你可以使用可用的实现替代Spring MVC。如果在你的应用上下文中将Jersey 1.x和Apache Celtix的Servlet或Filter注册为一个@Bean，那它们工作的相当好。Jersey 2.x有一些原生的Spring支持，所以我们会在Spring Boot为它提供自动配置支持，连同一个启动器（starter）。

想要开始使用Jersey 2.x只需要加入spring-boot-starter-jersey依赖，然后你需要一个ResourceConfig类型的@Bean，用于注册所有的端点（endpoints）。

~~~java
@Component
public class JerseyConfig extends ResourceConfig {
    public JerseyConfig() {
        register(Endpoint.class);
    }
}
~~~

所有注册的端点都应该被@Components和HTTP资源annotations（比如@GET）注解。

~~~java
@Component
@Path("/hello")
public class Endpoint {
    @GET
    public String message() {
        return "Hello";
    }
}
~~~

由于Endpoint是一个Spring组件（@Component），所以它的生命周期受Spring管理，并且你可以使用@Autowired添加依赖及使用@Value注入外部配置。Jersey servlet将被注册，并默认映射到/*。你可以将@ApplicationPath添加到ResourceConfig来改变该映射。

默认情况下，Jersey将在一个ServletRegistrationBean类型的@Bean中被设置成名称为jerseyServletRegistration的Servlet。通过创建自己的相同名称的bean，你可以禁止或覆盖这个bean。你也可以通过设置`spring.jersey.type=filter`来使用一个Filter代替Servlet（在这种情况下，被覆盖或替换的@Bean是jerseyFilterRegistration）。该servlet有@Order属性，你可以通过`spring.jersey.filter.order`进行设置。不管是Servlet还是Filter注册都可以使用`spring.jersey.init.*`定义一个属性集合作为初始化参数传递过去。

这里有一个[Jersey](http://github.com-projects-boot/tree/master-boot-samples-boot-sample-jersey)示例，你可以查看如何设置相关事项。

## 5.3 内嵌的容器支持

### 5.3.1 Servlets和Filters

当使用内嵌的servlet容器时，你可以直接将servlet和filter注册为Spring的beans。在配置期间，如果你想引用来自application.properties的值，这是非常方便的。默认情况下，如果上下文只包含单一的Servlet，那它将被映射到根路径（/）。在多Servlet beans的情况下，bean的名称将被用作路径的前缀。过滤器会被映射到/*。

如果基于约定（convention-based）的映射不够灵活，你可以使用ServletRegistrationBean和FilterRegistrationBean类实现完全的控制。如果你的bean实现了ServletContextInitializer接口，也可以直接注册它们。

### EmbeddedWebApplicationContext

Spring Boot底层使用了一个新的ApplicationContext类型，用于对内嵌servlet容器的支持。EmbeddedWebApplicationContext是一个特殊类型的WebApplicationContext，它通过搜索一个单一的EmbeddedServletContainerFactory bean来启动自己。通常，TomcatEmbeddedServletContainerFactory，JettyEmbeddedServletContainerFactory或UndertowEmbeddedServletContainerFactory将被自动配置。

注：你通常不需要知道这些实现类。大多数应用将被自动配置，并根据你的行为创建合适的ApplicationContext和EmbeddedServletContainerFactory。

### 自定义内嵌servlet容器

常见的Servlet容器设置可以通过Spring Environment属性进行配置。通常，你会把这些属性定义到application.properties文件中。 常见的服务器设置包括：

- server.port - 进来的HTTP请求的监听端口号
- server.address - 绑定的接口地址
- server.sessionTimeout - session超时时间

具体参考[ServerProperties](http://github.com-projects-boot/tree/master-boot-autoconfigure/src/main/java/orgframework/boot/autoconfigure/web/ServerProperties.java)。

#### 编程方式的自定义

如果需要以编程的方式配置内嵌的servlet容器，你可以注册一个实现EmbeddedServletContainerCustomizer接口的Spring bean。EmbeddedServletContainerCustomizer提供对ConfigurableEmbeddedServletContainer的访问，ConfigurableEmbeddedServletContainer包含很多自定义的setter方法。

~~~java
import org.springframework.boot.context.embedded.*;
import org.springframework.stereotype.Component;

@Component
public class CustomizationBean implements EmbeddedServletContainerCustomizer {
    @Override
    public void customize(ConfigurableEmbeddedServletContainer container) {
        container.setPort(9000);
    }
}
~~~

#### 直接自定义ConfigurableEmbeddedServletContainer

如果上面的自定义手法过于受限，你可以自己注册TomcatEmbeddedServletContainerFactory，JettyEmbeddedServletContainerFactory或UndertowEmbeddedServletContainerFactory。

~~~java
@Bean
public EmbeddedServletContainerFactory servletContainer() {
    TomcatEmbeddedServletContainerFactory factory = new TomcatEmbeddedServletContainerFactory();
    factory.setPort(9000);
    factory.setSessionTimeout(10, TimeUnit.MINUTES);
    factory.addErrorPages(new ErrorPage(HttpStatus.NOT_FOUND, "/notfound.html");
    return factory;
}
~~~

很多可选的配置都提供了setter方法，也提供了一些受保护的钩子方法以满足你的某些特殊需求。具体参考相关文档。

### JSP的限制

在内嵌的servlet容器中运行一个Spring Boot应用时（并打包成一个可执行的存档archive），容器对JSP的支持有一些限制。

- tomcat只支持war的打包方式，不支持可执行的jar。
- 内嵌的Jetty目前不支持JSPs。
- Undertow不支持JSPs。

这里有个[JSP示例](http://github.com-projects-boot/tree/master-boot-samples-boot-sample-web-jsp)，你可以查看如何设置相关事项。

# 参考文章

- [Spring Boot Reference Guide](http://docs.spring.io-boot/docs/1.2.2.RELEASE/reference/htmlsingle)

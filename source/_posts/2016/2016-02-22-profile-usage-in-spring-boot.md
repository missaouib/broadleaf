---
layout: post

title: Spring Boot Profile使用

category: spring

tags: [spring boot,spring,java]

description:  本文主要了解Spring Boot 1.3.0新添加的spring-boot-devtools模块的使用，该模块主要是为了提高开发者开发Spring Boot应用的用户体验。

published: true

---

Spring Boot使用`@Profile`注解可以实现不同环境下配置参数的切换，任何`@Component`或`@Configuration`注解的类都可以使用`@Profile`注解。

例如：

~~~java
@Configuration
@Profile("production")
public class ProductionConfiguration {
    // ...
}
~~~

通常，一个项目中可能会有多个profile场景，例如下面为test场景：

~~~java
@Configuration
@Profile("test")
public class TestConfiguration {
    // ...
}
~~~

在存在多个profile情况下，你可以使用`spring.profiles.active`来设置哪些profile被激活。`spring.profiles.include`属性用来设置无条件的激活哪些profile。

例如，你可以在`application.properties`中设置：

~~~
spring.profiles.active=dev,hsqldb
~~~

或者在`application.yaml`中设置：

~~~
spring.profiles.active:dev,hsqldb
~~~

`spring.profiles.active`属性可以通过命令行参数或者资源文件来设置，其查找顺序，请参考[Spring Boot特性](http://blog.javachen.com/2015/03/13/some-spring-boot-features.html)。

# 自定义Profile注解

`@Profile`注解需要接受一个字符串，作为场景名。这样每个地方都需要记住这个字符串。Spring的`@Profile`注解支持定义在其他注解之上，以创建自定义场景注解。

~~~java
@Target({ElementType.TYPE, ElementType.METHOD})
@Retention(RetentionPolicy.RUNTIME)
@Profile("dev")
public @interface Dev {
}
~~~

这样就创建了一个`@Dev`注解，该注解可以标识bean使用于`@Dev`这个场景。后续就不再需要使用`@Profile("dev")`的方式。这样即可以简化代码，同时可以利用IDE的自动补全:)

# 多个Profile例子

下面是一个例子：

~~~java
package com.javachen.example.service;

public interface MessageService {
  String getMessage();
}
~~~

对于MessageService接口，我们可以有生产和测试两种实现：

~~~java
package com.javachen.example.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

@Component
@Profile({ "dev" })
public class HelloWorldService implements MessageService{

  @Value("${name:World}")
  private String name;

  public String getMessage() {
    return "Hello " + this.name;
  }

}
~~~

~~~java
package com.javachen.example.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

@Component
@Profile({ "prod" })
public class GenericService implements MessageService {

  @Value("${hello:Hello}")
  private String hello;

  @Value("${name:World}")
  private String name;

  @Override
  public String getMessage() {
    return this.hello + " " + this.name;
  }

}
~~~

Application类为：

~~~java
@SpringBootApplication
public class Application implements CommandLineRunner {
  private static final Logger logger = LoggerFactory.getLogger(Application.class);

  @Autowired
  private MessageService messageService;

  @Override
  public void run(String... args) {
    logger.info(this.messageService.getMessage());
    if (args.length > 0 && args[0].equals("exitcode")) {
      throw new ExitException();
    }
  }

  public static void main(String[] args) throws Exception {
    SpringApplication.run(Application.class, args);
  }
}
~~~

实际使用中，使用哪个profile由`spring.profiles.active`控制，你在`resources/application.properties`中定义`spring.profiles.active=XXX`，或者通过`-Dspring.profiles.active=XXX`。`XXX`可以是`dev`或者`prod`或者`dev,prod`。`需要注意的是`：本例中是将`@Profile`用在Service类上，一个Service接口不能同时存在超过两个实现类，故本例中不能同时使用dev和prod。

通过不同的profile，可以有对应的资源文件`application-{profile}.properties`。例如，`application-dev.properties`内容如下：

~~~properties
name=JavaChen-dev
~~~

`application-prod.properties`内容如下：

~~~properties
name=JavaChen-prod
~~~

接下来进行测试。`spring.profiles.active=dev`时，运行Application类，查看日志输出。

~~~
2016-02-22 15:45:18,470 [main] INFO  com.javachen.example.Application - Hello JavaChen-dev
~~~

`spring.profiles.active=prod`时，运行Application类，查看日志输出。

~~~
2016-02-22 15:47:21,270 [main] INFO  com.javachen.example.Application - Hello JavaChen-prod
~~~

# logback配置多Profile

在resources目录下添加logback-spring.xml，并分别对dev和prod进行配置：

~~~xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <!--<include resource="orgframework/boot/logging/logback/base.xml" />-->

    <springProfile name="dev">
        <logger name="com.javachen.example" level="TRACE" />
        <appender name="LOGFILE" class="ch.qos.logback.core.ConsoleAppender">
            <encoder>
                <pattern>%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n</pattern>
            </encoder>
        </appender>
    <Profile>

    <springProfile name="prod">
        <appender name="LOGFILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
            <File>log/server.log</File>
            <rollingPolicy
                    class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
                <FileNamePattern>log/server_%d{yyyy-MM-dd}.log.zip</FileNamePattern>
            </rollingPolicy>
            <layout class="ch.qos.logback.classic.PatternLayout">
                <pattern>%date [%thread] %-5level %logger{80} - %msg%n</pattern>
            </layout>
        </appender>
    <Profile>

    <root level="info">
        <appender-ref ref="LOGFILE" />
    </root>

    <logger name="com.javachen.example" level="DEBUG" />
</configuration>
~~~

这样，就可以做到不同profile场景下的日志输出不一样。

# maven中的场景配置

使用maven的resource filter可以实现多场景切换。

~~~xml
<profiles>
    <profile>
        <id>prod</id>
        <activation>
            <activeByDefault>true</activeByDefault>
        </activation>
        <properties>
            <build.profile.id>prod</build.profile.id>
        </properties>
    </profile>
    <profile>
        <id>dev</id>
        <properties>
            <build.profile.id>dev</build.profile.id>
        </properties>
    </profile>
</profiles>

<build>
        <filters>
            <filter>application-${build.profile.id}.properties</filter>
        </filters>

        <resources>
            <resource>
                <filtering>true</filtering>
                <directory>src/main/resources</directory>
            </resource>
        </resources>
</build> 
~~~

这样在maven编译时，可以通过`-P`参数指定maven profile即可。

# 总结

使用Spring Boot的Profile注解可以实现多场景下的配置切换，方便开发中进行测试和部署生产环境。

本文中相关代码在[github](https://github.com/javachen-examples/tree/master-boot-boot-example)上面。

# 参考文章

- [Spring 3.1 M1: Introducing @Profile](https:/.io/blog/2011/02/14-3-1-m1-introducing-profile/)
- [spring boot profile试用](https://coolex.info/blog/508.html)

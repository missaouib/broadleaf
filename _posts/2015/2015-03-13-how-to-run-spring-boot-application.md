---
layout: post

title: Spring Boot之一：如何运行项目

category: spring

tags: [ java,spring boot ]

description: Spring Boot 是 Spring 产品中一个新的子项目，致力于简便快捷地搭建基于 Spring 的独立可运行的应用。大多数的 Spring Boot  应用只需要非常少的 Spring 配置。

published: true

---

# 介绍

Spring Boot 是 Spring 产品中一个新的子项目，致力于简便快捷地搭建基于 Spring 的独立可运行的应用。大多数的 Spring Boot  应用只需要非常少的 Spring 配置。

你能够使用 Spring Boot  创建 Java 应用并通过 `java -jar` 来运行或者创建传统的通过 war 来部署的应用。Spring Boot 也提供了一个命令行工具来运行 spring 脚本。

Spring Boot 的目标是：

- 快速开发基于 Spring 的应用
- 开箱即用的微服务
- 提供一些大型项目常用的非功能性特性，例如：嵌入式服务、安全、监控、健康检查、外部配置
- 不用生成代码，没有 xml 配置

# 系统要求

Spring Boot 的最新发布版本为 `1.3.2.RELEASE`，其需要 Java 7 和 Spring 4.1.3 或以上版本才能运行。当然，你也可以添加一些配置使其能够使用 Java 6。虽然，你可以使用 Java 6 或7 来运行 Spring Boot，但是，在可能的情况下，更建议你使用 Java 8。编译 Spring Boot 需要 Maven 3.2+ 或者 Gradle 1.12+。

Servlet 容易要求：

|Name |Servlet Version |Java Version|
|:---|:---|:----|
| Tomcat 8 | 3.1 | Java 7+ |
| Tomcat 7 | 3.0 |Java 6+ |
| Jetty 9 | 3.1 | Java 7+ |
| Jetty 8 |  3.0 |  Java 6+ |
| Undertow 1.1 | 3.1 | Java 7+ |

你也可以在兼容 `Servlet 3.0+` 的容器中部署 Spring Boot 应用。

# 安装

首先，需要安装 Java 并确认版本是否满足要求。

## Maven安装

Spring Boot 可以使用 Maven3.2 以上版本进行编译。使用压缩包解压安装 Maven 或者通过命令安装，例如，在 Mac 上安装：

~~~bash
$ brew install maven
~~~

要创建一个 Spring Boot 的项目，你需要创建一个 Maven 的 POM 文件并继承 `spring-boot-starter-parent` 项目，然后添加一些 Spring Boot 子项目的依赖，你也可以使用 `spring-boot-maven-plugin` 插件来创建可执行的 jar 包。

使用maven创建一个工程：

~~~bash
$ mvn archetype:generate -DgroupId=com.javachen -DartifactId=spring-boot-hello -DarchetypeArtifactId=maven-archetype-quickstart -DinteractiveModel=false
~~~

删除掉创建的App类和单元测试。

然后修改 pom.xml 为如下：

~~~xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.javachen</groupId>
    <artifactId>spring-boot-hello</artifactId>
    <version>1.0-SNAPSHOT</version>

    <!-- Inherit defaults from Spring Boot -->
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>1.5.20.RELEASE</version>
    </parent>

    <!-- Add typical dependencies for a web application -->
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
    </dependencies>

    <!-- Package as an executable jar -->
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
~~~

如果你不想继承 spring-boot-starter-parent 父项目，你也可以使用依赖管理来引入对 Spring Boot 的依赖。

~~~xml
<dependencyManagement>
     <dependencies>
        <dependency>
            <!-- Import dependency management from Spring Boot -->
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-dependencies</artifactId>
            <version>1.5.20.RELEASE</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>
~~~

还可以通过下面方式修改 Maven 使用的 Java 版本：

~~~xml
<properties>
    <java.version>1.7</java.version>
</properties>
~~~

编译代码：

~~~bash
$ mvn compile 
~~~

## Gradle 安装

Spring Boot兼容Gradle 1.12或更高版本。如果没有安装Gradle，你可以参考 [www.gradle.org] 上的指南。

在上面通过maven创建的目录spring-boot-example中，新建一个 `build.gradle` 文件如下：

~~~groovy
buildscript {
    repositories {
        jcenter()
        maven { url "http://repo.spring.io/snapshot" }
        maven { url "http://repo.spring.io/milestone" }
    }
    dependencies {
        classpath("org.springframework.boot:spring-boot-gradle-plugin:1.3.2.RELEASE")
    }
}

apply plugin: 'java'
apply plugin: 'spring-boot'

jar {
    baseName = 'spring-boot-example'
    version =  '0.0.1-SNAPSHOT'
}

repositories {
    jcenter()
    maven { url "http://repo.spring.io/snapshot" }
    maven { url "http://repo.spring.io/milestone" }
}

dependencies {
    compile("org.springframework.boot:spring-boot-starter-web")
    testCompile("org.springframework.boot:spring-boot-starter-test")
}
~~~

编译代码：

~~~bash
$ gradle build
~~~

# Spring Boot CLI 使用方法

## 安装 Spring Boot CLI

你可以手动安装：[https://github.com/spring-projects/spring-boot/releases]

或者使用 GVM 安装：

~~~bash
$ gvm install springboot
$ spring --version
Spring Boot v1.5.20.RELEASE
~~~

如果你使用 Mac，则可以通过 [Homebrew](http://brew.sh/) 或者 [MacPorts](http://www.macports.org/) 安装：

~~~bash
$ brew tap pivotal/tap
$ brew install springboot
~~~

~~~bash
$ sudo port install spring-boot-cli
~~~

spring 命令用法：

~~~bash
$ spring
usage: spring [--help] [--version]
       <command> [<args>]

Available commands are:

  run [options] <files> [--] [args]
    Run a spring groovy script

  ... more command help is shown here
~~~

使用 你可以很快创建一个简单的 web 应用来测试是否安装成功。创建 hello.groovy 文件，内容如下：

~~~groovy
@RestController
class ThisWillActuallyRun {

    @RequestMapping("/")
    String home() {
        "Hello World!"
    }
}
~~~

然后，运行下面命令：

~~~bash
$ spring run hello.groovy
~~~

使用浏览器打开 <http://localhost:8080/> 你会看到下面的输出：

~~~bash
Hello World!
~~~

你还可以传递一些命令行的参数，使用 `--` 分隔命令行参数，下面命令修改服务启动端口为 9000：

~~~bash
$ spring run hello.groovy -- --server.port=9000
~~~

设置 JVM 参数之后，在运行：

~~~bash
$ JAVA_OPTS=-Xmx1024m 
$ spring run hello.groovy
~~~

# 部署 Spring Boot 应用

## Maven 项目

如果你使用 Maven 编译项目，则你可以通过下面命令查看项目依赖：

~~~bash
$ mvn dependency:tree
~~~

在src/main/java/com/javachen/下面添加HelloWorld的Controller：

~~~java
package com.javachen.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

import java.util.HashMap;
import java.util.Map;

@Controller
public class HelloController {

    @ResponseBody
    @RequestMapping("/hello")
    public Map<String, Object> showHelloWork() {
        Map<String, Object> map = new HashMap<String, Object>();
        map.put("msg", "Hello World ！");
        return map;
    }
}
~~~

在src/main/java/com/javachen下面添加启动类：

~~~java
package com.javachen;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * spring boot启动类
 */
@SpringBootApplication
public class App {
    public static void main( String[] args ) {
        SpringApplication.run(App.class, args);
    }
}
~~~

如果你的 pom.xml 使用了 spring-boot-starter-parent，则我们可以运行 `mvn spring-boot:run` 命令启动应用：

~~~bash
$ mvn spring-boot:run
~~~

然后，使用浏览器打开 http://localhost:8080/ 你会看到下面的输出：

~~~bash
{"msg":"Hello World ！"}
~~~

点击ctrl-c，可以关闭应用程序。

添加`-Ddebug`参数可以查看加载了哪些配置类：

~~~bash
$ mvn spring-boot:run -Ddebug
…
=========================
AUTO-CONFIGURATION REPORT
=========================


Positive matches:
-----------------

   DispatcherServletAutoConfiguration
      - @ConditionalOnClass classes found: org.springframework.web.servlet.DispatcherServlet (OnClassCondition)
      - found web application StandardServletEnvironment (OnWebApplicationCondition)

...
~~~

加载了太多的配置类，会影响程序性能，故可以自定义导入需要的配置类：

~~~java
@Configuration
@Import({
        DispatcherServletAutoConfiguration.class,
        EmbeddedServletContainerAutoConfiguration.class,
        ErrorMvcAutoConfiguration.class,
        HttpEncodingAutoConfiguration.class,
        HttpMessageConvertersAutoConfiguration.class,
        JacksonAutoConfiguration.class,
        JmxAutoConfiguration.class,
        MultipartAutoConfiguration.class,
        ServerPropertiesAutoConfiguration.class,
        PropertyPlaceholderAutoConfiguration.class,
        ThymeleafAutoConfiguration.class,
        WebMvcAutoConfiguration.class,
        WebSocketAutoConfiguration.class,
})
public class App {
}
~~~

如果你的 pom.xml 中添加了 `spring-boot-maven-plugin` 插件，你可以运行 `mvn package` 命令在 target 目录生成一个可执行的 jar 文件：

~~~bash
➜  mvn package
[INFO] Scanning for projects...
[INFO]
[INFO] ------------------------------------------------------------------------
[INFO] Building spring-boot-hello 1.0-SNAPSHOT
[INFO] ------------------------------------------------------------------------
[INFO]
[INFO] --- maven-resources-plugin:2.7:resources (default-resources) @ spring-boot-hello ---
[INFO] Using 'UTF-8' encoding to copy filtered resources.
[INFO] skip non existing resourceDirectory /Users/june/workspace/project/spring-boot-hello/src/main/resources
[INFO] skip non existing resourceDirectory /Users/june/workspace/project/spring-boot-hello/src/main/resources
[INFO]
[INFO] --- maven-compiler-plugin:3.1:compile (default-compile) @ spring-boot-hello ---
[INFO] Nothing to compile - all classes are up to date
[INFO]
[INFO] --- maven-resources-plugin:2.7:testResources (default-testResources) @ spring-boot-hello ---
[INFO] Using 'UTF-8' encoding to copy filtered resources.
[INFO] skip non existing resourceDirectory /Users/june/workspace/project/spring-boot-hello/src/test/resources
[INFO]
[INFO] --- maven-compiler-plugin:3.1:testCompile (default-testCompile) @ spring-boot-hello ---
[INFO] No sources to compile
[INFO]
[INFO] --- maven-surefire-plugin:2.18.1:test (default-test) @ spring-boot-hello ---
[INFO]
[INFO] --- maven-jar-plugin:2.6:jar (default-jar) @ spring-boot-hello ---
[INFO] Building jar: /Users/june/workspace/project/spring-boot-hello/target/spring-boot-hello-1.0-SNAPSHOT.jar
[INFO]
[INFO] --- spring-boot-maven-plugin:1.5.20.RELEASE:repackage (default) @ spring-boot-hello ---
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time: 3.396s
[INFO] Finished at: Sat Apr 06 23:45:53 CST 2019
[INFO] Final Memory: 16M/226M
[INFO] ------------------------------------------------------------------------
~~~

然后，你可以运行项目命令执行生成的 jar 文件：

~~~bash
$ java -jar target/spring-boot-hello-1.0-SNAPSHOT.jar
~~~

如果 Maven 运行过程出现内存溢出，则可以添加下面参数：

~~~bash
$ export JAVA_OPTS=-Xmx1024m -XX:MaxPermSize=128M -Djava.security.egd=file:/dev/./urandom
~~~

## Gradle 项目

如果你使用 Gradle 编译项目，则可以在项目根路径直接运行下面命令来运行应用：

~~~bash
$ export JAVA_OPTS=-Xmx1024m -XX:MaxPermSize=128M -Djava.security.egd=file:/dev/./urandom

$ gradle bootRun
~~~

然后，通过浏览器访问 http://localhost:8080/ 。

也可以先 build 生成一个 jar 文件，然后执行该 jar 文件：

~~~bash
$ gradle build && java -jar build/libs/spring-boot-hello-1.0-SNAPSHOT.jar
~~~

你也可以启动远程调试：

~~~bash
$ gradle build 

$ java -Xdebug -Xrunjdwp:server=y,transport=dt_socket,address=8000,suspend=n \
       -jar build/libs/spring-boot-hello-1.0-SNAPSHOT.jar
~~~

# 参考文章

- [Spring Boot Reference Guide](http://docs.spring.io/spring-boot/docs/1.5.20.RELEASE/reference/htmlsingle)

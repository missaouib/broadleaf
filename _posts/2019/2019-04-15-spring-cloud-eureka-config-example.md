---
layout: post

title: Spring Cloud之Eureka配置示例

category: spring

tags: [spring cloud,eureka]

description:  Eureka是Netflix开源的服务发现组件，本身是一个基于REST的服务，包含Server和Client两部分，Spring Cloud将它集成在子项目Spring Cloud Netflix中，主要负责完成微服务架构中的服务治理功能。

---

Eureka是Netflix开源的服务发现组件，本身是一个基于REST的服务，包含Server和Client两部分，Spring Cloud将它集成在子项目Spring Cloud Netflix中，主要负责完成微服务架构中的服务治理功能。

在这里创建一个spring-cloud-examples的maven工程，然后再创建Spring Cloud相关的子模块。

版本说明：

- Spring Cloud：Greenwich.RELEASE
-  Spring Boot：2.1.3.RELEASE

# 创建服务注册中心

1、使用maven创建spring-cloud-examples工程，其为父模块，pom.xml文件如下：

```xml
    <?xml version="1.0" encoding="UTF-8"?>
    <project xmlns="http://maven.apache.org/POM/4.0.0"
             xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
        <modelVersion>4.0.0</modelVersion>

        <parent>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-parent</artifactId>
            <version>2.1.3.RELEASE</version>
        </parent>

        <groupId>com.javachen.springcloud</groupId>
        <artifactId>spring-cloud-examples</artifactId>
        <version>1.0-SNAPSHOT</version>
        <packaging>pom</packaging>

        <properties>
            <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
            <project.reporting.outputEncoding>UTF-8</project.reporting.outputEncoding>
            <java.version>1.8</java.version>
            <spring-cloud.version>Greenwich.RELEASE</spring-cloud.version>
        </properties>

        <dependencyManagement>
            <dependencies>
                <dependency>
                    <groupId>org.springframework.cloud</groupId>
                    <artifactId>spring-cloud-dependencies</artifactId>
                    <version>${spring-cloud.version}</version>
                    <type>pom</type>
                    <scope>import</scope>
                </dependency>
            </dependencies>
        </dependencyManagement>

        <repositories>
            <repository>
                <id>spring-milestones</id>
                <name>Spring Milestones</name>
                <url>https://repo.spring.io/milestone</url>
                <snapshots>
                    <enabled>false</enabled>
                </snapshots>
            </repository>
            <repository>
                <id>repository.springframework.maven.release</id>
                <name>Spring Framework Maven Release Repository</name>
                <url>http://maven.springframework.org/milestone/</url>
            </repository>
            <repository>
                <id>spring-milestone</id>
                <name>Spring Maven MILESTONE Repository</name>
                <url>http://repo.spring.io/libs-milestone</url>
            </repository>
            <repository>
                <id>spring-release</id>
                <name>Spring Maven RELEASE Repository</name>
                <url>http://repo.spring.io/libs-release</url>
            </repository>
        </repositories>
    </project>
```

说明：需要设置Spring的maven仓库才能下载到Spring Cloud的相关依赖。

2、创建一个子程spring-cloud-eureka-server作为服务注册中心，pom.xml如下：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <parent>
        <groupId>com.javachen.springcloud</groupId>
        <artifactId>spring-cloud-examples</artifactId>
        <version>1.0-SNAPSHOT</version>
    </parent>
    <modelVersion>4.0.0</modelVersion>
    <artifactId>spring-cloud-eureka-server</artifactId>
    <packaging>jar</packaging>

    <dependencies>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-netflix-eureka-server</artifactId>
        </dependency>
    </dependencies>
</project>
```

在这里，引入了eureka的相关依赖。

3、启动一个服务注册中心，只需要一个注解@EnableEurekaServer，这个注解需要在springboot工程的启动application类上加：

```java
@SpringBootApplication
@EnableEurekaServer
public class EurekaServerApplication {
    public static void main(String[] args) {
        SpringApplication.run( EurekaServerApplication.class, args );
    }
}
```

4、在resources目录下创建appication.yml文件如下：

```yml
server:
  port: 8761

eureka:
  instance:
    hostname: localhost
  client:
    registerWithEureka: false
    fetchRegistry: false
    serviceUrl:
      defaultZone: http://${eureka.instance.hostname}:${server.port}/eureka/

spring:
  application:
    name: eureka-server
```

在默认情况下erureka server也是一个eureka client ，必须要指定一个 server。通过`eureka.client.registerWithEureka：false`和`fetchRegistry：false`来表明自己是一个eureka server。

5、启动工程，打开浏览器访问： http://localhost:8761，这时候是 `No application available` 没有服务被发现 

# 创建一个服务提供者

1、创建一个子工程spring-cloud-eureka-client作为服务提供者，其pom如下：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <parent>
        <groupId>com.javachen.springcloud</groupId>
        <artifactId>spring-cloud-examples</artifactId>
        <version>1.0-SNAPSHOT</version>
    </parent>
    <modelVersion>4.0.0</modelVersion>
    <artifactId>spring-cloud-eureka-client</artifactId>

    <dependencies>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
    </dependencies>
</project>
```

2、通过注解`@EnableEurekaClient`表明自己是一个eureka client。

```java
/**
 * 注意：早期的版本（Dalston及更早版本）还需在启动类上添加注解@EnableDiscoveryClient 或@EnableEurekaClient ，从Edgware开始，该注解可省略。
 */
@SpringBootApplication
public class EurekaClientApplication {
    public static void main(String[] args) {
        SpringApplication.run( EurekaClientApplication.class, args );
    }
}
```

注意：

    早期的版本（Dalston及更早版本）还需在启动类上添加注解`@EnableDiscoveryClient `或`@EnableEurekaClient`，从Edgware开始，该注解可省略。

3、在resources目录下创建application.yml配置文件如下：

```yml
server:
  port: 8701

spring:
  application:
    name: eureka-client

eureka:
  client:
    serviceUrl:
      defaultZone: http://localhost:8761/eureka/
```

需要指明`spring.application.name`，因为服务与服务之间相互调用一般都是根据这个name。

4、启动工程，打开浏览器访问： http://localhost:8761。

这时候可以看到 EUREKA-CLIENT 被注册上去了，其状态为`UP (1) - 172.20.10.2:eureka-client:8701`，可以设置配置文件影藏IP信息，只需要修改application.yml配置文件如下：

```yml
eureka:
  client:
    serviceUrl:
      defaultZone: http://localhost:8761/eureka/
  instance:
    instance-id: eureka-client-8701 #自定义服务名称信息
```

这时候点击`172.20.10.2:eureka-client:8701`链接，会访问 http://172.20.10.2:8701/actuator/info 地址，并报错：

```
Whitelabel Error Page
This application has no explicit mapping for /error, so you are seeing this as a fallback.

Mon Apr 15 11:54:07 CST 2019
There was an unexpected error (type=Not Found, status=404).
No message available
```

这时候需要引入 spring-boot-starter-actuator 依赖：

```xml
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>
```

并在配置文件设置info信息：

```yml
info:
  app.name: spring-cloud-eureka-client
  company.name: www.javachen.com
  build.artifactId: $project.artifactId$
  build.version: $project.version$
```

该配置文件中$$中间的需要maven在编译时候替换掉，需要设置maven插件，修改pom.xml，添加：

```xml
    <build>
        <finalName>spring-cloud-eureka-clien</finalName>
        <resources>
            <resource>
                <directory>src/main/resources</directory>
                <filtering>true</filtering>
            </resource>
        </resources>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-resources-plugin</artifactId>
                <configuration>
                    <delimiters>
                        <delimit>$</delimit>
                    </delimiters>
                </configuration>
            </plugin>
        </plugins>
    </build>
```

重新clean、compile项目，再重启应用，点击 eureka-client-8701 访问 <http://172.20.10.2:8701/actuator/info>，可以看到：

```json
{"app":{"name":"spring-cloud-eureka-client"},"company":{"name":"www.javachen.com"},"build":{"artifactId":"spring-cloud-eureka-client","version":"1.0-SNAPSHOT"}}
```

# 配置注册中心高可用

以spring-cloud-eureka-server为模板在创建多个子工程，我这里创建两个，分别命名为spring-cloud-eureka-server-8762和spring-cloud-eureka-server-8763。

```yml
server:
  port: 8762

eureka:
  instance:
    hostname: eureka-8762.com
  client:
    registerWithEureka: false
    fetchRegistry: false
    serviceUrl:
      #      defaultZone: http://${eureka.instance.hostname}:${server.port}/eureka/
      defaultZone: http://eureka-8762.com:8762/eureka/,http://eureka-8763.com:8763/eureka/

spring:
  application:
    name: eureka-server-8762
```

主要做了以下几件事：

- 1、修改应用的端口号和应用名称
- 2、修改hostname名称，需要修改/etc/hosts映射
- 3、修改defaultZone

然后再访问 http://eureka-8762.com:8762/eureka/  或者 http://eureka-8763.com:8763/eureka/ 。

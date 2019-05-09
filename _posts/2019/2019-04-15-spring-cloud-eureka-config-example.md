---
layout: post

title: Spring Cloud之Eureka配置示例

category: spring

tags: [spring cloud,eureka]

description:  Eureka是Netflix开源的服务发现组件，本身是一个基于REST的服务，包含Server和Client两部分，Spring Cloud将它集成在子项目Spring Cloud Netflix中，主要负责完成微服务架构中的服务治理功能。

---

Eureka是Netflix开源的服务发现组件，本身是一个基于REST的服务，包含Server和Client两部分，Spring Cloud将它集成在子项目Spring Cloud Netflix中，主要负责完成微服务架构中的服务治理功能。

版本说明：

- Spring Cloud：Greenwich.RELEASE
- Spring Boot：2.1.3.RELEASE

# 1、创建服务注册中心

### 创建 spring-cloud-eureka-server 模块，并添加依赖

~~~xml
<properties>
    <maven.compiler.source>1.8</maven.compiler.source>
    <maven.compiler.target>1.8</maven.compiler.target>
    <java.version>1.8</java.version>
    <spring-cloud-dependencies.version>Greenwich.RELEASE</spring-cloud-dependencies.version>
</properties>

<dependencies>
     <dependency>
         <groupId>org.springframework.cloud</groupId>
         <artifactId>spring-cloud-starter-netflix-eureka-server</artifactId>
     </dependency>
 </dependencies>
 
<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-parent</artifactId>
            <version>${spring-cloud-dependencies.version}</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>
~~~

### 启用EurekaServer

~~~java
@SpringBootApplication
@EnableEurekaServer
public class EurekaServerApplication {
    public static void main(String[] args) {
        SpringApplication.run(EurekaServerApplication.class, args);
    }
}
~~~

### 修改配置文件

~~~
server:
  port: 8761

spring:
  application:
    name: spring-cloud-eureka-server

eureka:
  instance:
    hostname: eureka-8761.com
  client:
    registerWithEureka: false
    fetchRegistry: false
    serviceUrl:
      defaultZone: http://eureka-8761.com:8761/eureka/
~~~

### 访问页面

http://eureka-8761.com:8761/

### 配置权限认证

修改配置文件

开启基于HTTP basic的认证，并设置用户名和密码：

~~~yml
server:
  port: 8761

spring:
  application:
    name: spring-cloud-eureka-server-security
  security:
    basic:
      enabled: true # 开启基于HTTP basic的认证
    user:
      name: admin
      password: 654321
      roles: SYSTEM

eureka:
  instance:
    hostname: eureka-8761.com
  client:
    registerWithEureka: false
    fetchRegistry: false
    serviceUrl:
      defaultZone: http://${eureka.instance.hostname}:${server.port}/eureka/
~~~

# 2、配置客户端代码

### 创建 spring-cloud-eureka-client 子模块，并添加依赖

~~~xml
    <dependencies>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>
    </dependencies>
~~~

### 启用EurekaClient

~~~java
@SpringBootApplication
@EnableDiscoveryClient
public class EurekaClientApplication {
    public static void main(String[] args) {
        SpringApplication.run(EurekaClientApplication.class, args);
    }
}

~~~

### 修改 application.yml

~~~yml
spring:
  application:
    name: spring-cloud-eureka-client

server:
  port: 8701

eureka:
  client:
    registerWithEureka: true
    fetchRegistry: true
    serviceUrl:
      defaultZone: http://eureka-8761.com:8761/eureka/
  instance:
    hostname: localhost
    preferIpAddress: true
~~~

### 访问页面

<http://localhost:8701/greeting>

# 3、配置集群高可用

### 修改配置文件application.yml

~~~yml
server:
  port: 8761

spring:
  application:
    name: spring-cloud-eureka-server
  profiles:
    active: eureka-server

eureka:
  instance:
    hostname: localhost
  client:
    registerWithEureka: false
    fetchRegistry: false

---
server:
  port: 8761

spring:
  application:
    name: spring-cloud-eureka-server

eureka:
  instance:
    hostname: eureka-8761.com
  client:
    registerWithEureka: false
    fetchRegistry: false
    serviceUrl:
      defaultZone: http://eureka-8761.com:8761/eureka/

---
spring:
  profiles: eureka-server1

server:
  port: 8761

eureka:
  instance:
    hostname: eureka-8761.com
  client:
    registerWithEureka: false
    fetchRegistry: false
    serviceUrl:
        defaultZone: http://eureka-8762.com:8762/eureka/,http://eureka-8763.com:8763/eureka/

---
spring:
  profiles: eureka-server2

server:
  port: 8762

eureka:
  instance:
    hostname: eureka-8762.com
  client:
    registerWithEureka: false
    fetchRegistry: false
    serviceUrl:
      defaultZone: http://eureka-8761.com:8761/eureka/,http://eureka-8763.com:8763/eureka/

---
spring:
  profiles: eureka-server3

server:
  port: 8763

eureka:
  instance:
    hostname: eureka-8763.com
  client:
    registerWithEureka: false
    fetchRegistry: false
    serviceUrl:
      defaultZone: http://eureka-8761.com:8761/eureka/,http://eureka-8762.com:8762/eureka/
~~~

这里创建了三个profile。

### 根据不同profile启动应用

添加参数 `--spring.profiles.active=eureka-server1` 启动实例1。

添加参数 `--spring.profiles.active=eureka-server2` 启动实例2。

添加参数 `--spring.profiles.active=eureka-server3` 启动实例3。


# 4、源代码

源代码在：<https://github.com/javachen/java-tutorials/tree/master/spring-cloud/spring-cloud-eureka>。

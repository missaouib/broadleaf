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

## 添加依赖

创建 spring-cloud-eureka-server 模块，并添加依赖

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

## 启用@EurekaServer

~~~java
@SpringBootApplication
@EnableEurekaServer
public class AppEurekaServer {
    public static void main(String[] args) {
        SpringApplication.run(AppEurekaServer.class, args);
    }
}
~~~

## 修改 application.yml

~~~yml
server:
  port: 8761

spring:
  application:
    name: spring-cloud-eureka-server
  cloud:
    inetutils:
      ignoredInterfaces:  #禁用网卡
        - docker0
        - veth.*
        - en0
eureka:
  client:
    registerWithEureka: false
    fetchRegistry: false
    service-url:
      defaultZone: http://eureka-8761.com:8761/eureka/
    registry-fetch-interval-seconds: 5
  instance:
    #ip-address: 127.0.0.1
    prefer-ip-address: true
    instance-id: ${spring.application.name}:${server.port}
    lease-renewal-interval-in-seconds: 5 #每隔5秒剔除一次失效的服务
    lease-expiration-duration-in-seconds: 10 # 10秒不发送就过期
    enable-self-preservation: false #关闭自我保护
~~~

> 服务续约

有两个重要参数可以修改服务续约的行为：

```yml
eureka:
  instance:
    lease-expiration-duration-in-seconds: 90
    lease-renewal-interval-in-seconds: 30
```

- `lease-renewal-interval-in-seconds`：服务续约(renew)的间隔，默认为30秒
- `lease-expiration-duration-in-seconds`：服务失效时间，默认值90秒

也就是说，默认情况下每个30秒服务会向注册中心发送一次心跳，证明自己还活着。如果超过90秒没有发送心跳，EurekaServer就会认为该服务宕机，会从服务列表中移除，这两个值在生产环境不要修改，默认即可。

但是在开发时，这个值有点太长了，经常我们关掉一个服务，会发现Eureka依然认为服务在活着。所以我们在开发阶段可以适当调小。

```yml
eureka:
  instance:
    lease-expiration-duration-in-seconds: 10 # 10秒即过期
    lease-renewal-interval-in-seconds: 5 # 5秒一次心跳
```

> 失效剔除

有些时候，我们的服务提供方并不一定会正常下线，可能因为内存溢出、网络故障等原因导致服务无法正常工作。Eureka Server需要将这样的服务剔除出服务列表。因此它会开启一个定时任务，每隔60秒对所有失效的服务（超过90秒未响应）进行剔除。

可以通过`eureka.server.eviction-interval-timer-in-ms`参数对其进行修改，单位是毫秒，生成环境不要修改。

这个会对我们开发带来极大的不变，你对服务重启，隔了60秒Eureka才反应过来。开发阶段可以适当调整，比如10S。

> 自我保护

我们关停一个服务，就会在Eureka面板看到一条警告：

[![1525618396076](https://github.com/lyj8330328/Load-Balancing/raw/master/notes/assets/1525618396076.png)](https://github.com/lyj8330328/Load-Balancing/blob/master/notes/assets/1525618396076.png)

这是触发了Eureka的自我保护机制。当一个服务未按时进行心跳续约时，Eureka会统计最近15分钟心跳失败的服务实例的比例是否超过了85%。在生产环境下，因为网络延迟等原因，心跳失败实例的比例很有可能超标，但是此时就把服务剔除列表并不妥当，因为服务可能没有宕机。Eureka就会把当前实例的注册信息保护起来，不予剔除。生产环境下这很有效，保证了大多数服务依然可用。

但是这给我们的开发带来了麻烦， 因此开发阶段我们都会关闭自我保护模式：

```
eureka:
  server:
    enable-self-preservation: false # 关闭自我保护模式（缺省为打开）
    eviction-interval-timer-in-ms: 1000 # 扫描失效服务的间隔时间（缺省为60*1000ms）
```

## 访问页面

http://eureka-8761.com:8761/

# 2、配置客户端代码

## 添加依赖

创建 spring-cloud-eureka-client 子模块，并添加依赖

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

## 启用@EnableDiscoveryClient

~~~java
@SpringBootApplication
@EnableDiscoveryClient
public class AppEurekaClient {
    public static void main(String[] args) {
        SpringApplication.run(AppEurekaClient.class, args);
    }
}

~~~

## 修改 application.yml

~~~yml
server:
  port: 8701

spring:
  application:
    name: spring-cloud-eureka-client
  cloud:
    inetutils:
      ignoredInterfaces:  #禁用网卡
        - docker0
        - veth.*
        - en0

eureka:
  client:
    service-url:
      defaultZone: http://eureka-8761.com:8761/eureka
    registry-fetch-interval-seconds: 5
  instance:
    prefer-ip-address: true #当你获取host时，返回的不是主机名，而是ip
    instance-id: ${spring.application.name}:${server.port}
~~~

当服务消费者启动是，会检测`eureka.client.fetch-registry=true`参数的值，如果为true，则会从Eureka Server服务的列表只读备份，然后缓存在本地。并且`每隔30秒`会重新获取并更新数据。我们可以通过下面的参数来修改：

```yml
eureka:
  client:
    registry-fetch-interval-seconds: 5
```

生产环境中，我们不需要修改这个值。

但是为了开发环境下，能够快速得到服务的最新状态，我们可以将其设置小一点。

## 访问页面

<http://localhost:8701/greeting>

```
Hello from 172.20.10.10:8701 !
```



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

# 4、配置权限认证

添加依赖：

```xml
<dependencies>
    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-starter-netflix-eureka-server</artifactId>
    </dependency>

    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-security</artifactId>
    </dependency>

    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-actuator</artifactId>
    </dependency>
</dependencies>
```

开启基于HTTP basic的认证，并设置用户名和密码：

```yml
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
```

修改客户端配置文件，设置用户名和密码：

```yml
server:
  port: 8701

spring:
  application:
    name: spring-cloud-eureka-client
  cloud:
    inetutils:
      ignoredInterfaces:  #禁用网卡
        - docker0
        - veth.*
        - en0

eureka:
  client:
    service-url:
      #添加用户和密码：admin:654321@
      defaultZone: http://admin:654321@eureka-8761.com:8761/eureka
    registry-fetch-interval-seconds: 5
  instance:
    prefer-ip-address: true #当你获取host时，返回的不是主机名，而是ip
    instance-id: ${spring.application.name}:${server.port}
```

# 5、源代码

源代码在：<https://github.com/javachen/java-tutorials/tree/master/spring-cloud/spring-cloud-eureka>。


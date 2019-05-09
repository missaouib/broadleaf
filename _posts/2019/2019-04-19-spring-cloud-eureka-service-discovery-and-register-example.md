---
layout: post

title: Spring Cloud之Eureka服务发现和注册示例

category: spring

tags: [spring cloud,eureka]

description: Spring Cloud之Eureka服务发现和注册示例代码，集成Feign。

---

# 创建生产者项目

在 <https://github.com/javachen/java-tutorials/tree/master/spring-cloud/spring-cloud-examples> 工程中创建 provider 子模块。首先编辑pom文件：

```xml
<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>

    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
    </dependency>

    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-actuator</artifactId>
    </dependency>
</dependencies>
```

编写一个controller如下：

```java
@RestController
public class GreetingController {
    @RequestMapping("/greeting/{username}")
    public String greeting(@PathVariable("username") String username) {
        return String.format("Hello %s!\n", username);
    }
}
```

修改application.yml配置文件：

```yml
spring:
  application:
    name: provider

server:
  port: 8081

eureka:
  client:
    serviceUrl:
      defaultZone: http://eureka-8761.com:8761/eureka/
  instance:
    preferIpAddress: true
```

这里把生产者作为客户端注册到eureka了，可以打开eureka的主界面查看注册的服务信息。

启动应用，然后访问 <http://localhost:8081//greeting/aaa>，可以看到返回的结果：

```
Hello aaa!
```

# 创建消费者项目

创建consumer子模块，编辑pom：

```xml
 <dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
</dependencies>
```

编写一个控制类访问生产者接口：

```java
@RestController
public class GreetingController {
    @Autowired
    private GreetingService greetingService;

    @RequestMapping("/greeting/{username}")
    public String greeting(@PathVariable("username") String username) {
        return greetingService.greeting(username);
    }
}
```

创建Service类：

```java
@Service
public class GreetingService {
    private String REST_URL_PREFIX = "http://localhost:8081";

    @Autowired
    private RestTemplate restTemplate;

    public String greeting(String username) {
        return restTemplate.getForObject(REST_URL_PREFIX + "/greeting/{username}", String.class, username);
    }
}
```

这里是使用RestTemplate类访问rest接口，需要注入RestTemplate的bean：

```java
@Configuration
public class ConfigBean {
    @Bean
    public RestTemplate getRestTemplate(){
        return new RestTemplate();
    }
}
```

修改application.yml配置文件：

```yml
server:
  port: 9091

spring:
  application:
    name: consumer
```

最后创建启动类：

```java
@SpringBootApplication
public class ConsumerApplication {
    public static void main(String[] args) {
        SpringApplication.run(ConsumerEurekaApplication.class, args);
    }
}
```

启动应用，然后访问 <http://localhost:9091//greeting/aaa>，可以看到返回的结果：

```
Hello aaa!
```

# 集成Eureka访问服务

上面的消费者代码是通过rest的http接口访问生产者的接口，这里修改为通过eureka的注册中心去访问服务。

创建consumer-eureka 子模块，编辑pom：

```xml
<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>

    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
    </dependency>
</dependencies>
```

修改application.yml配置文件，注册到eureka：

```yml
server:
  port: 9092

spring:
  application:
    name: consumer-eureka


eureka:
  client:
    registerWithEureka: true
    fetchRegistry: true
    serviceUrl:
      defaultZone: http://eureka-8761.com:8761/eureka/
  instance:
    preferIpAddress: true
```

创建controller类：

```
@RestController
public class GreetingController {
    @Autowired
    private GreetingService greetingService;

    @RequestMapping("/greeting/{username}")
    public String greeting(@PathVariable("username") String username) {
        return greetingService.greeting(username);
    }
}
```

修改service类：

```java
@Service
public class GreetingService {
    private String REST_URL_PREFIX = "PROVIDER";

    @Autowired
    private RestTemplate restTemplate;

    public String greeting(String username) {
        return restTemplate.getForObject("http://" + REST_URL_PREFIX + "/greeting/{username}", String.class, username);
    }
}
```

启动类：

```java
@SpringBootApplication
@EnableDiscoveryClient
public class ConsumerEurekaApplication {
    public static void main(String[] args) {
        SpringApplication.run(ConsumerEurekaApplication.class, args);
    }
}
```

启动应用，然后访问 <http://localhost:9092//greeting/aaa>，可以看到返回的结果：

```
Hello aaa!
```

# 使用Feign调用生产者接口

创建 consumer-feign 子模块，编辑pom文件：

```xml
<dependencies>
    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
    </dependency>

    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-starter-openfeign</artifactId>
    </dependency>

    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>

    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-actuator</artifactId>
    </dependency>
</dependencies>
```

controller类：

```java
@RestController
public class GreetingController {
    @Autowired
    private GreetingService greetingService;

    @RequestMapping("/greeting/{username}")
    public String getGreeting(@PathVariable("username") String username) {
        return greetingService.greeting(username);
    }
}

```

修改GreetingService接口：

```java
@FeignClient(name = "provider")
public interface GreetingService {
    @GetMapping("/greeting/{username}")
    public String greeting(@PathVariable("username") String username);
}
```

修改启动类，添加`@EnableFeignClients`注解：

```java
@SpringBootApplication
@EnableFeignClients
public class ConsumerFeignApplication {
    public static void main(String[] args) {
        SpringApplication.run(ConsumerFeignApplication.class, args);
    }
}

```

application.yml配置文件:

```
server:
  port: 9093

spring:
  application:
    name: consumer-feign

eureka:
  client:
    registerWithEureka: true
    fetchRegistry: true
    serviceUrl:
      defaultZone: http://eureka-8761.com:8761/eureka/
  instance:
    preferIpAddress: true
```

启动应用，然后访问 <http://localhost:9093//greeting/aaa>，可以看到返回的结果：

```
Hello aaa!
```

# 源代码

源代码在：<https://github.com/javachen/java-tutorials/tree/master/spring-cloud/spring-cloud-examples>。

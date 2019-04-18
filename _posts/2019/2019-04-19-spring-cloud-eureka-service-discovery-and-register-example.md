---
layout: post

title: Spring Cloud之Eureka服务发现和注册示例

category: spring

tags: [spring cloud,eureka]

description: Spring Cloud之Eureka服务发现和注册示例代码，集成Feign。

---

# 创建生产者项目

在 <https://github.com/javachen/spring-cloud-examples> 工程中创建 spring-cloud-provider 子模块。首先编辑pom文件：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <artifactId>spring-cloud-provider</artifactId>
    <packaging>jar</packaging>

    <parent>
        <artifactId>spring-cloud-examples</artifactId>
        <groupId>com.javachen.springcloud</groupId>
        <version>1.0-SNAPSHOT</version>
    </parent>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>

        <dependency>
            <groupId>com.h2database</groupId>
            <artifactId>h2</artifactId>
        </dependency>

        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <optional>true</optional>
        </dependency>

        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-devtools</artifactId>
        </dependency>
    </dependencies>
</project>
```

编写一个controller如下：

```java
@RequestMapping("/users")
@RestController
public class UserController {
    @Autowired
    private UserRepository userRepository;

    @GetMapping("/{id}")
    public Optional<User> findById(@PathVariable Long id) {
        return this.userRepository.findById(id);
    }
}
```

这里使用了JPA，所有需要引入相应的依赖，并设置数据库，这里使用的是h2内存数据库。默认不需要配置。

创建 UserRepository：

```java
@Repository
public interface UserRepository extends JpaRepository<User, Long> {
}
```

创建User实体类：

```java
@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private Long id;
    @Column
    private String username;
    @Column
    private String name;
    @Column
    private Integer age;
    @Column
    private BigDecimal balance;
}
```

当然，这里使用了 lombok 简化代码编写。

编写启动类，并初始化h2数据：

```java
@SpringBootApplication
public class ProviderApplication {
    public static void main(String[] args) {
        SpringApplication.run( ProviderApplication.class, args );
    }

    /**
     * 初始化用户信息
     * 注：Spring Boot2不能像1.x一样，用spring.datasource.schema/data指定初始化SQL脚本，否则与actuator不能共存
     * 原因详见：
     * https://github.com/spring-projects/spring-boot/issues/13042
     * https://github.com/spring-projects/spring-boot/issues/13539
     *
     * @param repository repo
     * @return runner
     */
    @Bean
    ApplicationRunner init(UserRepository repository) {
        return args -> {
            User user1 = new User(1L, "account1", "张三", 20, new BigDecimal(100.00));
            User user2 = new User(2L, "account2", "李四", 28, new BigDecimal(180.00));
            User user3 = new User(3L, "account3", "王五", 32, new BigDecimal(280.00));
            Stream.of(user1, user2, user3)
                    .forEach(repository::save);
        };
    }
}
```

修改application.yml配置文件：

```yml
server:
  port: 8080

spring:
  application:
    name: provider
  jpa:
    show-sql: true

management:
  endpoints:
    web:
      exposure:
        # 开放所有监控端点
        include: '*'
  endpoint:
    health:
      # 是否展示健康检查详情
      show-details: always

eureka:
  client:
    serviceUrl:
      defaultZone: http://localhost:8761/eureka/
  instance:
    instance-id: provider-8080  #自定义服务名称信息
    # 是否注册IP到eureka server，如不指定或设为false，那就会注册主机名到eureka server
    prefer-ip-address: true

info:
  app.name: spring-cloud-provider
  company.name: www.javachen.com
  build.artifactId: $project.artifactId$
  build.version: $project.version$
```

这里把生产者作为客户端注册到eureka了，可以打开eureka的主界面查看注册的服务信息。

启动应用，然后访问 <http://localhost:8080/users/1>，可以看到返回的结果：

```json
{"id":1,"username":"account1","name":"张三","age":20,"balance":100.00}
```

# 创建消费者项目

创建spring-cloud-consumer子模块，编辑pom：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <parent>
        <artifactId>spring-cloud-examples</artifactId>
        <groupId>com.javachen.springcloud</groupId>
        <version>1.0-SNAPSHOT</version>
    </parent>
    <modelVersion>4.0.0</modelVersion>

    <artifactId>spring-cloud-consumer</artifactId>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>

        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <optional>true</optional>
        </dependency>
    </dependencies>
</project>
```

编写一个控制类访问生产者接口：

```java
@RestController
public class UserController {
    private String REST_URL_PREFIX="http://localhost:8080";

    @Autowired
    private RestTemplate restTemplate;

    @GetMapping("/users/{id}")
    public User findById(@PathVariable Long id) {
        User user = this.restTemplate.getForObject(REST_URL_PREFIX+"/users/{id}", User.class, id);
        return user;
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
  port: 8090
```

最后创建启动类：

```java
@SpringBootApplication
public class ConsumerApplication {
    public static void main(String[] args) {
        SpringApplication.run( ConsumerApplication.class, args );
    }
}
```

启动应用，然后访问 <http://localhost:8090/users/1>，可以看到返回的结果：

```json
{"id":1,"username":"account1","name":"张三","age":20,"balance":100.00}
```

# 通过注册中心访问服务

上面的消费者代码是通过rest的http接口访问生产者的接口，这里修改为通过eureka的注册中心去访问服务。

创建spring-cloud-consumer-eureka 子模块，编辑pom：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <parent>
        <artifactId>spring-cloud-examples</artifactId>
        <groupId>com.javachen.springcloud</groupId>
        <version>1.0-SNAPSHOT</version>
    </parent>
    <modelVersion>4.0.0</modelVersion>

    <artifactId>spring-cloud-consumer-eureka</artifactId>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>

        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <optional>true</optional>
        </dependency>

        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
        </dependency>
    </dependencies>
</project>
```

修改application.yml配置文件，注册到eureka：

```yml
server:
  port: 8091

spring:
  application:
    name: consumer

eureka:
  client:
    registerWithEureka: false
    serviceUrl:
      defaultZone: http://localhost:8761/eureka/

```

修改UserController类通过服务名称PROVIDER调用接口：

```
@RestController
public class UserController {
    private String REST_URL_PREFIX="http://PROVIDER";

    @Autowired
    private RestTemplate restTemplate;

    @GetMapping("/users/{id}")
    public User findById(@PathVariable Long id) {
        User user = this.restTemplate.getForObject(REST_URL_PREFIX+"/users/{id}", User.class, id);
        return user;
    }
}
```

启动类不用做修改：

```java
@SpringBootApplication
public class ConsumerApplication {
    public static void main(String[] args) {
        SpringApplication.run( ConsumerApplication.class, args );
    }
}
```

启动应用，然后访问 <http://localhost:8091/users/1>，可以看到返回的结果：

```json
{"id":1,"username":"account1","name":"张三","age":20,"balance":100.00}
```

# 使用Feign调用生产者接口

创建spring-cloud-consumer-feign 子模块，编辑pom文件：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <parent>
        <artifactId>spring-cloud-examples</artifactId>
        <groupId>com.javachen.springcloud</groupId>
        <version>1.0-SNAPSHOT</version>
    </parent>
    <modelVersion>4.0.0</modelVersion>

    <artifactId>spring-cloud-consumer-feign</artifactId>

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
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-openfeign</artifactId>
        </dependency>

        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <optional>true</optional>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>
    </dependencies>
</project>
```

修改UserController类，使用feign调用接口：

```java
@RestController
public class UserController {
    @Autowired
    private UserFeignService userFeignService;

    @GetMapping("/users/{id}")
    public User findById(@PathVariable Long id) {
        User user = this.userFeignService.findById(id);
        return user;
    }
}
```

需要创建UserFeignService接口：

```java
@FeignClient(name = "provider")
public interface UserFeignService {
    @GetMapping("/users/{id}")
    User findById(@PathVariable("id") Long id);
}
```

修改启动类，添加`@EnableFeignClients`注解：

```java
@SpringBootApplication
@EnableEurekaClient
@EnableFeignClients
public class ConsumerApplication {
    public static void main(String[] args) {
        SpringApplication.run( ConsumerApplication.class, args );
    }
}
```

application.yml配置文件:

```
server:
  port: 8092

spring:
  application:
    name: consumer

eureka:
  client:
    registerWithEureka: false
    serviceUrl:
      defaultZone: http://localhost:8761/eureka/
```

启动应用，然后访问 <http://localhost:8092/users/1>，可以看到返回的结果：

```json
{"id":1,"username":"account1","name":"张三","age":20,"balance":100.00}
```

# 源代码

源代码在：<https://github.com/javachen/spring-cloud-examples>，包括 spring-cloud-eureka-server 和spring-cloud-eureka-client代码。

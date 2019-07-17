---
layout: post
title: 不使用Eureka创建Spring Cloud微服务
category: spring
tags: eureka
description: 本文主要记录在不使用Eureka注册中心的情况下，如何使用Spring Cloud相关组件创建微服务。希望通过本篇文章，熟悉Spring Cloud相关组件的用法和基本原理。
---

首先创建一个普通项目，分为生产者和消费者两部分，然后在逐步集成SpringCloud的相关组件。

# 1、创建基本应用

## 1.1、创建工程

创建spring-cloud-examples-1模块，pom文件：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns="http://maven.apache.org/POM/4.0.0"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.javachen</groupId>
    <artifactId>spring-cloud-examples-1</artifactId>
    <version>1.0.0-SNAPSHOT</version>
    <packaging>pom</packaging>
</project>
```

## 1.2、创建生产者项目

在 spring-cloud-examples-1工程中创建 provider子模块。首先编辑pom文件：

```xml
<dependencies>
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

启动类：

```java
@SpringBootApplication
public class AppProvider {
    public static void main(String[] args) {
        SpringApplication.run(AppProvider.class, args);
    }
}
```

修改application.yml配置文件：

```yml
server:
  port: 8000

spring:
  application:
    name: provider
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

```

启动应用，然后访问 <http://localhost:8000/greeting/spring>，可以看到返回的结果：

```
Hello spring!
```

## 1.3、创建消费者项目

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

创建Service类，这里使用了RestTemplate类对生产端接口进行调用：

```java
@Service
public class GreetingService {
    private String REST_URL_PREFIX = "localhost:8000";

    @Autowired
    private RestTemplate restTemplate;

    public String greeting(String username) {
        return restTemplate.getForObject("http://" + REST_URL_PREFIX 
        + "/greeting/{username}", String.class, username);
    }
}
```

这里是使用RestTemplate类访问rest接口，需要注入RestTemplate的bean：

```java
@Configuration
public class RestClientConfig {
    @Bean
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }
}
```

修改application.yml配置文件：

```yml
server:
  port: 9000

spring:
  application:
    name: consumer
```

最后创建启动类：

```java
@SpringBootApplication
public class AppConsumer {
    public static void main(String[] args) {
        SpringApplication.run(AppConsumer.class, args);
    }
}
```

启动应用，然后访问 <http://localhost:9000/greeting/spring>，可以看到返回的结果：

```
Hello spring!
```

## 1.4、RestTemplate

RestTemplate是Spring提供的一个访问Rest接口的模板工具类，对基于Http的客户端进行了封装，并且实现了对象与json的序列化和反序列化，非常方便。RestTemplate并没有限定Http的客户端类型，而是进行了抽象，目前常用的3种都有支持：

- HttpClient
- OkHttp
- JDK原生的URLConnection（默认的）

如果想更换客户端类型，比如使用OkHttp，则需要先添加依赖：

```xml
<dependency>
    <groupId>com.squareup.okhttp3</groupId>
    <artifactId>okhttp</artifactId>
    <version>3.9.0</version>
</dependency>
```

然后修改RestClientConfig类，改为由OkHttp3ClientHttpRequestFactory工厂创建RestTemplate：

```java
@Configuration
public class RestClientConfig {
    @Bean
    public RestTemplate restTemplate() {
        return new RestTemplate(new OkHttp3ClientHttpRequestFactory());
    }
}
```

也可以使用RestTemplateBuilder类来构建，修改代码注入一个RestTemplateBuilder：

```java
@Configuration
public class RestClientConfig {
    @Bean
    @Qualifier("customRestTemplateCustomizer")
    public CustomRestTemplateCustomizer customRestTemplateCustomizer() {
        return new CustomRestTemplateCustomizer();
    }

    @Bean
    @DependsOn(value = {"customRestTemplateCustomizer"})
    public RestTemplateBuilder restTemplateBuilder() {
        return new RestTemplateBuilder(customRestTemplateCustomizer());
    }

//    @Bean
//    public RestTemplate restTemplate() {
//        return new RestTemplate(new OkHttp3ClientHttpRequestFactory());
//    }

    @Bean
    @Autowired
    public RestTemplate restTemplate(RestTemplateBuilder restTemplateBuilder) {
        return restTemplateBuilder
                .requestFactory(OkHttp3ClientHttpRequestFactory.class)
                .errorHandler(new RestTemplateResponseErrorHandler())
                .build();
    }
}
```

这里自定义了一个 ResponseErrorHandler ，可以处理异常：

```java
@Component
public class RestTemplateResponseErrorHandler
    implements ResponseErrorHandler {

    @Override
    public boolean hasError(ClientHttpResponse httpResponse)
        throws IOException {

        return (httpResponse
          .getStatusCode()
          .series() == HttpStatus.Series.CLIENT_ERROR || httpResponse
          .getStatusCode()
          .series() == HttpStatus.Series.SERVER_ERROR);
    }

    @Override
    public void handleError(ClientHttpResponse httpResponse)
        throws IOException {

        if (httpResponse
          .getStatusCode()
          .series() == HttpStatus.Series.SERVER_ERROR) {
            //Handle SERVER_ERROR
            throw new HttpClientErrorException(httpResponse.getStatusCode());
        } else if (httpResponse
          .getStatusCode()
          .series() == HttpStatus.Series.CLIENT_ERROR) {
            //Handle CLIENT_ERROR
            if (httpResponse.getStatusCode() == HttpStatus.NOT_FOUND) {
                throw new NotFoundException();
            }
        }
    }
}
```

而RestTemplateBuilder注入了一个RestTemplateCustomizer的bean：

```java
public class CustomRestTemplateCustomizer implements RestTemplateCustomizer {
    @Override
    public void customize(RestTemplate restTemplate) {
        restTemplate.getInterceptors().add(new CustomClientHttpRequestInterceptor());
    }
}
```

其中，自定义了一个拦截器CustomClientHttpRequestInterceptor：

```java
public class CustomClientHttpRequestInterceptor implements ClientHttpRequestInterceptor {
    @Override
    public ClientHttpResponse intercept(HttpRequest request, 
        byte[] body, ClientHttpRequestExecution execution) throws IOException {

        logRequestDetails(request);

        return execution.execute(request, body);
    }

    private void logRequestDetails(HttpRequest request) {
        System.out.println("Request Headers: "+ request.getHeaders());
        System.out.println("Request Method: "+ request.getMethod());
        System.out.println("Request URI: "+ request.getURI());
    }
}
```

重启消费端应用，再次访问浏览器： <http://localhost:9000/greeting/spring>，然后查看控制台打印的日志：

```java
Request Headers: [Accept:"text/plain, application/json, application/*+json, */*", Content-Length:"0"]
Request Method: GET
Request URI: http://localhost:8000/greeting/spring
```

# 2、集成Ribbon实现生产端负载均衡

Ribbon是Netflix发布的负载均衡器，它可以帮我们控制HTTP和TCP客户端的行为。只需为Ribbon配置服务提供者地址列表，Ribbon就可基于负载均衡算法计算出要请求的目标服务地址。

Ribbon默认为我们提供了很多的负载均衡算法，例如轮询、随机、响应时间加权等——当然，为Ribbon自定义负载均衡算法也非常容易，只需实现`IRule` 接口即可。

## 2.1、添加依赖

首先，基于consumer模块再创建consumer-ribbon模块，把代码拷贝过去，然后添加ribbon客户端依赖：

```xml
 <parent>
    <artifactId>spring-cloud-examples</artifactId>
    <groupId>com.javachen</groupId>
    <version>1.0.0-SNAPSHOT</version>
</parent>
<modelVersion>4.0.0</modelVersion>

<artifactId>consumer-ribbon</artifactId>

<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>

    <dependency>
        <groupId>com.squareup.okhttp3</groupId>
        <artifactId>okhttp</artifactId>
        <version>3.9.0</version>
    </dependency>

    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-starter-netflix-ribbon</artifactId>
    </dependency>

    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-test</artifactId>
    </dependency>

    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-actuator</artifactId>
    </dependency>
</dependencies>
```

## 2.2、修改配置文件

```yml
server:
  port: 9000

spring:
  application:
    name: consumer-ribbon

ribbon:
  eureka:
    enabled: false #禁用eureka客户端

service-provider:
  ribbon:
    # 负载均衡地址，配置多个
    listOfServers: localhost:8000,localhost:8001
    ServerListRefreshInterval: 15000
    NFLoadBalancerPingClassName: com.javachen.ping.MyPing
```

配置说明：

- 因为引入的是spring-cloud-starter-netflix-ribbon，其中包含eureka，所以需要禁用eureka客户端
- `<client>.ribbon.listOfServers`：可用微服务列表，注意这里没有使用 eureka。

SpringBoot帮我们提供了修改负载均衡规则和Ping算法的配置入口：

```yml
user-provider:
  ribbon:
    NFLoadBalancerRuleClassName: com.javachen.ping.MyRule
    NFLoadBalancerPingClassName: com.javachen.ping.MyPing
```

格式是：`{服务名称}.ribbon.NFLoadBalancerRuleClassName`，值就是IRule的实现类。



## 2.3、修改service代码

使用LoadBalancerClient来实现负载均衡功能：

```java
@Service
@Slf4j
public class GreetingService {
    private String REST_URL_PREFIX = "service-provider";

    @Autowired
    private RestTemplate restTemplate;

    @Autowired
    private LoadBalancerClient loadBalancerClient;

    public String greeting(String username) throws IOException {
//        return restTemplate.getForObject("http://" + 
//REST_URL_PREFIX + "/greeting/{username}", String.class, username);

        // 选择指定的 service Id
        ServiceInstance serviceInstance = 
        loadBalancerClient.choose(REST_URL_PREFIX);

        return loadBalancerClient.execute(REST_URL_PREFIX, 
            serviceInstance, instance -> {
            //服务器实例，获取 主机名（IP） 和 端口
            String host = instance.getHost();
            int port = instance.getPort();
            String url= host + ":" + port ;
            return restTemplate.getForObject("http://" + url 
            + "/greeting/{username}", String.class, username);

        });
    }
}
```

代码中将 REST_URL_PREFIX 修改为 service-provider，对应配置文件中定义的 service-provider，其是一个负载均衡列表地址。

LoadBalancerClient首先通过负载均衡算法，选出一个负载均衡服务器，然后获取host和端口，在通过restTemplate进行调用。

## 2.4、开启Ribbon客户端

```java
@SpringBootApplication
@RibbonClients(
        //设置一个 ribbon 客户端名称
        @RibbonClient(name = "service-provider")
)
public class AppConsumerRibbon {
    public static void main(String[] args) {
        SpringApplication.run(AppConsumerRibbon.class, args);
    }
}
```

## 2.5、测试

启动两个provider应用，端口分别为8000和8001，然后启动consumer-ribbon应用。浏览器访问 http://localhost:9000/greeting/spring ，同样可以看到：

```
Hello spring!
```

多访问几次，后台可以看到日志：

```yml
Request Headers: [Accept:"text/plain, application/json, application/*+json, */*", Content-Length:"0"]
Request Method: GET
Request URI: http://localhost:8001/greeting/spring
Request Headers: [Accept:"text/plain, application/json, application/*+json, */*", Content-Length:"0"]
Request Method: GET
Request URI: http://localhost:8000/greeting/spring
```

可以看到8000和8001都有访问到。

停掉8000应用，在访问一次，可以看到浏览器显示：

```
Whitelabel Error Page
This application has no explicit mapping for /error, so you are seeing this as a fallback.

Sun Jun 30 16:15:42 CST 2019
There was an unexpected error (type=Internal Server Error, status=500).
No instances available for service-provider
```

这是因为8000应用已经停掉了，所以不能服务，多刷几次，当请求负载到8001应用时，又能看到返回结果。**这说明：当服务宕机之后，ribbon没有将宕机的应用从负载均衡列表中删除。**

但是此时，8081服务其实是正常的。

因此Spring Cloud 整合了Spring Retry 来增强RestTemplate的重试能力，当一次服务调用失败后，不会立即抛出一次，而是再次重试另一个服务。

只需要简单配置即可实现Ribbon的重试：

```yml
spring:
  cloud:
    loadbalancer:
      retry:
        enabled: true # 开启Spring Cloud的重试功能
provider:
  ribbon:
    ConnectTimeout: 250 # Ribbon的连接超时时间
    ReadTimeout: 1000 # Ribbon的数据读取超时时间
    OkToRetryOnAllOperations: true # 是否对所有操作都进行重试
    MaxAutoRetriesNextServer: 1 # 切换实例的重试次数
    MaxAutoRetries: 1 # 对当前实例的重试次数
```

根据如上配置，当访问到某个服务超时后，它会再次尝试访问下一个服务实例，如果不行就再换一个实例，如果不行，则返回失败。切换次数取决于`MaxAutoRetriesNextServer`参数的值

引入spring-retry依赖

```xml
<dependency>
    <groupId>org.springframework.retry</groupId>
    <artifactId>spring-retry</artifactId>
</dependency>
```

将8000应用启动起来，等几秒之后，应用又能正常访问，不再报错，这是因为ribbo检测到8000端口的应用是正常的，默认是通过 http://localhost:8000/actuator/health 来检测的。

## 2.6、RestTemplate实现负载均衡

修改RestClientConfig类，添加@LoadBalanced注解：

```java
@Configuration
public class RestClientConfig {
    @Bean
    @Qualifier("customRestTemplateCustomizer")
    public CustomRestTemplateCustomizer customRestTemplateCustomizer() {
        return new CustomRestTemplateCustomizer();
    }

    @Bean
    @DependsOn(value = {"customRestTemplateCustomizer"})
    public RestTemplateBuilder restTemplateBuilder() {
        return new RestTemplateBuilder(customRestTemplateCustomizer());
    }


//    @Bean
//    public RestTemplate restTemplate() {
//        return new RestTemplate(new OkHttp3ClientHttpRequestFactory());
//    }

    @Bean
    @LoadBalanced
    public RestTemplate restTemplate() {
        return restTemplateBuilder()
                .requestFactory(OkHttp3ClientHttpRequestFactory.class)
                .errorHandler(new RestTemplateResponseErrorHandler())
                .build();
    }
}
```

修改service类：

```java
@Service
public class GreetingService {
    private String REST_URL_PREFIX = "service-provider";

    @Autowired
    private RestTemplate restTemplate;

    public String greeting(String username) throws IOException {
        return restTemplate.getForObject("http://" + REST_URL_PREFIX 
        + "/greeting/{username}", String.class, username);
    }
}
```

再次进行测试，可以看到日志：

```yml
Request Headers: [Accept:"text/plain, application/json, application/*+json, */*", Content-Length:"0"]
Request Method: GET
Request URI: http://service-provider/greeting/spring
```

## 2.7、自定义ribbon配置

修改启动类：

```java
@SpringBootApplication
@RibbonClients(
    //设置一个 ribbon 客户端名称
    @RibbonClient(name = "provider", configuration = RibbonConfig.class)
)
public class AppConsumerRibbon {
    public static void main(String[] args) {
        SpringApplication.run(AppConsumerRibbon.class, args);
    }
}
```

添加RibbonConfig类：

```java
@Configuration
public class RibbonConfig {
    @Bean
    public IPing ribbonPing() {
        return new MyPing();
    }

    @Bean
    public IRule ribbonRule() {
        return new RandomRule();
    }
}
```

主要功能：

- 实现IPing接口自定义一个ping逻辑
- 实现IRule接口，设置负载均衡算法，这里使用的是随机算法。
- Ribbon支持负载规则：
  -  AvailabilityFilteringRule
  -  BestAvailableRule
  -  PredicateBasedRule
  -  RandomRule 
  -  RetryRule 
  -  RoundRobinRule
  -  ZoneAvoidanceRule

负载均衡规则说明：

| 内置策略                  | 规则描述                                                     | 实现说明                                                     |
| ------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| RoundRobinRule            | 简单轮询服务列表来选择服务器。                               | 轮询index，选择index对应位置的server                         |
| AvailabilityFilteringRule |                                                              | 使用一个AvailabilityPredicate来包含过滤server的逻辑，其实就就是检查status里记录的各个server的运行状态 |
| WeightedResponseTimeRule  | 为每一个服务器赋予一个权重值。服务器响应时间越长，这个服务器的权重就越小。这个规则会随机选择服务器，这个权重值会影响服务器的选择。 | 一个后台线程定期的从status里面读取评价响应时间，为每个server计算一个weight。Weight的计算也比较简单responsetime 减去每个server自己平均的responsetime是server的权重。当刚开始运行，没有形成status时，使用roubine策略选择server。 |
| ZoneAvoidanceRule         | 以区域可用的服务器为基础进行服务器的选择。使用Zone对服务器进行分类，这个Zone可以理解为一个机房、一个机架等。 | 使用ZoneAvoidancePredicate和AvailabilityPredicate来判断是否选择某个server，前一个判断判定一个zone的运行性能是否可用，剔除不可用的zone（的所有server），AvailabilityPredicate用于过滤掉连接数过多的Server。 |
| BestAvailableRule         | 忽略哪些短路的服务器，并选择并发数较低的服务器。             | 逐个考察Server，如果Server被tripped了，则忽略，在选择其中ActiveRequestsCount最小的server |
| RandomRule                | 随机选择一个可用的服务器。                                   | 在index上随机，选择index对应位置的server                     |
| RetryRule                 | 重试机制的选择逻辑                                           | 在一个配置时间段内当选择server不成功，则一直尝试使用subRule的方式选择一个可用的server |

 AvailabilityFilteringRule规则说明：对以下两种服务器进行忽略： 

- （1）在默认情况下，这台服务器如果3次连接失败，这台服务器就会被设置为“短路”状态。短路状态将持续30秒，如果再次连接失败，短路的持续时间就会几何级地增加。 注意：可以通过修改配置`loadbalancer.<clientName>.connectionFailureCountThreshold`来修改连接失败多少次之后被设置为短路状态。默认是3次。 
- （2）并发数过高的服务器。如果一个服务器的并发连接数过高，配置了AvailabilityFilteringRule规则的客户端也会将其忽略。并发连接数的上线，可以由客户端的`<clientName>.<clientConfigNameSpace>.ActiveConnectionsLimit`属性进行配置。

也可以自定义一个IPing：

```java
public class MyPing implements IPing {

    @Override
    public boolean isAlive(Server server) {
        String host = server.getHost();
        int port = server.getPort();
        // /health endpoint
        // 通过 Spring 组件来实现URL 拼装
        UriComponentsBuilder builder = UriComponentsBuilder.newInstance();
        builder.scheme("http");
        builder.host(host);
        builder.port(port);
        builder.path("/actuator/health");
        URI uri = builder.build().toUri();

        RestTemplate restTemplate = new RestTemplate();

        ResponseEntity responseEntity = restTemplate.getForEntity(uri, String.class);
        // 当响应状态等于 200 时，返回 true ，否则 false
        return HttpStatus.OK.equals(responseEntity.getStatusCode());
    }
}
```

然后，需要修改配置文件，设置 NFLoadBalancerPingClassName ：

```yml
server:
  port: 9000

spring:
  application:
    name: consumer-ribbon

ribbon:
  eureka:
    enabled: false #禁用eureka客户端

service-provider:
  ribbon:
    # 负载均衡地址，配置多个
    listOfServers: localhost:8000,localhost:8001
    ServerListRefreshInterval: 15000
    NFLoadBalancerPingClassName: com.javachen.ping.MyPing
```

# 3、集成Hystrix实现服务熔断和降级

解决雪崩效应的方法：

1. 超时机制
2. 服务限流
3. 服务熔断
4. 服务降级

## 3.1、创建consumer-hystrix模块

pom.xml添加spring-cloud-starter-netflix-hystrix依赖：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xmlns="http://maven.apache.org/POM/4.0.0"
xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <parent>
        <artifactId>spring-cloud-examples-1</artifactId>
        <groupId>com.javachen</groupId>
        <version>1.0.0-SNAPSHOT</version>
    </parent>
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.javachen</groupId>
    <artifactId>consumer-hystrix</artifactId>
    <version>1.0.0-SNAPSHOT</version>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-netflix-hystrix</artifactId>
        </dependency>

        <dependency>
            <groupId>com.squareup.okhttp3</groupId>
            <artifactId>okhttp</artifactId>
            <version>3.9.0</version>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>

        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <optional>true</optional>
        </dependency>

    </dependencies>
</project>
```

## 3.2、RestTemplate类

 RestClientConfig：

```java
@Configuration
public class RestClientConfig {
    @Bean
    public RestTemplate getRestTemplate() {
        // 这次我们使用了OkHttp客户端,只需要注入工厂即可
        return new RestTemplate(new OkHttp3ClientHttpRequestFactory());
    }
}
```

## 3.3、Service类

```java
@Service
public class GreetingService {
    private String REST_URL_PREFIX = "localhost:8000";

    @Autowired
    private RestTemplate restTemplate;

    public String greeting(String username) {
        return restTemplate.getForObject("http://" + REST_URL_PREFIX 
        + "/greeting/{username}", String.class, username);
    }
}
```

## 3.4、Controller类

```java
@RestController
@Slf4j
public class GreetingController {
    @Autowired
    private GreetingService greetingService;

    private final static Random random = new Random();

    @HystrixCommand(fallbackMethod = "defaultGreeting")
    @RequestMapping("/greeting/{username}")
    public String getGreeting(@PathVariable("username") String username) throws TimeoutException {
       throw new TimeoutException("Execution is timeout!");
    }

    private String defaultGreeting(String username, Throwable throwable) {
        log.info("fallback method");
        return "Hello User!";
    }
}
```

- `@HystrixCommand(fallbackMethod="defaultGreeting")`：声明一个失败回滚处理函数defaultGreeting，当服务不可用的时候，实现**服务降级**。

实现超时回退：当getGreeting执行超时（默认是1000毫秒），就会执行fallback函数，返回错误提示。

```java
@HystrixCommand(fallbackMethod = "defaultGreeting")
    @RequestMapping("/greeting/{username}")
    public String getGreeting(@PathVariable("username") String username) throws TimeoutException {
       long executeTime = random.nextInt(2000);
       Thread.sleep(executeTime);
       //。。。。。。。
    }
```

> 如果集成了Ribbon，RIbbon的超时时间设置的也是1000ms，而Hystix的超时时间默认也是1000ms，因此重试机制不会被触发，而是先触发了熔断。

所以，Ribbon的超时时间一定要小于Hystix的超时时间。

我们可以通过`hystrix.command.default.execution.isolation.thread.timeoutInMilliseconds`来设置Hystrix超时时间。

```yml
hystrix:
  command:
  	default:
        execution:
          isolation:
            thread:
              timeoutInMillisecond: 6000 # 设置hystrix的超时时间为6000ms
```

如何实现服务熔断？在代码里增加模拟报错代码：

```java
@HystrixCommand(fallbackMethod = "defaultGreeting")
@RequestMapping("/greeting/{username}")
public String getGreeting(@PathVariable("username") String username) throws TimeoutException {
  long executeTime = random.nextInt(2000);
  Thread.sleep(executeTime);
  if (executeTime > 100) { 
    //抛异常，模拟服务不可用
    throw new TimeoutException("Execution is timeout!");
  }
  return greetingService.greeting(username);
}
```

测试报错和正常的情况，我们可以看到当报错达到一定阈值时，会自动熔断，阈值可以配置，如下: 

- 一个rolling window内最小的请求数。如果设为20，那么当一个rolling window的时间内 

(比如说1个rolling window是10秒)收到19个请求，即使19个请求都失败，也不会触发 circuit break。默认20 

```
hystrix.command.default.circuitBreaker.requestVolumeThreshold 
```

- 触发短路的时间值，当该值设为5000时，则当触发circuit break后的5000毫秒内都会拒绝request，也就是5000毫秒后才会关闭circuit。默认5000 

```
hystrix.command.default.circuitBreaker.sleepWindowInMilliseconds 
```

如何实现限流？

```java
@HystrixCommand(fallbackMethod = "defaultGreeting"
     groupKey="greetGroup",
     threadPoolKey="greetThreadPool",
     threadPoolProperties={
       @HystrixProperties(name="coreSize"，value="2"),
       @HystrixProperty(name = "maxQueueSize", value = "2"),
	     @HystrixProperty(name = "queueSizeRejectionThreshold", value = "1")
     }           
)
@RequestMapping("/greeting/{username}")
public String getGreeting(@PathVariable("username") String username) throws TimeoutException {
  long executeTime = random.nextInt(2000);
  Thread.sleep(executeTime);
  if (executeTime > 100) { 
    //抛异常，模拟服务不可用
    throw new TimeoutException("Execution is timeout!");
  }
  return greetingService.greeting(username);
}
```

注解配置说明:

- groupKey：配置全局唯一标识服务分组的名称，比如，库存系统就是一个服务分
  组。当我们监控时，相同分组的服务会聚合在一起，必填选项。
- commandKey：配置全局唯一标识服务的名称，比如，库存系统有一个获取库存服务，那么
  就可以为这个服务起一个名字来唯一识别该服务，如果不配置，则默认是简单类名。
- threadPoolKey：配置全局唯一标识线程池的名称，相同线程池名称的线程池是同一个，如
  果不配置，则默认是分组名，此名字也是线程池中线程名字的前缀。
- threadPoolProperties：配置线程池参数， 配置核心线程池大小和线程池最大大 小，keepAliveTimeMinutes是线程池中空闲线程生存时间(如果不进行动态配置，那么是没 有任何作用的)， 配置线程池队列最大大小， 限定当前队列大小，即实际队列大小由这个参数决定，通过 改变queueSizeRejectionThreshold可以实现动态队列大小调整。
- commandProperties：配置该命令的一些参数，如executionIsolationStrategy配置执行隔离策略，默认是使用线程隔离，此处我们配置为THREAD，即线程池隔离。 

此处可以粗粒度实现隔离，也可以细粒度实现隔离：

- 服务分组+线程池：粗粒度实现，一个服务分组/系统配置一个隔离线程池即可，不配置线程池名称或者相同分组的线程池名称配置为一样。
- 服务分组+服务+线程池：细粒度实现，一个服务分组中的每一个服务配置一个隔离线程池，为不同的命令实现配置不同的线程池名称即可。
- 混合实现：一个服务分组配置一个隔离线程池，然后对重要服务单独设置隔离线程池。

**Hystrix相关配置：**

hystrix.command.default和hystrix.threadpool.default中的default为默认CommandKey
Command Properties

Execution相关的属性的配置:

- `hystrix.command.default.execution.isolation.strategy` 隔离策略，默认是Thread, 可选Thread| Semaphore

- `hystrix.command.default.execution.isolation.thread.timeoutInMilliseconds` 命令执行超时时 间，默认1000ms

- `hystrix.command.default.execution.timeout.enabled` 执行是否启用超时，默认启用true

- `hystrix.command.default.execution.isolation.thread.interruptOnTimeout` 发生超时是是否中断， 默认true

- `hystrix.command.default.execution.isolation.semaphore.maxConcurrentRequests` 最大并发请求 数，默认10，该参数当使用ExecutionIsolationStrategy.SEMAPHORE策略时才有效。如果达到最大并发请求 数，请求会被拒绝。理论上选择semaphore size的原则和选择thread size一致，但选用semaphore时每次执行 的单元要比较小且执行速度快(ms级别)，否则的话应该用thread。 semaphore应该占整个容器(tomcat)的线程池的一小部分。

  

Fallback相关的属性
这些参数可以应用于Hystrix的`THREAD`和`SEMAPHORE`策略

- `hystrix.command.default.fallback.isolation.semaphore.maxConcurrentRequests` 如果并发数达到 该设置值，请求会被拒绝和抛出异常并且fallback不会被调用。默认10 
- `hystrix.command.default.fallback.enabled` 当执行失败或者请求被拒绝，是否会尝试调用 hystrixCommand.getFallback() 。默认true

Circuit Breaker相关的属性

- `hystrix.command.default.circuitBreaker.enabled` 用来跟踪circuit的健康性，如果未达标则让 request短路。默认true
- `hystrix.command.default.circuitBreaker.requestVolumeThreshold` 一个rolling window内最小的请 求数。如果设为20，那么当一个rolling window的时间内(比如说1个rolling window是10秒)收到19个请求， 即使19个请求都失败，也不会触发circuit break。默认20
- `hystrix.command.default.circuitBreaker.sleepWindowInMilliseconds` 触发短路的时间值，当该值设 为5000时，则当触发circuit break后的5000毫秒内都会拒绝request，也就是5000毫秒后才会关闭circuit。 默认5000 
- `hystrix.command.default.circuitBreaker.errorThresholdPercentage`错误比率阀值，如果错误率>=该 值，circuit会被打开，并短路所有请求触发fallback。默认50
- `hystrix.command.default.circuitBreaker.forceOpen` 强制打开熔断器，如果打开这个开关，那么拒绝所 有request，默认false
- `hystrix.command.default.circuitBreaker.forceClosed` 强制关闭熔断器 如果这个开关打开，circuit将 一直关闭且忽略circuitBreaker.errorThresholdPercentage

Metrics相关参数

- `hystrix.command.default.metrics.rollingStats.timeInMilliseconds` 设置统计的时间窗口值的，毫秒 值，circuit break 的打开会根据1个rolling window的统计来计算。若rolling window被设为10000毫秒， 则rolling window会被分成n个buckets，每个bucket包含success，failure，timeout，rejection的次数 的统计信息。默认10000
- `hystrix.command.default.metrics.rollingStats.numBuckets` 设置一个rolling window被划分的数 量，若numBuckets=10，rolling window=10000，那么一个bucket的时间即1秒。必须符合rolling window % numberBuckets == 0。默认10
- `hystrix.command.default.metrics.rollingPercentile.enabled` 执行时是否enable指标的计算和跟踪， 默认true
- `hystrix.command.default.metrics.rollingPercentile.timeInMilliseconds` 设置rolling percentile window的时间，默认60000
- `hystrix.command.default.metrics.rollingPercentile.numBuckets` 设置rolling percentile window的numberBuckets。逻辑同上。默认6 
- `hystrix.command.default.metrics.rollingPercentile.bucketSize` 如果bucket size=100，window =10s，若这10s里有500次执行，只有最后100次执行会被统计到bucket里去。增加该值会增加内存开销以及排序 的开销。默认100
- `hystrix.command.default.metrics.healthSnapshot.intervalInMilliseconds` 记录health 快照(用 来统计成功和错误绿)的间隔，默认500ms

Request Context 相关参数

- `hystrix.command.default.requestCache.enabled` 默认true，需要重载getCacheKey()，返回null时不缓存
- `hystrix.command.default.requestLog.enabled` 记录日志到HystrixRequestLog，默认true
  Collapser Properties 相关参数
- `hystrix.collapser.default.maxRequestsInBatch` 单次批处理的最大请求数，达到该数量触发批处理，默认 Integer.MAX_VALUE
- `hystrix.collapser.default.timerDelayInMilliseconds` 触发批处理的延迟，也可以为创建批处理的时间 +该值，默认10
- `hystrix.collapser.default.requestCache.enabled` 是否对HystrixCollapser.execute() and HystrixCollapser.queue()的cache，默认true

ThreadPool 相关参数：

- `hystrix.threadpool.default.coreSize` 并发执行的最大线程数，默认10
- `hystrix.threadpool.default.maxQueueSize` BlockingQueue的最大队列数，当设为-1，会使用 SynchronousQueue，值为正时使用LinkedBlcokingQueue。该设置只会在初始化时有效，之后不能修改 threadpool的queue size，除非reinitialising thread executor。默认-1
- `hystrix.threadpool.default.queueSizeRejectionThreshold` 即使maxQueueSize没有达到，达到 queueSizeRejectionThreshold该值后，请求也会被拒绝。因为maxQueueSize不能被动态修改，这个参数将允 许我们动态设置该值。if maxQueueSize == 1，该字段将不起作用
- `hystrix.threadpool.default.keepAliveTimeMinutes` 如果corePoolSize和maxPoolSize设成一样(默认 实现)该设置无效。如果通过[plugin](https://github.com/Netflix/Hystrix/wiki/Plugins)使用自定义 实现，该设置才有用，默认1
- `hystrix.threadpool.default.metrics.rollingStats.timeInMilliseconds` 线程池统计指标的时间，默 认10000
- `hystrix.threadpool.default.metrics.rollingStats.numBuckets` 将rolling window划分为n个 buckets，默认10

## 3.5、启动类

开启Hystrix：

```java
@SpringBootApplication
@EnableHystrix
public class AppConsumerHystrix {
    public static void main(String[] args) {
        SpringApplication.run(AppConsumerHystrix.class, args);
    }
}
```

## 3.6、配置文件

```yml
server:
  port: 9000

spring:
  application:
    name: consumer-hystrix
```

## 3.7、 测试

浏览器访问 http://localhost:9000/greeting/spring ，不停刷新，可以看到页面时而显示`Hello User!`，这是因为下面代码里直接抛出了异常：

```java
throw new TimeoutException("Execution is timeout!");
```

将代码修改一下，设置超时时间execution.isolation.thread.timeoutInMilliseconds=100，然后让线程休眠随机数毫秒：

```java
@RestController
@Slf4j
public class GreetingController {
    @Autowired
    private GreetingService greetingService;

    private final static Random random = new Random();

    @HystrixCommand(
        commandProperties = { // Command 配置
            // 设置操作时间为 100 毫秒
            @HystrixProperty(name = "execution.isolation.thread.timeoutInMilliseconds", 
            value = "100")
        },
        fallbackMethod = "defaultGreeting" // 设置 fallback 方法
    )
    @RequestMapping("/greeting/{username}")
    public String getGreeting(@PathVariable("username") String username) throws TimeoutException {
        long executeTime = random.nextInt(200);
      	Thread.sleep(executeTime);
        log.info("executeTime: {}", executeTime);
        return greetingService.greeting(username);
    }

    private String defaultGreeting(String username, Throwable throwable) {
        log.info("fallback method");
        return "Hello User!";
    }
}
```

再次测试，查看效果。可以看到当随机数小于100时候，接口返回正常值，否则，调用降级方法，返回`Hello User!`。

## 3.8、断路器HystrixCircuitBreaker

什么是HystrixCircuitBreaker？

HystrixCircuitBreaker可以防止应用程序重复的尝试调用容易失败的依赖服务。HystrixCircuitBreaker的目的和Retry模式的目的是不同的。Retry模式令应用程序不断的去重试调用依赖服务，直到最后成功。而HystrixCircuitBreaker是阻止应用程序继续尝试无意义的请求。

HystrixCircuitBreaker 有三种状态 ：

- 关闭：应用程序的请求已经路由到了这个操作。HystrixCircuitBreaker应该维护最近一段时间的错误信息，如果调用操作失败，那么大力增加这个错误信息的数量。如果这个错误数量超过给定时间的阈值，HystrixCircuitBreaker进入到打开状态。这个时候，HystrixCircuitBreaker启动一个超时的Timer，当Timer过期了，代理则进入半开状态。超时Timer的目的是为了给依赖服务一段时间来自我修复之前碰到的问题。

- 打开：令可能失败的外部调用操作立刻失败，所有的外部调用直接抛异常给应用程序。

- 半开：只有一定数量的应用请求可以进行操作的调用。如果这些请求成功了，那么就假定之前发生的错误已经被依赖服务自动修复了，而HystrixCircuitBreaker转换成关闭状态，同时重置错误计数器。如果任何请求失败了，那么HystrixCircuitBreaker会假定错误仍然在存在，HystrixCircuitBreaker会重新转换成打开状态，并重启超时Timer给依赖服务更多的时间来自我修复错误。 

其中，断路器处于 `OPEN` 状态时，链路处于**非健康**状态，命令执行时，直接调用**回退**逻辑，跳过**正常**逻辑。

HystrixCircuitBreaker 状态变迁如下图 ：

![img](http://www.iocoder.cn/images/Hystrix/2018_11_08/01.png)

- **红线** ：初始时，断路器处于 `CLOSED` 状态，链路处于**健康**状态。当满足如下条件，断路器从 `CLOSED` 变成 `OPEN` 状态：
  - **周期**( 可配，`HystrixCommandProperties.default_metricsRollingStatisticalWindow = 10000 ms` )内，总请求数超过一定**量**( 可配，`HystrixCommandProperties.circuitBreakerRequestVolumeThreshold = 20` ) 。
  - **错误**请求占总请求数超过一定**比例**( 可配，`HystrixCommandProperties.circuitBreakerErrorThresholdPercentage = 50%` ) 。
- **绿线** ：断路器处于 `OPEN` 状态，命令执行时，若当前时间超过断路器**开启**时间一定时间( `HystrixCommandProperties.circuitBreakerSleepWindowInMilliseconds = 5000 ms` )，断路器变成 `HALF_OPEN` 状态，**尝试**调用**正常**逻辑，根据执行是否成功，**打开或关闭**熔断器【**蓝线**】。

# 4、集成Hystrix和Ribbon

参照上面两个章节，将代码合并即可。

# 5、集成Feign调用Rest接口

SpringCloud为Feign默认整合了Hystrix，也就是说只要Hystrix在项目的classpath中， Feign就会使用断路器包裹Feign客户端的所有方法(Dalston及以上版本默认Feign不开启 Hystrix)。这样虽然方便，但有的场景并不需要该功能，如何为Feign开启Hystrix呢? 我们需要通过下面的参数来开启：

```yml
feign:
  hystrix:
    enabled: true # 开启Feign的熔断功能
```

如果要禁用，只需在application.yml中配置feign.hystrix.enabled=false即可。当然，也可以编程指定客户端禁用。

> 请求压缩

Spring Cloud Feign 支持对请求和响应进行GZIP压缩，以减少通信过程中的性能损耗。通过下面的参数即可开启请求与响应的压缩功能：

```yml
feign:
  compression:
    request:
      enabled: true # 开启请求压缩
    response:
      enabled: true # 开启响应压缩
```

同时，我们也可以对请求的数据类型，以及触发压缩的大小下限进行设置：

```yml
feign:
  compression:
    request:
      enabled: true # 开启请求压缩
      mime-types: text/html,application/xml,application/json # 设置压缩的数据类型
      min-request-size: 2048 # 设置触发压缩的大小下限
```

注：上面的数据类型、压缩大小下限均为默认值。

>日志级

可以通过`logging.level.xx=debug`设置日志级别。然而这个对Fegin客户端而言不会产生效果。因为`@FeignClient`注解修改的客户端在被代理时，都会创建一个新的Fegin.Logger实例。我们需要额外指定这个日志的级别才可以。

编写配置类，定义日志级别

```java
@Configuration
public class FeignConfig {
    @Bean
    Logger.Level feignLoggerLevel(){
        return Logger.Level.FULL;
    }
}
```

这里指定的Level级别是FULL，Feign支持4种级别：

- NONE：不记录任何日志信息，这是默认值。
- BASIC：仅记录请求的方法，URL以及响应状态码和执行时间
- HEADERS：在BASIC的基础上，额外记录了请求和响应的头信息
- FULL：记录所有请求和响应的明细，包括头信息、请求体、元数据。

# 6、源代码

源代码在：[spring-cloud-examples](https://github.com/javachen/java-tutorials/tree/master/parent-boot/spring-cloud/spring-cloud-examples-1)。

# 7、参考文章

- [微服务SpringCloud](https://github.com/lyj8330328/Load-Balancing)


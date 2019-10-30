---
layout: post
title: SpringBoot中Tomcat调优
date: 2019-07-26T08:00:00+08:00
categories: [ spring ]
tags: [spring,tomcat]
description:  Spring Boot中Tomcat调优
---

## Spring Boot中Tomcat调优

```yml
server:
  tomcat:
    accept-count: 100   #等待队列长度，默认为100
    max-connections: 10000 #最大可被连接数，默认为10000 
    max-threads: 1000  #最大工作线程数
    min-spare-threads: 10 #最小工作线程数
```

4核8G内存单进程调度线程数800-1000，超过这个并发数之后，将会花费巨大的时间在cpu调度上。

等待队列长度：队列做缓冲池用，但也不能无限长，消耗内存，出入队列也耗cpu。

建议值：

```yml
server:
  tomcat:
    accept-count: 1000
    max-connections: 10000 
    max-threads: 800 
    min-spare-threads: 100 
```

修改keepalivetimeout和maxKeepAliveRequests开启长连接

```java
//当Spring容器内没有TomcatEmbeddedServletContainerFactory这个bean时，会吧此bean加载进spring容器中
@Component
public class WebServerConfiguration implements WebServerFactoryCustomizer<ConfigurableWebServerFactory> {
    @Override
    public void customize(ConfigurableWebServerFactory configurableWebServerFactory) {
            //使用对应工厂类提供给我们的接口定制化我们的tomcat connector
        ((TomcatServletWebServerFactory)configurableWebServerFactory).addConnectorCustomizers(new TomcatConnectorCustomizer() {
            @Override
            public void customize(Connector connector) {
                Http11NioProtocol protocol = (Http11NioProtocol) connector.getProtocolHandler();

                //定制化keepalivetimeout,设置30秒内没有请求则服务端自动断开keepalive链接
                protocol.setKeepAliveTimeout(30000);
                //当客户端发送超过10000个请求则自动断开keepalive链接
                protocol.setMaxKeepAliveRequests(10000);
            }
        });
    }
}
```

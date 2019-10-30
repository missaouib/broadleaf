---
layout: post

title: 使用Spring Boot和Gradle创建AngularJS项目
date: 2015-01-06T08:00:00+08:00

categories: [ spring ]

tags: [ spring,gradle,spring boot,angular.js ]

description: 本文主要是记录快速使用 Spring Boot 和 Gradle 创建 AngularJS 项目的过程。

published: true

---

[Spring Boot](http://projects.spring.io-boot) 是由 Pivotal 团队提供的全新框架，其设计目的是用来简化新 Spring 应用的初始搭建以及开发过程。该框架使用了特定的方式来进行配置，从而使开发人员不再需要定义样板化的配置。

本文主要是记录使用 Spring Boot 和 Gradle 创建项目的过程，其中会包括 Spring Boot 的安装及使用方法，希望通过这篇文章能够快速搭建一个项目。

# 1. 开发环境

- 操作系统: mac
- JDK：1.8
- Spring Boot：2.1.3.RELEASE
- Gradle：2.2.1
- IDE：Idea

# 2. 创建项目

你可以通过 [Spring Initializr](http://start.spring.io/) 来创建一个空的项目，也可以手动创建，这里我使用的是手动创建 gradle 项目。

参考 [使用Gradle构建项目](/images/build-project-with-gradle.html) 创建一个 ng-spring-boot 项目，执行的命令如下：

~~~bash
$ mkdir ng-spring-boot && cd ng-spring-boot
$ gradle init
~~~

ng-spring-boot 目录结构如下：

~~~
➜  ng-spring-boot  tree
.
├── build.gradle
├── gradle
│   └── wrapper
│       ├── gradle-wrapper.jar
│       └── gradle-wrapper.properties
├── gradlew
├── gradlew.bat
└── settings.gradle

2 directories, 6 files
~~~

然后修改 build.gradle 文件：

~~~groovy
buildscript {
    ext {
        springBootVersion = '2.1.3.RELEASE'
    }
    repositories {
        mavenCentral()
    }
    dependencies {
        classpath("org.springframework.boot:spring-boot-gradle-plugin:${springBootVersion}")
    }
}

apply plugin: 'java'
apply plugin: 'eclipse'
apply plugin: 'idea'
apply plugin: 'spring-boot'

jar {
    baseName = 'ng-spring-boot'
    version = '1.0.0-SNAPSHOT'
}
sourceCompatibility = 1.8
targetCompatibility = 1.8

repositories {
    mavenCentral()
    maven { url "https://repo.spring.io/libs-release" }
}

dependencies {
    compile("org.springframework.boot:spring-boot-starter-data-jpa")
    compile("org.springframework.boot:spring-boot-starter-web")
    compile("org.springframework.boot:spring-boot-starter-actuator")
    runtime("org.hsqldb:hsqldb")
    testCompile("org.springframework.boot:spring-boot-starter-test")
}

eclipse {
    classpath {
         containers.remove('org.eclipse.jdt.launching.JRE_CONTAINER')
         containers 'org.eclipse.jdt.launching.JRE_CONTAINER/org.eclipse.jdt.internal.debug.ui.launcher.StandardVMType/JavaSE-1.7'
    }
}

task wrapper(type: Wrapper) {
    gradleVersion = '2.3'
}
~~~

使用 spring-boot-gradle-plugin 插件可以提供一些创建可执行 jar 和从源码运行项目的任务，它还提供了 `ResolutionStrategy` 以方便依赖中不用写版本号。

# 3. 创建一个可执行的类

首先，新建一个符合 Maven 规范的目录结构：

~~~bash
$ mkdir -p src/main/java/com/javachen
~~~

创建一个 Sping boot 启动类：

~~~java
package com.javachen;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;

@Configuration
@EnableAutoConfiguration
@ComponentScan
public class Application {

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}
~~~

main 方法使用了 SpringApplication 工具类。这将告诉Spring去读取 Application 的元信息，并在Spring的应用上下文作为一个组件被管理。

- `@Configuration` 注解告诉 spring 该类定义了 application context 的 bean 的一些配置。

- `@ComponentScan` 注解告诉 Spring 遍历带有 `@Component` 注解的类。这将保证 Spring 能找到并注册 GreetingController，因为它被 `@RestController` 标记，这也是 `@Component` 的一种。

- `@EnableAutoConfiguration` 注解会基于你的类加载路径的内容切换合理的默认行为。比如，因为应用要依赖内嵌版本的 tomcat，所以一个tomcat服务器会被启动并代替你进行合理的配置。再比如，因为应用要依赖 Spring 的 MVC 框架,一个 Spring MVC 的 DispatcherServlet 将被配置并注册，并且不再需要 web.xml 文件。

- 你还可以添加 `@EnableWebMvc` 注解配置 Spring Mvc。

上面三个注解还可以用 @SpringBootApplication 代替：

~~~java
package com.javachen.examples.springboot;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication // same as @Configuration @EnableAutoConfiguration @ComponentScan
public class Application {
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}
~~~

你也可以修改该类的 main 方法，获取 ApplicationContext：

~~~java
package com.javachen;

import java.util.Arrays;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.context.ApplicationContext;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;

@SpringBootApplication 
public class Application {

    public static void main(String[] args) {
        ApplicationContext ctx = SpringApplication.run(Application.class, args);

        System.out.println("Let's inspect the beans provided by Spring Boot:");

        String[] beanNames = ctx.getBeanDefinitionNames();
        Arrays.sort(beanNames);
        for (String beanName : beanNames) {
            System.out.println(beanName);
        }
    }
}
~~~

# 4. 创建一个实体类

创建一个实体类 src/main/java/com/javachen/model/Item.java：

~~~java
package com.javachen.model;

import javax.persistence.*;


@Entity
public class Item {
  @Id
  @GeneratedValue(strategy=GenerationType.IDENTITY)
  private Integer id;
  @Column
  private boolean checked;
  @Column
  private String description;

  public Integer getId() {
    return id;
  }

  public void setId(Integer id) {
    this.id = id;
  }

  public boolean isChecked() {
    return checked;
  }

  public void setChecked(boolean checked) {
    this.checked = checked;
  }

  public String getDescription() {
    return description;
  }

  public void setDescription(String description) {
    this.description = description;
  }
}
~~~

# 5. 创建控制类

创建一个 Restfull 的控制类，该类主要提供增删改查的方法：

~~~java
package com.javachen.controller;

import com.javachen.model.Item;
import com.javachen.repository.ItemRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import javax.persistence.EntityNotFoundException;
import java.util.List;

@RestController
@RequestMapping("/items")
public class ItemController {
  @Autowired
  private ItemRepository repo;

  @RequestMapping(method = RequestMethod.GET)
  public List<Item> findItems() {
    return repo.findAll();
  }

  @RequestMapping(method = RequestMethod.POST)
  public Item addItem(@RequestBody Item item) {
    item.setId(null);
    return repo.saveAndFlush(item);
  }

  @RequestMapping(value = "/{id}", method = RequestMethod.PUT)
  public Item updateItem(@RequestBody Item updatedItem, @PathVariable Integer id) {
    Item item = repo.getOne(id);
    item.setChecked(updatedItem.isChecked());
    item.setDescription(updatedItem.getDescription());
    return repo.saveAndFlush(item);
  }

  @RequestMapping(value = "/{id}", method = RequestMethod.DELETE)
  @ResponseStatus(value = HttpStatus.NO_CONTENT)
  public void deleteItem(@PathVariable Integer id) {
    repo.delete(id);
  }

  @ResponseStatus(HttpStatus.BAD_REQUEST)
  @ExceptionHandler(value = { EmptyResultDataAccessException.class, EntityNotFoundException.class })
  public void handleNotFound() { }
}
~~~

Greeting 对象会被转换成 JSON 字符串，这得益于 Spring 的 HTTP 消息转换支持，你不必人工处理。由于 Jackson2 在 classpath 里，Spring的 `MappingJackson2HttpMessageConverter` 会自动完成这一工作。

这段代码使用 Spring4 新的注解：`@RestController`，表明该类的每个方法返回对象而不是视图。它实际就是 `@Controller` 和 `@ResponseBody` 混合使用的简写方法。

# 6. 创建 JPA 仓库

使用 JAP 来持久化数据：

~~~java
package com.javachen.repository;

import com.javachen.model.Item;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface ItemRepository extends JpaRepository<Item, Integer> {

  @Query("SELECT i FROM Item i WHERE i.checked=true")
  List<Item> findChecked();
}
~~~

Spring Boot 可以自动配置嵌入式的数据库，包括  H2、HSQL 和 Derby，你不需要配置数据库链接的 url，只需要添加相关的依赖即可。另外，你还需要依赖 spring-jdbc，在本例中，我们是引入了对 spring-boot-starter-data-jpa 的依赖。如果你想使用其他类型的数据库，则需要配置 `spring.datasource.*` 属性，一个示例是在 application.properties 中配置如下属性：

~~~properties
spring.datasource.url=jdbc:mysql://localhost/test
spring.datasource.username=dbuser
spring.datasource.password=dbpass
spring.datasource.driver-class-name=com.mysql.jdbc.Driver
~~~

创建 src/main/resources/application.properties 文件，修改 JPA 相关配置，如：

~~~properties
spring.jpa.hibernate.ddl-auto=create-drop
~~~

>注意：
>
>SpringApplication 会在以下路径查找 application.properties 并加载该文件：
>
>- /config 目录下
>- 当前目录
>- classpath 中 /config 包下
>- classpath 根路径下

# 7. 运行项目

可以在项目根路径直接运行下面命令：

~~~bash
$ export JAVA_OPTS=-Xmx1024m -XX:MaxPermSize=128M -Djava.security.egd=file:/dev/./urandom

$ ./gradlew bootRun
~~~

也可以先 build 生成一个 jar 文件，然后执行该 jar 文件：

~~~bash
$ ./gradlew build && java -jar build/libs/ng-spring-boot-1.0.0-SNAPSHOT.jar
~~~

启动过程中你会看到如下内容，这部分内容是在 Application 类中打印出来的：

~~~
Let's inspect the beans provided by Spring Boot:
application
beanNameHandlerMapping
defaultServletHandlerMapping
dispatcherServlet
embeddedServletContainerCustomizerBeanPostProcessor
handlerExceptionResolver
helloController
httpRequestHandlerAdapter
messageSource
mvcContentNegotiationManager
mvcConversionService
mvcValidator
org.springframework.boot.autoconfigure.MessageSourceAutoConfiguration
org.springframework.boot.autoconfigure.PropertyPlaceholderAutoConfiguration
org.springframework.boot.autoconfigure.web.EmbeddedServletContainerAutoConfiguration
org.springframework.boot.autoconfigure.web.EmbeddedServletContainerAutoConfiguration$DispatcherServletConfiguration
org.springframework.boot.autoconfigure.web.EmbeddedServletContainerAutoConfiguration$EmbeddedTomcat
org.springframework.boot.autoconfigure.web.ServerPropertiesAutoConfiguration
org.springframework.boot.context.embedded.properties.ServerProperties
org.springframework.context.annotation.ConfigurationClassPostProcessor.enhancedConfigurationProcessor
org.springframework.context.annotation.ConfigurationClassPostProcessor.importAwareProcessor
org.springframework.context.annotation.internalAutowiredAnnotationProcessor
org.springframework.context.annotation.internalCommonAnnotationProcessor
org.springframework.context.annotation.internalConfigurationAnnotationProcessor
org.springframework.context.annotation.internalRequiredAnnotationProcessor
org.springframework.web.servlet.config.annotation.DelegatingWebMvcConfiguration
propertySourcesBinder
propertySourcesPlaceholderConfigurer
requestMappingHandlerAdapter
requestMappingHandlerMapping
resourceHandlerMapping
simpleControllerHandlerAdapter
tomcatEmbeddedServletContainerFactory
viewControllerHandlerMapping
~~~

你也可以启动远程调试：

~~~bash
$ ./gradlew build 

$ java -Xdebug -Xrunjdwp:server=y,transport=dt_socket,address=8000,suspend=n \
       -jar build/libs-boot-examples-1.0.0-SNAPSHOT.jar
~~~

接下来，打开浏览器访问 <http://localhost:8080/items>，你会看到页面输出一个空的数组。然后，你可以使用浏览器的 Restfull 插件来添加、删除、修改数据。

# 8. 添加前端库文件

这里主要使用 Bower 来管理前端依赖，包括 angular 和 bootstrap。

配置 Bower ，需要在项目根目录下创建 .bowerrc 和 bower.json 两个文件。

.bowerrc 文件制定下载的依赖存放路径：

~~~json
{
  "directory": "src/main/resources/static/bower_components",
  "json": "bower.json"
}
~~~

bower.json 文件定义依赖关系：

~~~json
{
  "name": "ng-spring-boot",
  "dependencies": {
    "angular": "~1.3.0",
    "angular-resource": "~1.3.0",
    "bootstrap-css-only": "~3.2.0"
  }
}
~~~

如果你没有安装 Bower，则运行下面命令进行安装：

~~~
npm install -g bower
~~~

安装之后下载依赖：

~~~
bower install
~~~

运行成功之后，查看 src/main/resources/static/bower_components 目录结构：

~~~
src/main/resources/static/bower_components
├── angular
├── angular-resource
└── bootstrap-css-only
~~~

我们可以将bower_components目录改名为lib，同时修改.bowerrc文件如下：

~~~
{
  "directory": "src/main/resources/static/libs",
  "json": "bower.json"
}
~~~

# 9. 创建前端页面

>注意：
>
>前端页面和 js 存放到 public 目录下，是因为 Spring Boot 会自动在 /static 或者 /public 或者 /resources 或者 /META-INF/resources 加载静态页面。

## 创建 index.html

创建 public 目录存放静态页面 index.html：

~~~html
<!DOCTYPE html>
<html lang="en">
  <head>
    <link rel="stylesheet" href="./lib/bootstrap-css-only/css/bootstrap.min.css" />
  </head>
  <body ng-app="myApp">
    <div class="container" ng-controller="AppController">
      <div class="page-header">
        <h1>A checklist</h1>
      </div>
      <div class="alert alert-info" role="alert" ng-hide="items &amp;&amp; items.length > 0">
        There are no items yet.
      </div>
      <form class="form-horizontal" role="form" ng-submit="addItem(newItem)">
        <div class="form-group" ng-repeat="item in items">
          <div class="checkbox col-xs-9">
            <label>
              <input type="checkbox" ng-model="item.checked" ng-change="updateItem(item)"/> {{item.description}}
            </label>
          </div>
          <div class="col-xs-3">
            <button class="pull-right btn btn-danger" type="button" title="Delete"
              ng-click="deleteItem(item)">
              <span class="glyphicon glyphicon-trash"></span>
            </button>
          </div>
        </div>
        <hr />
        <div class="input-group">
          <input type="text" class="form-control" ng-model="newItem" placeholder="Enter the description..." />
          <span class="input-group-btn">
            <button class="btn btn-default" type="submit" ng-disabled="!newItem" title="Add">
              <span class="glyphicon glyphicon-plus"></span>
            </button>
          </span>
        </div>
      </form>
    </div>
    <script type="text/javascript" src="./lib/angular/angular.min.js"></script>
    <script type="text/javascript" src="./lib/angular-resource/angular-resource.min.js"></script>
    <script type="text/javascript" src="./lib/lodash/dist/lodash.min.js"></script>
    <script type="text/javascript" src="./app/app.js"></script>
    <script type="text/javascript" src="./app/controllers.js"></script>
    <script type="text/javascript" src="./app/services.js"></script>
  </body>
</html>
~~~

## 初始化 AngularJS

这里使用闭包的方式来初始化 AngularJS，代码见 public/app/app.js ：

~~~javascript
(function(angular) {
  angular.module("myApp.controllers", []);
  angular.module("myApp.services", []);
  angular.module("myApp", ["ngResource", "myApp.controllers", "myApp.services"]);
}(angular));
~~~

## 创建 resource factory

代码见 public/app/services.js ：

~~~javascript
(function(angular) {
  var ItemFactory = function($resource) {
    return $resource('/items/:id', {
      id: '@id'
    }, {
      update: {
        method: "PUT"
      },
      remove: {
        method: "DELETE"
      }
    });
  };
  
  ItemFactory.$inject = ['$resource'];
  angular.module("myApp.services").factory("Item", ItemFactory);
}(angular));
~~~

## 创建控制器

代码见 public/app/controllers.js ：

~~~javascript
(function(angular) {
  var AppController = function($scope, Item) {
    Item.query(function(response) {
      $scope.items = response ? response : [];
    });
    
    $scope.addItem = function(description) {
      new Item({
        description: description,
        checked: false
      }).$save(function(item) {
        $scope.items.push(item);
      });
      $scope.newItem = "";
    };
    
    $scope.updateItem = function(item) {
      item.$update();
    };
    
    $scope.deleteItem = function(item) {
      item.$remove(function() {
        $scope.items.splice($scope.items.indexOf(item), 1);
      });
    };
  };
  
  AppController.$inject = ['$scope', 'Item'];
  angular.module("myApp.controllers").controller("AppController", AppController);
}(angular));
~~~

# 10. 测试前端页面

再一次打开浏览器，访问 <http://localhost:8080/> 进行测试。

![](/images/checklist-first-run.png)

# 11. 前后端分离部署

对于AngularJS应用，我们可以使用nodejs或者其他容器部署应用，例如，这里可以使用groovy服务来启动前端服务，然后通过http请求调用后端服务的接口。

先创建app.groovy文件：

~~~groovy
@Controller class JsApp { }
~~~

修改services.js文件中的请求地址为 `http://localhost:8080/items/:id`：

~~~javascript
(function(angular) {
  var ItemFactory = function($resource) {
    return $resource('http://localhost:8080/items/:id', {
      id: '@id'
    }, {
      update: {
        method: "PUT"
      },
      remove: {
        method: "DELETE"
      }
    });
  };
  
  ItemFactory.$inject = ['$resource'];
  angular.module("myApp.services").factory("Item", ItemFactory);
}(angular));
~~~

然后，启动groovy服务来托管静态文件，这里使用9000端口：

~~~
spring run app.groovy -- --server.port=9000
~~~

这时候，就可以服务 http://localhost:9000/ 来查看前端页面了。

这样，前后端就是分别部署属于两个不同的应用了，为了解决跨域的问题，需要添加一个过滤器，如下：

~~~java
package com.javachen.filter;

import org.springframework.stereotype.Component;

import javax.servlet.*;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

@Component
public class SimpleCORSFilter implements Filter {

    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain) throws IOException, ServletException {
        HttpServletResponse response = (HttpServletResponse) res;
        response.setHeader("Access-Control-Allow-Origin", "*");
        response.setHeader("Access-Control-Allow-Methods", "POST, GET, PUT, OPTIONS, DELETE");
        response.setHeader("Access-Control-Max-Age", "3600");
        response.setHeader("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
        chain.doFilter(req, res);
    }

    public void init(FilterConfig filterConfig) {}

    public void destroy() {}

}
~~~

然后，重启应用就可以了。

# 12. 总结

本文主要是记录快速使用 Spring Boot 和 Gradle 创建 AngularJS 项目的过程，并介绍了如何将前后端进行分离和解决跨域访问的问题，希望能对你有所帮助。

文中相关的源码在 [ng-spring-boot](https://github.com/javachen-boot-examples/tree/master/ng-spring-boot)，你可以下载该项目，然后编译、运行代码。

# 13. 参考文章

- [Rapid prototyping with Spring Boot and AngularJS](http://g00glen00b.be/prototyping-spring-boot-angularjs/)
- [Building an Application with Spring Boot](http:/.io/guides/gs-boot/)
- [Building a RESTful Web Service](http:/.io/guides/gs/rest-service/)
- [Enabling Cross Origin Requests for a RESTful Web Service](http:/.io/guides/gs/rest-service-cors)






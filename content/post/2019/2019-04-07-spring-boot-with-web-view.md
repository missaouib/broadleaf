---
layout: post

title: Spring Boot整合视图层
date: 2019-04-07T08:00:00+08:00

categories: [ spring ]

tags: [spring boot]

description:  Spring Boot整合视图层JSP、Freemarker、Thymeleaf。

---

# SpringBoot访问静态资源

1、从classpath/static目录访问静态资源，目录名称必须是static

2、从ServletContext根目录下src/main/webapp访问

3、如果上面都有，则以src/main/webapp为准

# SpringBoot整合JSP

## 1、添加jstl依赖：

```xml
    <dependency>
        <groupId>javax.servlet</groupId>
        <artifactId>jstl</artifactId>
    </dependency>

    <dependency>
        <groupId>org.apache.tomcat.embed</groupId>
        <artifactId>tomcat-embed-jasper</artifactId>
        <scope>provided</scope>
    </dependency>
```

## 2、配置视图

创建springBoot的全局配置文件`application.properties`：

```properties
spring.mvc.view.prefix=/WEB-INF/jsp/
spring.mvc.view.suffix=.jsp
```

## 3、编写Controller返回视图名称

```java
@RestController
public class HelloController {

    @RequestMapping("/hello")
    public Map<String, Object> showHelloWork() {
        Map<String, Object> map = new HashMap<String, Object>();
        map.put("msg", "Hello World ！");
        return map;
    }

    @RequestMapping("/jsp")
    public String test() {
        return "test1";
    }
}
```

上面test方法返回的是视图名称，他会在指定的目录（配置文件中指定的/WEB-INF/jsp/目录）返回test1.jsp文件给前端页面。

## 4、访问浏览器

访问 http://localhost:8080/jsp ，将看到：

```
test jsp
```

# SpringBoot整合Freemarker

## 1、添加Freemarker依赖：

```xml
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-freemarker</artifactId>
    </dependency>
```

## 2、编写视图

springBoot要求模板形式的视图层技术的文件必须要放到src/main/resources目录下必须要一个名称为templates。

创建test2.ftl文件：

```
test freemarker
```

## 3、编写控制类方法

```java
    @RequestMapping("/ftl")
    public String test() {
        return "test2";
    }
```

上面的test方法返回test视图，会到templates找相应的模板文件test2.ftl。

## 4、访问浏览器

访问 http://localhost:8080/ftl ，将看到：

```
test freemarker
```

# SpringBoot整合Thymeleaf

## 1、添加依赖：

```xml
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-thymeleaf</artifactId>
    </dependency>
```

## 2、创建存放视图的目录

创建存放视图的目录src/main/resources/templates

## 3、编写模板文件

Thymelaef是通过他特定语法对html的标记做渲染，所以模板文件都是html文件。

创建test3.html

```html
<span th:text="Hello"></span> <span th:text="${msg}"></span>
```

## 4、编写控制类

```java
    @RequestMapping("/thy")
    public String testThymeleaf(Model model) {
        model.addAttribute("msg", "Thymeleaf第一个案例");
        return "test3";
    }
```

## 5、访问浏览器

访问 http://localhost:8080/thy ，将看到：

```
Hello Thymeleaf第一个案例
```

注意：

使用Thymeleaf之后，视图文件会在src/main/resources/templates查找，这时候访问 http://localhost:8080/jsp 会报错，提示找不到文件。

```java
org.thymeleaf.exceptions.TemplateInputException: Error resolving template "test1", template might not exist or might not be accessible by any of the configured Template Resolvers
```

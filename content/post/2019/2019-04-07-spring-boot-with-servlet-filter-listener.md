---
layout: post

title: Spring Boot整合Servlet、Filter、Listener
date: 2019-04-07T08:00:00+08:00

categories: [ spring ]

tags: [spring boot]

description:  Spring Boot整合Servlet、Filter、Listener有两种方式：一是通过注解扫描完成；二是通过方法完成。

---

Spring Boot整合Servlet、Filter、Listener有两种方式：一是通过注解扫描完成；二是通过方法完成。

# 通过注解扫描完成

主要是用到了三个注解:@WebServlet、@WebFilter、@WebListener，例如，整合Servlet：

```java
/**
 * 在springBoot启动时会扫描@WebServlet，并将该类实例化
 */
@WebServlet(name = "FirstServlet",urlPatterns="/firstServlet")
public class FirstServlet extends HttpServlet
{
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        System.out.println("FirstServlet doGet......");
    }
}
```

整合Filter如下：

```java
@WebFilter(filterName = "FirstFilter", urlPatterns = "/fristFilter")
public class FirstFilter implements Filter {
    @Override
    public void init(FilterConfig filterConfig) throws ServletException {

    }

    public void doFilter(ServletRequest arg0, ServletResponse arg1, FilterChain arg2) throws IOException, ServletException {
        System.out.println("FirstFilter doFilter.......");
    }

    @Override
    public void destroy() {

    }
}
```

整合Listener如下：

```java
@WebListener
public class FirstListener implements ServletContextListener {

    @Override
    public void contextDestroyed(ServletContextEvent arg0) {

    }
    @Override
    public void contextInitialized(ServletContextEvent arg0) {
        System.out.println("FirstListener init......");
    }

}
```

修改启动类，添加@ServletComponentScan注解实现对Servlet组件的扫描：

```java
@SpringBootApplication
@ServletComponentScan
public class App {
    public static void main( String[] args ) {
        SpringApplication.run(App.class, args);
    }
}
```

# 通过方法完成

使用这种方式不需要在Servlet、Filter、Listener上添加注解，其实就是一个普通类。需要做的是通过方法注册bean实体，与之对应的有三个对象：ServletRegistrationBean、FilterRegistrationBean、ServletListenerRegistrationBean，在启动类中创建这三个实体方法如下：

```java
/**
 * spring boot启动类
 */
@SpringBootApplication
@ServletComponentScan
public class App {
    public static void main( String[] args ){
        SpringApplication.run(App.class, args);
    }

    @Bean
    public ServletRegistrationBean getServletRegistrationBean() {
        ServletRegistrationBean bean = new ServletRegistrationBean(new SecondServlet());
        bean.addUrlMappings("/secondServlet");
        return bean;
    }

    @Bean
    public FilterRegistrationBean getFilterRegistrationBean() {
        FilterRegistrationBean bean = new FilterRegistrationBean(new SecondFilter());
        bean.addUrlPatterns("/secondFilter");
        return bean;
    }

    @Bean
    public ServletListenerRegistrationBean<SecondListener> getServletListenerRegistrationBean() {
        ServletListenerRegistrationBean<SecondListener> bean = new ServletListenerRegistrationBean(new SecondListener());
        return bean;
    }
}
```

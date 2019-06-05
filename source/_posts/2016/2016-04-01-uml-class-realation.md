---
layout: post

title: UML类之间关系

category: java

tags: [uml,plantuml]

keywords: uml

description: 前面两篇文章讲到了使用PlantUML来画类图，要想准确地画出类与类之间的关系，必须理清类和类之间的关系。

published: true

---

前面两篇文章讲到了使用PlantUML来画类图，要想准确地画出类与类之间的关系，必须理清类和类之间的关系。类的关系有泛化(Generalization)、实现（Realization）、依赖(Dependency)和关联(Association)，其中关联又分为一般关联关系和聚合关系(Aggregation)、组成关系(Composition)。

# 基本概念

## 类图

类图（Class Diagram）: 类图是面向对象系统建模中最常用和最重要的图，是定义其它图的基础。类图主要是`用来显示系统中的类、接口以及它们之间的静态结构和关系的一种静态模型`。

类图的3个基本组件：类名、属性、方法。 

![](http://plantuml.com:80/plantuml/png/Iyv9B2vM22rEBLAevb9Gq5P8JotnIynDrT24yHnJKefIYukX0iL8qfbv9Gg9wQb0Ld19KMPUka81qApo_A8Khbe0)

## 泛化

泛化(generalization)：表示`is-a`的关系，表示一个对象是另外一个对象的意思，即`继承`的关系。泛化是对象之间耦合度最大的一种关系，子类继承父类的所有细节。例如，自行车是车，猫是动物。

`在类图中使用带三角箭头的实线表示，箭头从子类指向父类。`例如，下图表示猫继承动物。

![](http://plantuml.com:80/plantuml/png/SypBp4tCKR2fqTLLS4ui0G00)

>注意：最终代码中，泛化关系表现为一个类继承一个非抽象类。

在PlantUML中，`泛化`使用`<|--`来表示，例如，上面的类图表示为：

~~~java
Animal <|-- Cat
~~~


## 实现

实现（Realization）:在类图中就是`接口和实现类`的关系。接口定义标准，实现类来实现该标准。例如，跑步是一个接口，人是跑步的实现类，因为人能够跑步。

`在类图中使用带三角箭头的虚线表示，箭头从实现类指向接口。`

![](http://plantuml.com:80/plantuml/png/oymhIIrAIqnELGWgpUC2OWMR6Zqz1O_ItCGy0000)

在PlantUML中，`实现`使用`<|..`来表示，例如，上面的类图表示为：

~~~java
interface Run
Run <|.. Human
~~~ 

## 依赖

依赖(Dependency)：对象之间最弱的一种关联方式，是临时性的`关联`。代码中一般指由`局部变量、函数参数、返回值`建立的对于其他对象的调用关系。一个类调用被依赖类中的某些方法而得以完成这个类的一些职责。

`在类图使用带箭头的虚线表示，箭头从使用类指向被依赖的类。`

![](http://plantuml.com:80/plantuml/png/oymhIIrAIqnELGWjJYqAJYqgoqnEvKhEIImkHXRnp2t8gUPIK02BkIJcAvH2Q91GMNvcYa9nObcg1aWIBAF9LSk5P0WN5v9H2ZOrUdhePdEXyHNqzEp0QW00)

说明：

- UserServiceImpl`实现`了UserService接口
- UserServiceImpl类的save方法`依赖`User对象，因为方法参数类型是User
 
在PlantUML中，`依赖`使用`<..`来表示，例如，上面的类图表示为：

~~~java
interface UserService
class UserServiceImpl{
   UserDao userDao
   void save(User user)
}

class User

UserService <|.. UserServiceImpl
UserServiceImpl ..> User
~~~

## 关联

关联(Association) : 它描述不同类的对象之间的结构关系；它是一种`静态`关系， 通常与运行状态无关，一般由常识等因素决定的；它一般用来定义对象之间静态的、天然的结构； 所以，关联关系是一种`强关联`的关系。这种关系通常使用`类的属性`表达。关联又分为一般关联、聚合关联与组合关联。后两种在后面分析。

比如，乘车人和车票之间就是一种关联关系；学生和学校就是一种关联关系。

`在类图使用带箭头的实线表示，箭头从使用类指向被关联的类。`

![](http://plantuml.com:80/plantuml/png/oymhIIrAIqnELGWjJYqAJYqgoqnEvSf44NL9pETApaaiBaPMuvbRa5FDfQ00Kw5G2bK952hBpqnHA4uiIzK0IO9bDBbgkP0CuU92Cah1faPF3zriBZI-WfwU7KGhkeIkhXtC4G00)

在PlantUML中，`关联`使用`<--`来表示，例如，上面的类图表示为：

~~~java
interface UserService
interface UserDao
class UserServiceImpl{
   UserDao userDao
   void save(User user)
}

class User

UserService <|.. UserServiceImpl
UserServiceImpl ..> User
UserServiceImpl --> UserDao
~~~

关联关系默认不强调方向，表示对象间相互知道；如果特别强调方向，如上图，表示UserServiceImpl知道User，但User不知道UserServiceImpl；

>注意：在最终代码中，关联对象通常是以成员变量的形式实现的；

## 聚合

聚合(Aggregation) : 表示`has-a`的关系，用于表示实体对象之间的关系，表示整体由部分构成的语义；例如一个公司由多个员工组成；与`组合`关系不同的是，整体和部分不是强依赖的，即使整体不存在了，部分仍然存在；例如， 公司倒闭了，员工依然可以换公司，他们依然存在。

`在类图使用空心的菱形表示，菱形从局部指向整体。`

![](http://plantuml.com:80/plantuml/png/Iyv9B2vMSCxFBKZCgwpcKb1GyCaiBh5npIt8oQzCJRLJI8MoYhbgkRYImQfXabnSK7qA-RgwS540)

在PlantUML中，`聚合`使用`o--`来表示，例如，上面的类图表示为：

~~~java
class Company{
   List<Employee> employees
}

class Employee

Company o-- Employee
~~~

## 组合

组合(Composition) : 表示`contains-a`的关系，是一种强烈的包含关系。与聚合关系一样，组合关系同样表示整体由部分构成的语义；比如公司由多个部门组成；但组合关系是一种强依赖的特殊聚合关系，如果整体不存在了，则部分也不存在了；例如公司和部门的关系，没有了公司，部门也不能存在了；调查问卷中问题和选项的关系；订单和订单选项的关系。

`在类图使用实心的菱形表示，菱形从局部指向整体。`

![](http://plantuml.com:80/plantuml/png/Iyv9B2vMSCxFBKZCgwpcKb1GyCaiBh5nIIr8B2h9JSqhiLD8WREBkMgvai4Q4F9SK970qjJYaipyF8GP_WKWlfr2FfX6w8M8m_Jv5wMa5Y4qUPQavjefP099X0QG61SNr8qAMhgwoDR3x0MBGuq6cmaM06a50000)

在PlantUML中，`组合`使用`*--`来表示，例如，上面的类图表示为：

~~~java
class Company{
   List<Department> departments
}
class Department

class Question{
   List<Option> options
}
class Option

class Order{
   List<Item> items
}
class Item

Company *-- Department
Question *-- Option
Order *-- Item
~~~

## 多重性

多重性(Multiplicity) : 通常在`关联`、`聚合`、`组合`中使用。就是代表有多少个关联对象存在。使用`数字..星号（数字）`表示。例如，上面例子中的一个公司有0到多个员工。

![](http://plantuml.com:80/plantuml/png/Iyv9B2vMSCxFBKZCgwpcKb1GyCaiBh5npIt8oQzCJRLJI8MoYhbgkRYImQfXabnSK7qA-RgwIWPwUbfAS3a0)

在PlantUML中，`多重性`使用`0..*`这样的符号来表示，例如，上面的类图表示为：

~~~java
class Company{
   List<Employee> employees
}

class Employee

Company o--"0..*" Employee
~~~


# 聚合和组合的区别

聚合和组合的区别在于：聚合关系是`has-a`关系，组合关系是`contains-a`关系；`聚合关系表示整体与部分的关系比较弱，而组合比较强`；`聚合`关系中代表部分事物的对象与代表聚合事物的对象的生存期无关，一旦删除了聚合对象不一定就删除了代表部分事物的对象。`组合`关系中一旦删除了组合对象，同时也就删除了代表部分事物的对象。

# 总结

对于继承、实现这两种关系没多少疑问，他们体现的是一种类与类、或者类与接口间的纵向关系；其他的四者关系则体现的是类与类、或者类与接口间的引用、横向关系，是比较难区分的，有很多事物间的关系要想准备定位是很难的，前面也提到，这几种关系都是语义级别的，所以从代码层面并不能完全区分各种关系；
 
但总的来说，后几种关系所表现的强弱程度依次为：组合 > 聚合 > 关联 > 依赖。

说明：本文中的类图都是通过<http://plantuml.com/plantuml/>生成。

# 参考文章

- [UML类图与类的关系详解](http://www.uml.org.cn/oobject/201104212.asp)
- [看懂UML类图和时序图](http://design-patterns.readthedocs.org/zh_CN/latest/read_uml.html)


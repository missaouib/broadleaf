---
layout: post

title: PlantUML类图
date: 2016-02-29T08:00:00+08:00

categories: [ java ]

tags: [plantuml,uml]

keywords: plantuml,uml,class diagram

description: 主要介绍如何使用PlantUML的语法生成类图。

published: true

---

# 类之间的关系

PlantUML用下面的符号来表示类之间的关系：

- 泛化，`Generalization`：`<|--`  
- 关联，`Association`：`<--`   
- 组合，`Composition`：`*--`
- 聚合，`Aggregation`：`o--`
- 实现，`Realization`：`<|..` 
- 依赖，`Dependency`：`<..`

以上是常见的六种关系，`--`可以替换成`..`就可以得到虚线。另外，其中的符号是可以改变方向的，例如：`<|--`表示右边的类泛化左边的类；`--|>`表示左边的类泛化右边的类。

例如，下面的是`--`：

~~~
@startuml

Class01 <|-- Class02:泛化
Class03 <-- Class04:关联
Class05 *-- Class06:组合
Class07 o-- Class08:聚合
Class09 -- Class10

@enduml
~~~

生成的类图如下：

![](http://plantuml.com:80/plantuml/png/Syv9B2usC5ImgT7LLN06SuoidcsU_RHd6XU4QwnW0vSoiNhQklb5unIebAc25bpApEhvxfQd4pgWKkOA-N0f2wiNZRCGKfOAC1b30m00)

`--`可以替换成`..`，对应的虚线：

~~~
@startuml

Class11 <|.. Class12:实现
Class13 <.. Class14:依赖
Class15 *.. Class16
Class17 o.. Class18
Class19 .. Class20

@enduml
~~~

生成的类图如下：

![](http://plantuml.com:80/plantuml/png/Syv9B2usD5ImgT7JKt06SuoidgwRzxnl0nU4QwnW0vSoiNgoR-wBhTEWKgOAMd0fCwYOkK8-NCm2AcQf01CoCW00)

# 关系上的标签

可以在关系上添加标签，只需要在文本后面添加冒号和标签名称即可。可以在关联的两边使用双引号。例如：

~~~java
@startuml

Class01 "1" *-- "many" Class02 : contains
Class03 o-- Class04 : aggregation
Class05 --> "1" Class06

@enduml
~~~

生成的类图如下：

![](http://plantuml.com:80/plantuml/png/Syv9B2usC5HGCbHIqDBLLL3AJSohL59m1WiRALWf9EVdbIHcvXLpGOIC5VA1gY1i4w1qOdfwKMfwOabcVXvKXQc2hguTs3m8tmm0)

你可以在关系上使用`<`或者`>`表名两个类之间的关系，例如：

~~~java
@startuml

class Car

Driver - Car : drives >
Car *- Wheel : have 4 >
Car -- Person : < owns

@enduml
~~~

生成的类图如下：

![](http://plantuml.com:80/plantuml/png/Iyv9B2vMS4uiuk9oASeiIorIq0Nn5AmKKa3SOWKxBX1NIrSXF2CrDGSedf5ObgfW0XNNrLK8I2qgpiy3IjWev9Vd5NC10000)

上面的类图意思是：

- Driver 驾驶 Car
- Car 有4个 Wheel
- Person 拥有 Car

# 添加方法

在类名后面添加冒号可以添加方法和方法的参数，例如：

~~~java
@startuml

Object <|-- ArrayList

Object : equals()
ArrayList : Object[] elementData
ArrayList : size()

@enduml
~~~

生成的类图如下：

![](http://plantuml.com:80/plantuml/png/yq_AIaqkKR2fqTLLS2mgIgpqoImkuUBoXmXRAQGMbYRc56jeSi4bWO8GsUXOXTISrDpKl1ANn99450N5cLMfG3q0)

也可以使用{}来定义所有的字段及字段和方法，例如：

~~~java
@startuml
class Dummy {
  String data
  void methods()
}

class Flight {
   flightNumber : Integer
   departureTime : Date
}
@enduml
~~~

生成的类图如下：

![](http://plantuml.com:80/plantuml/png/7Oj13eCm30JlViKUsozmHfLwwGK-O8WR8c50ZeE4AluEpMrMipFEd3FQedhWHq3dbfQ8mCxtsjSKeEBJ6lBZIIVHMF-lESN9Qu1lvK_HGGmDtejB5FkR81kR5vC-gTogPHSwBm00)

# 定义可见性

以下符号定义字段或者方法的可见性：

- `-`：`private`
- `#`：`protected`
- `~`：`package private`
- `+`：`public`

例如：

~~~java
@startuml

class Dummy {
 -field1
 #field2
 ~method1()
 +method2()
}

@enduml
~~~

![](http://plantuml.com:80/plantuml/png/Iyv9B2vMS2dDpQrKgEPIq4tBJCr9CUHIK0OpZBWKwd9JIpBoKmmrDBaKj25i8o2xbWi0)

你可以使用skinparam classAttributeIconSize 0关掉icon的显示：

~~~java
@startuml
skinparam classAttributeIconSize 0
class Dummy {
 -field1
 #field2
 ~method1()
 +method2()
}

@enduml
~~~

![](http://plantuml.com:80/plantuml/png/AyxEp2j8B4hCLKZEIImkTYmfASfCAYr9zKpEpmlEh4fLCE02IoYubERcLYfKSodefcMcvgGOSYaeWnb6N0frkQab6VafXXgQN0hQ4BOHa5tB1G00)

# 抽象和静态

你可以使用`{static}`或者`{abstract}`来修饰字段或者方法，修饰符需要在行的开头或者末尾使用。你也可以使用`{classifier}`代替`{static}`。

~~~java
@startuml
class Dummy {
  {static} String id
  {classifier} String name
  {abstract} void methods()
}
@enduml
~~~

![](http://plantuml.com:80/plantuml/png/FSh13O0W34RXErFyHzt33PoW5jGc5X9QJGnXTyF5w_iUNsI6vLPzqGBGpCc5ErQlaWz879779Rka-aCcJODeCw_4tl4KYT3aPuaspQ5_)

# 类主体

默认的，字段和方法是由PlantUML自动分组的，你也可以使用`: -- .. == __`这些分隔符手动进行分组。

~~~java
@startuml
class Foo1 {
  You can use
  several lines
  ..
  as you want
  and group
  ==
  things together.
  __
  You can have as many groups
  as you want
  --
  End of classes
}

class User {
  .. Simple Getter ..
  + getName()
  + getAddress()
  .. Some setter ..
  + setName()
  __ private data __
  int age
  -- encrypted --
  String password
}

@enduml
~~~

![](http://plantuml.com:80/plantuml/png/PO-nQiH034HxVyMK2U4C-O0hKYJfqXnNf3B2gzWBzkwoadsOSFz-sZK1GngX4PhHKp-H23vYVCLl0tp71Jq5BCAcX5VED67oWSLqsreXmMPRDmfQL70OSboIzUUp5Hrz60GQ1zQHSt5qtI5vf9LBnanXsvtoB_Hqil9koV47VG6qw_UcgIskmhcojYqkVauJuvDLRLZnNc27lsZcf-S_zUPSPf4wAAOuixrsjCZ1qdL8sQ-a34TAExqF2Xguie53dxUax7RGYsPx6SdWRZ4x8tq0)

# 注释和原型

原型使用`class`、`<<`和`>>`进行定义。

注释使用`note left of`、`note right of`、`note top of`、`note bottom of`关键字进行定义。

你也可以在最后一个定义的类上使用`note left`、`note right`、`note top`、`note bottom`关键字。

注释可以使用`..`与其他对象进行连接。

~~~
@startuml
class Object << general >>
Object <|--- ArrayList

note top of Object : In java, every class\nextends this one.

note "This is a floating note" as N1
note "This note is connected\nto several objects." as N2
Object .. N2
N2 .. ArrayList

class Foo
note left: On last defined class

@enduml
~~~

![](http://plantuml.com:80/plantuml/png/JOx12eD034JlViNWkGhrA2BqKYWKlVJePQlHAf8KDqY5VdntjO8GI7QIsNdrQAn5-HoeLcGPEcAQp8Wy3tRn6qKHBjDabdjlDGXObA3oXhIxCSMDCPZPd40pJGjg_st5z57Yna9VlOKmnNzt-F22AuDs5ACzT_2B4CQYE1-Frj7rMfXT53KLgy3w68SfQxwDDsEoCyUnVnI97mxaAnMk8bl0IAscA1bELZJKzapDXXxy0000)

# 注释的其他特性

注释可以使用一些html标签进行修饰：

- `<b>`
- `<u>`
- `<i>`
- `<s>`, `<del>`, `<strike>`
- `<font color="#AAAAAA">` 或者 `<font color="colorName">`
- `<color:#AAAAAA>` 或者 `<color:colorName>`
- `<size:nn>` 该表font大小
- `<img src="file">` 或者 `<img:file>`，文件必须是可以访问的。

~~~
@startuml

class Foo
note left: On last defined class

note top of Object
  In java, <size:18>every</size> <u>class</u>
  <b>extends</b>
  <i>this</i> one.
end note

note as N1
  This note is <u>also</u>
  <b><color:royalBlue>on several</color>
  <s>words</s> lines
  And this is hosted by <img:sourceforge.jpg>
end note

@enduml
~~~

![](http://plantuml.com/imgp/classes_011.png)

# 连接上的注释

可以在连接上定义注释，只需要使用`note on link`，你可以使用`note left on link`、`note right on link`、`note top on link`、`note bottom on link`来改变注释的位置。

~~~
@startuml

class Dummy
Dummy --> Foo : A link
note on link #red: note that is red

Dummy --> Foo2 : Another link
note right on link #blue
    this is my note on right link
    and in blue
end note

@enduml
~~~

![](http://plantuml.com:80/plantuml/png/LOqn2iCm34Ndw1GVCcVfcA5GABs7quZOn971LeRUlefAIGj2IEAzhsSEhU6-RzkBl6COhdYKWX4tv2GhIL564L_GLvv7-4bZKAG6kz2_UpbaOoBNduYQbgXdq9HtfawZ9LYP_FtpuTphWin80cVPveEXDm00)

# 抽象类和接口

可以使用`abstract`或者`interface`来定义抽象类或者接口，也可以使用`annotation`、`enum`关键字来定义注解或者枚举。

~~~java
@startuml

abstract class AbstractList
abstract AbstractCollection
interface List
interface Collection

List <|-- AbstractList
Collection <|-- AbstractCollection

Collection <|- List
AbstractCollection <|- AbstractList
AbstractList <|-- ArrayList

class ArrayList {
  Object[] elementData
  size()
}

enum TimeUnit {
  DAYS
  HOURS
  MINUTES
}

annotation SuppressWarnings

@enduml
~~~

![](http://plantuml.com:80/plantuml/png/POzF2u904CNlyodcM0U_GPV8eA0IKec83gDCiQ6ZxAw7_dttT5LKEWtllT-ysQN4M4sfnJGZOt3PoPqo5gZFUdTLP1cdLXK2IYph6wMC3XtaY84cmiN7ywQz0p8DnwjJfZtopxbiqZqMNRlMz7GPT7_i3Nm3Of0ywgxB5JdZdCNwPAcsZNhnR0vV09OgnqZb78jgL_pbEQp79eYFpTnl3t6q3XkMH0fBxcLXLPQQZJcH5YLt0py0)

# 使用非字母

类名可以使用非字母的方式显示：

~~~
@startuml
class "This is my class" as class1
class class2 as "It works this way too"

class2 *-- "foo/dummy" : use
@enduml
~~~

![](http://plantuml.com:80/plantuml/png/Iyv9B2vMK0h9o2nM0ABSIeLaa8YIGc8nX6N81QOW72EGi99dYK9vVb5siK89I5TvOgL2INw-4XSNL8cMhgw2Kbf-ldvAQMvkfPA2bK9fSIe0)

# 隐藏字段和方法

~~~java
@startuml

class Dummy1 {
  +myMethods()
}

class Dummy2 {
  +hiddenMethod()
}

class Dummy3 <<Serializable>> {
    String name
}

hide members
hide <<Serializable>> circle
show Dummy1 methods
show <<Serializable>> fields

@enduml
~~~

![](http://plantuml.com:80/plantuml/png/POun3i8m34LdSWgF82RAMdLYPUe9qiGGItOgnKMeLDoT80inPFp-xra_i5U5oqDaFS7c08woNd59SzJzmRsT2t-WCo1HZ9WDQfWpzFs8XJpJoq-Cmr2btRWKodV8Nl3Brmy8WZ9XKGkD5AW4HgTfVlxMYSsoMoFS2BcM7m00)

# 隐藏类

~~~java
@startuml

class Foo1
class Foo2

Foo2 *-- Foo1

hide Foo2

@enduml
~~~

![](http://plantuml.com:80/plantuml/png/Iyv9B2vMSClFD-HAXZ6DkBX0f8AMhYv4XYiZCoKL8WC0)

# 使用泛型

~~~java
@startuml

class Foo<? extends Element> {
  int size()
}
Foo *- Element

@enduml
~~~

![](http://plantuml.com:80/plantuml/png/Iyv9B2vMSClFjx5NIAqeISrBALPmpKdDJSqhiLEevb9GoCmhKIZEh4hLqEIgvGAgKz3IXIdW0W00)

# 包

~~~java
@startuml

package "Classic Collections" #yellow{
  Object <|-- ArrayList
}

package net.sourceforge.plantuml {
  Object <|-- Demo1
  Demo1 *- Demo2
}

@enduml
~~~

![](http://plantuml.com:80/plantuml/png/AqXCpavCJrLGSiv9B2xEJ5Pmpi_9IKqkoSpFArPIKAvCpSd9Bw_cKb3mJye22YlOrEZgAZWM5ILM-cGMbt3LSd4LG4t8IotHAyulBKfEJSilIa_LAyX9p2ifpSrHGDVjafgRRmWK0zCAMX018w1H0000)

包可以设置样式，也可以使用`skinparam packageStyle`设置为默认样式。

~~~java
@startuml
scale 750 width
package foo1 <<Node>> {
  class Class1
}

package foo2 <<Rect>> {
  class Class2
}

package foo3 <<Folder>> {
  class Class3
}

package foo4 <<Frame>> {
  class Class4
}

package foo5 <<Cloud>> {
  class Class5
}

package foo6 <<Database>> {
  class Class6
}

@enduml
~~~

![](http://plantuml.com:80/plantuml/png/AqvEp4bLC3SrK2ZFJ2d9u2f8JCvEJ4zLIClFDrImiV7BJqcrirEevb9GICv9B2vMS0QHXborNCWgZO0gWrAJIp1L6g6fD0QgTClFIKajmbHhZARM1AIsA34NYmDCq9IQ0fKwv-INfc0gDKLJQWPKwf9OafYKM8p5O3EWQW00)

也可以在包之间设置联系：

~~~java
@startuml

skinparam packageStyle rect

package foo1.foo2 {
}

package foo1.foo2.foo3 {
  class Object
}

foo1.foo2 +-- foo1.foo2.foo3

@enduml
~~~

![](http://plantuml.com:80/plantuml/png/AyxEp2j8B4hCLIX8JCvEJ4yDBgdCILKeIaqkuUA22YcavUSRwW498uLghbeimY3262Yde92SarXShE2Vb0NI3rIAqAcjgukcWGi0)

# 命名空间

命名空间内使用默认的类，需要在类名前加上`点`。

~~~java
@startuml

class BaseClass

namespace net.dummy #DDDDDD {
    .BaseClass <|-- Person
    Meeting o-- Person
    
    .BaseClass <|- Meeting
}

namespace net.foo {
  net.dummy.Person  <|- Person
  .BaseClass <|-- Person

  net.dummy.Meeting o-- Person
}

BaseClass <|-- net.unused.Person

@enduml
~~~

![](http://plantuml.com:80/plantuml/png/Iyv9B2vMS4eiJdK6iRYuyX9pKuiB4fDJ5V9II_HIIdDpAnMKNS10ePfB0GZquAeLR6fqTHK2KekAy_F0KhwfgIMPUUaA-QZ2MBJ1b7BLebkPbfyFjWXklHx490MmDhYfE5o1eX6BSu3MeMa4AI_DAorEJO5Qn0K0)

命名空间可以自动设置，通过`set namespaceSeparator ???`设置命名空间分隔符，使用`set namespaceSeparator none`可以关闭自动设置命名空间。

~~~java
@startuml

set namespaceSeparator ::
class X1::X2::foo {
  some info
}

@enduml
~~~

![](http://plantuml.com:80/plantuml/png/AqujKSXBp4qjBaXCJWrEBKWiIYp9BrAmik9ApaaiBbQ8CBIoYZ2oiahBprUevb9GACxFJLN8p4lBvwhb0W00)

# 改变箭头方向

~~~java
@startuml
Room o- Student
Room *-- Chair
@enduml
~~~

![](http://plantuml.com:80/plantuml/png/2yhFprN8rrK8BYbDISqhuGe2yRLqTHMSCn8pYm00)

换个方向：

~~~java
@startuml
Student -o Room
Chair --* Room
@enduml
~~~

![](http://plantuml.com:80/plantuml/png/2oufJKdDAr7GpLS8oi_FvNBEICmiKj3LrG9p0G00)

也可以在箭头上使用left, right, up or down关键字：

~~~java
@startuml
foo -left-> dummyLeft 
foo -right-> dummyRight 
foo -up-> dummyUp 
foo -down-> dummyDown
@enduml
~~~

![](http://plantuml.com:80/plantuml/png/IylFLz3DIKqhqRLJI2dDpQtq0R8LkD90maMPwHbmyI0G1ofHMW0J3Is02gNab-V115s0R000)

这些关键字可以使用开头的几个字符简写，例如，使用`-d-`代替`-down-`。

# 标题

使用`title`或者`title end title`。

~~~java
@startuml

title Simple <b>example</b>\nof title 
Object <|-- ArrayList

@enduml
~~~

![](http://plantuml.com:80/plantuml/png/AyaioKbL2CxCBG1IDabsgHM98AQDVf9TJ5v-ca89M9xBFoahDRb4mQP6LrV1iQWeiT8dixY42m00)

# 设置Legend

~~~java
@startuml

Object <|- ArrayList

legend right
  <b>Object</b> and <b>ArrayList</b>
  are simple class
endlegend

@enduml
~~~

![](http://plantuml.com:80/plantuml/png/yq_AIaqkKR2fqLLmB2fAhFJ9B2xXuif9JK_DIr4eoapFAE5IKB19ilC7gxFHJx9JI0JA04NWoa62G4M9HQaAnPcv1Jcf2iavYSN5N40J8EPm0G00)

# 关联类

一个类和两个类有关联时设置关系：

~~~java
@startuml
class Student {
  Name
}
Student "0..*" - "1..*" Course
(Student, Course) .. Enrollment

class Enrollment {
  drop()
  cancel()
}
@enduml
~~~

![](http://plantuml.com:80/plantuml/png/Iyv9B2vM22ufJKdDAr6evb9Gy4lCJUMgvO89AHdewMafAUWgA1c26SxvfKN5gLmQK7aTg82cWfwUWcjUKNvEJYvGc8ih6MmmGWHiTafHVe669f2Hd9YNd9e3PDO20000)

换一个方向：

~~~java
@startuml
class Student {
  Name
}
Student "0..*" -- "1..*" Course
(Student, Course) . Enrollment

class Enrollment {
  drop()
  cancel()
}
@enduml
~~~

![](http://plantuml.com:80/plantuml/png/Iyv9B2vM22ufJKdDAr6evb9Gy4lCJUMgvO89AHdewMafAUZgAYWPWbdE-QL5nQbS6b05Eb01JGKz1TUyeloSd5oWA1TNCjXWX0ZOx9IY_08DJI0ZEJ4lEJK7oAm50000)

# 其他

还有一些特性，如设置皮肤参数、颜色、拆分大文件等等，请参考[官方文档](http://zh.plantuml.com/classes.html)。

# 例子

一个完整的例子：

~~~
@startuml 

title class-diagram.png
scale 1.5
/'组合关系(composition)'/
class Human {
    - Head mHead;
    - Heart mHeart;
    ..
    - CreditCard mCard;
    --
    + void travel(Vehicle vehicle);
}

Human *-up- Head : contains >
Human *-up- Heart : contains >

/'聚合关系(aggregation)'/
Human o-left- CreditCard : owns >

/'依赖关系(dependency)'/
Human .down.> Vehicle : dependent

/'关联关系(association'/
Human -down-> Company : associate

/'继承关系(extention)'/
interface IProgram {
    + void program();
}
class Programmer {
    + void program();
}
Programmer -left-|> Human : extend
Programmer .up.|> IProgram : implement
@enduml
~~~

![](http://plantuml.com:80/plantuml/png/VPA_JiCm4CPtFyLjRK5nnS2IIbcwb8s9tRAlmL9iHuvRg82X4aYmCI0696OUe6Ag12y3j8-14plzmq06MxhxVkVlxkAaAn1umQeg4PBbbYbQwfnKdFdu4Jqc_SvgUVlzUFzzjrWjbbrkL6agwQJHlKwVD2IC9effk2BWlmH6o0Ie-Xni8zOr8Uj2ZDAO6beKqWsPzKXzHYHfhaEO6Yd0MJR5edk6vv9xLzDmzmRaXf3mz44oAUF3AN2Z7PEwWknlrflOI_lcrlENRNCipotch6qkq2OfSEpsdAPWBje2Nn-lw_VdM41WYLgWvhCjJuKNqmnQ-ocqAbVpdbpFdre3LMMuR0ni-AJcamo6Vl9CpppVgf0qstdxUVYCF5uwNpRQbzgX7JEES79gJRtQkA8urZ84kyqWmoAZJg7zHxeZ2gEvpk8Va49ZGEnAwAIaNh2na89KPO7A-_m5)

下面例子，参考自[Class Diagram](https://avono-support.atlassian.net/wiki/display/PUML/Class+Diagram)。

## Java集合类图

~~~java
@startuml
abstract class AbstractList
abstract AbstractCollection
interface List
interface Collection
  
List <|-- AbstractList
Collection <|-- AbstractCollection
  
Collection <|- List
AbstractCollection <|- AbstractList
AbstractList <|-- ArrayList
  
ArrayList : Object[] elementData
ArrayList : size()
  
enum TimeUnit
TimeUnit : DAYS
TimeUnit : HOURS
TimeUnit : MINUTES
@enduml
~~~

![](http://plantuml.com:80/plantuml/png/POt12e9048Rl-nHph8Cl45qaWu9II3r4T1YN2JRM5NQdGz73fwRfq6s--R_v1wl07ZM3jXW2n0CUJ625OpPkDusrfDaqJXd7v6-e2Nfrmfa3eBeGrkyeaisJ94DvBAtlet-ppqJx78P-x_7PPstj3s05MNLlMovN84irEKwGKGZ1l6YnxCx8FMeeJ4sbCwp6eLMI-9pFUPUL9x4uxjEosEOV)

## 类和接口

~~~java
@startuml
Object -- AbstractList
  
class ArrayList extends Object {
  int size
}
  
interface List extends Collection {
  add()
}
  
interface Set extends Collection
  
class TreeSet implements SortedSet
@enduml
~~~

![](http://plantuml.com:80/plantuml/png/RSuz3i8m38RXFQVm24CFKR4YTIWNS9CFoIXDaEs17t5t4XWGYD6VtaVoj9mGdOQ1niLSEVfUp0DHY9dDQ5JbQvy85qT9HjDRt5iZnSdaXl3ee5tG8qVGLx-hEJSWjRmCfxJP_e8P__hF5mS5UYFhEMD5SQEvgYEryGa0)

## Repository接口

~~~java
@startuml
package framework <<Folder>>{
 
    interface BasicRepository {
        E find(Object pk);
        List<E> findAll();
        void save(E entity);
        void update(E entity);
        void remove(E entity);
    }
     
    class AbstractHibernateRepository << @Repository >> {
        -EntityManager entityManager;
    }
 
}
 
interface PartnerRepository {
 
    List<PartnerEntity> findByFoo(...);
    List<PartnerEntity> search(String pattern, int maxResult);
 
}
 
class HibernatePartnerRepository << @Repository >> {
 
}
 
class InMemoryPartnerRepository {
 
}
  
BasicRepository <|.. PartnerRepository
BasicRepository <|.. AbstractHibernateRepository
AbstractHibernateRepository <|-- HibernatePartnerRepository
PartnerRepository <|.. HibernatePartnerRepository
PartnerRepository <|.. InMemoryPartnerRepository
@enduml
~~~

![](http://plantuml.com:80/plantuml/png/bPBRQi9048RlzodcCeMQ5sW8LOYqK6cnJp1kHhicxeRPqJPetxqvaQOQXIviOFddzFsJ0dM66u8ruuu-7MSGHNENfyHnV5IWe3h62l4QDS4ClT5BAfmtuhY4OwFN9u6riMdmkjgI5YYokuTUUZ5UeYHk0gPv7WoaWpCfU3nGa01PCLAUY_iYHRakC-tSPVPt6zHyTOxUmtJbXL7BaraHswhY02AAu77mZEC1rYHfwYxGLYPnrwLxzRrKVNzDUaCMI_pN9jKxqSbjuTQLMJbtBWZ3i9j_BCuJilu8teMDtK21KhMpz_LkO8TVI_BxNEhqPfWMkeUzd6YKUP3wR1ULiroEizJ-glD_8Jg5uINxUDYDTQYRgpfD9ZUmr0XetUx_6LVvVm00)

## Java异常层次

~~~java
@startuml

namespace java.lang #DDDDDD {
    class Error << unchecked >>
    Throwable <|-- Error
    Throwable <|-- Exception
    Exception <|-- CloneNotSupportedException
    Exception <|-- RuntimeException
    RuntimeException <|-- ArithmeticException
    RuntimeException <|-- ClassCastException
    RuntimeException <|-- IllegalArgumentException
    RuntimeException <|-- IllegalStateException
    Exception <|-- ReflectiveOperationException
    ReflectiveOperationException <|-- ClassNotFoundException
}
  
namespace java.io #DDDDDD {
    java.lang.Exception <|-- IOException
    IOException <|-- EOFException
    IOException <|-- FileNotFoundException
}
  
namespace java.net #DDDDDD {
    java.io.IOException <|-- MalformedURLException
    java.io.IOException <|-- UnknownHostException 
}
@enduml
~~~

![](http://plantuml.com:80/plantuml/png/bP9HJiCm38RVUuf8FAydg2PDXGeaeDB63c1IhmrBx2frDoJOtUbQDBLbbE8tv_-S-BT3uB0gGQDwWmE45YXNDxTjg8z0DQ4jL9MwyvwzYY9LaovGxp5JosMhlnIUZ_1gKKMVYqK7NXNUDPPYc5hnadLYR9dmcMLJboLxmMoINjSank6G6HzswCeRAHoAqNFe-EmrXahcm0_MOWvsvVFQ8VsdP2CWEEqGTnQrc0Ec9Neu2wFx9u2UbsQa2TVK6-UfAGzek7N3evrV_a8uDf0Es-ZbtrjEap-8n5YSrnQXNElBSFZZqYUmE_OEi-twSVZ-hoLRsXCVwPvxsrR1wGi0)

# 参考文章

- [PlantUML Classes](http://zh.plantuml.com/classes.html)
- [Class Diagram](https://avono-support.atlassian.net/wiki/display/PUML/Class+Diagram)

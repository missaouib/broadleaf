---
layout: post

title:  Groovy语法介绍

description: 本文主要整理一下 Groovy 的一些基本语法。Groovy 是基于 JRE 的脚本语言，和Perl，Python等等脚本语言一样，它能以快速简洁的方式来完成一些工作：如访问数据库，编写单元测试用例，快速实现产品原型等等。

keywords:  

category:  java

tags: [groovy]

published: true

---

# 1. 介绍

Groovy 是基于 JRE 的脚本语言，和Perl，Python等等脚本语言一样，它能以快速简洁的方式来完成一些工作：如访问数据库，编写单元测试用例，快速实现产品原型等等。

Groovy 是由James Strachan 和 Bob McWhirter 这两位天才发明的（JSR 241 2004 年 3 月）。Groovy 完全以Java API为基础，使用了Java开发人员最熟悉的功能和库。Groovy 的语法近似Java，并吸收了 Ruby 的一些特点，因此 Groovy 在某些场合可以扮演一种 “咖啡伴侣”的角色。   

官网地址：<http://groovy.codehaus.org/>

Groovy的主要特性： 

- Closure（闭包）的支持
- 本地的 List 和 Map 语法 
- Groovy 标记：支持多种标记语言，如 XML、HTML、SAX、W3C DOM
- Groovy Path 表达式语言：类似 Xpath 
- Groovlet：用简单的 Groovy 脚本实现 Servlet
- Groovy SQL：使得和 SQL 一起工作更简单
- Groovy Bean：和 Bean 一起工作的简单语法
- Groovy模版引擎：简单使用，集成了 Gpath 和编译成字节码
- Ant 脚本化 
- 正则表达式：简洁的脚本语法使用正则表达式 
- 操作符重载：使 Collection 和 Map 的数据类型简单化
- 多形式的 iteration 和 Autoboxing 
- 直接编译成 Java 字节码，很干净的和所有已存在的 Java 对象和类库一起工作

Groovy 可以作为 javac 的一种可选编译器来生成标准的 Java 字节码，在任何 Java 工程 中使用。Groovy 可以作为一种动态的可选语言，如脚本化 Java对 象、模版化、编写单元测试用例。

工具介绍： 

- Groovy ：运行 groovy 脚本文件。 
- Groovyc：编译 groovy 脚本成 java 的 bytecode 文件（.class） 
- Groovysh：运行命令行的控制台，可以输入 groovy 语句直接执行
- GroovyConsole：GUI 形式的控制台，相当于简单的编辑器

# 2. 使用

使用压缩包安装，下载地址为 <http://groovy.codehaus.org/Download>，下载然后解压配置环境变量。

在 mac 上安装 groovy：

~~~
brew install groovy
~~~

Groovy 脚本可以直接用 Groovy 解析执行：

~~~
groovy hello.groovy
~~~

编译为字节码：

~~~
groovyc -d classes hello.groovy
~~~

运行编译好的groovy脚本：

~~~
java -cp %GROOVY_HOM E%/embeddable/groovy-all.jar;classes hello
~~~

你会发现其实就是运行 java 的 class 文件。

# 3. 语法

Groovy 的语法融合了 Ruby、Python 和 Smalltalk 的一些最有用的功能，同时保留了基于 Java 语言的核心语法。对于Java 开发人员，Groovy 提供了更简单的替代语言，且几乎不需要学习时间。

Groovy在语法上跟java有几点不同：

- Groovy中，”= =”等同于java中的equals方法；”= = =”等同于java中的”= =”。
- Groovy中缺省的标志符是public。

## 3.1 关键字

在 Groovy 可以用 def 定义无类型的变量(定义变量方面 def 与 JavaScript 中的 var 相似)，和返回值为无类型的方法 

~~~groovy
class Man {
  def name = "javachen"
  def introduce() {
    return "I'm $name" // return可以省略
  }
}
~~~

## 3.2 语句

Groovy的语句和Java类似，但是有一些特殊的地方。例如语句的分号是可选的。如果每行一个语句，就可以省略分号；如果一行上有多个语句，则需要用分号来分隔。

另外return关键字在方法的最后是可选的；同样，返回类型也是可选（缺省是Object）。  

调用方法时可以不用括号，只要有参数，并且没有歧义。

一个示例：

~~~groovy
package com.javachen.groovy.test

class Hello{
    static main(args){
        println "hello world"
    }
}
~~~

和Java一样，程序会从这个类的main方法开始执行，和Java的区别是：

- class 前省略 public 修饰；
- main 方法前省略 public 修饰；
- main 方法省略返回值类型 void；
- main 方法形参列表省略类型 String[]；

当然，这只是 Groovy 代码的一种写法，实际上执行 Groovy 代码完全可以不必需要一个类或 main 方法，所以更简单的写法如下：

~~~groovy
package com.javachen.groovy.test

println "hello world"
~~~

将上述代码保存为 hello.groovy，然后运行：

~~~
$ groovy hello.groovy
hello world
~~~

可以看到正确的输出了 “hello world”

## 3.3 变量和类型

像其他 Script 一样，Groovy 不需要显式声明类型。在 Groovy 中，一个对象的类型是在运行时动态发现的，这极大地减少了要编写的代码数量。

在 Groovy 中，类型对于值(varibles)、属性(properties)、方法(method)和闭包(closure)参数、返回值都是可有可无的，只有在给定值的时候，才会决定它的类型，(当然声明了类型的除外）。

Groovy 对 boolean 类型放宽了限制：

- 常量true和false分别表示“真”和“假”；
- null表示false，非null表示true；
- 空字符串""表示false，非空字符串表示true；
- 0表示false，非0表示true；
- 空集合表示false，非空集合表示true；

## 3.4 字符串 

Groovy 中的字符串允许使用双引号和单引号。   当使用双引号时，可以在字符串内嵌入一些运算式，Groovy 允许您使用 与 bash 类似的 `${expression}` 语法进行替换。可以在字符串中包含任意的 Groovy 表达式。

大块文本：

如果有一大块文本（例如 HTML 和 XML）不想编码，你可以使用Here-docs。 here-docs 是创建格式化字符串的一种便利机制。它需要类似 Python 的三重引号(""")开头，并以三重引号结尾。

~~~groovy
package com.javachen.groovy.test

// groovy中对字符串的使用做了大量的简化

// 获取字符串中的字符
s = "Hello"
println s[0]		// 输出'H'
// 遍历字符串中的所有字符
s.each {
	print it + ", "		// 遍历字符串中的所有字符
}
println ""

// 截取字符串
s1 = s[1..3]		// 截取s字符串标号从1到3的3个字符，组成新的字符串赋予s1
					// 该语法是String类的substring方法的简化
println s1

// 模板式字符串
n = 100
s1 = "The number n is ${n}"		// ${n}表示将变量n的值放在字符串该位置
println s1

// 带格式的长字符串
// """和"""之间的所有字符都会被算做字符串内容，包括// /*以及回车，制表符等
s = """
大家好
欢迎大家学习Groovy编程
Groovy is a better Java
"""
println s

// groovy中单引号的作用

// 在不定义类型时，单引号也表示字符串
c1 = 'A'
println c1.getClass().getName()

// 要明确的定义字符类型，需要给变量增加定义
char c2 = 'A'
println c2.getClass().getName()

// 取消转义字符
s = 'c:\\windows\\system'
println s
s = /c:\windows\system/		// 利用/字符串/定义的字符串
println s

// 字符串运算
s = "hello"
s = s + " world"			// +运算符用于连接字符串
println s
s -= "world"				// -可以从字符串中去掉一部分
println s
s = s * 2					// *可以让字符串重复n次
println s

// 字符串比较
s1 = "Abc"
s2 = "abc"

println s1 == s2 ? "Same" : "Different"		// 执行s1.equals(s2)
println s1 != s2 ? "Different" : "Same"		// 执行!s1.equals(s2)
println s1 > s2 ? "Great" : "Less"			// 执行s1.compareTo(s2) > 0
println s1 < s2 ? "Less" : "Great"			// 执行s1.compareTo(s2) < 0
println s1 <=> s2 == 1 ? "Same" : "Different"		// 执行s1.compareTo(s2)
~~~

Groovy增加了对字符串的如下操作：

- 集合操作，Groovy 将字符串看为字符的集合，可以通过 [n] 运算符直接访问字符串内的字符，也可以通过 each 循环遍历字符串的每一个字符；
- 截取子字符串的 substring 方法被简化为使用数值范围来进行截取，"hello"[1..3]表示截取字符串 "hello" 从下标为1到下标为3的部分，结果为 "ell"；
- Groovy 增加了一个新的字符串类型 GString，这种字符串可以进行格式化，在 GString 字符串中使用 ${变量}，可以将该变量的值放入字符串的相应位置；
- 带格式的字符串，使用 """字符串内容"""(连续的三个引号)，这种字符串中可以包含直接输入的回车，TAB键，//或/*等字符，而这些在 Java 原本的字符串里，都必须通过转义字符来表示，例如只能用 \n 表示回车；
- 单引号问题，和 Javascript 和 PHP 类似，Groovy 中无论是单引号还是双引号都表示是字符串类型，例如 'a' 和”a"都是字符串类型，所以如果要确定存储一个 char 类型变量，就必须使用 char 类型定义强类型变量；实际上 Groovy 认为 char 类型并不是必须的，大部分时候字符串类型更方便一些；
- 用 / 包围的字符串，即 /字符串内容/，可以避免在字符串中使用转义字符，但 \n 字符不包含在内；
- Java 中对字符串的运算只有+运算，在 Groovy 中，字符串还可以使用 - 运算 和 * 运算，减法运算可以从一个字符串中删除一部分，乘法运算可以将一个字符串重复n次；
- Groovy 还为字符串加入了所有关系运算符，包括 ==, !=, >, <, >=, <=，这要归功于 Groovy 允许运算符重载，对于 == 和 !=，将调用 String 类的 equals 方法，对于 >, >=, <, <=，将调用 String 类的 compareTo 方法；Groovy 还增加了一个特殊的运算符<=>，这个运算符也会调用 compareTo 方法，返回 compareTo 方法的返回值； 

## 3.5 switch语句

Groovy 的 switch 语句兼容 Java 代码，但是更灵活，Groovy 的 switch 语句能够处理各种类型的 switch 值，可以做各种类型的匹配：   

- 1. case 值为类名，匹配 switch 值为类实例   
- 2. case 值为正则表达式，匹配 switch 值的字符串匹配该正则表达式  
- 3. case 值为集合，匹配 switch 值包含在集合中，包括 ranges
- 4. 除了上面的，case值与switch值相等才匹配。 

Switch 语句的工作原理：switch 语句在做 case 值匹配时，会调用 `isCase(switchValue)` 方法，Groovy 提供了各种类型，如类，正则表达式、集合等等的重载。可以创建自定义的匹配类，增加 `isCase(switchValue)` 方法来提供自定义的匹配类型。

## 3.6 循环

~~~groovy
package com.javachen.groovy.loops

public class LoopTest{
  public static void main(args){
  	def list = ["Lars", "Ben", "Jack"]
    // using a variable assignment
    list.each{firstName->
      println firstName
    }
    // using the it variable
    list.each{println it}

	5.times {println "Times + $it "}
	1.upto(3) {println "Up + $it "}
	4.downto(1) {print "Down + $it "}
	def sum = 0
	1.upto(100) {sum += 1}
	print sum
	
	(1..6).each {print "Range $it"}

	for (i in 0..9) {
      println ("Hello $i")
    }
  }  
} 
~~~

Groovy对Java循环结构作了如下的修整：

- 对于 for 循环：除了传统三表达式的 for 循环和用于迭代的 for each 循环外，Groovy 允许 for 循环遍历一个范围（Range），例如 `for (i in 1..10)`，表示循环10次，i在1至10之间取值；
- 对于整数，Groovy 增加了如下几个方法来进行循环：
  - upto：`n.upto(m)` 函数，表示循环 m- n 次，并且会有一个循环变量it，从 n 开始，每次循环增加1，直到 m。循环体写在upto方法之后大括号中，表示一个闭包，在闭包中，it 作为循环变量，值从 a 增长到 n；
  - times：`n.times` 函数，表示循环 n 次，循环变量 it 从0开始到n结束。
  - step：`n.step(x, y)` 函数，表示循环变量从 n 开始到 x 结束，每次循环后循环变量增加 y，所以整个循环次数为 `(x - n) / y `次；

## 3.7 集合

# 参考文章

- [1] [Groovy基本语法(1)](http://blog.csdn.net/mousebaby808/article/details/7093946)  
- [2] [Groovy基本语法(2)](http://blog.csdn.net/mousebaby808/article/details/7093950) 
- [3] [Groovy基本语法(3)](http://blog.csdn.net/mousebaby808/article/details/7097114) 
- [4] [Groovy with Eclipse - Tutorial](http://www.vogella.com/tutorials/Groovy/article.html)

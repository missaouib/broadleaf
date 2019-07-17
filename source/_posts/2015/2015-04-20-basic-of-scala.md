---
layout: post

title: Scala基本语法和概念

category: scala

tags: [ scala ]

description: 本文主要包括Scala的安装过程并理解Scala的基本语法和概念，包括表达式、变量、基本类型、函数、流程控制等相关内容。

published: true

---

本文主要包括Scala的安装过程并理解Scala的基本语法和概念，包括表达式、变量、基本类型、函数、流程控制等相关内容。

# 1. 安装

从[All Versions Scala](http://www.scala-lang.org/download/all.html)下载所需版本Scala安装包，解压到指定目录之后，配置环境变量并使其生效。

如果你使用Mac，则可以使用`brew`安装：

~~~bash
⇒  brew install scala
~~~

在终端键入`scala`查看Scala的版本，并进入Scala的解释器：

~~~scala
⇒  scala
Welcome to Scala version 2.11.6 (Java HotSpot(TM) 64-Bit Server VM, Java 1.7.0_60).
Type in expressions to have them evaluated.
Type :help for more information.

scala>
~~~

# 2. 表达式

~~~scala
scala> 1 + 1
res0: Int = 2
~~~

res0是解释器自动创建的变量名称，用来指代表达式的计算结果。它是Int类型，值为2。

resX识别符还将用在后续的代码行中。例如,既然res0已在之前设为3，res0 * 3就是 9:

~~~scala
scala> res0 * 3
res1: Int = 9
~~~

打印 "Hello, world!''  : 

~~~scala
scala> println("Hello, world!")
Hello, world!
~~~

`println`函数在标准输出上打印传给它的字串，就跟Java里的`System.out.println`一样。

# 3. 变量

Scala 有两种变量：`val` 和 `var`。val 类似于 Java 里的 final 变量。一旦初始化了，val 就不能再赋值了。与之对应的，var 如同 Java 里面的非 final 变量。var 可以在它生命周期 中被多次赋值。下面是一个 val 的定义:

~~~scala
scala> val msg = "Hello, world!"
msg: String = Hello, world!
~~~

这个语句引入了msg当作字串"Hello, world!"的名字。类型是 java.lang.String，因为 Scala 的字串是由 Java 的 String 类实现的。

这里定义的msg变量并没有指定类型，Scala解释器会自动推断出其类型，当然你也可以显示的标注类型：

~~~scala
scala> val msg2: java.lang.String = "Hello again, world!"
msg2: String = Hello again, world!
~~~

因为在Scala程序里`java.lang`类型的简化名也是可见的，所以可以简化为:

~~~scala
scala> val msg3: String = "Hello yet again, world!"
msg3: String = Hello yet again, world!
~~~

如果你想定义一个变量并修改它的值，你可以选择使用`var`。

~~~scala
scala> var greeting = "Hello, world!"
greeting: String = Hello, world!
~~~

由于 greeting 是 var 而不是 val,你可以在之后对它重新赋值。

~~~scala
scala> greeting = "Leave me alone, world!"
greeting: String = Leave me alone, world!
~~~

要输入一些能跨越多行的东西,只要一行行输进去就行。如果输到行尾还没结束,解释器 将在下一行回应一个竖线。

~~~scala
scala> val multiLine =
     | "This is the next line."
multiLine: java.lang.String = This is the next line.
~~~

如果你意识到你输入了一些错误的东西,而解释器仍在等着你更多的输入,你可以通过按 两次回车取消掉:

~~~scala
scala> val oops =
     |
     |
You typed two blank lines. Starting a new command.
scala>
~~~

var 变量可重新赋值，如果赋值为`_`，则表示使用缺省值(0、false、null)，例如：

~~~scala
var d:Double = _ // d = 0.0
var i:Int = _ // i = 0
var s:String = _ // s = null
var t:T = _  // 泛型T对应的默认值
~~~

Scala还能像Python一样方便的赋值：

~~~scala
// 给多个变量赋同一初始值
scala> val x,y=0
x: Int = 0
y: Int = 0

// 同时定义多个变量，注意：val x,y=10,"hello" 是错误的
scala> val (x,y) = (10, "hello")
x: Int = 10
y: String = hello

// x = 1, y = List(2,3,4)
scala> val x::y = List(1,2,3,4)
x: Int = 1
y: List[Int] = List(2, 3, 4)

// a = 1, b = 2, c = 3
scala> val List(a,b,c) = List(1,2,3)
a: Int = 1
b: Int = 2
c: Int = 3

// 也可以用List，Seq
scala> val Array(a, b, _, _, c @ _*) = Array(1, 2, 3, 4, 5, 6, 7)
a: Int = 1
b: Int = 2
c: Seq[Int] = Vector(5, 6, 7) // Array(5, 6, 7), _*匹配0个到多个
~~~

使用正则表达式赋值：

~~~scala
scala> val regex = "(\\d+)/(\\d+)/(\\d+)".r
regex: scala.util.matching.Regex = (\d+)/(\d+)/(\d+)

scala> val regex(year, month, day) = "2015/04/20"
year: String = 2015
month: String = 04
day: String = 20
~~~

除了`val`，你还可以使用`lazy`：

- `val`：定义时就一次求值完成，保持不变
- `lazy`：定义时不求值，第一次使用时完成求值，保持不变

总结：

- Scala是严格意义上的静态类型语言，由于其采用了先进的类型推断技术，程序员不需要在写程序时显式指定类型，编译器会根据上下文推断出类型信息。
- Scala程序语句结尾没有分号，这也是 Scala中约定俗成的编程习惯。大多数情况下分号都是可省的，如果你需要将两条语句写在同一行，则需要用分号分开它们。
- val用于定义不能修改的变量，var定义的变量可以修改和赋值，赋值为`_`表示使用默认值。

# 4. 基本类型和操作

## 一些基本类型

Scala 中的一些基本类型和其实例值域范围如下：

|值 | 类型 |
|:---|:---|
| Byte | 8 位有符号补码整数(-27~27-1)|
| Short | 16 位有符号补码整数(-215~215-1) |
| Int | 32 位有符号补码整数(-231~231-1) |
| Long | 64 位有符号补码整数(-263~263-1) |
| Char | 16 位无符号Unicode字符(0~216-1)  |
| String | 字符序列 |
| Float | 32 位 IEEE754 单精度浮点数 | |
| Double | 64 位 IEEE754 单精度浮点数 |
| Boolean | true 或 false |

除了String归于`java.lang`包之外，其余所有的基本类型都是包scala的成员。如`Int`的全名是`scala.Int`。然而，由于包`scala`和`java.lang`的所有成员都被每个Scala源文件自动引用，你可以在任何地方只用简化名。

Scala的基本类型与Java的对应类型范围完全一样，这让Scala编译器能直接把Scala的值类型在它产生的 字节码里转译成 Java 原始类型。
 
Scala用`Any`统一了原生类型和引用类型。

~~~
Any
    AnyRef
        java String
        其他Java类型
        ScalaObject
    AnyVal
        scala Double
        scala Float
        scala Long
        scala Int
        scala Short
        scala Unit
        scala Boolean
        scala Char
        scala Byte
~~~

对于基本类型，可以用`asInstanseOf[T]`方法来强制转换类型：

~~~scala
scala> def i = 10.asInstanceOf[Double]
i: Double

scala> List('A','B','C').map(c=>(c+32).asInstanceOf[Char])
res1: List[Char] = List(a, b, c)
~~~

用`isInstanceOf[T]`方法来判断类型：

~~~scala
scala> val b = 10.isInstanceOf[Int]
b: Boolean = true
~~~

而在`match ... case`中可以直接判断而不用此方法。

## 操作符和方法

Scala为它的基本类型提供了丰富的操作符集。例如，`1 + 2`与`(1).+(2)`其实是一回事。换句话说，就是 Int 类包含了叫做`+`的方法，它带一个 Int 参数并返回一个 Int 结果。这个`+`方法在两 个 Int 相加时被调用：

~~~scala
scala> val sum = 1 + 2 // Scala调用了(1).+(2) 
sum: Int = 3
~~~

想要证实这点，可以把表达式显式地写成方法调用：

~~~scala
scala> val sumMore = (1).+(2)
sumMore: Int = 3
~~~

而真正的事实是，Int包含了许多带不同的参数类型的重载的`+`方法。

符号`+`是操作符——更明确地说，是中缀操作符。操作符标注不仅限于像`+`这种其他语言里 看上去像操作符一样的东西。你可以把任何方法都当作操作符来标注。例如，类 String 有一个方法 `indexOf` 带一个 Char 参数。`indexOf` 方法搜索 String 里第一次出现的指定字符，并返回它的索引或 -1 如果没有找到。你可以把 `indexOf` 当作中缀操作符使用，就像这样：

~~~scala
scala> val s = "Hello, world!"
s: String = Hello, world!
scala> s indexOf 'o' // Scala调用了s.indexOf(’o’) 
res30: Int = 4
~~~

String 提供一个重载的 indexOf 方法，带两个参数，分别是要搜索的字符和从哪个索引开始搜索。尽管 这个 indexOf 方法带两个参数,你仍然可以用操作符标注的方式使用它。

~~~scala
scala> s indexOf ('o', 5) // Scala调用了s.indexOf(’o’, 5) 
res31: Int = 8
~~~

> 任何方法都可以是操作符。

Scala 还有另外两种操作符标注：前缀和后缀。前缀标注中，方法名被放在调用的对象之前，如，`-7` 里的`-`。后缀标注在方法放在对象之后，如`7 toLong`里的`toLong`。

与中缀操作符-------操作符带后两个操作数，一个在左一个在右，相反，前缀和后缀操作符都是一元 unary 的：它们仅带一个操作数。前缀方式中，操作数在操作符的右边。前缀操作符的例子有 `-2.0`、`!found`和`~0xFF`。与中缀操作符一致，这些前缀操作符是在值类型对象上调用方法的简写方式。然而这种情况下，方法名在操作符字符上前缀了`unary_`。 例如，Scala 会把表达式 `-2.0` 转换成方法调用`(2.0).unary_-`。你可以输入通过操作符和显式方法名两种方式对方法的调用来演示这一点：

~~~scala
scala> -2.0 // Scala调用了(2.0).unary_- res2: Double = -2.0
scala> (2.0).unary_-
res32: Double = -2.0
~~~

> 可以当作前缀操作符用的标识符只有+,-,!和~

后缀操作符是不用点或括号调用的不带任何参数的方法。

~~~scala
scala> val s = "Hello, world!"
s: String = Hello, world!
scala> s.toLowerCase
res33: String = hello, world!
~~~

后面的这个例子里，方法没带参数，或者还可以去掉点，采用后缀操作符标注方式：

~~~scala
scala> s toLowerCase
res34: String = hello, world!
~~~

## 数学运算

Int 无`++`、`--`操作，但可以`+=`、`-=`, 如下：

~~~scala
var i = 0
i++  // 报错，无此操作
i+=1 // 1
i--  // 报错，无此操作
i-=1 // 0
~~~

## 对象相等性

如果你想比较一下看看两个对象是否相等，可以使用`==`，或它的反义`!=`。

~~~scala
//比较基本类型
scala> 1 == 2
res36: Boolean = false

scala> 1 != 2
res37: Boolean = true

scala> 2 == 2
res38: Boolean = true

//比较对象
scala> List(1, 2, 3) == List(1, 2, 3)
res39: Boolean = true

scala> List(1, 2, 3) == List(4, 5, 6)
res40: Boolean = false

//比较不同类型
scala> 1 == 1.0
res41: Boolean = true

scala> List(1, 2, 3) == "hello"
res42: Boolean = false

//和null进行比较，不会有任何异常抛出
scala> List(1, 2, 3) == null
res43: Boolean = false

scala> null == List(1, 2, 3)
res44: Boolean = false

scala> null == List(1, 2, 3)
res45: Boolean = false
~~~

Scala的`==`很智能，他知道对于数值类型要调用Java中的`==`，引用类型要调用Java的`equals()`：

~~~scala
scala> "hello"=="Hello".toLowerCase()
res46: Boolean = truescala
~~~

在java中为false，在scala中为true。

Scala的`==`总是内容对比，`eq`才是引用对比，例如：

~~~scala
val s1,s2 = "hello"
val s3 = new String("hello")
s1==s2 // true
s1 eq s2 // true
s1==s3 // true 值相同
s1 eq s3 // false 不是同一个引用
~~~

## 富包装器

Scala的每一个基本类型都有一个富包装类：

- Byte：scala.runtime.RichByte 
- Short：scala.runtime.RichShort 
- Int：scala.runtime.RichInt 
- Long：scala.runtime.RichLong 
- Char：scala.runtime.RichChar 
- String：scala.runtime.RichString 
- Float：scala.runtime.RichFloat 
- Double：scala.runtime.RichDouble 
- Boolean：scala.runtime.RichBoolean

一些富操作的例子如下：

~~~scala
0 max 5
0 min 5
-2.7 abs
-2.7 round
1.5 isInfinity
(1.0 / 0) isInfinity
4 to 6
"bob" capitalize
"robert" drop 2
~~~

# 5. 函数

函数的地位和一般的变量是同等的，可以作为函数的参数，可以作为返回值。传入函数的任何输入是只读的，比如一个字符串，不会被改变，只会返回一个新的字符串。
 
Java里面的一个问题就是很多只用到一次的private方法，没有和使用它的方法紧密结合；Scala可以在函数里面定义函数，很好地解决了这个问题。

## 函数定义

函数和方法一般用`def`定义。

~~~scala
scala> def max(x: Int, y: Int): Int = {
     |   if (x > y) x
     |   else y }
max: (x: Int, y: Int)Int
~~~

函数的基本结构如下：

![](/images/scala-function-defined.jpg)

有时候Scala编译器会需要你定义函数的结果类型。比方说，如果函数是递归的，你就必须显式地定义函数结果类型。然而在max的例子里，你可以不用写结果类型，编译器也能够推断它。同样，如果函数仅由一个句子组成，你可以可选地不写大括号。这样，你就可以把max函数写成这样:

~~~scala
scala> def max2(x: Int, y: Int) = if (x > y) x else y
~~~

一旦你定义了函数，你就可以用它的名字调用它，如：

~~~scala
scala> max(3, 5)
res25: Int = 5
~~~

函数不带参数，调用时括号可以省略：

~~~scala
scala> def three() = 1 + 2
three: ()Int

scala> three()
res26: Int = 3

scala> three
res27: Int = 3
~~~

还有既不带参数也不返回有用结果的函数定义：

~~~scala
scala> def greet() = println("Hello, world!")
greet: ()Unit
~~~

当你定义了`greet()`函数，解释器会回应一个`greet: ()Unit`。空白的括号说明函数不带参数。Unit 是 greet 的结果类型，Unit 的结果类型指的是函数没有返回有用的值。Scala 的 Unit 类型比较接近 Java 的 void 类型，而且实际上 Java 里 每一个返回 void 的方法都被映射为 Scala 里返回 Unit 的方法。

**总结**：

- 函数体没有像Java那样放在`{}`里，Scala 中的一条语句其实是一个表达式
- 如果函数体只包含一条表达式，则可以省略`{}`
- 函数体没有显示的return语句，最后一条表达式的值会自动返回给函数的调用者
- 没有参数的函数调用时，括号可以省略

## 映射式定义

一种特殊的定义：映射式定义（直接相当于数学中的映射关系）；其实也可以看成是没有参数的函数，返回一个匿名函数；调用的时候是调用这个返回的匿名函数。

~~~scala
def f:Int=>Double = { 
    case 1 => 0.1
    case 2 => 0.2
    case _ => 0.0
}
f(1) // 0.1
f(3) // 0.0

def m:Option[User]=>User = {
    case Some(x) => x
    case None => null
}
m(o).getOrElse("none...")

def m:(Int,Int)=>Int = _+_
m(2,3) // 5

def m:Int=>Int = 30+  // 相当于30+_,如果唯一的"_"在最后,可以省略
m(5) // 35
~~~

## 特殊函数名 + - * /

方法名可以是`+`、`-`、`*`、`/`：

~~~scala
def *(x:Int, y:Int) = { x*y }
*(10,20) // = 200
1+2  //相当于1.+(2)
~~~

定义一元操作符（置前）可用`unary_`：一元的，单一元素的，单一构成的。

~~~scala 
-2  //相当于：(2).unary_- 
+2 //相当于：(2).unary_+ 
!true //相当于：(true).unary_! 
~0  //相当于 (0).unary_~  
~~~

## 函数的调用

正常调用，不传参数时候可以省略括号：

~~~scala
def f(s: String = "default") = { s }
f // "hello world"
f() // "hello world"
~~~

对象的无参数方法的调用，可以省略`.`和`()`：

~~~scala
"hello world" toUpperCase // "HELLO WORLD"
~~~

对象的1个参数方法的调用，可以省略`.`和`()`：

~~~scala
"hello world" indexOf w // 6
"hello world" substring 5 // "world"
Console print 10 // 但不能写 print 10，只能print(10)，省略Console.
1 + 2 // 相当于 (1).+(2)
~~~

对象的多个参数方法的调用,也可省略`.`但不能省略`()`：

~~~scala
"hello world" substring (0, 5) // "hello"
~~~

**注意**：

 - 不在class或者object中的函数不能如此调用：

~~~scala
def m(i:Int) = i*i
m 10 // 错误
~~~

 - 但在class或者object中可以使用`this`调用：

~~~scala
object method {
   def m(i:Int) = i*i
   def main(args: Array[String]) = {
        val ii = this m 15  // 等同于 m(15), this 不能省略
       println(ii)
   }
}   
~~~

## 匿名函数

形式：`((命名参数列表)=>函数实现)(参数列表)`

特殊地：

- 无参数： `(()=>函数实现)()`
- 有一个参数且在最后： `(函数实现)(参数)`
- 无返回值： `((命名参数列表)=>Unit)(参数列表)`

使用`=>`创建匿名函数：

~~~bash
scala> (x: Int)=> x+1 
res23: Int => Int = <function1>

scala> x:Int => x+1 // 没有大括号时，()是必须的
<console>:1: error: ';' expected but '=>' found.
       x:Int => x+1

scala> {(x: Int)=> x+1 } 
res24: Int => Int = <function1>

scala> {x:Int => x+1} // 有大括号时，()可以去掉
res25: Int => Int = <function1>
~~~

函数值是对象，所以如果你愿意可以把它们存入变量。它们也是函数，所以你可以使用通常的括
号函数调用写法调用它们：

~~~scala
scala> val m1 = (x:Int)=> x+1
m1: Int => Int = <function1>

scala> val m2 = {x:Int=> x+1} // 不用(), 用{}
m2: Int => Int = <function1>

scala> m1(10)
res26: Int = 11
~~~
 
有参数的匿名函数的调用：

~~~scala
scala> ((i:Int)=> i*i)(3)
res25: Int = 9

scala> ((i:Int, j:Int) => i+j)(3, 4)
res26: Int = 7
~~~

有一个参数且在最后的匿名函数的调用：

~~~scala
scala> (10*)(2) // 20, 相当于 ((x:Int)=>10*x)(2)
res27: Int = 20

scala> (10+)(2) // 12, 相当于 ((x:Int)=>10+x)(2)
res28: Int = 12

scala> (List("a","b","c") mkString)("=") // a=b=c
res29: String = a=b=c
~~~

无参数的匿名函数的调用：

~~~scala
scala> (()=> 10)() // 10
res30: Int = 10
~~~

无参数无返回值：

~~~scala
scala> (() => Unit)
res31: () => Unit.type = <function0>

scala> ( ()=> {println("hello"); 20*10} )()
hello
res32: Int = 200

//相当于调用一段方法
scala> { println("hello"); 20*10 }
hello
res33: Int = 200
~~~

匿名函数的两个例子：

- 例子1：直接使用匿名函数。

~~~scala
scala> List(1,2,3,4).map( (i:Int)=> i*i)
res34: List[Int] = List(1, 4, 9, 16)

//这里对变量 i 使用了类型推断
scala> List(1,2,3,4).map( i=> i*i)
res35: List[Int] = List(1, 4, 9, 16)
~~~

- 例子2：无参数的匿名函数

~~~scala
//定义一个普通的函数，参数为函数，返回值为空
scala> def times3(m:()=> Unit) = { m();m();m() }
times3: (m: () => Unit)Unit

//传入一个无参数的匿名函数
scala> times3 ( ()=> println("hello world") )
hello world
hello world
hello world
~~~

由于是无参数的匿名函数，可进一步简化：

~~~scala
scala> def times3(m: =>Unit) = { m;m;m }  // 参见“lazy参数”
times3: (m: => Unit)Unit

scala> times3 ( println("hello world") )
hello world
hello world
hello world
~~~

## 偏应用函数（Partial application）

用下划线代替一个或多个参数的函数叫偏应用函数（partially applied function），例如：

~~~scala
scala> def sum(a: Int, b: Int, c: Int) = a + b + c
sum: (Int,Int,Int)Int
~~~

你就可以把函数 sum 应用到参数 1、2 和 3 上，如下: 

~~~scala
scala> sum(1, 2, 3)
res1: Int = 6
~~~

偏应用函数是一种表达式，你不需要提供函数需要的所有参数。代之以仅提供部分，或不提供所需参数。比如，要创建不提供任何三个所需参数的调用 sum 的偏应用表达式，只要在“sum”之后放一个下划线即可，然后可以把得到的函数存入变量。举例如下:

~~~scala
scala> val a = sum _
a: (Int, Int, Int) => Int = <function>
~~~

有了这个代码，Scala 编译器以偏应用函数表达式`sum _`，实例化一个带三个缺失整数参数的函数值，并把这个新的函数值的索引赋给变量 a。当你把这个新函数值应用于三个参数之上时，它就转回头调用 `sum`，并传入这三个参数:

~~~scala
scala> a(1, 2, 3)
res2: Int = 6
~~~

实际发生的事情是这样的：名为a的变量指向一个函数值对象。这个函数值是由Scala编译器依照偏应用函数表达式`sum _`，自动产生的类的一个实例。编译器产生的类有一个`apply`方法带三个参数。之所以带三个参数是因为`sum _`表达式缺少的参数数量为三。Scala编译器把表达式`a(1,2,3)`翻译成对函数值的`apply`方法的调用，传入三个参数 1、2、3。因此 `a(1,2,3)`是下列代码的短格式：

~~~scala
scala> a.apply(1, 2, 3)
res3: Int = 6
~~~

也可针对部分参数使用：

~~~scala
scala> val b = sum(1, _: Int, 3)
b: (Int) => Int = <function>
scala> b(2)
res4: Int = 6
~~~

`_` 在Scala中的使用场景，见 [Scala中下划线的用途](/2015/04/23/all-the-uses-of-an-underscore-in-scala.html)。

如果`_`在最后，则可以省略：

~~~scala
1 to 5 foreach println
1 to 5 map (10*)
~~~

## 柯里化函数

有时会有这样的需求：允许别人一会在你的函数上应用一些参数，然后又应用另外的一些参数。

例如一个乘法函数，在一个场景需要选择乘数，而另一个场景需要选择被乘数。

~~~scala
scala> def multiply(m: Int)(n: Int): Int = m * n
multiply: (m: Int)(n: Int)Int
~~~

你可以直接传入两个参数。

~~~scala
scala> multiply(2)(3)
res0: Int = 6
~~~

你可以填上第一个参数并且部分应用第二个参数。

~~~scala
scala> val timesTwo = multiply(2) _
timesTwo: (Int) => Int = <function1>

scala> timesTwo(3)
res1: Int = 6
~~~

你可以对任何多参数函数执行柯里化。

~~~scala
scala> (multiply _).curried
res1: (Int) => (Int) => Int = <function1>
~~~

## 可变长度参数

这是一个特殊的语法，可以向方法传入任意多个同类型的参数。例如要在多个字符串上执行String的`capitalize`函数，可以这样写：

~~~scala
def capitalizeAll(args: String*) = {
  args.map { arg =>
    arg.capitalize
  }
}

scala> capitalizeAll("rarity", "applejack")
res1: Seq[String] = ArrayBuffer(Rarity, Applejack)
~~~

函数内部，重复参数的类型是声明参数类型的数组。因此，capitalizeAll函数里被声明为类型“String*” 的args的类型实际上是 Array[String]。然而，如果你有一个合适类型的数组，并尝试把它当作重复参数传入，你会得到一个编译器错误:

~~~scala
scala> val arr = Array("what's", "up", "doc?")
scala> capitalizeAll(arr)
<console>:31: error: type mismatch;
 found   : Array[String]
 required: String
              capitalizeAll(arr)
                            ^
~~~

要实现这个做法，你需要在数组参数后添加一个冒号和一个`_*`符号，像这样:

~~~scala
scala> capitalizeAll(arr: _*)
res2: Seq[String] = ArrayBuffer(What's, Up, Doc?)
~~~

这个标注告诉编译器把arr的每个元素当作参数，而不是当作单一的参数传给capitalizeAll。

## lazy参数

就是调用时用到函数的该参数，每次都重新计算。

lazy参数是变量或值：

~~~scala
//一般参数
def f1(x: Long) = {
  val (a,b) = (x,x)
  println("a="+a+",b="+b)
}
f1(System.nanoTime)
//a=1429501936753731000,b=1429501936753731000

//lazy参数
def f2(x: =>Long) = {
  val (a,b) = (x,x)
  println("a="+a+",b="+b)
}
f2(System.nanoTime)
//a=1429502007512014000,b=1429502007512015000
~~~

lazy参数是函数时：

~~~scala
//一般参数，打印一次
scala> def times1(m: Unit) = { m;m;m }
times1: (m: Unit)Unit

scala> times1 ( println("hello world") )
hello world

//lazy参数，打印三次
scala> def times2(m: =>Unit) = { m;m;m }
times2: (m: => Unit)Unit

scala> times2 ( println("hello world") )
hello world
hello world
hello world
~~~

# 6. 流程控制

## if..else

使用 if else 表达式:

~~~scala
if (x>y) 100 else -1
~~~

## while

使用 while 为列表求和:

~~~scala
def sum(xs: List[Int]) = { 
    var total = 0 
    var index = 0 
    while (index < xs.size) { 
        total += xs(index) 
        index += 1 
    } 
    total 
}
~~~

Scala 也有 do-while 循环。除了把状态测试从前面移到后面之外,与 while 循环没有区别。

~~~scala
var line = ""
do {
  line = readLine()
  println("Read: " + line)
} while (line != null)
~~~

## 循环操作

for：

~~~scala
//循环中的变量不用定义，如：
scala> for(i<-1 to 3; j=i*i) println(j)  // 包含3
1
4
9

scala> for (i <- 1 until 3) println(i)  // 不包含3
1
2

//如果for条件是多行，不能用()，要用{}
scala> for{i<-0 to 5
     | j<-0 to 2} yield i+j
res3: scala.collection.immutable.IndexedSeq[Int] = Vector(0, 1, 2, 1, 2, 3, 2, 3, 4, 3, 4, 5, 4, 5, 6, 5, 6, 7)

//带有过滤条件，可以有多个过滤条件，逗号分隔
scala> for (i <- 1 until 10 if i%2 == 0) println(i)
2
4
6
8

//for中的嵌套循环，包括多个 <-
scala> for {i <- 1 until 3; j <- 1 until 3} println(i*j)
1
2
2
4
~~~

for yield：把每次循环的结果`移进`一个集合（类型和循环内的一致），格式：`for {子句} yield {循环体}`

~~~scala
for (e<-List(1,2,3)) yield (e*e) // List(1,4,9)
for {e<-List(1,2,3)} yield { e*e } // List(1,4,9)
for {e<-List(1,2,3)} yield e*e // List(1,4,9)
~~~

foreach:

~~~scala
scala> List(1,2,3).foreach(println)
1
2
3

scala> (1 to 3).foreach(println)
1
2
3

scala> (1 until 4) foreach println
1
2
3

scala> Range(1,4) foreach println
1
2
3

//可以写步长
scala> 1 to (11,2)
res9: scala.collection.immutable.Range.Inclusive = Range(1, 3, 5, 7, 9, 11)

scala> 1 to 11 by 2
res10: scala.collection.immutable.Range = Range(1, 3, 5, 7, 9, 11)

scala> 1 until (11,2)
res11: scala.collection.immutable.Range = Range(1, 3, 5, 7, 9)

scala> 1 until 11 by 2
res12: scala.collection.immutable.Range = Range(1, 3, 5, 7, 9)

scala> val r = (1 to 10 by 4)
r: scala.collection.immutable.Range = Range(1, 5, 9)

//也可以是BigInt
scala> (1:BigInt) to 3
res13: scala.collection.immutable.NumericRange.Inclusive[BigInt] = NumericRange(1, 2, 3)
~~~

forall：判断是否所有都符合。

~~~scala
scala> (1 to 3) forall (0<)
res0: Boolean = true

scala> (-1 to 3) forall (0<)
res1: Boolean = false

scala> def isPrime(n:Int) = 2 until n forall (n%_!=0)
isPrime: (n: Int)Boolean

scala> for (i<-1 to 10 if isPrime(i)) println(i)
1
2
3
5
7

scala> (2 to 20) partition (isPrime _)
res4: (scala.collection.immutable.IndexedSeq[Int], scala.collection.immutable.IndexedSeq[Int]) = (Vector(2, 3, 5, 7, 11, 13, 17, 19),Vector(4, 6, 8, 9, 10, 12, 14, 15, 16, 18, 20))
//也可直接调用BigInt的内部方法
scala> (2 to 20) partition (BigInt(_) isProbablePrime(10))
res5: (scala.collection.immutable.IndexedSeq[Int], scala.collection.immutable.IndexedSeq[Int]) = (Vector(2, 3, 5, 7, 11, 13, 17, 19),Vector(4, 6, 8, 9, 10, 12, 14, 15, 16, 18, 20))
~~~

reduceLeft方法首先应用于前两个元素，然后再应用于第一次应用的结果和接下去的一个元素，等等，直至整个列表。

~~~scala
//计算阶乘
scala> def fac(n: Int) = 1 to n reduceLeft(_*_)
fac: (n: Int)Int

scala> fac(5) // 5*4*3*2 = 120
res6: Int = 120

//求和
scala> List(2,4,6).reduceLeft(_+_)
res7: Int = 12

//取max：
scala> List(1,4,9,6,7).reduceLeft( (x,y)=> if (x>y) x else y )
res8: Int = 9
//或者简化为：  
scala> List(1,4,9,6,7).reduceLeft(_ max _)
res9: Int = 9
~~~

foldLeft：

~~~scala
//累加
scala> def sum(L: Seq[Int]) = L.foldLeft(0)((a, b) => a + b)
sum: (L: Seq[Int])Int

scala> def sum(L: Seq[Int]) = L.foldLeft(0)(_ + _)
sum: (L: Seq[Int])Int

scala> def sum(L: List[Int]) = (0/:L){_ + _}
sum: (L: List[Int])Int

scala> sum(List(1,3,5,7))
res10: Int = 16

//乘法：
scala> def multiply(L: Seq[Int]) = L.foldLeft(1)(_ * _)
multiply: (L: Seq[Int])Int

scala> multiply(Seq(1,2,3,4,5))
res11: Int = 120

scala> multiply(1 until 5+1)
res12: Int = 120
~~~

scanLeft:

~~~scala
scala> List(1,2,3,4,5).scanLeft(0)(_+_)
res13: List[Int] = List(0, 1, 3, 6, 10, 15)
//相当于 (0,(0+1),(0+1+2),(0+1+2+3),(0+1+2+3+4),(0+1+2+3+4+5))

scala> List(1,2,3,4,5).scanLeft(1)(_*_)
res14: List[Int] = List(1, 1, 2, 6, 24, 120)
//相当于 (1, 1*1, 1*1*2, 1*1*2*3, 1*1*2*3*4, 1*1*2*3*4*5)

scala> List(1,2,3,4,5).scanLeft(2)(_*_)
res16: List[Int] = List(2, 2, 4, 12, 48, 240)
~~~

take、drop、splitAt:

~~~scala
1 to 10 by 2 take 3 // Range(1, 3, 5)
1 to 10 by 2 drop 3 // Range(7, 9)
1 to 10 by 2 splitAt 2 // (Range(1, 3),Range(5, 7, 9))
~~~

takeWhile、dropWhile、span：

~~~scala
1 to 10 takeWhile (_<5) // (1,2,3,4)
1 to 10 takeWhile (_>5) // ()
10 to (1,-1) takeWhile(_>6) // (10,9,8,7)

1 to 10 takeWhile ( n=> n*n<25)  // (1, 2, 3, 4)

1 to 10 dropWhile (_<5) // (5,6,7,8,9,10)
1 to 10 dropWhile (n=>n*n<25) // (5,6,7,8,9,10)
 
1 to 10 span (_<5) // ((1,2,3,4),(5,6,7,8)
List(1,0,1,0) span (_>0) // ((1), (0,1,0))
// 注意，partition是和span完全不同的操作
List(1,0,1,0) partition (_>0) // ((1,1),(0,0))
~~~

## match 表达式

Scala 的匹配表达式允许你在许多可选项中做选择，就好象其它语言中的 switch 语句。通常说来 match 表达式可以让你使用任意的模式。

匹配值：

~~~scala
val times = 1

times match {
  case -1|0 => "zore"
  case 1 => "one"
  case 2 => "two"
  case _ => "some other number"
}
~~~

使用守卫进行匹配:

~~~scala
times match {
  case i if i == 1 => "one"
  case i if i == 2 => "two"
  case _ => "some other number"
}
~~~

匹配类型:

~~~
def bigger(o: Any): Any = {
  o match {
    case i: Int if i < 0 => i - 1
    case i: Int => i + 1
    case d: Double if d < 0.0 => d - 0.1
    case d: Double => d + 0.1
    case text: String => text + "s"
  }
}
~~~

匹配 Option 类型：

~~~scala
scala> map.get(1) match {
     |  case Some(i) => println("Got something")
     |  case None => println("Got nothing")
     | }
Got something
~~~

匹配类成员:

~~~scala
def calcType(calc: Calculator) = calc match {
  case _ if calc.brand == "hp" && calc.model == "20B" => "financial"
  case _ if calc.brand == "hp" && calc.model == "48G" => "scientific"
  case _ if calc.brand == "hp" && calc.model == "30B" => "business"
  case _ => "unknown"
}
~~~

与 Java 的 switch 语句比，匹配表达式还有一些重要的差别：

- case 后面可以是任意类型。
- 每个可选项的最后并没有 break，break 是隐含的。
- match 表达式也能产生值。
- 在最后一行指令中的`_`是一个通配符，它保证了我们可以处理所有的情况。

参考 Effective Scala 对[什么时候使用模式匹配](http://twitter.github.com/effectivescala/#Functional programming-Pattern matching)和 [模式匹配格式化](http://twitter.github.com/effectivescala/#Formatting-Pattern matching)的建议。A Tour of Scala 也描述了[模式匹配](http://www.scala-lang.org/node/120)。

##  case if 表达式

写法1：

~~~scala
(1 to 20) foreach {                          
    case x if (x % 15 == 0) => printf("%2d:15n\n",x)
    case x if (x % 3 == 0)  => printf("%2d:3n\n",x)
    case x if (x % 5 == 0)  => printf("%2d:5n\n",x)
    case x => printf("%2d\n",x)                          
}
~~~

写法2：

~~~scala
(1 to 20) map (x=> (x%3,x%5) match {
  case (0,0) => printf("%2d:15n\n",x)
  case (0,_) => printf("%2d:3n\n",x)
  case (_,0) => printf("%2d:5n\n",x)
  case (_,_) => printf("%2d\n",x)
})
~~~

##  break、continue

Scala中没有break和continue语法，需要break得加辅助boolean变量，或者用库（continue没有）。
 
例子1：打印'a'到'z'的前10个

~~~java
var i=0; val rt = for(e<-('a' to 'z') if {i=i+1;i<=10}) printf("%d:%s\n",i,e)

('a' to 'z').slice(0,10).foreach(println)
~~~

例子2：1 到 100 和小于1000的数

~~~scala
var (n,sum)=(0,0); for(i<-0 to 100 if (sum+i<1000)) { n=i; sum+=i }
// n = 44, sum = 990
~~~

例子3：使用库来实现break

~~~scala
import scala.util.control.Breaks._
for(e<-1 to 10) { val e2 = e*e; if (e2>10) break; println(e) }
~~~

##   try catch finally

~~~scala
var f = openFile()
try {
  f = new FileReader("input.txt")
} catch {
  case ex: FileNotFoundException => // Handle missing file
  case ex: IOException => // Handle other I/O error
} finally {
  f.close()
}
~~~

捕获异常使用的是`模式匹配`。

# 7. 其他

## Null, None, Nil, Nothing

- `Null`： `Trait`，其唯一实例为null，是`AnyRef`的子类，*不是* `AnyVal`的子类
- `Nothing`： `Trait`，所有类型（包括`AnyRef`和`AnyVal`）的子类，没有实例
- `None`： `Option`的两个子类之一，另一个是`Some`，用于安全的函数返回值
- `Unit`： 无返回值的函数的类型，和java的void对应
- `Nil`： 长度为0的List

## 区分<-,=>,->

`<-`用于for循环，符号`∈`的象形:

~~~scala
for (i <- 0 until 100)
~~~

`=>`用于匿名函数，也可用在import中定义别名：`import javax.swing.{JFrame=>jf}`

~~~scala
List(1,2,3).map(x=> x*x)
((i:Int)=>i*i)(5) // 25
~~~

`->`用于Map初始化

~~~scala
Map(1->"a",2->"b") // (1:"a",2:"b")
~~~

>注意：在scala中任何对象都能调用`->`方法（隐式转换），返回包含键值对的二元组!

# 8. 参考资料

- <http://www.scala-lang.org/>
- [Scala 课堂](http://twitter.github.io/scala_school/zh_cn/index.html)
- [Scala 2.8+ Handbook](http://qiujj.com/static/Scala-Handbook.htm)
- [面向 Java 开发人员的 Scala 指南系列](http://www.ibm.com/developerworks/cn/java/j-scala/)


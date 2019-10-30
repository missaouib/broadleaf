---
layout: post

title: 使用Scala高价函数简化代码
date: 2015-06-18T08:00:00+08:00

categories: [ scala ]

tags: [scala]

description:  阅读《Programming in Scala》整理的笔记。在Scala里，带有其他函数做参数的函数叫做高阶函数，使用高阶函数可以简化代码。

published: true

---

在Scala里，带有其他函数做参数的函数叫做`高阶函数`，使用高阶函数可以简化代码。

# 减少重复代码

有这样一段代码，查找当前目录样以某一个字符串结尾的文件：

~~~scala
object FileMatcher {
  private def filesHere = (new java.io.File(".")).listFiles
  def filesEnding(query: String) =
    for (file <- filesHere; if file.getName.endsWith(query))
      yield file
}
~~~

如果，我们想查找包含某一个字符串的文件，则代码需要修改为：

~~~scala
def filesContaining(query: String) =
  for (file <- filesHere; if file.getName.contains(query))
    yield file
~~~

上面的改动只是使用了 contains 替代 endsWith，但是随着需求越来越复杂，我们要不停地去修改这段代码。例如，我想实现正则匹配的查找，则代码会是下面这个样子：

~~~scala
def filesRegex(query: String) =
  for (file <- filesHere; if file.getName.matches(query))
    yield file
~~~

为了应变复杂的需求，我们可以进行重构代码，抽象出变化的代码部分，将其声明为一个方法：

~~~scala
def filesMatching(query: String,matcher: (String, String) => Boolean) = {
  for (file <- filesHere; if matcher(file.getName, query))
    yield file
}
~~~

这样，针对不同的需求，我们可以编写不同的matcher方法实现，该方法返回一个布尔值。

有了这个新的 filesMatching 帮助方法，你可以通过让三个搜索方法调用它，并传入合适的函数 来简化它们：

~~~scala
def filesEnding(query: String) = filesMatching(query, _.endsWith(_))

def filesContaining(query: String) = filesMatching(query, _.contains(_))

def filesRegex(query: String) = filesMatching(query, _.matches(_))

~~~

上面的例子使用了占位符，例如， filesEnding 方法里的函数文本 `_.endsWith(_)` 其实就是：

~~~scala
(fileName: String, query: String) => fileName.endsWith(query)
~~~

因为，已经确定了参数类型为字符串，故上面可以省略参数类型。由于第一个参数 fileName 在方法体中被第一个使用，第二个参数 query 第二个使用，你也可以使用占位符语法：`_.endsWith(_)`。第一个下划线是第一个参数文件名的占位符，第二个下划线是第二个参数查询字串的占位符。

因为query参数是从外部传过来的，其可以直接传递给matcher函数，故filesMatching可以只需要一个参数：

~~~scala
object FileMatcher {
  private def filesHere = (new java.io.File(".")).listFiles

  private def filesMatching(matcher: String => Boolean) =
    for (file <- filesHere; if matcher(file.getName))
      yield file

  def filesEnding(query: String) = filesMatching(_.endsWith(query))

  def filesContaining(query: String) = filesMatching(_.contains(query))

  def filesRegex(query: String) = filesMatching(_.matches(query))
}
~~~

上面的例子使用了函数作为第一类值帮助你减少代码重复的方式，另外还演示了闭包是如何能帮助你减少代码重复的。前面一个例子里用到的函数文本，如 `_.endsWith(_)`和`_.contains(_)`都是在运行期实例化成函数值而不是闭包，因为它们没有捕 获任何自由变量。

举例来说，表达式`_.endsWith(_)`里用的两个变量都是用下划线代表的，也就是说它们都是从传递给函数的参数获得的。因此，`_.endsWith(_)`使用了两个绑定变量，而不是自由变量。

相对的，最近的例子里面用到的函数文本`_.endsWith(query)`包含一个绑定变量，下划线代表的参数和一个名为 query 的自由变量。仅仅因为 Scala 支持闭包才使得你可以在最近的这个例子里从 `filesMatching` 中去掉 query 参数，从而更进一步简化了代码。

另外一个例子，是循环集合时可以使用`exists`方法来简化代码。以下是使用了这种方式的方法去判断是否传入的 List 包含了负数的例子:

~~~scala
def  containsNeg(nums: List[Int]): Boolean = {
    var exists = false
    for (num <- nums)
        if (num < 0)
            exists = true
    exists
}
~~~

采用和上面例子同样的方法，我们可以抽象代码，将重要的逻辑抽离到一个独立的方法中去实现。对于上面的查找判断是否存在的逻辑，Scala中提供了高阶函数 exists 来实现，代码如下：

~~~scala
def containsNeg(nums: List[Int]) = nums.exists(_ < 0)
~~~

同样，如果你要查找集合中是否存在偶数，则可以使用下面的代码：

~~~scala
def containsOdd(nums: List[Int]) = nums.exists(_ % 2 == 1)
~~~

# 柯里化

当函数有多个参数列表时，可以使用`柯里化函数`来简化代码调用。例如，对下面的函数，它实现两个 Int 型参数，x 和 y 的加法：

~~~scala
scala> def plainOldSum(x: Int, y: Int) = x + y
plainOldSum: (Int,Int)Int

scala> plainOldSum(1, 2)
res4: Int = 3
~~~

我们可以将其柯里化，代之以一个列表的两个Int参数，实现如下：

~~~scala
scala> def curriedSum(x: Int)(y: Int) = x + y
curriedSum: (Int)(Int)Int

scala> curriedSum(1)(2)
res5: Int = 3
~~~

当你调用 curriedSum，你实际上背靠背地调用了两个传统函数。第一个函数调 用带单个的名为 x 的 Int 参数，并返回第二个函数的函数值，第二个函数带 Int 参数 y。

你可以使用`偏函数`，填上第一个参数并且部分应用第二个参数。

~~~scala
scala> val onePlus = curriedSum(1)_
onePlus: (Int) => Int = <function>
~~~

`curriedSum(1)_`里的下划线是第二个参数列表的占位符。结果就是指向一个函数的参考，这个函数在被调用的时候，对它唯一的Int参数加1并返回结果：

~~~scala
scala> onePlus(2)
res7: Int = 3
~~~

# 可变长度参数

类似柯里化函数，对于`同类型的多参数列表`，我们还可以使用`可变长度参数`，这部分内容，请参考《Scala基本语法和概念》中的[可变长度参数](/2015/04/20/basic-of-scala.html#可变长度参数)。

# 贷出模式

前面的例子提到了使用函数作为参数，我们可以将这个函数的执行结果再次作为参数传入函数，即`双倍`控制结构：能够重复一个操作两次并返回结果。

下面是一个例子：

~~~scala
scala> def twice(op: Double => Double, x: Double) = op(op(x))
twice: ((Double) => Double,Double)Double

scala> twice(_ + 1, 5)
res9: Double = 7.0
~~~

上面例子中 op 的类型是 `Double => Double`，就是说它是带一个 Double 做参数并返回另一个 Double 的函数。这里，op函数等同于：

~~~scala
def add(x:Int)=x+1
~~~

op函数会执行两次，第一次是执行`add(5)=6`，第二次是执行`add(add(5))=add(6)=6+1=7`。

>任何时候，你发现你的代码中多个地方有重复的代码块，你就应该考虑把它实现为这种双重控制结构。

考虑这样一种需求：打开一个资源，对它进行操作，然后关闭资源，你可以这样实现：

~~~scala
def withPrintWriter(file: File, op: PrintWriter => Unit) {
  val writer = new PrintWriter(file)
  try {
    op(writer)
  } finally {
    writer.close()
  }
}
~~~

有了这个方法，你就可以这样使用:

~~~scala
withPrintWriter(new File("date.txt"), writer => writer.println(new java.util.Date) )
~~~

>注意：
>这里和上面的例子一样，使用了`=>` 来映射式定义函数，其可以看成是没有参数的函数，返回一个匿名函数；调用的时候是调用这个返回的匿名函数。

使用这个方法的好处是，调用这个方法只需要关注如何操作资源，而不用去关心资源的打开和关闭。这个技巧被称为`贷出模式`：loan pattern，因为该函数要个模板方法一样，实现了资源的打开和关闭，而将使用 PrintWriter 操作资源`贷出`给函数，交由调用者来实现。

例子里的 withPrintWriter 把 PrintWriter 借给函数 op。当函数完成的时候，它发出信号说明它不再需要“借”的资源。于是资源被关闭在 finally 块中，以确信其确实被关闭，而忽略函数是正常结束返回还是抛出了异常。

因为，这个函数有两个参数，所以你可以将该函数柯里化：

~~~scala
def withPrintWriter(file: File)(op: PrintWriter => Unit) {
  val writer = new PrintWriter(file)
  try {
    op(writer)
  } finally {
    writer.close()
  } 
}
~~~

这样的话，你可以如下方式调用：

~~~scala
val file = new File("date.txt")
withPrintWriter(file) {
    writer => writer.println(new java.util.Date)
}
~~~

这个例子里，第一个参数列表，包含了一个 File 参数，被写成包围在小括号中。第二个参数列表，包含了一个函数参数，被包围在大括号中。

>当一个函数只有一个参数时，可以使用大括号代替小括号。

# 传名参数 by-name parameter

《Programming in Scala》的第九章提到了`传名参数`这个概念。其中举的例子是：实现一个称为myAssert的断言函数，该函数将带一个函数值做输入并参考一个标志位来决定该做什么。

如果没有传名参数，你可以这样写myAssert：

~~~scala
var assertionsEnabled = true 
def myAssert(predicate: () => Boolean) =  
    if (assertionsEnabled && !predicate())  
        throw new AssertionError
~~~

这个定义是正确的，但使用它会有点儿难看：

~~~scala
myAssert(() => 5 > 3) 
~~~

你或许很想省略函数文本里的空参数列表和`=>`符号，写成如下形式：

~~~scala
myAssert(5 > 3) // 不会有效，因为缺少() => 
~~~

传名函数恰好为了实现你的愿望而出现。要实现一个传名函数，要定义参数的类型开始于`=>`而不是`() =>`。例如，你可以通过改变其类型`() => Boolean`为`=> Boolean`，把myAssert的predicate参数改为传名参数。

~~~scala
def byNameAssert(predicate: => Boolean) =  
    if (assertionsEnabled && !predicate)  
        throw new AssertionError  
~~~

现在你可以在需要断言的属性里省略空的参数了。使用byNameAssert的结果看上去就好象使用了内建控制结构：

~~~scala
byNameAssert(5 > 3)  
~~~

传名类型中，空的参数列表`()`被省略，它仅在参数中被允许。没有什么传名变量或传名字段这样的东西。

现在，你或许想知道为什么你不能简化myAssert的编写，使用陈旧的Boolean作为它参数的类型，如：

~~~scala
def boolAssert(predicate: Boolean) =  
    if (assertionsEnabled && !predicate)  
        throw new AssertionError         
~~~

当然这种格式同样合法，并且使用这个版本boolAssert的代码看上去仍然与前面的一样：

~~~scala
boolAssert(5 > 3)  
~~~

**虽然如此，这两种方式之间存在一个非常重要的差别须指出**。因为boolAssert的参数类型是Boolean，在boolAssert(5 > 3)里括号中的表达式先于boolAssert的调用被评估。表达式`5 > 3`产生true，被传给boolAssert。相对的，因为byNameAssert的predicate参数的类型是`=> Boolean`，`byNameAssert(5 > 3)`里括号中的表达式不是先于byNameAssert的调用被评估的。而是代之以先创建一个函数值，其apply方法将评估`5 > 3`，而这个函数值将被传递给byNameAssert。

因此这两种方式之间的差别，在于如果断言被禁用，你会看到boolAssert括号里的表达式的某些副作用，而byNameAssert却没有。例如，如果断言被禁用，boolAssert的例子里尝试对`x / 0 == 0`的断言将产生一个异常：

~~~scala
scala> var assertionsEnabled = false 
assertionsEnabled: Boolean = false 
scala> boolAssert(x / 0 == 0)  
java.lang.ArithmeticException: / by zero  
 at .< init>(< console>:8)  
 at .< clinit>(< console>)  
 at RequestResult$.< init>(< console>:3)  
 at RequestResult$.< clinit>(< console>)...  
~~~

但在byNameAssert的例子里尝试同样代码的断言将不产生异常：

~~~scala
scala> byNameAssert(x / 0 == 0) 
~~~

# 总结

本文主要总结了几种使用Scala高阶函数简化代码的方法，涉及到的知识点有：柯里化、偏函数、函数映射式定义、可变长度参数、贷出模式以及传名参数。需要意识到的是，灵活使用高阶函数可以简化代码，但也可能会增加代码阅读的复杂度。

---
layout: post

title: Scala中下划线的用途

category: scala

tags: [ scala ]

description: 本文主要整理Scala中下划线的用途。

published: true

---

存在性类型：

~~~scala
def foo(l: List[Option[_]]) = 

def f(m: M[_]) 
~~~

高阶类型参数：

~~~scala
case class A[K[_],T](a: K[T])

def f[M[_]] 
~~~

临时变量：

~~~scala
val _ = 5
~~~

临时参数：

~~~scala
List(1, 2, 3) foreach { _ => println("Hi") }    //List(1, 2, 3) foreach { t => println("Hi") }
~~~

通配模式：

~~~scala
Some(5) match { case Some(_) => println("Yes") }

match {
     case List(1,_,_) => " a list with three element and the first element is 1"
     case List(_*)  => " a list with zero or more elements "
     case Map[_,_] => " matches a map with any key type and any value type "
     case _ =>
 }

val (a, _) = (1, 2)
for (_ <- 1 to 10)
~~~

通配导入：

~~~scala
// Imports all the classes in the package matching
import scala.util.matching._

import com.test.Fun._
~~~

隐藏导入：

~~~scala
// Imports all the members of the object Fun but renames Foo to Bar
import com.test.Fun.{ Foo => Bar , _ }

// Imports all the members except Foo. To exclude a member rename it to _
import com.test.Fun.{ Foo => _ , _ }
~~~

连接字母和标点符号：

~~~scala
def bang_!(x: Int) = 5
~~~

占位符：

~~~scala
( (_: Int) + (_: Int) )(2,3)

val nums = List(1,2,3,4,5,6,7,8,9,10)

nums map (_ + 2)
nums sortWith(_>_)
nums filter (_ % 2 == 0)
nums reduceLeft(_+_)
nums reduce (_ + _)
nums reduceLeft(_ max _)
nums.exists(_ > 5)
nums.takeWhile(_ < 8)
~~~

偏函数：

~~~scala
def fun = {
    // Some code
}
val funLike = fun _

List(1, 2, 3) foreach println _

1 to 5 map (10 * _)

//List("foo", "bar", "baz").map(_.toUpperCase())
List("foo", "bar", "baz").map(n => n.toUpperCase())
~~~

初始化默认值:

~~~scala
var d:Double = _ 
var i:Int = _
~~~

参数序列：

~~~scala
//Range转换为List
List(1 to 5:_*)

//Range转换为Vector
Vector(1 to 5: _*)

//可变参数中
def capitalizeAll(args: String*) = {
  args.map { arg =>
    arg.capitalize
  }
}

val arr = Array("what's", "up", "doc?")
capitalizeAll(arr: _*)
~~~

作为参数名：

~~~scala
//访问map
var m3 = Map((1,100), (2,200))
for(e<-m3) println(e._1 + ": " + e._2)
m3 filter (e=>e._1>1)
m3 filterKeys (_>1)
m3.map(e=>(e._1*10, e._2))
m3 map (e=>e._2)

//元组
(1,2)._2
~~~


# 参考资料

- [1] [What are all the uses of an underscore in Scala?](http://stackoverflow.com/questions/8000903/what-are-all-the-uses-of-an-underscore-in-scala)

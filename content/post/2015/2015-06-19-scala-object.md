---
layout: post

title: Scala中的对象
date: 2015-06-19T08:00:00+08:00

categories: [ scala ]

tags: [scala]

description: 主要记录Scala中对象相关的知识点。Scala中没有静态方法或静态字段，但可以使用object这个语法结构来实现相同的功能。对象与类在语法层面上很相似，除了不能提供构造器参数外，对象可以拥有类的所有特性。

published: true

---

Scala中没有静态方法或静态字段，但可以使用`object`这个语法结构来实现相同的功能。对象与类在语法层面上很相似，除了不能提供构造器参数外，对象可以拥有类的所有特性。

Scala的object定义了`单个实例`，其可以用来存放工具函数或常量等：

~~~scala
object Timer {
  var count = 0

  def currentCount(): Long = {
    count += 1
    count
  }
}
~~~

使用object中的常量或方法，通过object名称直接调用，对象构造器在对象第一次被使用时调用（如果某对象一直未被使用，那么其构造器也不会被调用）。

~~~scala
scala> Timer.currentCount()
res52: Long = 1

scala> Timer.currentCount
res53: Long = 2

scala> Timer.count
res54: Int = 2
~~~

object的构造器不接受参数传递。

# 伴生对象

对象如果与某个类同名，那么它就是一个`伴生对象`。**类和它的伴生对象必须在同一个源文件中**，可以将在Java类中定义的静态常量、方法等放置到Scala的类的伴生对象中。

类可以访问伴生对象私有属性，但是必须通过`伴生对象.属性名` 或 `伴生对象.方法` 调用，伴生对象也可以访问类的私有属性。

伴生对象是类的一个特殊实例。

~~~scala
class Counter{
    def getTotalCounter()= Counter.getCount
}

object Counter{
    private var cnt = 0
    private def getCount()= cnt
}
~~~

对象可以继承类，以及一个或多个特质，其结果是一个继承了指定类以及特质的类的对象，同时拥有在对象定义中给出的所有特性。

~~~scala
abstract class Person(var name:String, var age:Int){
    def info():Unit
}

object XiaoMing extends Person("XiaoMing", 5){
    def info(){
        println(" name is "+name+", age is "+age)
    }
}
~~~

Java程序通常从一个public类的main方法开始。而**在Scala中，程序从对象的main方法开始**，方法的类型是 `Array[String] => Unit`。

~~~scala
object Hello {
  def main(args: Array[String]) {
    println("Hello, world!")
  }
}
~~~

除此之外，`还可以扩展App特质`，然后将程序代码放在构造器内即可，命令行参数从args属性获取。

~~~scala
object Hello extends App {
  if (args.length > 0)
    println("Hello, " + args(0))
  else
    println("Hello, world!")
}
~~~

# apply 方法

**apply方法是对象的一类特有方法，一般可用于创建伴生类**。apply方法可以用简洁的方式调用，形如`Object(args..)`， 当然，你也可以跟其他方法一样调用，`Object.apply(args...)`，这两种写法的结果是一样的。

现在，当你看到`List(1,2,3)`这样的语句就不会感到奇怪了，这只是`List.apply(1,2,3)`的简写而已。

使用apply方法的好处是，*在创建对象时，可以省去使用new关键字*。

当类或对象有一个主要用途的时候，apply方法为你提供了一个很好的语法糖。

~~~scala
scala> class Foo {}
defined class Foo

scala> object FooMaker {
     |   def apply() = new Foo
     | }
defined module FooMaker

scala> val newFoo = FooMaker() //没有new
newFoo: Foo = Foo@5b83f762
~~~

或者：

~~~scala
scala> class Bar {
     |   def apply() = 0
     | }
defined class Bar

scala> val bar = new Bar
bar: Bar = Bar@47711479

scala> bar()
res8: Int = 0
~~~

# 枚举

在Scala中并没有`枚举`类型，但在标准类库中提供了`Enumeration`类来获得枚举。扩展Enumeration类后，调用`Value`方法来初始化枚举中的可能值。

~~~scala
object TrafficLightColor extends Enumeration {
  val Red, Yellow, Green = Value
}
~~~

上述实例中代码可以改为下面这样，区别是：Value方法每次返回内部类Value的新实例。

~~~scala
val Red = Value
val Yellow = Value
val Green = Value
~~~

用Value方法初始化枚举类变量时，Value方法会返回内部类的新实例，且该内部类也叫Value。另外，在调用Value方法时，也可传入ID、名称两参数。如果未指定ID，默认从零开始，后面参数的ID是前一参数ID值加1。如果未指定名称，默认与属性字段同名。

~~~scala
object TrafficLight extends Enumeration{
     val Red = Value(1, "Stop")
     val Yellow = Value("Wait")    //可以单独传名称
     val Green = Value(4) //可以单独传ID
}
~~~

上例中，Yellow属性就仅定义了名称，Green仅定义ID。

参数在不指定名称时，默认参数的Value为字段名。枚举类型的值是 `对象名.Value` ，如上例中的枚举类型是 TrafficLight.Value。

~~~scala
TrafficLight.Green
//TrafficLight.Value = Green
~~~

通过id方法获取枚举类型值的ID:

~~~scala
TrafficLight.Yellow.id
//Int = 2
~~~

通过values方法获取所有枚举值的集合:

~~~scala
TrafficLight.values
//TrafficLight.ValueSet = TrafficLight.ValueSet(Stop, Wait, Green)
~~~

通过ID来获取对应的枚举对象:

~~~scala
TrafficLight(1)
//TrafficLight.Value = Stop
~~~

# 参考文章

- [Scala学习——对象](http://nerd-is.in/images-08/scala-learning-objects/)

---
layout: post

title: Scala中的类

category: scala

tags: [scala]

description:  阅读《Programming in Scala》，整理Scala类、继承、重载相关的一些知识点。

published: true

---

阅读《Programming in Scala》，整理Scala类、继承、重载相关的一些知识点。

# 类

Scala使用class来定义类。

~~~scala
class Counter {
  private var value = 0 // 必须初始化字段
  def increment() { value += 1 } // 方法默认公有
  def current() = value  //空括号方法
}
~~~

>Scala中的类不能声明为public，一个Scala源文件中可以有多个类。

类的初始化和调用：

~~~scala
val myCounter = new Counter // 或new Counter()
myCounter.increment()
~~~

**Scala在遇到混合了无参数和空括号方法的情况时很大度。特别是，你可以用空括号方法重载无参数方法，并且反之亦可**。你还可以在调用任何不带参数的方法时省略空的括号：

~~~scala
myCounter.increment

myCounter.current()
myCounter.current
~~~

>原则上 Scala 的函数调用中可以省略所有的空括号，但在可能产生副作用的情况下，推荐仍然写一对空的括号。

如果将current方法的声明改为下面这种`无参方法`的形式，则调用时不能带`( )`：

~~~scala
class Counter {
  private var value = 0 // 必须初始化字段
  def increment() { value += 1 } // 方法默认公有
  def current = value //无参方法
}

val myCounter = new Counter 

myCounter.current()  // 调用必须是myCounter.current这种风格
<console>:10: error: Int does not take parameters
              myCounter.current()
~~~

我们还可以选择把current作为字段而不是方法来实现，只要简单地在每个实现里把 def 修改成 val 即可：

~~~scala
class Counter {
  private var value = 0 // 必须初始化字段
  def increment() { value += 1 } // 方法默认公有
  val current = value 
}
~~~

唯一的差别是字段的访问或许稍微比方法调用要快，因为字段值在类被初始化的时候被预计算，而方法调用在每次调用的时候都要计算。换句话说，字 段在每个 Element 对象上需要更多的内存空间。

# getter和setter

Scala对每个字段都提供了getter和setter方法。

~~~scala
class Person {
  var age = 0
}
~~~

上面例子中，getter和setter分别叫做`age`和`age_=`。

~~~scala
println(fred.age) // 调用方法fred.age()
fred.age = 21 // 调用方法fred.age_=(21)
~~~

将这个简单的Person编译后，使用`javap`查看生成的字节码，可以验证这一点。

~~~scala
// -private选项说明显示所有的类和成员
javap -private Person.class
~~~

Person字节码如下：

~~~scala
public class Person implements scala.ScalaObject {
  private int age;
  public int age();
  public void age_$eq(int); // =号被翻译成了$eq
  public Person();
}
~~~

Scala中，字段和getter/setter间的关系，还有其他几种情况。

使用val声明的字段，是只有getter，因为val声明的是不可变的。Scala中不能实现只有setter的字段。

还有种对象私有字段。Scala中，方法可以访问该类的所有对象的私有字段，这一点与Java一样。如果通过private[this]来字段来修饰，那么这个字段是对象私有的，这种情况下，不会生成getter和setter。对象私有字段，只能由当前对象的方法访问，而该类的其他对象的方法是无法访问的。

接下来是一种与private[this]相似的访问控制。Scala中可以使用private[class-name]来指定可以访问该字段的类，class-name必须是当前定义的类，或者是当前定义的类的外部类。这种情况会生成getter和setter方法。

没有初始值的字段即是`抽象字段`，关于`抽象类`的说明，后面再讨论。根据是val声明还是var声明，会生成相应的抽象的setter/getter，但是不生成字段。

~~~scala
abstract class Person {
  val id: Int
  var name: String
}
~~~

查看编译后的字节码，可以得知，JVM类只生成了setter/getter，但没有生成字段。

~~~java
public abstract class Person implements scala.ScalaObject {
  public abstract int id();
  public abstract java.lang.String name();
  public abstract void name_$eq(java.lang.String);
  public Person();
}
~~~

# Bean属性

使用 `@BeanProperty` 注解来为字段生成符合JavaBeans规范的getter/setter方法。使用该注解后，将会生成4个方法：Scala的getter/setter和JavaBeans规范的getter/setter（如果是val声明，就没有setter部分了）。

~~~scala
import scala.reflect.BeanProperty
// 在Scala 2.10.0之后已被废弃
// 使用scala.beans.BeanProperty代替
class Person {
  @BeanProperty var name: String = _
}
~~~

# 构造器

在Scala中，有两种构造器，主构造器（primary constructor）和辅助构造器（auxiliary constructor）。

## 辅助构造器

`辅助构造器`与Java构造器很相似，但有两点不同：

- 名字是this（Java中构造器名称与类名相同）
- 辅助构造器必须以对已经定义的辅助构造器或主构造器的调用开始

~~~scala
class Person {
  private var name = ""
  private var age = 0
 
  def this(name: String) {
    this() // 调用主构造器
    this.name = name
  }
 
  def this(name: String, age: Int) {
    this(name)  // 调用辅助构造器
    this.age = age
  }
}
~~~

调用：

~~~scala
val p1 = new Person // 主构造器
val p2 = new Person("Fred")  // 第一个辅助构造器
val p3 = new Person("Fred", 42) // 第二个辅助构造器
~~~

## 主构造器

在scala中每个类都有主构造器，主构造器并不是以`this`方法定义，而是与类定义交织在一起。

1、主构造器参数直接放在类名之后，指的是`()`中的参数，主构造器参数会被编译成字段，其值被初始化成构造时传入的参数。

~~~scala
class Person(a: String) {
  val name:String =a
}
~~~

2、主构造器会执行类定义中的所有语句，这里是是`{}`中的语句。

~~~scala
class Person {
  println(0)
  def printNum(num: Int) { println(num) }
  println(1)
  printNum(2)
}
~~~

3、如果主构造器参数不带val或var，那么会根据是否被方法使用来决定。如果不带val或var的参数被方法使用了，它会变为对象私有字段；如果没有被方法使用，则被当成一个普通的参数，不升级成字段。这部分说明请看`参数化字段`。

4、可以将主构造器变为私有的，将private关键字放在圆括号前：

~~~scala
class Person private(var name: String,val age: Int){
}
~~~

编译之后：

~~~scala
//javap
public class Person {
  private java.lang.String name;
  private final int age;
  public java.lang.String name();
  public void name_$eq(java.lang.String);
  public int age();
  
  //注意私有构造方法
  private Person(java.lang.String, int);
}
~~~

## 参数化字段

1、构造参数不带var或val，被类中函数使用：

~~~scala
class Person(a: String) {
  def name:String =a
}
~~~

则构造参数被升格为私有字段，效果类似`private[this] val`，反编译该类为：

~~~java
public class Person extends java.lang.Object{
    //私有final
    private final java.lang.String a;

    public static java.lang.String $lessinit$greater$default$1();

    //函数
    public java.lang.String name();

    public Person(java.lang.String);
}
~~~

2、构造参数不带var或val，未在类中使用，则该参数为普通参数：

~~~scala
class Person(a: String) {
}
~~~

反编译为：

~~~java
public class Person extends java.lang.Object{
    public Person(java.lang.String);
}
~~~

3、构造参数带var或val。Person类的定义中有一个构造参数a，并在name方法中被使用，如果你想避免这种参数和方法混合在一起的定义方式，你可以使用`参数化字段`来定义类，如下：

~~~scala
// 请注意小括号 
class Person( val name: String) {

}
~~~

这是在同一时间使用相同的名称定义参数和属性的一个`简写`方式。尤其特别的是，类 Person 现在拥有一个`可以从类外部访问的不能重新赋值`的属性name。

同样也可以使用var前缀类参数，这种情况下相应的字段将能重新被赋值。最终，还有可能添加 如private、protected、或override这类的修饰符到这些参数化字段上，就好象你可以在其他类成员上做的事情。

# 嵌套类

在Scala中，几乎可以在任何的语法结构中内嵌任何语法结构。可以类中定义类，也可以在方法中定义方法。

Scala中每个实例都有自己的内部类。

~~~scala
import scala.collection.mutable.ArrayBuffer
 
class NetWork {
  class Member(val name: String) {
  }
 
  private val members = new ArrayBuffer[Member]
 
  def join(m: Member) = {
    members += m
    m
  }
}
 
val chatter = new NetWork
val myFace = new NetWork

val m1=new chatter.Member("m1")
val m2=new chatter.Member("m2")

chatter.join(m1)
chatter.join(m2)

val m3=new myFace.Member("m3")
chatter.join(m3)
~~~

往chatter中加入m3时，会出现编译错误：

~~~
<console>:14: error: type mismatch;
 found   : myFace.Member
 required: chatter.Member
              chatter.join(m3)
~~~

这是因为，chatter.Member类和myFace.Member类是不同的两个类。这一点与Java中内部类是不同的。

如果想产生类似Java中的内部类特性，可以将Member声明到Network的外部，或者使用`类型投影`，这里是将内部类中的Member换成NetWork#Member，代码如下。

~~~scala
import scala.collection.mutable.ArrayBuffer
 
class NetWork {
  class Member(val name: String) {
  }
 
  private val members = new ArrayBuffer[NetWork#Member]
 
  def join(m: NetWork#Member) = {
    members += m
    m
  }
}
 
val chatter = new NetWork
val myFace = new NetWork

val m1=new chatter.Member("m1")
val m2=new chatter.Member("m2")

chatter.join(m1)
chatter.join(m2)

val m3=new myFace.Member("m3")
chatter.join(m3)
~~~

与Java中一样，如果需要在内部类中使用外部类的引用，使用 `外部类名.class` 的语法即可。不过Scala中有一个为这种情况服务的语法：

~~~scala
class NetWork(val name: String) { outer =>
  class Member(val name: String) {
    def description = name + " inside " + outer.name
  }
}

val work = new NetWork("work")
work.name
//work

val m1=new work.Member("m1")
m1.description
//m1 inside work
~~~

# 抽象类

和Java一样，Scala用`abstract`修饰抽象类，抽象类没有具体实例方法。具有抽象成员的类本身必须被声明为抽象的。抽象类定义如下：

~~~scala
abstract class Element {
  def contents: Array[String]
} 
~~~

请注意类 Element 的 contents 方法并没带有 abstract 修饰符，如果方法没有实现，也就是说没有等号或方法体，它就是抽象的。类 Element `声明`了抽象方法 contents，但当前没有`定义`具体方法。

抽象类不能实例化，否则会得到编译器错误：

~~~scala
scala> new Element
<console>:9: error: class Element is abstract; cannot be instantiated
              new Element
~~~

我们可以向 Element 添加显示宽度和高度的方法：

~~~scala
abstract class Element {
  def contents: Array[String]
  def height: Int = contents.length
  def width: Int = if (height == 0) 0 else contents(0).length
}
~~~

请注意 Element 的三个方法没一个有参数列表，甚至连个空列表都没有。这种`无参数方法`在Scala里是非常普通的，带有空括号的方法，被称为`空括号方法`。

# 继承

继承一个抽象类使用`extends`关键字，如果你省略 extends，Scala 编译器隐式地假设你的类扩展自 `scala.AnyRef`，在 Java 平台上与 java.lang.Object 一致。

~~~scala
class ArrayElement(conts: Array[String]) extends Element {
    def contents: Array[String] = conts
}
~~~

如果将类声明为final的，则这个类不能被继承。如果将类的方法和字段声明为final，则它们不能被重写。

子类继承超类中所有`非私有`的成员，如果子类中的成员与超类中成员具有相同名称和参数，则成为`重载`；如果子类中的成员是具体的而超类中的是抽象的，我们还可以说子类实现了超类中的成员。

上面例子中，ArrayElement类的contents方法重载或者说实现了超类的contents方法，并继承了width和height方法。我们可以实例一个ArrayElement对象，然后调用方法：

~~~scala
scala> val ae = new ArrayElement(Array("hello", "world"))
ae: ArrayElement = ArrayElement@d94e60
scala> ae.width
res1: Int = 5
~~~

上面ae变量的类型是ArrayElement，其实我们也可以将其声明为超类类型，这叫做`子类型化`：是指子类的值可以被用在需要其超类的值的任何地方。

~~~scala
val e: Element = new ArrayElement(Array("hello"))
~~~

这样的话，e变量是声明为Element类型，但是是初始化为ArrayElement类型。这个涉及到`多态`的概念。

如果子类要调用超类的构造器，则需要这样定义：

~~~scala
class LineElement(s: String) extends ArrayElement(Array(s)) {
  override def width = s.length
  override def height = 1
}
~~~

LineElement类继承自ArrayElement，并且LineElement类的构造器中传入了一个参数s，LineElement类想要调用超类的构造器，需要把要传递的参数或参数列表放在超类名之后的括号里即可：

~~~scala
... extends ArrayElement(Array(s)) ...
~~~

这样，就完成了子类调用父类的构造器进行初始化父类。

# 重载

统一访问原则只是 Scala 在对待字段和方法方面比 Java 更统一的一个方面；另一个差异是 Scala 里，字段和方法属于相同的命名空间。这使得字段重载无参数方法成为可能。比如说，你可以改变类 ArrayElement 中 contents 的实现，从一个方法变为一个字段，而无需修改类 Element 中 contents 的抽象方法定义：

~~~scala
class ArrayElement(conts: Array[String]) extends Element {
  val contents: Array[String] = conts
}
~~~

`Scala里禁止在同一个类里用同样的名称定义字段和方法`，例如，下面的代码在Scala中无法通过编译：

~~~scala
class WontCompile {
  private var f = 0  // 编译不过，因为字段和方法重名 
  def f = 1
}
~~~

通常情况下，Scala 仅为定义准备了两个命名空间：值(字段、方法、包还有单例对象)、类型(类和特质名)，而 Java 有四个：字 段、方法、类型和包。

Scala把字段和方法放进同一个命名空间，这样你就可以使用val重载无参数的方法。

# 重写

在Scala中`重写一个非抽象方法必须使用override修饰符`，**重写超类的抽象方法时，不需要使用override关键字**。调用超类的方法就如Java一样，使用`super`关键字。

请注意 LineElement 里 width 和 height 的定义带着 `override` 修饰符。`Scala里所有重载了父类具体成员的成员都需要这样的修饰符`。如果成员实现的 是同名的抽象成员则这个修饰符是可选的。而如果成员并未重载或实现什么其它基类里的成员则禁用这个修饰符。由于类 LineElement 的 height 和 width 重载了类 Element 的具体成员定义，override 是需要的。

这条规则给编译器提供了有用的信息来帮助避免某些难以捕捉的错误并使得系统的改进更加安全。

# 构造顺序和提前定义

现有如下的类：

~~~scala
class Creature {
  val range: Int = 10
  val env: Array[Int] = new Array[Int](range)
}
 
class Ant extends Creature {
  override val range = 2
}
~~~

在构造时，发生的过程如下：

- Ant构造器在构造自己之前，调用超类构造器；
- Creature的构造器将range字段设为10；
- Creature的构造器初始化env数组，调用range字段的getter；
- range的getter被Ant类重写了，返回的Ant类中的range，但是Ant类还未初始化，所以返回了0；
- env被设置成长度为0的数组
- Ant构造器继续执行，将range字段设为2。

在Java中也会出现碰见相似的问题，被调用的方法被子类所重写，有可能结果不是预期的。在构造器中，不应该依赖val的值。（只能重写超类抽象的var声明字段，所以没有这个问题；如果是def，也一样会出现这种问题。）

这个问题的根本原因来自于Java语言的设计决定——允许在超类的构造方法中调用子类的方法。而在C++中，构造前后会更改指向虚函数的指针，所以不会出现这类问题。

这个问题有几种解决方法：

- 将val声明为`final`，安全但不灵活；
- 在超类中将val声明为`lazy`，安全但不高效；
- 使用提前定义语法。

`提前定义语法`是将需要提前定义的成员放在extends关键字后的一个语法块中，还需要使用`with`关键字：

~~~scala
class Ant extends {
  override val range = 2
} with Creature
~~~

提前定义的等号右侧只能引用之前已经有的提前定义，不能出现类中其他的成员（因为都还没初始化呢）。

>使用`-Xcheckinit`编译器标志来调试构造顺序问题。这个标志会在有未初始化的字段被访问时抛出异常。

# 参考文章

- [Scala学习——类](http://nerd-is.in/images-08/scala-learning-classes/)

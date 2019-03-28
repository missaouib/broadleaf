---
layout: post

title: Java笔记：工厂模式

description: 工厂模式主要是为创建对象提供接口，以便将创建对象的具体过程屏蔽隔离起来，达到提高灵活性的目的。

keywords: 工厂模式主要是为创建对象提供接口，以便将创建对象的具体过程屏蔽隔离起来，达到提高灵活性的目的。

category: java

tags: [java]

published: true

---

工厂模式主要是为创建对象提供接口，以便将创建对象的具体过程屏蔽隔离起来，达到提高灵活性的目的。

工厂模式在《Java与模式》中分为三类：

- 1)简单工厂模式(Simple Factory)：不利于产生系列产品。
- 2)工厂方法模式(Factory Method)：又称为多形性工厂。
- 3)抽象工厂模式(Abstract Factory)：又称为工具箱，产生产品族，但不利于产生新的产品。

GOF在《设计模式》一书中将工厂模式分为两类：工厂方法模式(Factory Method)与抽象工厂模式(Abstract Factory)。将简单工厂模式(Simple Factory)看为工厂方法模式的一种特例，两者归为一类。

# 简单工厂模式

在简单工厂模式中，可以根据自变量的不同返回不同类的实例。简单工厂模式专门定义一个类来负责创建其他类的实例，被创建的实例通常都具有共同的父类。   

简单工厂模式角色：

- 工厂类
- 抽象产品
- 具体产品

简单工厂模式的优点如下：

- 工厂类含有必要的判断逻辑，可以决定在什么时候创建哪一个产品类的实例，客户端可以免除直接创建产品对象的责任，而仅仅“消费”产品；简单工厂模式通过这种做法实现了对责任的分割，它提供了专门的工厂类用于创建对象。
- 客户端无需知道所创建的具体产品类的类名，只需要知道具体产品类所对应的参数即可，对于一些复杂的类名，通过简单工厂模式可以减少使用者的记忆量。  
- 通过引入配置文件，可以在不修改任何客户端代码的情况下更换和增加新的具体产品类，在一定程度上提高了系统的灵活性。

简单工厂模式的缺点如下：

- 工厂类中包括了创建产品类的业务逻辑，一旦工厂类不能正常工作，整个系统都要受到影响。  
- 系统扩展困难，一旦添加新产品就需要修改工厂逻辑，在产品类型较多时，有可能造成工厂逻辑过于复杂，不利于系统的扩展和维护。
- 简单工厂模式由于使用了静态工厂方法，造成工厂角色无法形成基于继承的等级结构。  

举例：

~~~java
 //抽象产品角色
public interface Car{
    public void drive();
}
//具体产品角色
public class Benz implements Car{
    public void drive() {
        System.out.println("Driving Benz ");
    }
}
public class Bmw implements Car{
    public void drive() {
        System.out.println("Driving Bmw ");
    }
}
//工厂类角色
public class CarFactory{
    //工厂方法.注意 返回类型为抽象产品角色
    public static Car create(String s)throws Exception{
        if(s.equalsIgnoreCase("Benz"))
            return new Benz();
        else if(s.equalsIgnoreCase("Bmw"))
            return new Bmw();
        else throw new Exception();
    }
}
~~~

# 工厂方法模式 

在工厂方法模式中，核心的工厂类不再负责所有的产品的创建，而是将具体创建的工作交给子类去做。

工厂方法模式角色:

- 抽象工厂：是具体工厂角色必须实现的接口或者必须继承的父类。
- 具体工厂：它含有和具体业务逻辑有关的代码。由应用程序调用以创建对应的具体产品的对象。
- 抽象产品：它是具体产品继承的父类或者是实现的接口。
- 具体产品：具体工厂角色所创建的对象就是此角色的实例。

举例：

~~~java
 //抽象产品角色
public interface Car{
    public void drive();
}
//具体产品角色
public class Benz implements Car{
    public void drive() {
        System.out.println("Driving Benz ");
    }
}
public class Bmw implements Car{
    public void drive() {
        System.out.println("Driving Bmw ");
    }
}
//抽象工厂类角色
public abstract class CarFactory{
    public abstract Car create();
}

public class BenzCarFactory extends CarFactory{
    public Car create(){
        return new Benz();
    }
}

public class BmwCarFactory extends CarFactory{
    public Car create(){
        return new Bmw();
    }
}

//测试类
public class Test {
    public static void main(String[] args) {
        CarFactory factory = new BenzCarFactory();
        Car m = factory.create();
        m.drive();
    }
}
~~~

# 抽象工厂模式

抽象工厂模式提供一个创建一系列或相互依赖的对象的接口，而无需指定它们具体的类。它针对的是有多个产品的等级结构。而工厂方法模式针对的是一个产品的等级结构。

举例：

~~~java
//抽象工厂类
public abstract class AbstractFactory {
    public abstract Vehicle createVehicle();
    public abstract Weapon createWeapon();
    public abstract Food createFood();
}
//具体工厂类，其中Food,Vehicle，Weapon是抽象类
public class DefaultFactory extends AbstractFactory{
    @Override
    public Food createFood() {
        return new Apple();
    }
    @Override
    public Vehicle createVehicle() {
        return new Car();
    }
    @Override
    public Weapon createWeapon() {
        return new AK47();
    }
}
//测试类
public class Test {
    public static void main(String[] args) {
        AbstractFactory f = new DefaultFactory();
        Vehicle v = f.createVehicle();
        Weapon w = f.createWeapon();
        Food a = f.createFood();
    }
}
~~~

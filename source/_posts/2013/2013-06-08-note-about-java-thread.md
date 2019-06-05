---
layout: post

title: Java笔记：多线程

description:  多线程间堆空间共享，栈空间独立。堆存的是地址，栈存的是变量（如：局部变量）。多线程共同访问的同一个对象（临界资源），如果破坏了不可分割的操作（原子操作），就会造成数据不一致的情况。

keywords: java,thread

category: java

tags: [java,thread]

published: true

---

# 一些概念

现在的操作系统是多任务操作系统。多线程是实现多任务的一种方式。

`进程` 是指一个内存中运行的应用程序，每个进程都有自己独立的一块内存空间，一个进程中可以启动多个线程。比如在 Windows 系统中，一个运行的 exe 就是一个进程。
 
`线程` 是指进程中的一个执行流程，一个进程中可以运行多个线程。比如 `java.exe` 进程中可以运行很多线程。`线程总是属于某个进程，进程中的多个线程共享进程的内存`。
 
`同时` 执行是人的感觉，**在线程之间实际上轮换执行**。

>多线程间堆空间共享，栈空间独立。堆存的是地址，栈存的是变量（如：局部变量）。这部分内容结合 [Java 内存模型](/2014/04/09/note-about-jvm-memery-model.html) 来理解。

创建线程两种方式：`继承Thread类` 或 `实现Runnable接口`。

Thread 对象代表一个线程，一个 Thread 类实例只是一个对象，像 Java 中的任何其他对象一样，具有变量和方法，生死于堆上。
 
Java 中，每个线程都有一个调用栈，即使不在程序中创建任何新的线程，线程也在后台运行着。
 
一个 Java 应用总是从 `main()` 方法开始运行，`mian()` 方法运行在一个线程内，它被称为主线程。
 
一旦创建一个新的线程，就产生一个新的调用栈。
 
多线程共同访问的同一个对象（临界资源），如果破坏了不可分割的操作（原子操作），就会造成数据不一致的情况。

线程总体分两类：`用户线程` 和`守候线程`。

当所有用户线程执行完毕的时候，JVM自动关闭。但是守候线程却不独立于JVM，守候线程一般是由操作系统或者用户自己创建的。

# 线程状态图

 ![](http://7xnrdo.com1.z0.glb.clouddn.com/2014/thread-state.jpg)

 说明：
线程共包括以下5种状态。

- 1. `新建状态(New)`： 线程对象被创建后，就进入了新建状态。例如，`Thread thread = new Thread()`。
- 2. `就绪状态(Runnable)`： 也被称为“可执行状态”。线程对象被创建后，其它线程调用了该对象的 `start()` 方法，从而来启动该线程。例如，`thread.start()`。运行中的线程调用 `yield()` 之后也会进入就绪状态。处于就绪状态的线程，随时可能被 CPU 调度执行。
- 3. `运行状态(Running)`： 线程获取CPU权限进行执行。需要注意的是，线程只能从就绪状态进入到运行状态。
- 4. `阻塞状态(Blocked)`： 阻塞状态是线程因为某种原因放弃 CPU 使用权，暂时停止运行。直到线程进入就绪状态，才有机会转到运行状态。阻塞的情况分三种：
  - a) 等待阻塞 -- 通过调用线程的 `wait()` 方法，让线程等待某工作的完成。
  - b) 同步阻塞 -- 线程在获取 synchronized 同步锁失败(因为锁被其它线程所占用)，它会进入同步阻塞状态。
  - b) 其他阻塞 -- 通过调用线程的 `sleep()` 或 `join()` 或发出了 I/O 请求时，线程会进入到阻塞状态。当 `sleep()` 状态超时、`join()` 等待线程终止或者超时、或者 I/O 处理完毕时，线程重新转入就绪状态。
- 5. `死亡状态(Dead)`：线程执行完了或者因异常退出了 `run()` 方法，该线程结束生命周期。

# Thread 和 Runnable

Runnable 是一个接口，该接口中只包含了一个 `run()` 方法。它的定义如下：

~~~java
public interface Runnable {
    public abstract void run();
}
~~~

我们可以定义一个类 A 实现 Runnable 接口；然后，通过 `new Thread(new A())` 等方式新建线程。

Thread 是一个类。Thread 本身就实现了 Runnable 接口。它的声明如下：

~~~java
public class Thread implements Runnable {
	public Thread() {}
	public Thread(Runnable target) {}
	public Thread(ThreadGroup group, Runnable target){}
	public Thread(String name){}
	public Thread(ThreadGroup group, String name){}
	public Thread(Runnable target, String name){}
	public Thread(ThreadGroup group, Runnable target, String name){}
	public Thread(ThreadGroup group, Runnable target, String name,long stackSize){}
}
~~~

**相同点**：

都是“多线程的实现方式”。

**不同点**：

Thread 是类，而 Runnable 是接口；Thread 本身是实现了 Runnable 接口的类。我们知道“一个类只能有一个父类，但是却能实现多个接口”，因此 Runnable 具有更好的扩展性。

此外，Runnable 还可以用于“资源的共享”。即，**多个线程都是基于某一个Runnable对象建立的**，它们会共享这个Runnable对象上的资源。

## 创建和运行线程的两种方法：

~~~java
//测试Runnable类实现的多线程程序 
public class DoSomething implements Runnable { 
    private String name; 

    public DoSomething(String name) { 
        this.name = name; 
    } 

    public void run() { 
        for (int i = 0; i < 5; i++) { 
            for (long k = 0; k < 100000000; k++) ; 
            System.out.println(name + ": " + i); 
        } 
    } 
}

public class TestRunnable { 
    public static void main(String[] args) { 
        DoSomething ds1 = new DoSomething("javachen"); 
        DoSomething ds2 = new DoSomething("blog"); 

        Thread t1 = new Thread(ds1); 
        Thread t2 = new Thread(ds2); 

        t1.start(); 
        t2.start(); 
    } 
}
~~~

~~~java
//测试扩展Thread类实现的多线程程序 
public class TestThread extends Thread{ 
    public TestThread(String name) { 
        super(name); 
    } 

    public void run() { 
        for(int i = 0;i<5;i++){ 
            for(long k= 0; k <100000000;k++); 
            System.out.println(this.getName()+" :"+i); 
        } 
    } 

    public static void main(String[] args) { 
        Thread t1 = new TestThread("javachen"); 
        Thread t2 = new TestThread("blog"); 
        t1.start(); 
        t2.start(); 
    } 
}
~~~

## start() 和 run()

- `start()`：它的作用是启动一个新线程，新线程会执行相应的 `run()`方法。`start()` 不能被重复调用。

- `run()`：和普通的成员方法一样，可以被重复调用。单独调用 `run()` 的话，会在当前线程中执行 `run()`，而并不会启动新线程！

在调用 `start()`方法之前，线程处于新状态中，新状态指有一个 Thread 对象，但还没有一个真正的线程。
 
在调用 `start()`方法之后，发生了一系列复杂的事情：

- 启动新的执行线程（具有新的调用栈）；
- 该线程从新状态转移到可运行状态；
- 当该线程获得机会执行时，其目标 `run()`方法将运行。

## wait(), notify(), notifyAll()

在 Object.java 中，定义了 `wait()`, `notify()` 和 `notifyAll()` 等接口。`wait()` 的作用是让**当前线程**进入等待状态，同时，`wait()` 也会让当前线程释放它所持有的锁。而 `notify()` 和 `notifyAll()` 的作用，则是唤醒当前对象上的等待线程；`notify()` 是唤醒单个线程，而 `notifyAll()`是唤醒所有的线程。

`notify()`,` wait()` 依赖于“同步锁”，而“同步锁”是对象锁持有，并且每个对象有且仅有一个！

在 java 中，任何对象都有一个锁池，用来存放等待该对象锁标记的线程，线程阻塞在对象锁池中时，不会释放其所拥有的其它对象的锁标记。

在 java 中，任何对象都有一个等待队列，用来存放线程，线程 t1对（让）o调用 wait 方法,必须放在对 o 加锁的同步代码块中! 
	
- 1. t1 会释放其所拥有的所有锁标记;
- 2. t1会进入 o 的等待队列
    
 t2 对（让）o调用 notify/notifyAll 方法,也必须放在对 o 加锁的同步代码块中! 会从 o 的等待队列中释放一个/全部线程，对 t2 毫无影响，t2 继续执行。

## yield()

`Thread.yield()` 方法作用是：暂停当前正在执行的线程对象，并执行其他线程。

`yield()` 应该做的是让当前运行线程回到可运行状态，以允许具有相同优先级的其他线程获得运行机会。因此，使用 `yield()` 的目的是让相同优先级的线程之间能适当的轮转执行。

但是，实际中无法保证 `yield()` 达到让步目的，因为让步的线程还有可能被线程调度程序再次选中。

结论：`yield()`从未导致线程转到等待/睡眠/阻塞状态。在大多数情况下，`yield()` 将导致线程从运行状态转到可运行状态，但有可能没有效果。

**wait()是会线程释放它所持有对象的同步锁，而yield()方法不会释放锁。**

## sleep()

`sleep()` 的作用是让当前线程休眠，即当前线程会从 `运行状态` 进入到 `休眠(阻塞)状态` 。`sleep()` 会指定休眠时间，线程休眠的时间会大于/等于该休眠时间；在线程重新被唤醒时，它会由 `阻塞状态` 变成 `就绪状态`，从而等待 cpu 的调度执行。

**wait()会释放对象的同步锁，而sleep()则不会释放锁。**

## join()

Thread的非静态方法 `join()` 让一个线程 B “加入” 到另外一个线程 A 的尾部。在 A 执行完毕之前，B 不能工作。例如：

~~~java
Thread t = new MyThread();
t.start();
t.join();
~~~

另外，`join()` 方法还有带超时限制的重载版本。 例如 `t.join(5000);` 让线程等待5000毫秒，如果超过这个时间，则停止等待，变为可运行状态。

##  interrupt()

interrupt()的作用是中断本线程。

本线程中断自己是被允许的；其它线程调用本线程的 interrupt() 方法时，会通过 checkAccess() 检查权限。这有可能抛出 SecurityException 异常。

如果本线程是处于阻塞状态：调用线程的wait(), wait(long)或 wait(long, int)会让它进入等待(阻塞)状态，或者调用线程的join(), join(long), join(long, int), sleep(long), sleep(long, int) 也会让它进入阻塞状态。若线程在阻塞状态时，调用了它的 `interrupt()`方法，那么它的“中断状态”会被清除并且会收到一个 InterruptedException 异常。

例如，线程通过 wait() 进入阻塞状态，此时通过 interrupt() 中断该线程；调用 interrupt() 会立即将线程的中断标记设为“true”，但是由于线程处于阻塞状态，所以该“中断标记”会立即被清除为“false”，同时，会产生一个 InterruptedException 的异常。

如果线程被阻塞在一个 Selector 选择器中，那么通过 interrupt() 中断它时；线程的中断标记会被设置为 true，并且它会立即从选择操作中返回。

如果不属于前面所说的情况，那么通过 interrupt() 中断线程时，它的中断标记会被设置为“true”。中断一个“已终止的线程”不会产生任何操作。

**interrupt()常常被用来终止“阻塞状态”线程。**

interrupted() 和 isInterrupted()都能够用于检测对象的“中断标记”。

区别是，interrupted()除了返回中断标记之外，它还会清除中断标记(即将中断标记设为false)；而isInterrupted()仅仅返回中断标记。

# 线程的同步与锁

**线程的同步** 是为了防止多个线程访问一个数据对象时，对数据造成的破坏。

Java中每个对象都有一个内置锁。当程序运行到非静态的 synchronized 同步方法上时，自动获得与正在执行代码类的当前实例有关的锁。获得一个对象的锁也称为获取锁、锁定对象、在对象上锁定或在对象上同步。
 
当程序运行到 synchronized 同步方法或代码块时才该对象锁才起作用。
 
一个对象只有一个锁。所以，如果一个线程获得该锁，就没有其他线程可以获得锁，直到第一个线程释放（或返回）锁。这也意味着任何其他线程都不能进入该对象上的 synchronized 方法或代码块，直到该锁被释放。`释放锁` 是指持锁线程退出了synchronized同步方法或代码块。

**关于锁和同步，有一下几个要点**：

- 1）、只能同步方法，而不能同步变量和类；
- 2）、每个对象只有一个锁；当提到同步时，应该清楚在什么上同步？也就是说，在哪个对象上同步？
- 3）、不必同步类中所有的方法，类可以同时拥有同步和非同步方法。
- 4）、如果两个线程要执行一个类中的 synchronized 方法，并且两个线程使用相同的实例来调用方法，那么一次只能有一个线程能够执行方法，另一个需要等待，直到锁被释放。也就是说：如果一个线程在对象上获得一个锁，就没有任何其他线程可以进入（该对象的）类中的任何一个同步方法。
- 5）、如果线程拥有同步和非同步方法，则非同步方法可以被多个线程自由访问而不受锁的限制。
- 6）、线程睡眠时，它所持的任何锁都不会释放。
- 7）、线程可以获得多个锁。比如，在一个对象的同步方法里面调用另外一个对象的同步方法，则获取了两个对象的同步锁。
- 8）、同步损害并发性，应该尽可能缩小同步范围。同步不但可以同步整个方法，还可以同步方法中一部分代码块。
- 9）、在使用同步代码块时候，应该指定在哪个对象上同步，也就是说要获取哪个对象的锁。

举例：

~~~java
//对方法同步
public synchronized int getX() {
    return x++;
}

//对代码块同步
public int getX() {
    synchronized (this) {
        return x;
    }
}    

//对静态方法同步
public static synchronized int setName(String name){
    Xxx.name = name;
}

//对静态方法中的代码块同步
public static int setName(String name){
    synchronized(Xxx.class){
        Xxx.name = name;
    }
}
~~~

# 参考资料

- [Java多线程编程总结](http://lavasoft.blog.51cto.com/62575/27069)

---
layout: post

title: Python中的多线程

category: python

tags: [ python]

description: Python 通过两个标准库 thread 和 threading 提供对线程的支持。Python 的 thread 模块是比较底层的模块，Python 的 threading 模块是对 thread 做了一些包装的，可以更加方便的被使用。

published: true

---

### 线程模块

Python 通过两个标准库 thread 和 threading 提供对线程的支持。Python 的 thread 模块是比较底层的模块，Python 的 threading 模块是对 thread 做了一些包装的，可以更加方便的被使用。

**thread 模块提供的其他方法：**

- `start_new_thread(function,args,kwargs=None)`：生一个新线程，在新线程中用指定参数和可选的 kwargs 调用 function 函数
- `allocate_lock()`：分配一个 **LockType** 类型的锁对象（注意，此时还没有获得锁）
- `interrupt_main()`：在其他线程中终止主线程
- `get_ident()`：获得一个代表当前线程的魔法数字，常用于从一个字典中获得线程相关的数据。这个数字本身没有任何含义，并且当线程结束后会被新线程复用
- `exit()`：退出线程

**LockType 类型锁对象的函数：**

- `acquire(wait=None)`：尝试获取锁对象
- `locked()`：如果获得了锁对象返回 True，否则返回 False
- `release()`：释放锁

thread 还提供了一个 ThreadLocal 类用于管理线程相关的数据，名为 `thread._local`，threading 中引用了这个类。

*由于 thread 提供的线程功能不多，无法在主线程结束后继续运行，不提供条件变量等等原因，一般不使用 thread 模块。*

**threading 模块提供的其他方法：**

- `threading.currentThread()`：返回当前的线程变量。
- `threading.enumerate()`：返回一个包含正在运行的线程的 list。正在运行指线程启动后、结束前，不包括启动前和终止后的线程。
- `threading.activeCount()`：返回正在运行的线程数量，与 `len(threading.enumerate())` 有相同的结果。

除了使用方法外，线程模块同样提供了 Thread 类来处理线程，构造方法：

~~~python
Thread(group=None, target=None, name=None, args=(), kwargs={})
~~~

**参数说明：**

- `group`：线程组，目前还没有实现，库引用中提示必须是 None；
- `target`：要执行的方法；
- `name`：线程名；
- `args/kwargs`：要传入方法的参数。

Thread 类提供了以下实例方法:

- `run()`：用以表示线程活动的方法。
- `start()`：启动线程活动。
- `join([timeout])`：阻塞当前上下文环境的线程，直到调用此方法的线程终止或到达指定的 timeout（可选参数）。
- `isAlive()`：返回线程是否活动的。
- `getName()`：返回线程名。
- `setName()`：设置线程名。

threading 模块提供的类：Thread, Lock, Rlock, Condition, [Bounded]Semaphore, Event, Timer, local。

### 使用 thread 模块创建线程

**函数式：** 调用 thread 模块中的 `start_new_thread()` 函数来产生新线程。语法如下:

~~~python
thread.start_new_thread ( function, args[, kwargs] )
~~~

**参数说明：**

- `function` - 线程函数。
- `args` - 传递给线程函数的参数，他必须是个 tuple 类型。
- `kwargs` - 可选参数。

例子1：

~~~python
# -* - coding: UTF-8 -* -

import thread
import time

# 为线程定义一个函数
def print_time( threadName, delay):
    count = 0
    while count < 5:
      time.sleep(delay)
      count += 1
      print "%s: %s" % ( threadName, time.ctime(time.time()) )


# 创建两个线程
try:
   thread.start_new_thread( print_time, ("Thread-1", 1, ) )
   thread.start_new_thread( print_time, ("Thread-2", 2, ) )
except:
   print "Error: unable to start thread"

while 1:
   pass
~~~

输出结果如下：

~~~
Thread-1: Tue Dec 23 14:54:51 2014
Thread-2: Tue Dec 23 14:54:52 2014
Thread-1: Tue Dec 23 14:54:52 2014
Thread-1: Tue Dec 23 14:54:53 2014
Thread-2: Tue Dec 23 14:54:54 2014
Thread-1: Tue Dec 23 14:54:54 2014
Thread-1: Tue Dec 23 14:54:55 2014
Thread-2: Tue Dec 23 14:54:56 2014
Thread-2: Tue Dec 23 14:54:58 2014
Thread-2: Tue Dec 23 14:55:00 2014
~~~

主线程没有结束，是因为有个 while 循环一直在执行 pass 语句，导致程序一直没有退出。如果想要主线程主动结束，可以在线程函数中调用 `thread.exit()`，他抛出SystemExit exception，达到退出线程的目的。

### 使用 Threading 模块创建线程

使用 Threading 模块创建线程，直接从 `threading.Thread` 继承，然后重写 `__init__` 方法和`run` 方法。

例子2：

~~~python
# -* - coding: UTF-8 -* -
#!/usr/bin/python

from threading import Thread
import time

#继承父类threading.Thread
class myThread(Thread):

    def __init__(self, name, delay):
        Thread.__init__(self)
        self.name = name
        self.delay = delay

    def run(self):                   #把要执行的代码写到run函数里面 线程在创建后会直接运行run函数
        print "Starting " + self.name
        print_time(self.name, self.delay, 5)
        print "Exiting " + self.name

def print_time(threadName, delay, counter):
    while counter:
        time.sleep(delay)
        print "%s: %s" % (threadName, time.ctime(time.time()))
        counter -= 1

# 创建新线程
thread1 = myThread("Thread-1", 1)
thread2 = myThread("Thread-2", 2)

# 开启线程
thread1.start()
thread2.start()

print "Exiting Main Thread"
~~~

执行结果如下：

~~~
Starting Thread-1
Starting Thread-2
Starting Thread-3
Thread-3 processing One
Thread-2 processing Two
Thread-3 processing Three
Thread-1 processing Four
Thread-2 processing Five
Exiting Thread-3
Exiting Thread-1
Exiting Thread-2
Exiting Main Thread
~~~

### 线程同步

如果多个线程共同对某个数据修改，则可能出现不可预料的结果，为了保证数据的正确性，需要对多个线程进行同步。

使用 Thread 对象的 `Lock` 和 `Rlock` 可以实现简单的线程同步，这两个对象都有 acquire 方法和 release 方法，对于那些需要每次只允许一个线程操作的数据，可以将其操作放到 acquire 和 release 方法之间。

**Lock**（指令锁）是可用的最低级的同步指令。Lock 处于锁定状态时，不被特定的线程拥有。Lock 包含两种状态——锁定和非锁定，以及两个基本的方法。

可以认为 Lock 有一个锁定池，当线程请求锁定时，将线程至于池中，直到获得锁定后出池。池中的线程处于状态图中的同步阻塞状态。

**构造方法：**

~~~python
Lock()
~~~

**实例方法：**

- `acquire([timeout])`：使线程进入同步阻塞状态，尝试获得锁定。
- `release()`：释放锁。使用前线程必须已获得锁定，否则将抛出异常。

**RLock**（可重入锁）是一个可以被同一个线程请求多次的同步指令。RLock 使用了**拥有的线程**和**递归等级**的概念，处于锁定状态时，RLock 被某个线程拥有。拥有RLock的线程可以再次调用acquire()，释放锁时需要调用 release() 相同次数。

可以认为 RLock 包含一个锁定池和一个初始值为0的计数器，每次成功调用 `acquire()/release()`，计数器将 +1/-1，为0时锁处于未锁定状态。

例子3：

~~~python
# -* - coding: UTF-8 -* -

#!/usr/bin/python

from threading import Thread,Lock
import time

threadLock = Lock()

class myThread (Thread):
    def __init__(self, name, delay):
        Thread.__init__(self)
        self.name = name
        self.delay = delay

    def run(self):
        print "Starting " + self.name
       # 获得锁，成功获得锁定后返回True
       # 可选的timeout参数不填时将一直阻塞直到获得锁定
       # 否则超时后将返回False
        threadLock.acquire()
        print_time(self.name, self.delay, 3)
        # 释放锁
        threadLock.release()

def print_time(threadName, delay, counter):
    while counter:
        time.sleep(delay)
        print "%s: %s" % (threadName, time.ctime(time.time()))
        counter -= 1

# 创建新线程
thread1 = myThread( "Thread-1", 1)
thread2 = myThread("Thread-2", 2)

# 开启新线程
thread1.start()
thread2.start()

# 等待所有线程完成
thread1.join()
thread2.join()

print "Exiting Main Thread"
~~~

运行结果：

~~~
Starting Thread-1
Starting Thread-2
Thread-1: Tue Dec 23 16:06:32 2014
Thread-1: Tue Dec 23 16:06:33 2014
Thread-1: Tue Dec 23 16:06:34 2014
Thread-2: Tue Dec 23 16:06:36 2014
Thread-2: Tue Dec 23 16:06:38 2014
Thread-2: Tue Dec 23 16:06:40 2014
Exiting Main Thread
~~~

例子3和例子2的区别在于，例子上中 `print_time` 方法前后添加了 threadLock 的两个方法，并且在主线程调用了两个线程的 join 方法，
使得主线程阻塞直到两个子线程运行完成。待子线程运行完成之后，最后才会打印 `Exiting Main Thread` ，即表示主线程运行完成。

除了使用 Lock 类获取锁之外，我们还可以使用 Condition 类，condition 的 acquire() 和 release() 方法内部调用了 lock 的 acquire() 和 release()，所以我们可以用 condiction 实例取代 lock 实例，但 lock 的行为不会改变。

### 线程优先级队列

Python 的 Queue 模块中提供了同步的、线程安全的队列类，包括 FIFO（先入先出)队列 Queue，LIFO（后入先出）队列 LifoQueue，和优先级队列 PriorityQueue。这些队列都实现了锁原语，能够在多线程中直接使用。可以使用队列来实现线程间的同步。

Queue模块中的常用方法:

- `Queue.qsize()`：返回队列的大小
- `Queue.empty()`：如果队列为空，返回 True，反之 False
- `Queue.full()`：如果队列满了，返回 True，反之 False
- `Queue.full`：与 maxsize 大小对应
- `Queue.get([block[, timeout]])`：获取队列，timeout 等待时间
- `Queue.get_nowait()`：相当 `Queue.get(False)`
- `Queue.put(item)`：写入队列，timeout 等待时间
- `Queue.put_nowait(item)`：相当 `Queue.put(item, False)`
- `Queue.task_done()`：在完成一项工作之后，`Queue.task_done()` 函数向任务已经完成的队列发送一个信号
- `Queue.join()`：实际上意味着等到队列为空，再执行别的操作

实例4：

~~~python
# -* - coding: UTF-8 -* -

#!/usr/bin/python

from threading import Thread,Lock
import Queue
import time

threadList = ["Thread-1", "Thread-2", "Thread-3"]
nameList = ["One", "Two", "Three", "Four", "Five"]
workQueue = Queue.Queue(10)
queueLock = Lock()
threads = []
exitFlag = 0

class myThread (Thread):
    def __init__(self, name, q):
        Thread.__init__(self)
        self.name = name
        self.q = q

    def run(self):
        print "Starting " + self.name
        process_data(self.name, self.q)
        print "Exiting " + self.name

def process_data(threadName, q):
    while not exitFlag:
        queueLock.acquire()
        if not workQueue.empty():
            data = q.get()
            queueLock.release()
            print "%s processing %s" % (threadName, data)
        else:
            queueLock.release()
        time.sleep(1)

# 创建新线程
for tName in threadList:
    thread = myThread(tName, workQueue)
    thread.start()
    threads.append(thread)

# 填充队列
queueLock.acquire()
for word in nameList:
    workQueue.put(word)
queueLock.release()

# 等待队列清空
while not workQueue.empty():
    pass

# 通知线程是时候退出
exitFlag = 1

# 等待所有线程完成
for t in threads:
    t.join()
print "Exiting Main Thread"
~~~

例子4中创建了3个线程读取队列的数据，当队列为空时候，三个线程停止运行，另外主线程会一直阻塞直到三个子线程运行完毕，最后再打印 "Exiting Main Thread"。

### 生产者和消费者模型

> 生产者的工作是产生一块数据，放到 buffer 中，如此循环。与此同时，消费者在消耗这些数据（例如从 buffer 中把它们移除），每次一块。
> 这个为描述了两个共享固定大小缓冲队列的进程，即生产者和消费者。

示例5：

~~~python
from threading import Thread, Condition
import time
import random

queue = []
MAX_NUM = 10
condition = Condition()

class ProducerThread(Thread):
    def run(self):
        nums = range(5)
        global queue
        while True:
            condition.acquire()
            if len(queue) == MAX_NUM:
                print "Queue full, producer is waiting"
                condition.wait()
                print "Space in queue, Consumer notified the producer"
            num = random.choice(nums)
            queue.append(num)
            print "Produced", num
            condition.notify()
            condition.release()
            time.sleep(random.random())

class ConsumerThread(Thread):
    def run(self):
        global queue
        while True:
            condition.acquire()
            if not queue:
                print "Nothing in queue, consumer is waiting"
                condition.wait()
                print "Producer added something to queue and notified the consumer"
            num = queue.pop(0)
            print "Consumed", num
            condition.notify()
            condition.release()
            time.sleep(random.random())

ProducerThread().start()
ConsumerThread().start()
~~~

上面例子中使用了 **Condition**，Condition（条件变量）通常与一个锁关联。需要在多个 Contidion 中共享一个锁时，可以传递一个 Lock/RLock 实例给构造方法，否则它将自己生成一个RLock实例。

可以认为，除了 Lock 带有的锁定池外，Condition 还包含一个等待池，池中的线程处于状态图中的等待阻塞状态，直到另一个线程调用 notify()/notifyAll() 通知；得到通知后线程进入锁定池等待锁定。

**构造方法：**

~~~python
Condition([lock/rlock])
~~~

**实例方法：**

- `acquire([timeout])/release()`：调用关联的锁的相应方法。
- `wait([timeout])`：调用这个方法将使线程进入 Condition 的等待池等待通知，并释放锁。使用前线程必须已获得锁定，否则将抛出异常。
- `notify()`：调用这个方法将从等待池挑选一个线程并通知，收到通知的线程将自动调用 acquire() 尝试获得锁定（进入锁定池）；其他线程仍然在等待池中。调用这个方法不会释放锁定。使用前线程必须已获得锁定，否则将抛出异常。
- `notifyAll()`：调用这个方法将通知等待池中所有的线程，这些线程都将进入锁定池尝试获得锁定。调用这个方法不会释放锁定。使用前线程必须已获得锁定，否则将抛出异常。

例子5中生产者和消费者共享一个 list 集合，其实也可以换成 queue。

例子6：

~~~python
from threading import Thread
import time
import random
from Queue import Queue

queue = Queue(3)

class ProducerThread(Thread):
    def run(self):
        nums = range(5)
        global queue
        while True:
            num = random.choice(nums)
            queue.put(num)
            print "Produced", num
            time.sleep(random.random())

class ConsumerThread(Thread):
    def run(self):
        global queue
        while True:
            num = queue.get()
            queue.task_done()
            print "Consumed", num
            time.sleep(random.random())

ProducerThread().start()
ConsumerThread().start()
~~~

**解释：**

- 在原来使用 list 的位置，改为使用 Queue 实例（下称队列）。
- 这个队列有一个 condition ，它有自己的 lock。如果你使用 Queue，你不需要为 condition 和 lock 而烦恼。
- 生产者调用队列的 put 方法来插入数据。
- put() 在插入数据前有一个获取 lock 的逻辑。
- 同时，put() 也会检查队列是否已满。如果已满，它会在内部调用 wait()，生产者开始等待。
- 消费者使用get方法。
- get() 从队列中移出数据前会获取 lock。
- get() 会检查队列是否为空，如果为空，消费者进入等待状态。
- get() 和 put() 都有适当的 notify()。

### 总结

本文主要介绍了 Python 中创建多线程的两种方法，并简单说了 threading 模块中的 Lock、RLock、Condition 三个类以及 Queue 类的使用方法，另外，还通过代码实现了生产者和消费者模型。

### 参考文章

- [Python多线程](http://www.w3cschool.cc/python/python-multithreading.html)
- [Python中的生产者消费者问题](http://blog.jobbole.com/52412/)

---
layout: post

title: 高级Bash脚本编程入门

category: devops

tags: [bash]

description: 最近在看《Advanced Bash Scripting Guide》这本书，第二章举了一个清除日志的例子，来讲述如何使用Bash进行编程并聊到了一些编程规范。本文主要是基于这部分内容记录我的读书笔记并整理一些相关知识点。

published: true

---

最近在看《Advanced Bash Scripting Guide》这本书，第二章举了一个清除日志的例子，来讲述如何使用Bash进行编程并聊到了一些编程规范。本文主要是基于这部分内容记录我的读书笔记并整理一些相关知识点。

说到清除日志，你可以使用下面命令来完成清除/var/log下的log文件这件事情：

~~~bash
cd /var/log
cat /dev/null > messages 
cat /dev/null > wtmp
echo "Logs cleaned up."
~~~

更简单的清除日志方法是：

~~~bash
echo "" >messages 
#或者
>messages 
~~~

>注意：
>/var/log/messages 记录系统报错信息
>/var/log/wtmp 记录系统登录信息

在Bash编程时，脚本通常都是放到一个文件里面，该文件可以有后缀名也可以没有，例如，你可以将该文件命名为cleanlog，然后在文件头声明一个命令解释器，这里是`#!/bin/bash`：

~~~bash
#!/bin/bash
LOG_DIR=/var/log
cd $LOG_DIR
cat /dev/null > messages
cat /dev/null > wtmp
echo "Logs cleaned up."
exit
~~~

当然，还可以使用其他的命令行解释器，例如：

~~~bash
#!/bin/sh
#!/bin/bash
#!/usr/bin/perl 
#!/usr/bin/tcl 
#!/bin/sed -f
#!/usr/awk -f

#自删除脚本
#!/bin/rm
~~~

说明：

- `#!` 后面的路径必须真实存在，否则运行时会提示`Command not found的错误`。
- 在UNIX系统中，在`!`后边需要一个空格。
- 如果脚本中还包含有其他的`#!`行，那么bash将会把它看成是一个一般的注释行。

上面代码将/var/log定义为变量，这样会比把代码写死好很多，因为如果你可能想修改为其他目录，只需要修改变量的值就可以。

对于/var/log目录，一般用户没有访问权限，故需要使用root用户来运行上面脚本，另外，用户不一定有修改目录的权限，所以需要增强代码，做一些判断。

~~~bash
#!/bin/bash

LOG_DIR=/var/log
ROOT_UID=0
LINES=50
E_XCD=66
E_NOTROOT=67

# 当然要使用root 用户来运行.
if [ "$UID" -ne "$ROOT_UID" ]
then
    echo "Must be root to run this script."
    exit $E_NOTROOT
fi

cd $LOG_DIR

if[ "$PWD" != "$LOG_DIR" ]
then
    echo "Can't change to $LOG_DIR."
    exit $E_XCD
fi

cat /dev/null > messages
cat /dev/null > wtmp
echo "Logs cleaned up."

#返回0表示成功
exit 0
~~~

上面代码一样定义了一些变量，然后加了两个判断，去检查脚本运行中可能出现的错误并打印错误说明。如果脚本运行错误，则程序会退出并返回一个错误码，不同类型的错误对应的错误码不一样，这样便于识别错误原因；如果脚本运行正常，则正常退出，默认返回码为0。

对于`cd $LOG_DIR`操作判断是否执行成功，更有效的做法是：

~~~bash
#使用或操作替代if else判断
cd /var/log || {
    echo "Cannot change to necessary directory." >&2
    exit $E_XCD
}
~~~

通常，我们可能不想全部清除日志，而是保留最后几行日志，这样就需要给脚本传入参数：

~~~bash
#!/bin/bash

LOG_DIR=/var/log
ROOT_UID=0
LINES=50
E_XCD=66
E_NOTROOT=67

# 当然要使用root 用户来运行.
if [ "$UID" -ne "$ROOT_UID" ]
then
    echo "Must be root to run this script."
    exit $E_NOTROOT
fi

cd $LOG_DIR

if[ "$PWD" != "$LOG_DIR" ]
then
    echo "Can't change to $LOG_DIR."
    exit $E_XCD
fi

# 测试是否有命令行参数，非空判断
if [ -n "$1" ]
then
    lines=$1
else
    lines=$LINES # 默认，如果不在命令行中指定
fi

# 保存log file消息的最后部分
tail -$lines messages > mesg.temp
mv mesg.temp messages

cat /dev/null > wtmp
echo "Logs cleaned up."

#返回0表示成功
exit 0
~~~

上面使用if else来判断是否有输入参数，一个更好的检测命令行参数的方式是使用正则表达式做判断，以检查输入参数的合法性：

~~~bash
E_WRONGARGS=65 # 非数值参数(错误的参数格式)

case "$1" in
    "" ) lines=50;;
    *[!0-9]*) echo "Usage: `basename $0` file-to-cleanup"; exit $E_WRONGARGS;; 
    * ) lines=$1;;
esac
~~~

编写完脚本之后，你可以使用`sh scriptname`或者`bash scriptname`来调用这个脚本。不推荐使用`sh <scriptname`，因为这禁用了脚本从stdin中读数据的功能。更方便的方法是让脚本本身就具有 可执行权限，通过`chmod`命令可以修改。比如:

~~~bash
chmod 555 scriptname  #允许任何人都具有可读和执行权限
~~~

或者：

~~~bash
chmod +rx scriptname #允许任何人都具有可读和执行权限 
chmod u+rx scriptname #只给脚本的所有者可读和执行权限
~~~

既然脚本已经具有了可执行权限，现在你可以使用`./scriptname`来测试这个脚本了。如果这个脚本以一个`#!`行开头，那么脚本将会调用合适的命令解释器来运行。

这样一个简单的脚本就编写完成并能运行了，从这个例子中，我们可以学到bash编程的一些代码规范：

- 使用变量
- 脚本运行中，需要做一些异常判断

除此之外，google公司还定义了一份[Shell Style Guide](https://google-styleguide.googlecode.com/svn/trunk/shell.xml)，可以仔细阅读并约束自己去遵循这些规范。

# 参考文章

- [高级Bash脚本编程指南-中文版](http://blog.javachen.com/static/doc/abs-guide/html/index.html)

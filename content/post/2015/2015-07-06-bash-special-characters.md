---
layout: post

title: Bash中的特殊字符
date: 2015-07-06T08:00:00+08:00

categories: [ devops ]

tags: [bash]

description:  本文根据《Advanced Bash Scripting Guide》这本书整理而来。Bash中，用在脚本和其他地方的字符叫做特殊字符。

published: true

---

Bash中，用在脚本和其他地方的字符叫做特殊字符。下面依次举例介绍每个字符的用途。

## `#`

行首以`#`(`#!`是个例外)开头是注释。

~~~bash
# This line is a comment.
~~~

注释也可以放在于本行命令的后边。

~~~bash
echo "A comment will follow."   # 注释在这里。
~~~

>命令是不能放在同一行上注释的后边的。因为没有办法把注释结束掉，好让同一行上后边的"代码生效"，只能够另起一行来使用下一个命令。

在echo中转义的`#`是不能作为注释的，同样也可以出现在特定的参数替换结构中，或者是出现在数字常量表达式中。

~~~bash
echo "The # here does not begin a comment." 
echo 'The # here does not begin a comment.' 
echo The \# here does not begin a comment.    #转义字符\
echo The # 这里开始一个注释.
echo ${PATH#*:}   # 参数替换, 不是一个注释
echo $(( 2#101011 ))   # 数制转换, 不是一个注释
~~~

标准的引用和转义字符`" ' \`可以用来转义`#`，某些特定的模式匹配操作也可以使用`#`。

##  `;`


分号作为命令行分隔符，可以在同一行上写两个或两个以上的命令。

~~~bash
echo hello; echo there

if [ -x "$filename" ]; then
    echo "File $filename exists.";
else
    echo "File $filename not found."; touch $filename 
fi; echo "File test complete."    
~~~

在某些情况下，`; `也可以被转义。

## `;;`

终止case选项。

~~~bash
case "$variable" in
    abc) echo "\$variable = abc" ;; 
    xyz) echo "\$variable = xyz" ;;
esac
~~~

## `.`

点命令等价于`source`命令，这是一个bash的内建命令。

如果点放在文件名的开头的话，那么这个文件将会成为"隐藏"文件，并且`ls`命令将不会正常的显示出这个文件。

如果作为目录名的话，一个单独的点代表当前的工作目录，而两个点表示上一级目录。

点也可以表示当前目录。

~~~bash
cp /home/javachen/current_work/* .
~~~

当用作匹配字符的作用时，通常都是作为正则表达式的一部分来使用，点用来匹配任何的单个字符。

## `"`,`'`

双引号为部分引用，单引号为全引用。

~~~bash
echo "The # here does not begin a comment." 
echo 'The # here does not begin a comment.' 
~~~

## `,`

逗号操作费，链接了一系列的算术操作。 虽然里边所有的内容都被运行了，但只有最后一项被返回。

~~~bash
let "t2 = ((a = 9, 15 / 3))" # a = 9   t2 = 15 / 3
~~~

也可以这样使用：

~~~bash
mkdir -p {a,b,c}  #创建三个目录a、b、c
~~~

## `\`

转义符，一种对单字符的引用机制，通常是用于对单字符进行转义。`\`通常用来转义`"`和`'`，这样双引号和但引号就不会被解释成特殊含义了。

## `/`

文件名路径分隔符，分隔文件名不同的部分，也可以用来作为除法算术操作符。

~~~bash
/home/bozo/projects/Makefile
let "t2 = ((a = 9, 15 / 3))" # a = 9   t2 = 15 / 3
~~~

## \`

命令替换，`command`结构可以将命令的输出赋值到一个变量中去。

~~~bash
date=`date`
~~~

## `:`

空命令，等价于"NOP"，什么都不做，也可以被认为与shell的内建命令true作用相同。":"命令是一个bash的内建命令，它的退出码是"true"，即为0。

~~~bash
:
echo $? # 0
~~~

死循环：

~~~bash
while :   # while true
do
    date
done
~~~

在 if/then 中的占位符，什么都不做，引出分支。

~~~bash
if condition
then :          # 什么都不做，引出分支
else
    take-some-action
fi
~~~

在一个二元命令中提供一个占位符。

~~~bash
n=1
: $((n = $n + 1))  # 如果没有":"的话，Bash 将会尝试把 $((n = $n + 1)) 解释为一个命令，运行时会报错
echo -n "$n "
~~~

在here document中提供一个命令所需的占位符或者用于注释代码。

~~~bash
: <<TESTVARIABLES
${HOSTNAME?}${USER?}${MAIL?} # 如果其中某个变量没被设置, 那么就打印错误信息. 
TESTVARIABLES


: <<COMMENTBLOCK
echo "This line will not echo."
This is a comment line missing the "#" prefix.
This is another comment line missing the "#" prefix.
&*@!!++=
The above line will cause no error message,
because the Bash interpreter will ignore it.
COMMENTBLOCK
~~~

使用参数替换来评估字符串变量。

~~~bash
: ${HOSTNAME ?} ${USER?} ${MAIL?}  #如果一个或多个必要的环境变量没被设置的话，就打印错误信息.
~~~

在与`>`重定向操作符结合使用时，将会把一个文件清空，但是并不会修改这个文件的权限。如果之前这个文件并不存在，那么就创建这个文件。

~~~bash
: > data.xxx  # 文件"data.xxx" 现在被清空了
# 与 cat /dev/null >data.xxx 的作用相同
# 然而，这并不会产生一个新的进程，因为":"是一个内建命令
~~~

在与`>>`重定向操作符结合使用时，将不会对预先存在的目标文件产生任何影响。如果这个文件之前并不存在，那么就创建它。`这只适用于正规文件,，而不适用于管道、符号连接和某些特殊文件`。

~~~bash
: >> target_file
~~~

也可能用来作为注释行，虽然我们不推荐这么做。使用#来注释的话，将关闭剩余行的错误检查，所以可以在注释行中写任何东西。然而，使用:的话将不会这样。

~~~bash
: This is a comment that generates an error, ( if [ $x -eq 3] fi ).
~~~

":"还用来在/etc/passwd和`$PATH`变量中做分隔符。

~~~bash
echo $PATH
/usr/java/default/bin:/usr/lib64/qt-3.3/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
~~~

## `!`

取反操作符。`! `操作符将会反转命令的退出码的结果：

~~~bash
true        # "true" 是内建命令
echo "exit status of \"true\" = $?"         # 0

! true
echo "exit status of \"! true\" = $?"       # 1
~~~

如果一个命令以`!`开头，那么会启用Bash的历史机制。

~~~bash
true
!true
# 这次就没有错误了, 也没有反转结果.它只是重复了之前的命令(true).
~~~

在另一种上下文中，如命令行模式下，`!`还能反转bash的历史机制。需要注意 的是，在一个脚本中，历史机制是被禁用的。

~~~bash
$ history |head -n 10
   18  date
   19  ls
   20  cd
   21  pwd
   22  jps
   23  java
   24  ll
   25  ps
   26  history

#执行bash历史中的一条命令
$ !25

~~~

`! `操作符还是Bash的关键字。

在一个不同的上下文中，`! `也会出现在变量的`间接引用`中。

~~~bash
a=letter_of_alphabet
letter_of_alphabet=z

# 直接引用.
echo "a = $a"   # a = letter_of_alphabet

# 间接引用.
eval a=\$$a 
echo "Now a=$a"    #Now a = z

# 间接引用.
echo ${!a}  # a = z
~~~

## `*`

用来做文件名匹配：

~~~bash
$ echo *
abs-book.sgml add-drive.sh agram.sh alias.sh
~~~

也可以用在正则表达式中，用来匹配任意个数(包含0个)的字符。

在算术操作符的上下文中， `*`号表示乘法运算。如果要做幂运算，使用`**`，这是求幂操作符。

## `？`

测试操作符。在一个特定的表达式中，`?`用来测试一个条件的结果。

在一个双括号结构中，`?`就是C语言的三元操作符。

~~~bash
(( t = a<45?7:11 )) # C语言风格的三元操作
~~~

在参数替换表达式中，`?`用来测试一个变量是否set。

在通配中，用来做匹配单个字符的"通配符"，在正则表达式中，也是用来表示一个字符。

## `$`

在`变量替换`中，用于引用变量的内容。

~~~bash
var1=5
echo $var1
~~~

在一个变量前面加上`$`用来引用这个变量的值。

 在正则表达式中，表示行结束符。

 `${}` 是参数替换，`$*`, `$@`是位置参数，`$?` 是退出状态码变量，`$$`是进程id变量，保存所在脚本的进程 ID。

## `()`

命令组：

~~~bash
(a=hello; echo $a)
~~~

> 在括号中的命令列表，将会作为一个子shell来运行。

例外: 在pipe中的一个大括号中的代码段可能运行在一个 子shell中。

~~~bash
ls | { read firstline; read secondline; }

#错误. 在大括号中的代码段, 将运行到子shell中, 所以"ls"的输出将不能传递到代码块中
echo "First line is $firstline; second line is $secondline"  # 不能工作
~~~

初始化数组：

~~~bash
Array=(element1 element2 element3)
~~~

## `{xxx,yyy,zzz,...}`

大括号扩展：

~~~bash
cat {file1,file2,file3} > combined_file

cp file22.{txt,backup} # 拷贝"file22.txt"到"file22.backup"中
~~~

一个命令可能会对大括号中的以逗号分的文件列表起作用。在通配符中，将对大括号中的文件名做扩展。

在大括号中，不允许有空白，除非这个空白引用或转义。

~~~bash
$ echo {file1,file2}\ :{\ A," B",' C'}
file1 : A file1 : B file1 : C file2 : A file2 : B file2 : C
~~~

## `{}`

代码块，又被称为内部组，这个结构事实上创建一个匿名函数。与"标准"函数不同的是，在其中的变量，对于脚本其他部分的代码来还是可见的。

~~~bash
{ local a; a=1; }
-bash: local: can only be used in a function
~~~

~~~bash
a=123
{ a=321; }
echo "a = $a"  # a = 321 (说明在代码块中对变量a所作的修改影响了外边的变量)
~~~

下边的代码展示在大括号结构中代码的I/O 重定向。

~~~bash
#!/bin/bash
# 从/etc/fstab中读行. 3
File=/etc/fstab

{
 read line1
 read line2
} < $File

echo "First line in $File is:" "$line1"
echo "Second line in $File is:" "$line2"
exit
~~~

与上面所讲到的`()`中的命令组不同的是，大括号中的代码块将不会开一个新的子shell。

## `'{}' \;`

路径名。一般都在`find`命令中使用，这不是一个shell内建命令。`;`用来结束find命令序列的`-exec`选项，它需要被保护以防止被shell所解释。

~~~bash
find . -mtime -1 -type f -exec tar rvf archive.tar '{}' \;
~~~

## `[]`

条件测试。

在一个array结构的上下文中，中括号用来引用数组中每个元素的编号。

~~~bash
Array[1]=a 
echo ${Array[1]}
~~~

用作正则表达式的一部分，方括号描一个匹配的字符范围。例如，正则表达式中，"[xyz]" 将会匹配字符x, y, 或z。

## `[[ ]] `

测试表达式在`[[ ]]`中。

## `(( ))`

双圆括号结构，扩展并计算在`(( ))`中的整数表达式。

与let命令很相似，(`(...))`结构允许算术扩展和赋值。举个简单的例子，`a=$(( 5 + 3 ))`，将把变量"a"设为"5 + 3"或者8。 

## `>` `&>` `>&` `>>` `<` `<>`

重定向。

重定向scriptname的输出到文件filename中。如果filename存在的，那么将会被覆盖：

~~~bash
scriptname >filename 
~~~

也可以清空文件内容：

~~~bash
> a.log 
~~~

重定向command的stdout和stderr到filename中:

~~~bash
command &>filename
~~~

重定向command的stdout到stderr中:

~~~bash
command >&2 
~~~

把scriptname的输出加到文件filename中。如果filename不存在的话，将被创建。

~~~bash
scriptname >> filename 
~~~

打开文件filename用来读写，并且分配文件描述符i给这个文件。如果filename不存在，这个文件将会创建：

~~~bash
[i]<>filename 
~~~

"<"或">"还可以用于`进程替换`。

在一种不同的上下文中，"<"和">"可用来做字符串比较操作或者整数比较。

## `<<`

用在here document中的重定向。

## `<<<`

用在here string中的重定向。

## `\<`,`\>` 

正则表达式中的单词边：

~~~bash
grep '\<the\>' textfile
~~~

## `|`

管道。分析前边命令的输出，并将输出作为后边命令的输入。这是一种产生命令链的好方法。

~~~bash
# 与一个简单的"ls -l"结果相同
echo ls -l | sh

# 合并和排序所有的".lst"文件, 然后删除所有重复的行.
cat *.lst | sort | uniq
~~~

输出的命令也可以传递到脚本中：

~~~bash
#!/bin/bash
# uppercase.sh : 修改输入, 全部转换为大写

tr 'a-z' 'A-Z'

exit 0
~~~

现在我们输送`ls -l`的输出到该脚本中：

~~~bash
$ ls -l | ./uppercase.sh
DRWXR-X--- 2 ROOT ROOT      4096 05-28 10:06 ML-1M
-RW-R--R-- 1 ROOT ROOT         0 2014-11-21 MONITOR_DISK.TXT
DRWXR-XR-X 2 ROOT ROOT      4096 2014-11-21 SCRIPT
-RW-R--R-- 1 ROOT ROOT        16 07-06 16:09 UPPERCASE.SH
~~~

管道中的每个进程的stdout比下一个进程作为stdin来读入，否则，数据流会阻塞，并且管道将产生一些非预期的行为：

~~~bash
# 从"cat file1 file2"中的输出并没出现
cat file1 file2 | ls -l | sort
~~~

作为子进程的运行的管道，不能够改变脚本的变量：

~~~bash
variable="initial_value"
echo "new_value" | read variable
echo "variable = $variable" # variable =initial_value
~~~

如果管道中的这个命令产生一个异常，并中途失败，那么这个管道将过早的终止，这种行为叫做broken pipe，并且这种状态下将发送一个`SIGPIPE`信号。

## `>|`

强制重定向(使设置`noclobber`选项，就是`-C`选项)，这将强制的覆盖一个现存文件。

## `||`

或操作，在一个条件测试结构中，如果条件测试结构两边中的任意一边结果为true的话，`||`操作就会返回0(代表执行成功)。

## `&`

后台运行命令，一个命令后边跟一个`&`表示在后台运行。

~~~bash
sleep 10 &
~~~

在一个脚本中，命令和循环都可能运行在后台：

~~~bash
for i in1 2 3 4 5 6 7 8 9 10
do
    echo -n "$i "
done & 
~~~

在一个脚本中，使用后台运行命令可能会使这个脚本挂起，直到敲`ENTER` 键，挂起的脚本才会恢复。看起来只有在这个命令的结果需要输出到stdout的时候，这种现象才会出现。

只要在后台运行命令的后边加上一个`wait`命令就会解决这个问题。

~~~bash
#!/bin/bash 
# test.sh

ls -l &
echo "Done."
wait
~~~

如果将后台运行命令的输出重定向到文件中或`/dev/null`中，也能解决这个问题。

## `&&`

与逻辑操作。在一个条件测试结构中，只有在条件测试结构的两边结果都为true的时，`&&`操作才会返回0(代表sucess)。

## `-`

选项，前缀。在所有的命令内如果使用选项参数的话，前边都要加上`-`。

~~~bash
ls -al

sort -dfu $filename

set -- $variable

if [ $file1 -ot $file2 ]
then
    echo "File $file1 is older than $file2." 
fi
~~~

用于重定向stdin或stdout：

~~~bash
# 从一个目录移动整个目录树到另一个目录
(cd /source/directory && tar cf - . ) | (cd /dest/directory && tar xpvf -)

# 当然也可以这样写：
cp -a /source/directory/* /dest/directory
cp -a /source/directory/* /source/directory/.[^.]* /dest/directory  # 如果在/source/directory中有隐藏文件的话

bunzip2 -c linux-2.6.16.tar.bz2 | tar xvf -
~~~

注意，在这个上下文中，`-`本身并不是一个Bash操作，而是一个可以被特定的UNIX工具识别的选项，这些特定的UNIX工具特指那些可以写输出到stdout的工具，比如tar、cat等等。

~~~bash
$ echo "whatever" | cat -
whatever
~~~

使用diff命令来和另一个文件的一段进行比较：

~~~bash
grep Linux file1 | diff file2 -
~~~

一个更真实的例子是备份最后一天所有修改的文件：

~~~bash
#!/bin/bash

BACKUPFILE=backup-$(date +%m-%d-%Y)

# 如果在命令行中没有指定备份文件的文件名，那么将默认使用"backup-MM-DD-YYYY.tar.gz"
archive=${1:-$BACKUPFILE}

tar cvf - `find . -mtime -1 -type f -print` > $archive.tar

# 还有两种简单写法：
# find . -mtime -1 -type f -print0 | xargs -0 tar rvf  "$archive.tar"
# find . -mtime -1 -type f -exec tar rvf "$archive.tar" '{}' \;

gzip $archive.tar

echo "Directory $PWD backed up in archive file \"$archive.tar.gz\"."

exit 0
~~~

`-`还可以用来指先前的工作目录，`cd -`将会回到当前的工作目录，它使用了 `$OLDPWD` 环境变量。

另外，还可以当做减号来使用。

## `=`

等号，赋值操作。

## `+`

加号，也可以用在正则表达式中。某些内建命令使用`+`来打开特定的选项，用`-`来用这些特定的选项。

## `%`

取模操作，也可以用于正则表达式。

## `~`

home目录。

## `~+`

当前工作目录，相当于`$PWD`内部变量。

## `~-`

当前的工作目录，相当于`$OLDPWD`内部变量。

## `^`

行首，在正则表达式中，`^`表示定位到文本行的行首。

## 控制字符

修改终端或文本显示的行为。控制字符以`CONTROL + key`这种方式进行组合(同时按下)。控制字符也可以使用8进制或16进制表示法来进行表示，但是前边必须要加上转义符。

控制字符比较多，这里不一一列出了。

## 空白

用来分隔函数，命令或变量。空白包含空格、tab、空行，或者是它们之间任意的组合体。在某些上下文中，比如变量赋值，空白是不被允许的，会产生语法错误。

空行不会影响脚本的行为，因此使用空行可以很好的划分独立的函数段以增加可读性。

特殊变量`$IFS`用来做一些输入命令的分隔符，默认情况下是空白。

如果想在字符串或变量中使用空白，那么应该使用引用。例如下面例子：

~~~bash
hello="A B  C   D"
echo $hello                  # A B C D
echo "$hello"               # A B  C   D
~~~

# 参考文章

- [高级Bash脚本编程指南-中文版](http://blog.javachen.space/static/doc/abs-guide/html/index.html)

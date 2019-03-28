---
layout: post

title: Bash内部变量

category: devops

tags: [bash]

description:  整理Bash中存在一些内部变量。

published: true

---

Bash中存在一些内部变量。

## `$BASH`

Bash的二进制程序文件的路径。

~~~bash
$ echo $BASH
/bin/bash
~~~

## `$BASH_ENV`

这个环境变量会指向一个Bash的启动文件，当一个脚本被调用的时候，这个启动文件将会被读取。

## `$BASH_SUBSHELL`

这个变量用来提示子shell的层次。这是一个Bash的新特性，直到版本3的Bash才被引入近来。

~~~bash
#!/bin/bash
# subshell.sh

echo "Subshell level OUTSIDE subshell = $BASH_SUBSHELL"
outer_variable=Outer

(
echo "Subshell level INSIDE subshell = $BASH_SUBSHELL"
inner_variable=Inner
 
echo "From subshell, \"inner_variable\" = $inner_variable"
echo "From subshell, \"outer\" = $outer_variable"
)

echo "Subshell level OUTSIDE subshell = $BASH_SUBSHELL"

if [ -z "$inner_variable" ]
then
    echo "inner_variable undefined in main body of shell"
else
    echo "inner_variable defined in main body of shell"
fi

exit 0
~~~

## `$BASH_VERSINFO[n]`

这是一个含有6个元素的数组，它包含了所安装的Bash的版本信息。这与下边的$BASH_VERSION很相像，但是这个更加详细一些。

~~~bash
for n in 0 1 2 3 4 5
do
    echo "BASH_VERSINFO[$n] = ${BASH_VERSINFO[$n]}"
done 

# BASH_VERSINFO[0] = 3                      # 主版本号.
# BASH_VERSINFO[1] = 2                     # 次版本号.
# BASH_VERSINFO[2] = 25                    # 补丁次数.
# BASH_VERSINFO[3] = 1                      # 编译版本.
# BASH_VERSINFO[4] = release                # 发行状态.
# BASH_VERSINFO[5] = x86_64-redhat-linux-gnu  # 结构体系
~~~


## `$BASH_VERSION`

安装在系统上的Bash版本号。

~~~bash
bash$ echo $BASH_VERSION
3.2.25(1)-release

tcsh% echo $BASH_VERSION
BASH_VERSION: Undefined variable.
~~~

检查$BASH_VERSION对于判断系统上到底运行的是哪个shell来说是一种非常好的方法。变量$SHELL有时候不能够给出正确的答案。

## `$DIRSTACK`

在目录栈中最顶端的值(将会受到pushd和popd的影响)。这个内建变量与dirs命令相符，但是dirs命令会显示目录栈的整个内容。

## `$EDITOR`

脚本所调用的默认编辑器，通常情况下是vi或者是emacs。

## `$EUID`

有效用户ID。不管当前用户被假定成什么用户，这个数都用来表示当前用户的标识号，也可能使用su命令来达到假定的目的。

> $EUID并不一定与$UID相同。

## `$FUNCNAME`

当前函数的名字。

~~~bash
xyz23 (){
    echo "$FUNCNAME now executing."  # 打印: xyz23 now executing.
}
~~~

## `$GLOBIGNORE`

一个文件名的模式匹配列表，如果在通配中匹配到的文件包含有这个列表中的某个文件，那么这个文件将被从匹配到的结果中去掉。

## `$GROUPS`

目前用户所属的组。这是一个当前用户的组id列表(数组)，与记录在/etc/passwd文件中的内容一样。

~~~bash
root# echo $GROUPS
0

root# echo ${GROUPS[1]}
1

root# echo ${GROUPS[5]}
6
~~~

## `$HOME`

用户的home目录。

## `$HOSTNAME`

hostname放在一个初始化脚本中，在系统启动的时候分配一个系统名字。然而，gethostname()函数可以用来设置这个Bash内部变量$HOSTNAME。

~~~bash
$ hostname
localhost

$ cat /etc/sysconfig/network
NETWORKING=yes
NETWORKING_IPV6=no
HOSTNAME=localhost
~~~

## `$HOSTTYPE`

主机类型，就像`$MACHTYPE`，用来识别系统硬件。

~~~bash
bash$ echo $HOSTTYPE
x86_64
~~~

## `$IFS`

内部域分隔符，这个变量用来决定Bash在解释字符串时如何识别域或者单词边界。

`$IFS`默认为空白(空格、制表符和换行符)，但这是可以修改的，比如，在分析逗号分隔的数据文件时，就可以设置为逗号。注意，`$*`使用的是保存在`$IFS`中的第一个字符。

~~~bash
bash$ echo $IFS | cat -vte
$

bash$ bash -c 'set w x y z;echo "$*"'
w x y z

bash$ bash -c 'set w x y z; IFS=":-;"; echo "$*"'
w:x:y:z
#从字符串中读取命令，并分配参数给位置参数
~~~

$IFS处理其他字符与处理空白字符不同。

~~~bash
output_args_one_per_line(){
    for arg
        do echo "[$arg]"
    done
}

IFS=" "

#空白做分隔符
var=" a  b c   "
output_args_one_per_line $var 
#[a]
#[b]
#[c]


IFS=:

#:做分隔符
var=":a::b:c:::" 
output_args_one_per_line $var
#[]
#[a]
#[]
#[b]
#[c]
#[]
#[]
~~~

上面，同样的事情也会发生在awk的"FS"域中。

## `$IGNOREEOF`

忽略`EOF`：告诉shell在log out之前要忽略多少文件结束符(control-D)。

## `$LC_COLLATE`

常在`.bashrc`或`/etc/profile`中设置，这个变量用来控制文件名扩展和模式匹配的展开顺序。如果$LC_COLLATE设置得不正确的话，LC_COLLATE会在文件名匹配中产生不可预料的结果。

## `$LC_CTYPE`

这个内部变量用来控制通配和模式匹配中的字符串解释。

## `$LINENO`

这个变量用来记录自身在脚本中所在的行号。这个变量只有在脚本使用这个变量的时候才有意义，并且这个变量一般用于调试目的。

~~~bash
# *** 调试代码块开始 ***
last_cmd_arg=$_  # Save it.

echo "At line number $LINENO, variable \"v1\" = $v1"
echo "Last command argument processed = $last_cmd_arg"
# *** 调试代码块结束 ***
~~~

## `$MACHTYPE`

机器类型，标识系统的硬件。

~~~bash
bash$ echo $MACHTYPE
x86_64-redhat-linux-gnu
~~~

## `$OLDPWD`

之前的工作目录。

## `$OSTYPE`

操作系统类型。

~~~bash
bash$ echo $OSTYPE
linux
~~~

## `$PATH`

可执行文件的搜索路径，一般为/usr/bin/, /usr/X11R6/bin/, /usr/local/bin等等。

当给出一个命令时，shell会自动生成一张哈希表，并且在这张哈希表中按照path变量中所列出的路径来搜索这个可执行命令。路径会存储在环境变量中，$PATH变量本身就一个以冒号分隔的目录列表。通常情况下，系统都是在`/etc/profile`和`~/.bashrc`中存储$PATH的定义。

~~~bash
echo $PATH
/usr/kerberos/sbin:/usr/kerberos/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin://usr/java/latest/bin:/root/bin
~~~

>当前的工作目录，通常是不会出现在$PATH中的，这样做的目的是出于安全的考虑。

## `$PIPESTATUS`

这个数组变量将保存最后一个运行的前台管道的退出状态码。相当有趣的是，这个退出状态码和最后一个命令运行的退出状态码并不一定相同。

~~~bash
bash$ echo $PIPESTATUS
0

bash$ ls -al | bogus_command
-bash: bogus_command: command not found

bash$ echo $PIPESTATUS
141

bash$ ls -al | bogus_command
-bash: bogus_command: command not found

bash$ echo $?
127
~~~

`$PIPESTATUS`数组的每个成员都保存了运行在管道中的相应命令的退出状态码。`$PIPESTATUS[0]`保存管道中第一个命令的退出状态码，`$PIPESTATUS[1]`保存第二个命令的退出状态码，依此类推。

~~~bash
bash$ who | grep nobody | sort
bash$ echo ${PIPESTATUS[*]}
0 1 0
~~~

在某些上下文中，变量`$PIPESTATUS`可能不会给出期望的结果。

~~~bash
bash$ $ ls | bogus_command | wc
bash: bogus_command: command not found
 0       0       0

bash$ echo ${PIPESTATUS[@]}
141 127 0
~~~

上边输出不正确的原因归咎于ls的行为。因为如果把ls的结果放到管道上，并且这个输出并没有被读取，那么SIGPIPE将会杀掉它，同时退出状态码变为141，而不是我们所期望的0。这种情况也会发生在tr命令中。

## `$PPID`

进程的`$PPID`就是这个进程的父进程的进程ID。

## `$PROMPT_COMMAND`

这个变量保存了在主提示符`$PS1`显示之前需要执行的命令。

## `$PS1`

这是主提示符，可以在命令行中见到它。

## `$PS2`

第二提示符，当你需要额外输入的时候，你就会看到它，默认显示`>`。

## `$PS3`

第三提示符，它在一个`select`循环中显示。

~~~bash
#!/bin/bash

PS3='Choose your favorite vegetable: ' # 设置提示符字串.

select vegetable in "beans" "carrots" "potatoes" "onions" "rutabagas"

do
    echo "Your favorite veggie is $vegetable."
    echo "Yuck!"
    break  # 如果这里没有 'break' 会发生什么?
done

exit 0
~~~

## `$PS4`

第四提示符，当你使用`-x`选项来调用脚本时，这个提示符会出现在每行输出的开头。默认显示`+`。

## `$PWD`

工作目录，你当前所在的目录。

## `$REPLY`

当没有参数变量提供给`read`命令的时候，这个变量会作为默认变量提供给`read`命令，也可以用于`select`菜单，但是只提供所选择变量的编号，而不是变量本身的值。

~~~bash
#!/bin/bash
# reply.sh

# REPLY是提供给'read'命令的默认变量.

echo -n "What is your favorite vegetable? "
read

echo "Your favorite vegetable is $REPLY."
#  当且仅当没有变量提供给"read"命令时，REPLY才保存最后一个"read"命令读入的值

echo -n "What is your favorite fruit? "
read fruit
echo "Your favorite fruit is $fruit."
echo "but..."
echo "Value of \$REPLY is still $REPLY."
#  $REPLY还是保存着上一个read命令的值，因为变量$fruit被传入到了这个新的"read"命令中

exit 0
~~~

## `$SECONDS`

这个脚本已经运行的时间(以秒为单位)。

~~~bash
#!/bin/bash

TIME_LIMIT=10
INTERVAL=1

echo "Hit Control-C to exit before $TIME_LIMIT seconds."

while [ "$SECONDS" -le "$TIME_LIMIT" ]
do
    if [ "$SECONDS" -eq 1 ]
    then
        units=second
    else  
        units=seconds
    fi

    echo "This script has been running $SECONDS $units."
    #  在一台比较慢或者是附载过大的机器上, 
    #+ 在单次循环中, 脚本可能会忽略计数. 
    sleep $INTERVAL
done

echo -e "\a"  # Beep!(哔哔声!)

exit 0
~~~

## `$SHELLOPTS`

shell中已经激活的选项的列表，这是一个只读变量。

~~~bash
bash$ echo $SHELLOPTS
braceexpand:emacs:hashall:histexpand:history:interactive-comments:monitor
~~~

## `$SHLVL`

Shell级别，就是Bash被嵌套的深度。如果是在命令行中，那么$SHLVL为1，如果在脚本中那么$SHLVL为2。

## `$TMOUT`

如果$TMOUT环境变量被设置为非零值time的话，那么经过time秒后，shell提示符将会超时，这将会导致登出(logout)。

在2.05b版本的Bash中, $TMOUT变量与命令read可以在脚本中结合使用.

~~~bash
# 只能够在Bash脚本中使用, 必须使用2.05b或之后版本的Bash.

TMOUT=3    # 提示输入时间为3秒.

echo "What is your favorite song?"
echo "Quickly now, you only have $TMOUT seconds to answer!"

read song

if [ -z "$song" ]
then
    song="(no answer)"
    # 默认响应.
fi
 
echo "Your favorite song is $song."
~~~

有更加复杂的办法可以在脚本中实现定时输入。一种办法就是建立一个定式循环，当超时的时候给脚本发个信号。不过这也需要有一个信号处理例程能够捕捉由定时循环所产生的中断。

定时输入的例子：

~~~bash
#!/bin/bash
# timed-input.sh

TIMELIMIT=3  # 这个例子中设置的是3秒. 也可以设置为其他的时间值.

PrintAnswer(){
    if [ "$answer" = TIMEOUT ]
    then
        echo $answer
    else       # 别和上边的例子弄混了.
        echo "Your favorite veggie is $answer"
        kill $!  # 不再需要后台运行的TimerOn函数了, kill了吧.
              # $! 变量是上一个在后台运行的作业的PID.
    fi
}  

TimerOn()
{
    sleep $TIMELIMIT && kill -s 14 $$ &
     # 等待3秒, 然后给脚本发送一个信号.
}  

Int14Vector()
{
    answer="TIMEOUT"
    PrintAnswer
    exit 14
}  

trap Int14Vector 14   # 定时中断(14)会暗中给定时间限制. 

echo "What is your favorite vegetable "
TimerOn
read answer
PrintAnswer

#  无可否认, 这是一个定时输入的复杂实现,
 #+ 然而"read"命令的"-t"选项可以简化这个任务. 
#  参考后边的"t-out.sh".

#  如果你需要一个真正优雅的写法...
#+ 建议你使用C或C++来重写这个应用,
 #+ 你可以使用合适的函数库, 比如'alarm'和'setitimer'来完成这个任务.

exit 0
~~~

另一种选择是使用`stty`。

可能最简单的办法就是使用`-t`选项来`read`了。

~~~bash
#!/bin/bash
# t-out.sh

TIMELIMIT=4         # 4秒

read -t $TIMELIMIT variable <&1
#                           ^^^
#  在这个例子中，对于Bash 1.x和2.x就需要"<&1"了，但是Bash 3.x就不需要.

if [ -z "$variable" ]  # 值为null?
then
    echo "Timed out, variable still unset."
else  
    echo "variable = $variable"
fi  

exit 0
~~~

## `$UID`

用户ID号，当前用户的用户标识号，记录在/etc/passwd文件中。

这是当前用户的真实id，即使只是通过使用su命令来临时改变为另一个用户标识，这个id也不会被改变。$UID是一个只读变量，不能在命令行或者脚本中修改它，并且和id内建命令很相像。

变量`$ENV`、`$LOGNAME`、`$MAIL`、`$TERM`、`$USER`和`$USERNAME`都不是Bash的内建变量。然而这些变量经常在Bash的启动文件中被当作环境变量来设置。$SHELL是用户登陆shell的名字，它可以在/etc/passwd中设置，或者也可以在"init"脚本中设置，并且它也不是Bash内建的。

## 位置参数

### `$0`, `$1`, `$2`

位置参数，从命令行传递到脚本，或者传递给函数，或者`set`给变量。

### `$#`

命令行参数或者位置参数的个数。

### `$*`

所有的位置参数都被看作为一个单词。`$*`必须被引用起来。

### `$@`

与`$*`相同，但是每个参数都是一个独立的引用字符串，这就意味着，参数是被完整传递的，并没有被解释或扩展。这也意味着，参数列表中每个参数都被看作为单独的单词。当然，`$@`应该被引用起来。

~~~bash
#!/bin/bash
# arglist.sh
# 多使用几个参数来调用这个脚本，比如"one two three"

E_BADARGS=65

if [ ! -n "$1" ]
then
    echo "Usage: `basename $0` argument1 argument2 etc."
    exit $E_BADARGS
fi

echo

index=1 
echo "Listing args with \"\$*\":"
for arg in "$*"  # 如果"$*"不被""引用，那么将不能正常地工作
do
    echo "Arg #$index = $arg"
    let "index+=1"
done
# $* 将所有的参数看成一个单词

echo

index=1    

echo "Listing args with \"\$@\":"
for arg in "$@"  # 如果"$*"不被""引用，那么将不能正常地工作
do
    echo "Arg #$index = $arg"
    let "index+=1"
done 
# $@ 把每个参数都看成是单独的单词

echo

index=1 

echo "Listing args with \$*:"
for arg in $*
do
    echo "Arg #$index = $arg"
    let "index+=1"
done
# 未引用的$*将会把参数看成单独的单词

exit 0
~~~

`shift`命令执行以后, `$@`将会保存命令行中剩余的参数, 但是没有之前的`$1`, 因为被丢弃了.

~~~bash
#!/bin/bash
# 使用 ./scriptname 1 2 3 4 5 来调用这个脚本

echo "$@"    # 1 2 3 4 5
shift
echo "$@"    # 2 3 4 5
shift
echo "$@"    # 3 4 5

# 每次"shift"都会丢弃$1.
# "$@" 将包含剩下的参数.
~~~

`$@`也可以作为工具使用，用来过滤传递给脚本的输入。`cat "$@"`结构既可以接受从stdin传递给脚本的输入，也可以接受从参数中指定的文件中传递给脚本的输入。

~~~bash
#!/bin/bash
# rot13.sh: 典型的rot13算法

# 用法: ./rot13.sh filename
# 或     ./rot13.sh <filename
# 或     ./rot13.sh and supply keyboard input (stdin)

cat "$@" | tr 'a-zA-Z' 'n-za-mN-ZA-M'   # "a"变为"n"，"b"变为"o"，等等
#  'cat "$@"'结构允许从stdin或者从文件中获得输入. 

exit 0
~~~

`$*`和`$@`中的参数有时候会表现出不一致而且令人迷惑的行为，这都依赖于`$IFS`的设置。

~~~bash
#!/bin/bash

#  内部Bash变量"$*"和"$@"的古怪行为,
#+ 都依赖于它们是否被双引号引用起来.
#  单词拆分与换行的不一致的处理.

set -- "First one" "second" "third:one" "" "Fifth: :one"
# 设置这个脚本的参数, $1, $2, 等等

echo 'IFS unchanged, using "$*"'
c=0
for i in "$*"               # 引用起来
do 
    echo "$((c+=1)): [$i]"   # 这行在下边每个例子中都一样
done
echo ---

echo 'IFS unchanged, using $*'
c=0
for i in $*               # 未引用
do 
    echo "$((c+=1)): [$i]"   
done
echo ---

echo 'IFS unchanged, using "$@"'
c=0
for i in "$@"               
do 
    echo "$((c+=1)): [$i]"   
done
echo ---

echo 'IFS unchanged, using $@'
c=0
for i in $@             
do 
    echo "$((c+=1)): [$i]"   
done
echo ---

IFS=:
echo 'IFS=":", using "$*"'
c=0
for i in "$*"               
do 
    echo "$((c+=1)): [$i]"   
done
echo ---

echo 'IFS=":", using $*'
c=0
for i in $*              
do 
    echo "$((c+=1)): [$i]"   
done
echo ---

var=$*
echo 'IFS=":", using "$var" (var=$*)'
c=0
for i in "$var"
do 
    echo "$((c+=1)): [$i]"
done
echo ---

echo 'IFS=":", using $var (var=$*)'
c=0
for i in $var
do echo "$((c+=1)): [$i]"
done
echo ---

var="$*"
echo 'IFS=":", using $var (var="$*")'
c=0
for i in $var
do echo "$((c+=1)): [$i]"
done
echo ---

echo 'IFS=":", using "$var" (var="$*")'
c=0
for i in "$var"
do echo "$((c+=1)): [$i]"
done
echo ---

echo 'IFS=":", using "$@"'
c=0
for i in "$@"
do echo "$((c+=1)): [$i]"
done
echo ---

echo 'IFS=":", using $@'
c=0
for i in $@
do echo "$((c+=1)): [$i]"
done
echo ---
 
var=$@
echo 'IFS=":", using $var (var=$@)'
c=0
for i in $var
do echo "$((c+=1)): [$i]"
done
echo ---
 
echo 'IFS=":", using "$var" (var=$@)'
c=0
for i in "$var"
do echo "$((c+=1)): [$i]"
done
echo ---

var="$@"
echo 'IFS=":", using "$var" (var="$@")'
c=0
for i in "$var"
do echo "$((c+=1)): [$i]"
done
echo ---

echo 'IFS=":", using $var (var="$@")'
c=0
for i in $var
do echo "$((c+=1)): [$i]"
done

echo

# 使用ksh或者zsh -y来试试这个脚本.

exit 0
~~~

`$@`与`$*`中的参数只有在被双引号引用起来的时候才会不同。

当`$IFS`值为空时, `$*`和`$@`的行为**依赖于正在运行的Bash或者sh的版本**。

~~~bash
#!/bin/bash
#  如果$IFS被设置，但其值为空，那么"$*"和"$@"将不会像期望的那样显示位置参数.

mecho ()       # 打印位置参数
{
    echo "$1,$2,$3";
}

IFS=""         # 设置了，但值为空
set a b c      # 位置参数

mecho "$*"     # abc,,
mecho $*       # a,b,c

mecho $@       # a,b,c
mecho "$@"     # a,b,c
~~~

## 其他的特殊参数

### `$- `

传递给脚本的标记(使用`set`命令)。

### `$! `

运行在后台的最后一个作业的PID。

~~~bash
sleep ${TIMEOUT}; eval 'kill -9 $!' &> /dev/null;
~~~

### `$_` 

这个变量保存之前执行的命令的最后一个参数的值。

~~~bash
#!/bin/bash

echo $_      # /bin/bash
                    # 只是调用/bin/bash来运行这个脚本

du >/dev/null        # 这么做命令行上将没有输出
echo $_              # du

ls -al >/dev/null    # 这么做命令行上将没有输出.
echo $_              # -al  (这是最后的参数)

:
echo $_              # :
~~~

### `$?`

命令、函数或者是脚本本身的退出状态码。

### `$$`

脚本自身的进程ID。`$$`变量在脚本中经常用来构造"唯一的"临时文件名。这么做通常比调用`mktemp`命令来的简单。

~~~bash
#!/bin/bash
# temp.sh

mktemp

TMPFILE=/tmp/ftp.$$
echo $TMPFILE

exit 0
~~~

运行脚本，会输出结果：

~~~bash
/tmp/tmp.lrRiA13050
/tmp/ftp.13049
~~~

# 参考文章

- [高级Bash脚本编程指南-中文版](http://blog.javachen.com/static/doc/abs-guide/html/index.html)

---
layout: post

title: Bash条件判断

category: devops

tags: [bash]

description:  每个完整并且合理的程序语言都具有条件判断的功能，并且可以根据条件测试的结果做下一步的处理。Bash有test命令、各种中括号和圆括号操作，和if/then结构。

published: true

---

每个完整并且合理的程序语言都具有条件判断的功能，并且可以根据条件测试的结果做下一步的处理。Bash有test命令、各种中括号和圆括号操作，和if/then结构。

# 条件测试

if/then结构用来判断命令列表的退出状态码是否为0。

有一个专有命令`[ `(左中括号，特殊字符)。这个命令与`test`命令等价，并且出于效率上的考虑，这是一个`内建命令`。这个命令把它的参数作为比较表达式或者作为文件测试，并且根据比较的结果来返回一个退出状态码(0 表示真，1表示假)。

~~~bash
if  [ 0 ]      
then
    echo "0 is true."
else
    echo "0 is false."
fi            
# 0 is true.
~~~

在版本2.02的Bash中，引入了`[[ ... ]]`扩展测试命令，因为这种表现形式可能对某些语言的程序员来说更容易熟悉一些。

>注意：`[[`是一个`关键字`，并不是一个命令。

~~~bash
[[ 1 < 3 ]]
echo $?  
# 0
~~~

Bash把`[[ $a -lt $b ]]`看作一个单独的元素，并且返回一个退出状态码。`(( ... ))`和`let ...`结构也能够返回退出状态码，**当它们所测试的算术表达式的结果为非零的时候，将会返回退出状态码0**。这些算术扩展结构被用来做算术比较。

~~~bash
$ let "1<2"
$ echo $?
0

$ (( 0 && 1 ))
$ echo $?
1
~~~

if命令能够测试任何命令，并不仅仅是`中括号`中的条件。

~~~bash
cmp a b &> /dev/null 

echo $?    # 2

if cmp a b &> /dev/null  # 禁止输出.
then 
    echo "Files a and b are identical."
else 
    echo "Files a and b differ."
fi

# 非常有用的"if-grep"结构:
if grep -q bash /etc/profile
then 
    echo "File contains at least one occurrence of Bash."
fi

word=Linux
letter_sequence=inu
if echo "$word" | grep -q "$letter_sequence"
# "-q" 选项是用来禁止输出的.
then
    echo "$letter_sequence found in $word"
else
    echo "$letter_sequence not found in $word"
fi

if COMMAND_WHOSE_EXIT_STATUS_IS_0_UNLESS_ERROR_OCCURRED
then 
    echo "Command succeeded."
else 
    echo "Command failed."
fi
~~~

**条件判断主要判断的是条件是否为真或者假。那么，在什么情况下才为真呢？**

~~~bash
# 0 为真
if [ 0 ]      
then
    echo "0 is true."
else
    echo "0 is false."
fi

# 1 为真
if [ 1 ]      
then
    echo "1 is true."
else
    echo "1 is false."
fi

# -1 为真
if [ -1 ]      
then
    echo "-1 is true."
else
    echo "-1 is false."
fi

# NULL 为假
if [  ]      
then
    echo "NULL is true."
else
    echo "NULL is false."
fi

# 随便的一串字符为真
if [ xyz ]      
then
    echo "Random string is true."
else
    echo "Random string is false."
fi

# 未初始化的变量为假
if [ $xyz ]      
then
    echo "Uninitialized variable is true."
else
    echo "Uninitialized variable is false."
fi

# 更加正规的条件检查
if [ -n "$xyz" ]      
then
    echo "Uninitialized variable is true."
else
    echo "Uninitialized variable is false."
fi

xyz=     # 初始化了, 但是赋null值

# null变量为假
if [ -n "$xyz" ]      
then
    echo "Null variable is true."
else
    echo "Null variable is false."
fi

# "false" 为真
if [  "false" ]      
then
    echo "\"false\" is true." 
else
    echo "\"false\" is false." 
fi

# 再来一个, 未初始化的变量
# "$false" 为假
if [  "$false" ]      
then
    echo "\"\$false\" is true." 
else
    echo "\"\$false\" is false." 
fi
~~~

`[ `这个命令与`test`命令等价，把它的参数作为比较表达式或者作为文件测试，并且根据比较的结果来返回一个退出状态码(0 表示真，1表示假)，**如果参数为确定的一个值或者有初始化，则退出状态码为0；否者为空值或者未初始化，则为1**。上面例子也可以通过状态码来验证：

~~~bash
$ [ 0 ]  ;  echo $?
0
$ [ 1 ]  ;  echo $?
0
$ [ -1 ]  ;  echo $?
0
$ [  ]  ;  echo $?
1
$ [ xyz ]  ;  echo $?
0
$ [ $xyz ] ;  echo $?
1
$ [ -n "$xyz" ] ;  echo $?
1
$ xyz= ;  [ -n "$xyz" ] ;  echo $?
1
$ [ "false" ] ;  echo $?
0
$ [  "$false" ] ;  echo $?
1
~~~

如果if和then在条件判断的同一行上的话，必须使用分号来结束if表达式。if和then都是关键字，关键字(或者命令)如果作为表达式的开头，并且如果想在同一行上再写一个新的表达式的话，那么必须使用分号来结束上一句表达式。

if语句里还可以加上elif分支，elif是else if的缩写形式，作用是在外部的判断结构中再嵌入一个内部的if/then结构。

~~~bash
if [ condition1 ]
then
    command1
    command2
    command3
elif [ condition2 ]
# 与else if一样
then
    command4
    command5
else
    default-command
fi
~~~

`if test condition-true`结构与`if [ condition-true ]`完全相同. 就像我们前面所看到的，左中括号是调用`test`命令的标识，而关闭条件判断用的的右中括号在if/test结构中并不是严格必需的，但是在Bash的新版本中必须要求使用。

> 注意：
> `test`命令在Bash中是内建命令，用来测试文件类型，或者用来比较字符串。因此，在Bash脚本中，test命令并不会调用外部的/usr/bin/test中的test命令，这是sh-utils工具包中的一部分。同样的，`[`也并不会调用`/usr/bin/[`，这是/usr/bin/test的符号链接。

下面测试type命令：

~~~bash
bash$ type test
test is a shell builtin
bash$ type '['
[ is a shell builtin
bash$ type '[['
[[ is a shell keyword
bash$ type ']]'
]] is a shell keyword
bash$ type ']'
bash: type: ]: not found
~~~

`test`、`/usr/bin/test`、`[ ]`和`/usr/bin/[`都是等价命令。

~~~bash
if test -z "$1"
then
    echo "No command-line arguments."
else
    echo "First command-line argument is $1."
fi

if /usr/bin/test -z "$1"
then
    echo "No command-line arguments."
else
    echo "First command-line argument is $1."
fi

if [ -z "$1" ] 
#   if [ -z "$1"                应该能够运行，但是Bash报错, 提示缺少关闭条件测试的右中括号
then
    echo "No command-line arguments."
else
    echo "First command-line argument is $1."
fi

if /usr/bin/[ -z "$1" ]  
# if /usr/bin/[ -z "$1"       # 能够工作，但是还是给出一个错误消息。注意：在版本3.x的Bash中, 这个bug已经被修正了
then
    echo "No command-line arguments."
else
    echo "First command-line argument is $1."
fi
~~~

`[[ ]]`结构比`[   ]`结构更加通用。这是一个扩展的test命令，是从ksh88中引进的。在`[[`和`]]`之间**所有的字符都不会发生文件名扩展或者单词分割，但是会发生参数扩展和命令替换**。

~~~bash
file=/etc/passwd

if [[ -e $file ]]
then
    echo "Password file exists."
fi
~~~

使用`[[ ... ]]`条件判断结构而不是`[ ... ]`，能够防止脚本中的许多逻辑错误。比如`&&`、`||`、`<`和`>`操作符能够正常存在于`[[ ]]`条件判断结构中,，但是如果出现在`[ ]`结构中的话，会报错。

**在if后面也不一定非得是test命令或者是用于条件判断的中括号结构**。

~~~bash
dir=/home/bozo

if cd "$dir" 2>/dev/null; then   # "2>/dev/null" 会隐藏错误信息.
    echo "Now in $dir."
else
    echo "Can't change to $dir."
fi
~~~

"if COMMAND"结构将会返回COMMAND的退出状态码。与此相似，在中括号中的条件判断也不一定非得要if不可，也可以使用`列表结构`。

~~~bash
var1=20
var2=22
[ "$var1" -ne "$var2" ] && echo "$var1 is not equal to $var2"

home=/home/bozo
[ -d "$home" ] || echo "$home directory does not exist."
~~~

`(( ))`结构扩展并计算一个算术表达式的值。如果表达式的结果为0，那么返回的退出状态码为1，或者是"假"。而**一个非零值的表达式所返回的退出状态码将为0**，或者是"true"。**这种情况和先前所讨论的`test`命令和`[ ]`结构的行为正好相反**。

~~~bash
#!/bin/bash
# 算术测试.

# (( ... ))结构可以用来计算并测试算术表达式的结果. 
# 退出状态将会与[ ... ]结构完全相反!

(( 0 ))
echo "Exit status of \"(( 0 ))\" is $?."         # 1

(( 1 ))
echo "Exit status of \"(( 1 ))\" is $?."         # 0

(( 5 > 4 ))                                      # 真
echo "Exit status of \"(( 5 > 4 ))\" is $?."     # 0
  
(( 5 > 9 ))                                      # 假
echo "Exit status of \"(( 5 > 9 ))\" is $?."     # 1

(( 5 - 5 ))                                      # 0
echo "Exit status of \"(( 5 - 5 ))\" is $?."     # 1

(( 5 / 4 ))                                      # 除法也可以.
echo "Exit status of \"(( 5 / 4 ))\" is $?."     # 0

(( 1 / 2 ))                                      # 除法的计算结果 < 1.
echo "Exit status of \"(( 1 / 2 ))\" is $?."     # 截取之后的结果为 0.
                                                    # 1

(( 1 / 0 )) 2>/dev/null                          # 除数为0, 非法计算. 
#            ^^^^^^^^^^^
echo "Exit status of \"(( 1 / 0 ))\" is $?."     # 1

# "2>/dev/null"起了什么作用?
# 如果这句被删除会怎样?
(( 1 / 0 )) 
echo "Exit status of \"(( 1 / 0 ))\" is $?."     # 2

exit 0
~~~

就如文章开头所言，`(( ... ))`和`let ...`结构也能够返回退出状态码，当它们所测试的算术表达式的结果为非零的时候，将会返回退出状态码0。

# 测试操作符

**文件测试操作符**：

- `-e` 文件存在
- `-a` 文件存在，这个选项的效果与-e相同. 但是它已经被"弃用"了, 并且不鼓励使用.
- `-f`  表示这个文件是一个一般文件(并不是目录或者设备文件)
- `-s` 文件大小不为零
- `-d` 表示这是一个目录
- `-b` 表示这是一个块设备(软盘、光驱等。)
- `-c` 表示这是一个字符设备(键盘, modem, 声卡, 等等.)
- `-p` 这个文件是一个管道
- `-h` 这是一个符号链接
- `-L` 这是一个符号链接
- `-S` 表示这是一个socket
- `-t ` 文件(描述符)被关联到一个终端设备上。这个测试选项一般被用来检测脚本中的stdin([ -t 0 ]) 或者stdout([ -t 1 ])是否来自于一个终端.
- `-r` 文件是否具有可读权限(指的是正在运行这个测试命令的用户是否具有读权限)
- `-w` 文件是否具有可写权限(指的是正在运行这个测试命令的用户是否具有写权限)
- `-x` 文件是否具有可执行权限(指的是正在运行这个测试命令的用户是否具有可执行权限)
- `-g` set-group-id(sgid)标记被设置到文件或目录上。如果目录具有sgid标记的话, 那么在这个目录下所创建的文件将属于拥有这个目录的用户组，而不必是创建这个文件的用户组. 这个特性对于在一个工作组中共享目录非常有用。
- `-u` set-user-id (suid)标记被设置到文件上。如果一个root用户所拥有的二进制可执行文件设置了set-user-id标记位的话，那么普通用户也会以root权限来运行这个文件。这对于需要访问系统硬件的执行程序非常有用。如果没有suid标志的话，这些二进制执行程序是不能够被非root用户调用的。对于设置了suid标志的文件，在它的权限列中将会以s表示。
- `-k` 设置粘贴位。粘贴位设置在目录中，它将限制写权限，在它们的权限标记列中将会显示t。如果用户并不拥有这个设置了粘贴位的目录，但是他在这个目录下具有写权限，那么这个用户只能在这个目录下删除自己所拥有的文件。这将有效的防止用户在一个公共目录中不慎覆盖或者删除别人的文件，比如说/tmp目录。
- `-O` 判断你是否是文件的拥有者
- `-G` 文件的group-id是否与你的相同
- `-N` 从文件上一次被读取到现在为止，文件是否被修改过
- `f1 -nt f2` 文件f1比文件f2新
- `f1 -ot f2` 文件f1比文件f2旧
- `f1 -ef f2` 文件f1和文件f2是相同文件的硬链接
- `!` 反转上边所有测试的结果(如果没给出条件，那么返回真)。

**二元比较操作符**，用来比较两个变量或数字：

- `-eq` 等于 `if [ "$a" -eq "$b" ]`
- `-ne` 不等于 `if [ "$a" -ne "$b" ]`
- `-gt` 大于 `if [ "$a" -gt "$b" ]`
- `-ge` 大于等于 `if [ "$a" -ge "$b" ]`
- `-lt` 小于 `if [ "$a" -lt "$b" ]`
- `-le` 小于等于 `if [ "$a" -le "$b" ]`
- `<` 小于(在`双括号`中使用) `(("$a" < "$b"))`
- `<=` 小于等于(在`双括号`中使用) `(("$a" <= "$b"))`
- `>` 大于(在`双括号`中使用) `(("$a" > "$b"))`
- `>=` 大于等于(在`双括号`中使用) `(("$a" >= "$b"))`
- `-a` 逻辑与，一般都是和`test`命令或者是`单中括号`结构一起使用的 `if [ "$exp1" -a "$exp2" ]`
- `-o` 逻辑或，一般都是和`test`命令或者是`单中括号`结构一起使用的 `if [ "$exp1" -o "$exp2" ]`

**字符串比较**：

- `=` 等于 `if [ "$a" = "$b" ]`
- `==`等于 `if [ "$a" == "$b" ]` 与`=`等价
- `!=` 不等号 `if [ "$a" != "$b" ]` 这个操作符将在`[[ ... ]]`结构中使用模式匹配
- `<` 小于，按照ASCII字符进行排序 `if [[ "$a" < "$b" ]]` `if [ "$a" \< "$b" ]` 注意使用在`[ ]`结构中的时候需要被转义。
- `>` 大于，按照ASCII字符进行排序 `if [[ "$a" > "$b" ]]` `if [ "$a" \> "$b" ]` 注意使用在`[ ]`结构中的时候需要被转义。
- `-z` 字符串为"null"，意思就是字符串长度为零
- `-n` 字符串不为"null"，当`-n`使用在中括号中进行条件测试的时候，必须要把字符串用双引号引用起来。

注意：**==比较操作符在`双中括号对`和`单中括号对`中的行为是不同的**。

~~~bash
if [[ $a == z* ]]    # 如果$a以"z"开头(模式匹配)，那么结果将为真
then echo true
else echo false
fi

if [[ $a == "z*" ]]  # 如果$a与z*相等，就是字面意思完全一样，那么结果为真。
then echo true
else echo false
fi

if [ $a == z* ]      # 如果$a与z*相等，就是字面意思完全一样，那么结果为真。不存在模式匹配
then echo true
else echo false
fi

if [ "$a" == "z*" ]  # 如果$a与z*相等，就是字面意思完全一样，那么结果为真。
then echo true
else echo false
fi
~~~

**检查字符串是否为null**，有以下几种方法：

~~~bash
#!/bin/bash
#  str-test.sh: 检查null字符串和未引用的字符串

if [ -n $string1 ]    # $string1 没有被声明和初始化
then
    echo "String \"string1\" is not null."
else  
    echo "String \"string1\" is null."
fi

if [ -n "$string1" ]  # 这次$string1被引号扩起来了.
then
    echo "String \"string1\" is not null."
else  
    echo "String \"string1\" is null."
fi

if [ $string1 ]       # 这次，就一个$string1，什么都不加
then
    echo "String \"string1\" is not null."
else  
    echo "String \"string1\" is null."
fi
# [ ] 测试操作符能够独立检查string是否为null，然而，使用("$string1")是一种非常好的习惯
# if [ $string1 ]    只有一个参数 "]"
# if [ "$string1" ]  有两个参数，一个是空的"$string1"，另一个是"]" 

string1=initialized

if [ $string1 ]        # 再来，还是只有$string1，什么都不加
then
    echo "String \"string1\" is not null."
else  
    echo "String \"string1\" is null."
fi
# 这个例子运行还是给出了正确的结果，但是使用引用的("$string1")还是更好一些

string1="a = b"

if [ $string1 ]        # 再来，还是只有$string1，什么都不加
then
    echo "String \"string1\" is not null."
else  
    echo "String \"string1\" is null."
fi
# 未引用的"$string1"，这回给出了错误的结果

exit 0
~~~

# 总结

本篇文章介绍了如何使用Bash的条件判断，涉及到test命令、各种中括号和圆括号操作，以及if/then结构。需要知道，test、/usr/bin/test、[ ]和/usr/bin/[都是等价命令，使用type命令可以分区内建命令和关键字。另外，需要区分单中括号和双中括号以及双圆括号的含义是不同的。

- 单中括号`[`，与test命令等价，是个内建命令
- 双中括号`[[`，是扩展测试命令，是个关键字
- 双圆括号`(())`，是根据算术表达式运行结果来返回不同状态码

使用`[[ ... ]]`条件判断结构而不是`[ ... ]`，能够防止脚本中的许多逻辑错误。比如`&&`、`||`、`<`和`>`操作符能够正常存在于`[[ ]]`条件判断结构中,，但是如果出现在`[ ]`结构中的话，会报错。

# 参考文章

- [高级Bash脚本编程指南-中文版](http://blog.javachen.com/static/doc/abs-guide/html/index.html)

---
layout: post

title:  使用Groovy操作文件

description: Java 读写文件比较麻烦，那 Groovy 操作文件又如何呢？

keywords:  

category:  java

tags: [groovy]

published: true

---


Java 读写文件比较麻烦，那 Groovy 操作文件又如何呢？

# 1. 读文件

## 读文件内容

在groovy中输出文件的内容：

~~~groovy
println new File("tmp.csv").text  
~~~

上面代码非常简单，没有流的出现，没有资源关闭的出现，也没有异常控制的出现，所有的这些groovy已经搞定了。

读取每一行内容：

~~~groovy
File file = new File('tmp.csv')
assert file.name == 'tmp.csv'
assert ! file.isAbsolute()
assert file.path == 'tmp.csv'
assert file.parent == null

//使用系统默认的编码处理文件流  
file.eachLine {println it }  
//指定处理流的编码
file.eachLine("UTF-8") { println it }

file.eachLine("UTF-8",10) {str,no->  
    println str  
    println no }
~~~

对文件中每一行的内容做处理：

~~~groovy
file.splitEachLine("\t") { println it  }

//以大写行式输出文件内容  
lineList = file.readLines();  
liineList.each {  
  println it.toUpperCase();  
}

file.filterLine {String str->  
    if (str.contains('code'))  
        println str  
}.writeTo(new PrintWriter(System.out)) 
~~~

## 解析 xml 文件

~~~xml
<?xml version="1.0" encoding="UTF-8"?> 
<customers> 
  <corporate> 
    <customer name="bill gates" company="microsoft"></customer> 
    <customer name="steve jobs" company="apple"></customer> 
    <customer name="bill dyh" company="sun"></customer> 
  </corporate> 
  <consumer> 
    <customer name="jone Doe"></customer> 
    <customer name="jane Doe"></customer>    
  </consumer> 
</customers>
~~~

~~~groovy
def customers = new XmlSlurper().parse(new File("customers.xml")) 
/*对文件进行解析*/ 
for(customer in customers.corporate.customer){ 
    println "${customer.@name} works for${customer.@company}"; 
} 
~~~

## 解析 propeties 文件

参考 [groovy: How to access to properties file?](http://stackoverflow.com/questions/2055959/groovy-how-to-access-to-properties-file)，代码如下：

~~~groovy
def props = new Properties()
new File("message.properties").withInputStream { 
  stream -> props.load(stream) 
}
// accessing the property from Properties object using Groovy's map notation
println "capacity.created=" + props["capacity.created"]

def config = new ConfigSlurper().parse(props)
// accessing the property from ConfigSlurper object using GPath expression
println "capacity.created=" + config.capacity.created
~~~

另外一种方式：

~~~groovy
def config = new ConfigSlurper().parse(new File("message.groovy").toURL())
~~~

message.groovy 内容如下：

~~~groovy
capacity {
  created="x"
  modified="y"
}
~~~

# 2. 操作目录

列出目录所有文件（包含子文件夹，子文件夹内文件） ：

~~~groovy
def dir = new File(dirName)  
if (dir.isDirectory()) {  
    dir.eachFileRecurse { file ->  
        println file  
    }  
} 

dir.eachFileMatch(~/.*\.txt/) {File it-> println it.name  } //使正则表达式匹配文件名  
dir.eachFileMatch(FILES, ~/.*\.txt/) { File it-> println it.name  }   
~~~

# 3. 写文件

~~~groovy
import java.io.File  
  
def writeFile(fileName) {  
    def file = new File(fileName)  
      
    if (file.exists())   
        file.delete()  
          
    def printWriter = file.newPrintWriter() //   
      
    printWriter.write('The first content of file')  
    printWriter.write('\n')  
    printWriter.write('The first content of file')  
      
    printWriter.flush()  
    printWriter.close()  
}  
~~~

除了 `file.newPrintWriter()` 可以得到一个 PrintWriter，类似方法还有 `file.newInputStream()`、
`file.newObjectInputStream()`等。

更简洁写法：

~~~groovy
new File(fileName).withPrintWriter { printWriter ->  
     printWriter.println('The first content of file')  
}  
~~~

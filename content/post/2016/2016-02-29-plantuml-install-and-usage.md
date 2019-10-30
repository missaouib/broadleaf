---
layout: post

title: PlantUML安装和使用
date: 2016-02-29T08:00:00+08:00

categories: [ java ]

tags: [plantuml,uml]

keywords: plantuml,uml,java,sublime text

description: 主要介绍什么是PlantUML，以及PlantUML的安装和使用。

published: true

---

# 什么是PlantUML

PlantUML是一个快速创建UML图形的组件，PlantUML支持的图形有：

- sequence diagram,
- use case diagram,
- class diagram,
- activity diagram,
- component diagram,
- state diagram,
- object diagram,
- wireframe graphical interface

PlantUML通过简单和直观的语言来定义图形，语法参见[PlantUML Language Reference Guide](http://plantuml.com/PlantUML_Language_Reference_Guide.pdf)，它支持很多[工具](http://plantuml.com/running.html)，可以生成PNG、SVG、LaTeX和二进制图片。例如，下面的例子是通过[在线示例工具](http://plantuml.com/plantuml/)生成的。

![](http://plantuml.com/plantuml/png/SyfFKj2rKt3CoKnELR1Io4ZDoSa70000)

ASCII Art格式：

~~~
     ┌───┐          ┌─────┐
     │Bob│          │Alice│
     └─┬─┘          └──┬──┘
       │    hello      │   
       │──────────────>│   
     ┌─┴─┐          ┌──┴──┐
     │Bob│          │Alice│
     └───┘          └─────┘
~~~

<http://www.planttext.com/planttext>也是一个类似的导出工具，甚至你可以自建一个服务器生成图片。使用在线生成工具的好处是不用保存图片，可以直接应用生成的图片地址。


# 主页

官网地址：<http://plantuml.com/>。

# 安装

PlantUML下载地址：<http://plantuml.com/download.html>。你可以下载jar包和java的开发工具集成使用，更多的安装或者集成方式见<http://plantuml.com/running.html>。

对于我来说，有用的是在Chrome上集成[PlantUML插件](https://chrome.google.com/webstore/detail/plantuml-viewer/legbfeljfbjgfifnkmpoajgpgejojooj)和在Sublime Text中集成。

## Sublime Text集成PlantUML

PlantUML依赖`Graphviz`，故先安装：

~~~
brew install graphviz
~~~

Sublime Text 的集成使用的是`sublime_diagram_plugin`因为默认的包管理中没有，所以需要自己添加源。

- 使用 `Command-Shift-P` 打开 `Command Palette`
- 输入 `add repository` 找到 `Package Control:Add Repository`
在下方出现的输入框中输入 <https://github.com/jvantuyl/sublime_diagram_plugin.git>， 然后回车
- 等待添加完成后再次使用`Command-Shift-P`打开`Command Palette`
- 输入`install package`找到`Package Control:Install Package`
- 等待列表加载完毕，输入`diagram`找到`sublime_diagram_plugin` 安装
- 重启`Sublime Text`

重启后可以在`Preferences -> Packages Setting`看到`Diagram`，默认绑定的渲染快捷键是`super + m`也就是`Command + m`如果不冲突直接使用即可。

为了简化使用，可以在 Sublime 里配置个快捷键。打开 `Preferences -> Key Binding - User`，添加一个快捷键：

~~~
{ "keys": ["alt+d"], "command": "display_diagrams"}
~~~

上面的代码配置成按住 `Alt + d` 来生成 PlantUML 图片，你可以修改成你自己喜欢的按键。

# 简单使用

使用的话比较简单，绘图的内容需要包含在`@startuml`和`@enduml`中，不然会报错。

在文本中输入以下内容：

~~~
@startuml
Bob -> Alice : Hello, how are you
Alice -> Bob : Fine, thank you, and you?
@enduml
~~~

按`Command + m`会在当前工作目录下生成这个图片文件，同时自动弹出窗口显示如下图片。

![](http://plantuml.com:80/plantuml/png/SyfFKj2rKt3CoKnELR1Iy4ZDoSdNKSZ8BrT8B4fLgCmlvO980TKu0PLQARXbvgNgA9Ha9EPbWwHr51BpKa0CUm00)

将其保存为basic.txt之后，可以在命令行运行：

~~~java
java -jar /path/to/jar/plantuml.jar -tsvg basic.txt
~~~

这样会在当前路径生成了名为 basic.svg 的图片。

命令行使用参见：<http://plantuml.sourceforge.net/command_line.html> 。

# 参考文章

- [在 Mac 上使用 PlantUML 高效画图](http://blog.yourtion.com/use-plantuml-on-mac.html)





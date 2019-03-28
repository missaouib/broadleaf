---
layout: post

title: All Things Markdown

description: 记录一些关于Markdown的知识,所有相关内容来自互联网。

keywords: 关于Markdown

category: devops

tags: [markdown]

---

# 目录

1. [概述](#Intro)
1. [特点](#Feture)
1. [语法](#Syntax)
1. [编辑器](#Editor)
1. [浏览器插件](#BrowserPlugin)
1. [实现版本](#Implements)
1. [参考资料](#Reference)

# <a id="Intro">概述</a>

[Markdown](http://zh.wikipedia.org/wiki/Markdown) 是一种轻量级标记语言，创始人为约翰·格鲁伯（John Gruber）和亚伦·斯沃茨（Aaron Swartz）。它允许人们“使用易读易写的纯文本格式编写文档，然后转换成有效的XHTML(或者HTML)文档”。这种语言吸收了很多在电子邮件中已有的纯文本标记的特性。


# <a id="Feture">特点</a>

## 兼容 HTML

要在Markdown中输写HTML区块元素，比如`<div>`、`<table>`、`<pre>`、`<p>` 等标签，必须在前后加上空行与其它内容区隔开，还要求它们的开始标签与结尾标签不能用制表符或空格来缩进。Markdown 的生成器有足够智能，不会在 HTML 区块标签外加上不必要的 `<p>` 标签。

例子如下，在 Markdown 文件里加上一段 HTML 表格：

~~~
这是一个普通段落。

<table>
    <tr>
        <td>a</td>
        <td>a</td>
    </tr>
    <tr>
        <td>b</td>
        <td>b</td>
    </tr>
</table>

这是另一个普通段落。
~~~

请注意:
 
 - 在 HTML 区块标签间的 Markdown 格式语法将不会被处理。
 - HTML 的区段（行内）标签如 `<span>`、`<cite>`、`<del>` 可以在 Markdown 的段落、列表或是标题里随意使用。
 
## 特殊字符自动转换

Markdown会对一些特殊字符进行转化，如：`&`、`©`、`<`、`>`,如果`<`、`>`用作html标签的界定符，则不会对其转换。

不过需要注意的是，code 范围内，不论是行内还是区块， `<` 和 `&` 两个符号都一定会被转换成 HTML 实体。

# <a id="Syntax">语法</a>

## 标题

Markdown 支持两种标题的语法，类 [Setext](http://docutils.sourceforge.net/mirror/setext.html) 和类 [atx](http://www.aaronsw.com/2002/atx/) 形式。

类 Atx 形式则是在行首插入 1 到 6 个 # ，对应到标题 1 到 6 阶，例如：

~~~
# This is an <h1> tag
## This is an <h2> tag
###### This is an <h6> tag
~~~

你可以选择性地「闭合」类 atx 样式的标题，这纯粹只是美观用的，若是觉得这样看起来比较舒适，你就可以在行尾加上 #，而行尾的 # 数量也不用和开头一样（行首的井字符数量决定标题的阶数）

类 Setext 形式是用底线的形式，利用 = （最高阶标题）和 - （第二阶标题），例如：

~~~
This is an H1
=============

This is an H2
-------------
~~~

任何数量的 = 和 - 都可以有效果。

## 强调

Markdown 使用星号（`*`）和底线（`_`）作为标记强调字词的符号，被 `*` 或 `_` 包围的字词会被转成用 `<em>` 标签包围，用两个 `*` 或 `_` 包起来的话，则会被转成 `<strong>`，例如：

~~~
*This text will be italic*
_This will also be italic_

**This text will be bold**
__This will also be bold__

*You **can** combine them*
~~~

## 断行

如果你真的想在Markdown中插入换行标签`<br/>`，你可以在行尾输入两个或以上的空格，然后回车。 这样插入换行十分麻烦，但是“每个换行都转换为`<br/>`”在 Markdown中并不合适，所以只在你确定你需要时手动添加。

## 列表

Markdown 支持有序列表和无序列表。

### 无序

无序列表使用星号、加号或是减号作为列表标记：

~~~
*   Red
*   Green
*   Blue
~~~

### 有序

有序列表则使用数字接着一个英文句点：

~~~
1.  Bird
2.  McHale
3.  Parish
~~~

很重要的一点是，你在列表标记上使用的数字并不会影响输出的 HTML 结果。

如果你的列表标记写成：

~~~
1.  Bird
1.  McHale
1.  Parish
~~~
或甚至是：

~~~
3. Bird
1. McHale
8. Parish
~~~

你都会得到完全相同的 HTML 输出。

注意：

- 如果列表项目间用空行分开，在输出 HTML 时 Markdown 就会将项目内容用 `<p>` 标签包起来
- 列表项目可以包含多个段落，每个项目下的段落都必须缩进 4 个空格或是 1 个制表符
- 如果要放代码区块的话，该区块就需要缩进两次，也就是 8 个空格或是 2 个制表符

## 区块引用

Markdown 标记区块引用是使用类似 email 中用 `>` 的引用方式。

~~~
As Kanye West said:

> We're living the future so
> the present is our past.
~~~

**Markdown 也允许你偷懒只在整个段落的第一行最前面加上 `>`**

区块引用可以嵌套（例如：引用内的引用），只要根据层次加上不同数量的 > ：

~~~
> This is the first level of quoting.
>
> > This is nested blockquote.
>
> Back to the first level.
~~~
引用的区块内也可以使用其他的 Markdown 语法，包括标题、列表、代码区块等：

~~~
> ## 这是一个标题。
> 
> 1.   这是第一行列表项。
> 2.   这是第二行列表项。
> 
> 给出一些例子代码：
> 
>     return shell_exec("echo $input | $markdown_script");
~~~

## 分隔线

你可以在一行中用三个以上的星号、减号、底线来建立一个分隔线，行内不能有其他东西。你也可以在星号或是减号中间插入空格。下面每种写法都可以建立分隔线：

~~~
* * *
***
*****
- - -
---------------------------------------
~~~

## 代码区块

和程序相关的写作或是标签语言原始码通常会有已经排版好的代码区块，通常这些区块我们并不希望它以一般段落文件的方式去排版，而是照原来的样子显示，Markdown 会用 `<pre>` 和 `<code>` 标签来把代码区块包起来。

要在 Markdown 中建立代码区块很简单，只要简单地缩进 4 个空格或是 1 个制表符就可以

## 内联代码

~~~
I think you should use an `<addr>` element here instead.
~~~

## 链接

Markdown 支持两种形式的链接语法： 行内式和参考式两种形式。

不管是哪一种，链接文字都是用 [方括号] 来标记。

要建立一个**行内式的链接**，只要在方块括号后面紧接着圆括号并插入网址链接即可，如果你还想要加上链接的 title 文字，只要在网址后面，用双引号把 title 文字包起来即可，例如：

~~~
This is [an example](http://example.com/ "Title") inline link.
[This link](http://example.net/) has no title attribute.
~~~

**参考式的链接****是在链接文字的括号后面再接上另一个方括号，而在第二个方括号里面要填入用以辨识链接的标记：

~~~
This is [an example][id] reference-style link.
~~~

你也可以选择性地在两个方括号中间加上一个空格：

~~~
This is [an example] [id] reference-style link.
~~~

接着，在文件的任意处，你可以把这个标记的链接内容定义出来（**注意去掉冒号前面空格**）：

~~~
[id] : http://example.com/  "Optional Title Here"
~~~

引用本地资源，可以使用相对路径：`[about me](/about/)`

**隐式链接**标记功能让你可以省略指定链接标记，这种情形下，链接标记会视为等同于链接文字，要用隐式链接标记只要在链接文字后面加上一个空的方括号，如果你要让 "Google" 链接到 google.com，你可以简化成：

~~~
[Google][]
~~~
然后定义链接内容（**注意去掉冒号前面空格**）：

~~~
[Google] : http://google.com/
~~~


由于链接文字可能包含空白，所以这种简化型的标记内也许包含多个单词：

~~~
Visit [Daring Fireball][] for more information.
~~~
然后接着定义链接（**注意去掉冒号前面空格**）：

~~~
[Daring Fireball] : http://daringfireball.net/
~~~

链接的定义可以放在文件中的任何一个地方，我比较偏好直接放在链接出现段落的后面，你也可以把它放在文件最后面，就像是注解一样。

下面是一个参考式链接的范例（**注意去掉冒号前面空格**）：

~~~
I get 10 times more traffic from [Google] [1] than from
[Yahoo] [2] or [MSN] [3].

[1] : http://google.com/        "Google"
[2] : http://search.yahoo.com/  "Yahoo Search"
[3] : http://search.msn.com/    "MSN Search"
~~~
  
如果改成用链接名称的方式写（**注意去掉冒号前面空格**）：

~~~
I get 10 times more traffic from [Google][] than from
[Yahoo][] or [MSN][].

  [google] : http://google.com/        "Google"
  [yahoo] :  http://search.yahoo.com/  "Yahoo Search"
  [msn] :    http://search.msn.com/    "MSN Search"
~~~

## 图片

Markdown 使用一种和链接很相似的语法来标记图片，同样也允许两种样式： 行内式和参考式。

行内式的图片语法看起来像是：

~~~
![Alt text](/path/to/img.jpg)

![Alt text](/path/to/img.jpg "Optional title")
~~~

详细叙述如下：

- 一个惊叹号 !
- 接着一个方括号，里面放上图片的替代文字
- 接着一个普通括号，里面放上图片的网址，最后还可以用引号包住并加上 选择性的 'title' 文字。

参考式的图片语法则长得像这样：

~~~
![Alt text][id]
~~~
「id」是图片参考的名称，图片参考的定义方式则和连结参考一样（**注意去掉冒号前面空格**）：

~~~
[id] : url/to/image  "Optional title attribute"
~~~

到目前为止， Markdown 还没有办法指定图片的宽高，如果你需要的话，你可以使用普通的 <img> 标签。

## 自动链接

Markdown 支持以比较简短的自动链接形式来处理网址和电子邮件信箱，只要是用方括号包起来， Markdown 就会自动把它转成链接。一般网址的链接文字就和链接地址一样，例如

~~~
<http://example.com/>
~~~

Markdown 会转为：

~~~
<a href="http://example.com/">http://example.com/</a>
~~~

邮址的自动链接也很类似，例如：

~~~
<address@example.com>
~~~

Markdown 会转成：

~~~
<a href="mailto:address@example.com">address@example.com</a>
~~~

## 反斜杠

Markdown 可以利用反斜杠来插入一些在语法中有其它意义的符号，例如：如果你想要用星号加在文字旁边的方式来做出强调效果（但不用 `<em>` 标签），你可以在星号的前面加上反斜杠：

~~~
\*literal asterisks\*
~~~

Markdown 支持以下这些符号前面加上反斜杠来帮助插入普通的符号：

~~~
\   反斜线
`   反引号
*   星号
_   底线
{}  花括号
[]  方括号
()  括弧
#   井字号
+   加号
-   减号
.   英文句点
!   惊叹号
~~~

## 表格

使用语法解释引擎 Redcarpet(需要开启`tables`选项)，则表格如下定义：

~~~
|head1 head1 head1|head2 head2 head2|head3 head3 head3|head4 head4 head4|
|---|:---|:---:|---:|
|row1text1|row1text3|row1text3|row1text4|
|row2text1|row2text3|row2text3|row2text4|
~~~
其中`:`所在位置表示表格的位置对齐

添加 `table thead tobody th tr td` 样式后显示的效果是：

|head1 head1 head1|head2 head2 head2|head3 head3 head3|head4 head4 head4|
|---|:---|:---:|---:|
|row1text1|row1text3|row1text3|row1text4|
|row2text1|row2text3|row2text3|row2text4|

Github中定义表格方式如下：

~~~
First Header | Second Header
------------ | -------------
Content from cell 1 | Content from cell 2
Content in the first column | Content in the second column
~~~

显示的效果如下：

First Header | Second Header
------------ | -------------
Content from cell 1 | Content from cell 2
Content in the first column | Content in the second column

# <a id="Editor">在线编辑器</a>

作为一种小型标记语言，Markdown很容易阅读，也很容易用普通的文本编辑器编辑。另外也有一些编辑器专为Markdown设计，可以直接预览文档的样式。下面有一些编辑器可供参考：

- [Cmd Markdown](http://www.zybuluo.com/mdeditor) 支持实时同步预览，区分写作和阅读模式，支持在线存储，分享文稿网址。
- [Dillinger.io](http://dillinger.io/) 一个在线Markdown编辑器，提供实时预览以及到 GitHub 和 Dropbox 的拓展连接。
- [notepag](http://notepag.es/) 另一个在线Markdown编辑器，支持实时预览，提供临时网址和和密码，可以分享给其他人。
- [Mou](http://mouapp.com/) 一个Mac OS X上的Markdown编辑器。
- [MarkdownPad](http://www.markdownpad.com/) a full-featured Markdown editor for Windows.
- [WMD](http://code.google.com/p/wmd/) a Javascript WYSIWYM editor for Markdown (from AttackLab)
- [PageDown](http://code.google.com/p/pagedown/) 一个Javascript WYSIWYM Markdown编辑器 (来自 StackOverflow)
- [IPython Notebook](http://ipython.org/notebook) 以ipython为后台，利用浏览器做IDE，支持MarkDown与LaTex公式。
- <http://mahua.jser.me/> 一个在线编辑markdown文档的编辑器
- <http://markable.in/editor/> A remarkable online markdown editor
- [OsChina](http://tool.oschina.net/markdown) OsChina在线编辑器
- [Logdown](http://logdown.com/) 是台湾一个博客写手和开发者在一个周末和三位朋友在24小时之内做的一个Hackathon 項目。这是一个支持Markdown的博客写作平台。在国际上也引起关注。它的写作界面是单栏宽屏。
- <jianshu.io> 这是一个支持Markdown的中文写作社区。
- [有记 | noteton](http://noteton.com/) 有记提供基于云笔记服务的博客发布平台。

# <a id="BrowserPlugin">浏览器插件</a>

- [MaDe](https://chrome.google.com/webstore/detail/oknndfeeopgpibecfjljjfanledpbkog) (Chrome)
- [Markdown Here](http://markdown-here.com/) (Chrome, Firefox, Safari, and Thunderbird)
- [Poe: Markdown Editor](https://chrome.google.com/webstore/detail/poe-markdown-editor/mpghdlgejmakmgbigejnjnmgdjaddhje) (Chrome)
- [MarkDown](https://chrome.google.com/webstore/detail/markdown/anjbpnjfkbpkkjpfnaomopbpcldihjlg) (Chrome)
- [StackEdit](https://chrome.google.com/webstore/detail/stackedit/iiooodelglhkcpgbajoejffhijaclcdg) (Chrome)
- [扩展程序Markdown Preview Plus](https://chrome.google.com/webstore/detail/markdown-preview-plus/febilkbfcbhebfnokafefeacimjdckgl) (Chrome)

# <a id="Implements">实现版本</a>

由于Markdown的易读易写，很多人用不同的编程语言实现了多个版本的解析器和生成器。下面是一个按编程语言排序的实现列表。

- C
  - [Sundown](https://github.com/vmg/sundown), 一个用C写的Markdown实现。
  - [Discount](http://www.pell.portland.or.us/~orc/Code/discount/), 一个Markdown标记语言的C语言实现版本。
  - [peg-markdown](https://github.com/jgm/peg-markdown), 一个用C写的，使用了PEG (parsing expression grammar)的Markdown实现。
- Java
  - [MarkdownJ](http://code.google.com/p/markdownj/) the pure Java port of Markdown.
  - [Pegdown](http://github.com/sirthias/pegdown), a pure-Java Markdown implementation based on a PEG parser
  - [MarkdownPapers](http://markdown.tautua.org/), Java implementation based on a JavaCC parser
  - [Txtmark](http://github.com/rjeschke/txtmark/), another Markdown implementation written in Java
- Lua
  - [Markdown.lua](http://luaforge.net/projects/markdown/), a Markdown implementation in Lua
  - [Lunamark](http://jgm.github.com/lunamark), a markdown to HTML and LaTeX converter written in Lua, using a PEG grammar
- PHP
  - [PHP Markdown](http://michelf.com/projects/php-markdown/) and Markdown Extra
  - [Markdown Viewer for PHP](http://www.wolfiezero.com/935/markdown-viewer-for-php/), allows the viewing of a Mardown doc via a local PHP server (a wrapper for PHP Markdown)
- JavaScript
  - [Uedit](https://github.com/amir-hadzic/uedit), a Javascript "WYSIWYM" 
  editor for Markdown
  - [Strapdown.js](http://strapdownjs.com/) - JavaScript客户端解析markdown内容为html
  - [Marked](https://github.com/chjj/marked/) - Fast Markdown parser in JavaScript 
- Python 
  - [Markdown in Python](http://freewisdom.org/projects/python-markdown), A Python implementation of Markdown
  - [Misaka](http://misaka.61924.nl/), a Python binding for Sundown.
- Ruby
  - [BlueCloth](http://deveiate.org/projects/BlueCloth/), an implementation of Markdown in Ruby
- Scala
  - [Knockoff](http://tristanhunt.com/projects/knockoff/), a Markdown implementation written in Scala using Parser Combinators
  - [Actuarius](http://henkelmann.eu/projects/actuarius/), another Markdown implementation written in Scala using Parser Combinators
- GO
  - [Blackfriday](http://github.com/russross/blackfriday), another Markdown implementation written in Go
- 其它
  - [MarkdownSharp](http://code.google.com/p/markdownsharp/), a slightly modified C# implementation of the Markdown markup language. Developed and used by Stack Overflow.
  - [Markdownr.com](http://markdownr.com/), a simple website to preview markdown in real time
  - [Pandoc](http://johnmacfarlane.net/pandoc/), a universal document converter written in Haskell
  - [ReText](http://sourceforge.net/p/retext/home/ReText/), an implementation for Markdown and reStructuredText.
 
# 其他资料
- [Markdown+R写作](http://www.yangzhiping.com/tech/r-markdown-knitr.html)

# <a id="Reference">参考资料</a>

- [1] [维基百科 Markdown](http://zh.wikipedia.org/wiki/Markdown)
- [2] [Markdown 语法说明 (简体中文版)](http://wowubuntu.com/markdown/)
- [3] [GitHub Guides:Mastering Markdown](https://guides.github.com/features/mastering-markdown)
- [4] [Daring Fireball](http://daringfireball.net/projects/markdown/syntax)
- [5] [Markdown在线写作速成](http://joinwee.com/lesson/10/)

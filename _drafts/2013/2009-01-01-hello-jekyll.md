---
layout: post
title:  "Hello Jekyll!"
keywords: "hello, jekyll"
description: "hello jekyll"
category: devops
tags: [jekyll,markdown]
---

目前，博客使用的是Jekyll搭建的，markdown语法使用的是Redcarpet。Redcarpet支持设置 extensions ，值为一个字符串数组，每个字符串都是 Redcarpet::Markdown 类的扩展，相应的扩展就会设置为 true 。

配置为：

~~~yaml
highlighter: pygments
markdown: redcarpet  # [ maruku | rdiscount | kramdown | redcarpet ]

redcarpet:
    extensions:
        - fenced_code_blocks
        - no_intra_emphasis
        - strikethrough
        - autolink
        - tables
        - superscript
        - highlight
        - prettify
        - with_toc_data
~~~

redcarpet有几个扩展：

- `fenced_code_blocks` 解析代码块，使用3个或3个以上 ~ 或者 ` 包围起来的文本会被解析为代码块，你可以在开头指定代码的语言类型
- `no_intra_emphasis` 不解析单词中的下划线
- `strikethrough` 支持两个 ~ 包围的文本，解析为删除线
- `space_after_headers` #后面必须加空格，否则不会被解析为标题
- `autolink` 自动检查文本中 http https ftp 等协议的链接文本，将之解析为链接。没有以 http:// 开头，而是直接以 www. 开头的同样会被检查到
- `hard_wrap` 如果 Markdown 文本中有折行的话，会转换为标签
- `tables` 表格
- `superscript` 上标，例如 : `this is the 2^(nd) time` ，效果为：this is the 2^(nd) time
- `with_toc_data` 给生成的 Header 标签增加锚点

升级到jekyll3之后，需要修改为kramdown：

~~~yaml
markdown:    kramdown
highlighter: rouge

kramdown:
  input: GFM
  auto_ids:       true
  footnote_nr:    1
  entity_output:  as_char
  toc_levels:     1..6
  smart_quotes:   lsquo,rsquo,ldquo,rdquo
  enable_coderay: false
  syntax_highlighter: rouge
  hard_wrap: false

  extensions:
    - autolink
    - footnotes
    - smart
    - table
~~~

# 语法

## 标题

标题

~~~
# 测试 h1
## 测试 h2
### 测试 h3
#### 测试 h4
##### 测试 h5
###### 测试 h6
~~~

效果：

# 测试 h1
## 测试 h2
### 测试 h3
#### 测试 h4
##### 测试 h5
###### 测试 h6

## 列表

无序列表：

~~~
* 项目1
* 项目2
* 项目3
~~~

效果：

* 项目1
* 项目2
* 项目3

有序列表：

~~~
1. 项目1
2. 项目2
3. 项目3
   * 项目1
   * 项目2
~~~

效果：

1. 项目1
2. 项目2
3. 项目3
   * 项目1
   * 项目2

## 粗体与斜体

文字格式：

~~~
**这是文字粗体格式**
*这是文字斜体格式*
~~在文字上添加删除线~~
~~~

效果：

**这是文字粗体格式**
*这是文字斜体格式*
~~在文字上添加删除线~~

##  链接与图片

自动链接

~~~bash
 <http://blog.javachen.com>
 <XhstormR@foxmail.com>
~~~

插入链接

~~~bash
 [link text](http://example.com/ "optional title")

 [link text][id]
 [id]: http://example.com/  "optional title here"
~~~

插入图片

~~~bash
 ![](/path/to/img.jpg "optional title"){ImgCap}alt text{/ImgCap}
~~~

图片链接

~~~bash
 [![][jane-eyre-pic]{ImgCap}{/ImgCap}][jane-eyre-douban]

 [jane-eyre-pic]: http://img3.douban.com/mpic/s1108264.jpg
 [jane-eyre-douban]: http://book.douban.com/subject/1141406/
~~~

## 代码

行代码： `code`

用TAB键起始的段落，会被认为是代码块，或者使用三个`或~：

~~~ruby
/* hello world demo */
#include <stdio.h>
int main(int argc, char **argv)
{
        printf("Hello, World!\n");
        return 0;
}
~~~

## 表格

~~~
|head1|head2|head3|head4
|---|:---|---:|:---:|
|row1text1|row1text2|row1text3|row1text4
|row2text1|row2text2|row2text3|row2text4
|row3text1|row3text2|row3text3|row3text4
|row4text1|row4text2|row4text3|row4text4
~~~

效果：

|head1|head2|head3|head4
|---|:---|---:|:---:|
|row1text1|row1text2|row1text3|row1text4
|row2text1|row2text2|row2text3|row2text4
|row3text1|row3text2|row3text3|row3text4
|row4text1|row4text2|row4text3|row4text4

## 引用

~~~
> 第一行引用文字
> 第二行引用文字
~~~

> 第一行引用文字
> 第二行引用文字

## 水平线

~~~
***
~~~

***

# 参考资料

- [Jekyll 扩展的 Liquid 设计](http://havee.me/internet/2013-11/jekyll-liquid-designers.html)
- [Jekyll 扩展的 Liquid 模板](http://havee.me/internet/2013-07/jekyll-liquid-extensions.html)
- [kramdown和markdown较大的差异比较](http://platinhom.github.io/2015/11/06/Kramdown-note/)

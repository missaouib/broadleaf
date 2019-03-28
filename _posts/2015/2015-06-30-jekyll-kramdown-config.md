---
layout: post

title: Jekyll kramdown配置

category: web

tags: [jekyll,kramdown,markdown]

description:  之前博客是使用的redcarpet的markdown语法，现在想改为使用kramdown，这样就可以使用MathJax了。

published: true

---

之前博客是使用的redcarpet的markdown语法，其在_config.yml中的配置方式为：

~~~yaml
markdown: redcarpet
redcarpet:
    extensions: [ "fenced_code_blocks", "hard_wrap","autolink", "tables", "strikethrough", "superscript", "with_toc_data", "highlight", "prettify","no_intra_emphasis"]
~~~

这种配置支持使用 ~~~ 高亮代码块、自动链接、表格等特性。

现在，想尝试使用karkdown的语法。kramdown是一个Markdown解析器，它能够正确解释公式内部的符号，不会与Markdown语法冲突，比如不会将^符号变成<sup></sup>标签。

kramdown支持MathJax，见[Jekyll中使用MathJax](http://www.pkuwwt.tk/linux/2013-12-03-jekyll-using-mathjax/)。

kramdown默认是支持TOC，你可以进一步设置TOC相关的参数，见 [为 Octopress 添加 TOC](http://loudou.info/blog/2014/08/01/wei-octopress-tian-jia-toc/)。

安装kramdown：

~~~bash
$ gem install kramdown
~~~

在_config.yml中的配置方式为：

~~~yaml
markdown: kramdown
kramdown:
  input:  GFM
  use_coderay: true
~~~

在编写文章时，插入下面代码，渲染之后就可以生成TOC了：

~~~
* TOC
{:toc}
~~~

krmadown支持和github一样的语法高亮，用三个 ~~~，但是需要安装coderay，而github pages上不支持coderay，所以该方式无法搞定，可行的解决方法是上传本地编译好的html。如果是本地或者自己的空间，可以安装coderay。

~~~bash
$ gem install coderay
~~~

使用 ~~~ 引用代码块：

~~~python
class AdView (object):
    def __init__ (self, name = None):
        self.name = name

    def test (self):
        if self.name == 'admin':
            return False
        else
            return True
~~~

更多语法，见[kramdown语法小记](http://blog.will6run.com/tool/2014/11/22/kramdown/)。

最后的配置为：

~~~yaml
kramdown:
  input: GFM
  extensions:
    - autolink
    - footnotes
    - smart
  use_coderay: true
  syntax_highlighter: rouge
  coderay:
    coderay_line_numbers:  nil
~~~

coderay支持的语言有限，并且rouge兼容Pygments，故这里使用rouge：

~~~bash
$ gem install rouge
~~~

# 参考文章

- [jekyll kramdown 语法高亮配置](http://noyobo.com/2014/10/19/jekyll-kramdown-highlight.html)
- [jekyll kramdown 语法高亮](http://www.quts.me/2015/03/05/kramdown-highlight.html)
- [Octopress 精益修改 (4)](http://shengmingzhiqing.com/blog/octopress-lean-modification-4.html/)
- [Kramdown 语法文档翻译（一）](http://pikipity.github.io/blog/kramdown-syntax-chinese-1.html)
- [Markdown的各种扩展](http://www.pchou.info/open-source/2014/07/07/something-about-markdown.html)

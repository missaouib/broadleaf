---
layout: post

title: Python开发框架Flask

description: Flask 是一个 Python 实现的 Web 开发微框架。虽然Flask是微框架，不过我们并不需要像别的微框架建议的那样把所有代码都写到单文件中。毕竟微框架真正的含义是简单和短小。

keywords: Flask,Python,web

category: python

tags: [python,flask]

---

# 1. Flask介绍

[Flask](http://flask.pocoo.org/) 是一个基于Python的微型的web开发框架。虽然Flask是微框架，不过我们并不需要像别的微框架建议的那样把所有代码都写到单文件中。毕竟微框架真正的含义是简单和短小。

![flask-logo](http://flask.pocoo.org/static/logo.png)

关于Flask值得知道的一些事：

- Flask由Armin Ronacher于2010年创建。
- Flask的灵感来自Sinatra。（Sinatra是一个极力避免小题大作的创建web应用的Ruby框架。）
- Flask 依赖两个外部库： [Jinja2](http://jinja.pocoo.org/2/) 模板引擎和 [Werkzeug](http://werkzeug.pocoo.org/) WSGI 工具集。
- Flask遵循“约定优于配置”以及合理的默认值原则。

默认情况下，Flask 不包含数据库抽象层、表单验证或是任何其它现有库可以胜任的东西。作为替代的是，Flask 支持扩展来给应用添加这些功能，如同是在 Flask 自身中实现。众多的扩展提供了数据库集成、表单验证、上传处理、多种开放认证技术等功能。

Flask 数目众多的配置选项在初始状况下都有一个明智的默认值，并遵循一些惯例。 例如，按照惯例，模板和静态文件存储在应用的 Python 源代码树下的子目录中，名称分别为 templates 和 static 。虽然可以更改这个配置，但你通常不必这么做， 尤其是在刚接触 Flask 的时候。

# 2. Flask安装

你首先需要 Python 2.6 或更高的版本，所以请确认有一个最新的 Python 2.x 安装。

## virtualenv

virtualenv 允许多个版本的 Python 同时存在，对应不同的项目。 它实际上并没有安装独立的 Python 副本，但是它确实提供了一种巧妙的方式来让各项目环境保持独立。

如果你在 Mac OS X 或 Linux下，下面两条命令可能会适用:

~~~
$ sudo easy_install virtualenv
~~~

或更好的:

~~~
$ sudo pip install virtualenv
~~~

上述的命令会在你的系统中安装 virtualenv。它甚至可能会存在于包管理器中，如果你使用 Ubuntu ，可以尝试:

~~~
$ sudo apt-get install python-virtualenv
~~~

现在你只需要键入以下的命令来激活 virtualenv 中的 Flask:

~~~
$ pip install Flask
~~~

## 全局安装

这样也是可以的，只需要以 root 权限运行 pip:

~~~
$ sudo pip install Flask
~~~

# 3. Flask入门

一个最小的 Flask 应用看起来是这样:

~~~
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello_world():
    return 'Hello World!'

if __name__ == '__main__':
    app.run()
~~~

把它保存为 hello.py（或是类似的），然后用 Python 解释器来运行。

~~~
$ python hello.py
 * Running on http://127.0.0.1:5000/
~~~

现在访问`http://127.0.0.1:5000/`

我们来解释一下上面的代码吧：

- 第一行导入了Flask类，以便创建一个Flask应用的实例。
- 接下来一行我们创建了一个Flask类的实例。这是一个WSGI应用实例。WSGI是"Web服务器网关接口"Web Service Gateway Interface）的缩写，同时也是架设web项目的Python标准。这一行要告诉Flask到哪里去找应用所需的静态资源和模板。在我们的例子中，我们传递了name，让Flask在当前模块内定位资源。
- 接着我们定义了一些关于`/`的路由。第一个路由是为根路径`/`准备的，第二个则对应于类似`/shekhar`、`/abc`之类的路径。对于`/`路由，我们将初始的name设定为Guest。如果用户访问 `http://localhost:5000/` ，那么他会看到`Hello Guest`。如果用户访问 `http://localhost:5000/shekhar` ，那么他会看到 `Hello shekhar`。
- 最后我们用 run() 函数来让应用运行在本地服务器上。 其中 `if __name__ == '__main__'`: 确保服务器只会在该脚本被 Python 解释器直接执行的时候才会运行，而不是作为模块导入的时候。

如果你禁用了 debug 或信任你所在网络的用户，你可以简单修改调用 run() 的方法使你的服务器公开可用，如下:

~~~
app.run(host='0.0.0.0')
~~~

这会让操作系统监听所有公开的IP。

有两种途径来启用调试模式。一种是在应用对象上设置:

~~~
app.debug = True
app.run()
~~~

另一种是作为 run 方法的一个参数传入:

~~~
app.run(debug=True)
~~~

# 4. 总结

本文简单介绍了Flask框架的安装和使用，如果你想要深入研究 Flask 的话，可以查看 [API](http://www.pythondoc.com/flask/api.html#api)。 

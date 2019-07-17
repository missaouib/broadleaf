---
layout: post

title: Bower介绍

description: Bower是 twitter 推出的一款包管理工具，基于 node.js 的模块化思想，把功能分散到各个模块中，让模块和模块之间存在联系，通过 bower 来管理模块间的这种联系。

keywords: bower

category: web

tags: [javascript,node.js,bower]

---

# 1. bower介绍

Bower 是用于 web 前端开发的包管理器。对于前端包管理方面的问题，它提供了一套通用、客观的解决方案。它通过一个 API 暴露包之间的依赖模型，这样更利于使用更合适的构建工具。bower 没有系统级的依赖，在不同 app 之间也不互相依赖，依赖树是扁平的。

![bower-logo](http://sfault-image.b0.upaiyun.com/bc/b4/bcb41307d0c6b3f16013c8abf865fe85)

Bower 运行在 Git 之上，它将所有包都视作一个黑盒子。任何类型的资源文件都可以打包为一个模块，并且可以使用任何规范（例如：AMD、CommonJS 等）。

包管理工具一般有以下的功能：

- `注册机制`：每个包需要确定一个唯一的 ID 使得搜索和下载的时候能够正确匹配，所以包管理工具需要维护注册信息，可以依赖其他平台。
- `文件存储`：确定文件存放的位置，下载的时候可以找到，当然这个地址在网络上是可访问的。
- `上传下载`：这是工具的主要功能，能提高包使用的便利性。比如想用 jquery 只需要 install 一下就可以了，不用到处找下载。上传并不是必备的，根据文件存储的位置而定，但需要有一定的机制保障。
- `依赖分析`：这也是包管理工具主要解决的问题之一，既然包之间是有联系的，那么下载的时候就需要处理他们之间的依赖。下载一个包的时候也需要下载依赖的包。

功能介绍，摘自文章：<http://chuo.me/images/02/twitter-bower.html>

# 2. 安装

bower 插件是通过 npm, node.js 包管理器安装和管理的。

npm 是 node 程序包管理器。它是捆绑在 node.js 的安装程序上的，所以一旦你已经安装了 node，npm 也就安装好了。

在 mac上 安装 node.js 方法：

~~~
brew install nodejs
~~~

通过 npm 安装 bower 到全局环境中：

~~~
npm install -g bower
~~~

# 3. 使用

安装之后，可以通过 `bower help` 命令可以获取更多帮助信息。了解了这些信息就可以开始了。

## 安装包及其依赖的包

Bower 提供了几种方式用于安装包：

~~~bash
# Using the dependencies listed in the current directory's bower.json
bower install
# Using a local or remote package
bower install <package>
# Using a specific Git-tagged version from a remote package
bower install <package>#<version>
~~~

其中，`<package>` 可以是以下列出的一种：

- 注册到 bower 中的一个包名, 例如：jquery。
- 一个 Git 仓库地址,例如： git://github.com/someone/some-package.git
- 一个本地的 Git 目录
- github 的别名,例如：someone/some-package (defaults to GitHub)。
- 一个文件 url，包括 zip 和t ar.gz 文件。

举例来看一下来如何使用 bower 安装 jQuery，在你想要安装该包的地方创建一个新的文件夹，键入如下命令：

~~~bash
$ bower install jquery
~~~

上述命令完成以后，你会在你刚才创建的目录下看到一个 `bower_components` 的文件夹，其中目录如下：

~~~bash
$ tree bower_components/
bower_components
└── jquery
    ├── MIT-LICENSE.txt
    ├── bower.json
    ├── dist
    │   ├── jquery.js
    │   ├── jquery.min.js
    │   └── jquery.min.map
    └── src
        ├── ajax
        │   ├── jsonp.js
        │   ├── load.js
        │   ├── parseJSON.js
        │   ├── parseXML.js
        │   ├── script.js
        │   ├── var
        │   │   ├── nonce.js
        │   │   └── rquery.js
        │   └── xhr.js
        ├── ajax.js
        ├── attributes
        │   ├── attr.js
        │   ├── classes.js
        │   ├── prop.js
        │   ├── support.js
        │   └── val.js
        ├── attributes.js
        ├── callbacks.js
        ├── core
        │   ├── access.js
        │   ├── init.js
        │   ├── parseHTML.js
        │   ├── ready.js
        │   └── var
        │       └── rsingleTag.js
        ├── core.js
        ├── css
        │   ├── addGetHookIf.js
        │   ├── curCSS.js
        │   ├── defaultDisplay.js
        │   ├── hiddenVisibleSelectors.js
        │   ├── support.js
        │   ├── swap.js
        │   └── var
        │       ├── cssExpand.js
        │       ├── getStyles.js
        │       ├── isHidden.js
        │       ├── rmargin.js
        │       └── rnumnonpx.js
        ├── css.js
        ├── data
        │   ├── Data.js
        │   ├── accepts.js
        │   └── var
        │       ├── data_priv.js
        │       └── data_user.js
        ├── data.js
        ├── deferred.js
        ├── deprecated.js
        ├── dimensions.js
        ├── effects
        │   ├── Tween.js
        │   └── animatedSelector.js
        ├── effects.js
        ├── event
        │   ├── alias.js
        │   └── support.js
        ├── event.js
        ├── exports
        │   ├── amd.js
        │   └── global.js
        ├── intro.js
        ├── jquery.js
        ├── manipulation
        │   ├── _evalUrl.js
        │   ├── support.js
        │   └── var
        │       └── rcheckableType.js
        ├── manipulation.js
        ├── offset.js
        ├── outro.js
        ├── queue
        │   └── delay.js
        ├── queue.js
        ├── selector-native.js
        ├── selector-sizzle.js
        ├── selector.js
        ├── serialize.js
        ├── sizzle
        │   └── dist
        │       ├── sizzle.js
        │       ├── sizzle.min.js
        │       └── sizzle.min.map
        ├── traversing
        │   ├── findFilter.js
        │   └── var
        │       └── rneedsContext.js
        ├── traversing.js
        ├── var
        │   ├── arr.js
        │   ├── class2type.js
        │   ├── concat.js
        │   ├── hasOwn.js
        │   ├── indexOf.js
        │   ├── pnum.js
        │   ├── push.js
        │   ├── rnotwhite.js
        │   ├── slice.js
        │   ├── strundefined.js
        │   ├── support.js
        │   └── toString.js
        └── wrap.js

23 directories, 88 files
~~~

## 包的使用

现在就可以在应用程序中使用 jQuery 包了，在 jQuery 里创建一个简单的 html5 文件：

~~~html
<!doctype html>
<html>
<head>
    <title>Learning bower</title>
</head>
<body>
<button>Animate Me!!</button>
<div style="background:red;height:100px;width:100px;position:absolute;">
</div>
<script type="text/javascript" src="bower_components/jquery/jquery.min.js"></script>
<script type="text/javascript">
    $(document).ready(function(){
        $("button").click(function(){
            $("div").animate({left:'250px'});
        });
    });
</script>
</body>
</html>
~~~

正如你所看到的，你刚刚引用 jquery.min.js 文件，现阶段完成。

## 查看安装的包

执行以下命令可以列出所有本地安装的包。

~~~bash
$ bower list
~~~

## 查找包

查找bower注册的包：

~~~bash
$ bower search [<name>]
~~~

只需执行 `bower search` 命令即可列出所有已经注册的包。

## 包的信息

如果你想看到关于特定的包的信息，可以使用 `info` 命令来查看该包的所有信息：

~~~bash
$ bower info jquery
bower cached        git://github.com/jquery/jquery.git#2.1.1
bower validate      2.1.1 against git://github.com/jquery/jquery.git#*

{
  name: 'jquery',
  version: '2.1.1',
  main: 'dist/jquery.js',
  license: 'MIT',
  ignore: [
    '**/.*',
    'build',
    'speed',
    'test',
    '*.md',
    'AUTHORS.txt',
    'Gruntfile.js',
    'package.json'
  ],
  devDependencies: {
    sizzle: '1.10.19',
    requirejs: '2.1.10',
    qunit: '1.14.0',
    sinon: '1.8.1'
  },
  keywords: [
    'jquery',
    'javascript',
    'library'
  ],
  homepage: 'https://github.com/jquery/jquery'
}

Available versions:
  - 2.1.1
  - 2.1.1-rc2
  - 2.1.1-rc1
~~~

## 注册包

可以注册自己的包，这样其他人也可以使用了:

~~~bash
$ bower register project git://github.com/yourname/project
~~~


## 包的卸载

卸载包可以使用 uninstall 命令：

~~~bash
$ bower uninstall jquery
~~~

## 配置文件

每个包应该有一个配置文件，描述包的信息，jquery 的配置文件为 bower.json。

~~~json
{
  "name": "jquery",
  "version": "2.1.1",
  "main": "dist/jquery.js",
  "license": "MIT",
  "ignore": [
    "**/.*",
    "build",
    "speed",
    "test",
    "*.md",
    "AUTHORS.txt",
    "Gruntfile.js",
    "package.json"
  ],
  "devDependencies": {
    "sizzle": "1.10.19",
    "requirejs": "2.1.10",
    "qunit": "1.14.0",
    "sinon": "1.8.1"
  },
  "keywords": [
    "jquery",
    "javascript",
    "library"
  ]
}
~~~

name 和 version 描述包的名称和版本，dependencies 描述这个包依赖的其他包。main 指定包中的静态文件，可以为一个数组。license 指定版权协议，ignore 指定忽略哪些文件，devDependencies 指定依赖，keywords 描述该包的关键字。

除了包的配置文件，Bower 有一个项目的配置文件 .bowerrc ，存在于当期项目目录下，和 bower.json 文件同级，该文件内容如下：

~~~json
{
  "directory": "src/main/resources/static/libs",
  "json": "bower.json"
}
~~~

参数说明：

- `directory`：配置下载的依赖存放路径，默认为 bower_components
- `json`：保存项目依赖的文件名称，默认为 bower.json

更多的配置参数，需要查验官方文档，这里暂时不做补充。

类似的，你可以配置一个全局的配置文件 `~/.bowerrc`，位于用户根目录下面。

## 项目中使用

bower.json 文件的使用可以让包的安装更容易，你可以在应用程序的根目录下创建一个名为 `bower.json` 的文件，并定义它的依赖关系。使用 `bower init`命令来创建 bower.json 文件：

~~~bash
[?] name: blog
[?] version: 0.0.0
[?] description: 
[?] main file: 
[?] what types of modules does this package expose? 
[?] keywords: 
[?] authors: javachen <june.chan@javachen.com>
[?] license: MIT
[?] homepage: 
[?] would you like to mark this package as private which prevents it from being accidentally published to the registry? No
accidentally published to the registry? (y/N) 
{
  name: 'blog',
  version: '0.0.0',
  authors: [
    'javachen <june.chan@javachen.com>'
  ],
  license: 'MIT',
  ignore: [
    '**/.*',
    'node_modules',
    'bower_components',
    'test',
    'tests'
  ],
  dependencies: {
    jquery: '~2.1.1'
  }
}

[?] Looks good? Yes
~~~

注意看，它已经加入了 jQuery 依赖关系。

现在假设也想用 twitter bootstrap，我们可以用下面的命令安装 twitter bootstrap 并更新 bower.json文件：

~~~bash
$ bower install bootstrap --save
~~~

它会自动安装最新版本的 bootstrap 并更新 bower.json 文件：

~~~javascript
{
  name: 'blog',
  version: '0.0.0',
  authors: [
    'javachen <june.chan@javachen.com>'
  ],
  license: 'MIT',
  ignore: [
    '**/.*',
    'node_modules',
    'bower_components',
    'test',
    'tests'
  ],
  dependencies: {
    jquery: '~2.1.1',
    bootstrap: '~3.0.0'
  }
}
~~~


如果想查看有哪些包和文件，可执行 `bower list --path`。比如安装了 jquery，可以看到以下信息：

~~~json
{
  "jquery": "bower_components/jquery/dist/jquery.js"
}
~~~

现在就可以使用了，在当前目录建一个页面，script 嵌入需要的 js。

# 4. 总结

Bower 类似 maven 用于管理 javascript 的版本及其依赖，使用非常简单。

# 5. 参考文章

- [用于web前端开发的包管理器](http://bower.jsbin.cn/)
- [twitter 的包管理工具 - bower](http://chuo.me/images/02/twitter-bower.html)
- [Day 1: Bower —— 管理你的客户端依赖关系](http://segmentfault.com/a/1190000000349555)

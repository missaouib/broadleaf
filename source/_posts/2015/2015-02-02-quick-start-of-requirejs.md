---
layout: post

title: Require.JS快速入门

category: web

tags: [ require.js ]

description: Require.JS 是一个基于 AMD 规范的 JavaScript 模块加载框架。实现 JavaScript 文件的异步加载，管理模块之间的依赖性，提升网页的加载速度。

published: true

---

## Require.JS 介绍

Require.JS 是一个基于 AMD 规范的 JavaScript 模块加载框架。实现 JavaScript 文件的异步加载，管理模块之间的依赖性，提升网页的加载速度。

AMD 是 `Asynchronous Module Definition` 的缩写，意思就是 `异步模块定义`。它采用异步方式加载模块，模块的加载不影响它后面语句的运行。所有依赖这个模块的语句，都定义在一个回调函数中，等到加载完成之后，这个回调函数才会运行。

官网地址：<www.requirejs.org>

Require.JS 的诞生主要为了解决两个问题：　　

- 1）实现 JavaScript 文件的异步加载，避免网页失去响应；
- 2）管理模块之间的依赖性，便于代码的编写和维护。

## 加载 Require.JS

去[官方网站](http://requirejs.org/docs/download.html)下载最新版本，然后创建一个工程，目录如下：

~~~
project-directory
├── project.html
└── scripts
    ├── lib
    │   ├── a.js
    │   ├── b.js
    │   ├── backbone.js
    │   └── underscore.js
    ├── main.js
    └── require.js
~~~

编写 project.html 内容，引入 Require.JS 文件：

~~~html
<!DOCTYPE html>
<html>
    <head>
        <title>My Sample Project</title>
        <!-- data-main attribute tells require.js to load
             scripts/main.js after require.js loads. -->
        <script data-main="scripts/main" src="scripts/require.js"></script>
    </head>
    <body>
        <h1>My Sample Project</h1>
    </body>
</html>
~~~

加载 scripts/require.js 这个文件，也可能造成网页失去响应。解决办法有两个，一个是把它放在网页底部加载，另一个是写成下面这样：

~~~html
<script data-main="scripts/main" src="js/require.js" defer async="true" ></script>
~~~

[async](https://developer.mozilla.org/en/docs/Web/HTML/Element/script#Attributes) 属性表明这个文件需要异步加载，避免网页失去响应。IE 不支持这个属性，只支持 `defer`，所以把 `defer` 也写上。

加载 Require.JS 以后，下一步就要加载我们自己的代码了，这里我们使用 [data-main](http://requirejs.org/docs/api.html#data-main) 属性来指定网页程序的主模块。在上例中，就是 scripts 目录下面的 main.js，这个文件会第一个被 Require.JS 加载。由于 Require.JS 默认的文件后缀名是 js，所以可以把 main.js 简写成 main。

在浏览器中打开 project.html 文件，查看浏览器是否提示有错误。

## 定义模块

Require.JS 加载的模块，采用 AMD 规范。也就是说，模块必须按照 AMD 的规定来写。
具体来说，就是模块必须采用特定的 `define()` 函数来定义。如果一个模块不依赖其他模块，那么可以直接定义在 `define()` 函数之中。

定义：

~~~javascript
define(id, dependencies, factory);
~~~

参数：

  - `id` : 模块标示符[可省略]
  - `dependencies` : 所依赖的模块[可省略]
  - `factory` : 模块的实现，或者一个 JavaScript 对象。

Require.JS 定义模块的几种方式：

1、定义一个最简单的模块：

~~~javascript
define({
        color: "black",
        size: "unisize"
});
~~~

2、传入匿名函数定义一个模块：

~~~javascript
define(function () {
        return {
            color: "black",
            size: "unisize"
        }
 });
~~~

3、定义一个模块并依赖于 cart.js

~~~javascript
define(["./cart"], function(cart) {
        return {
            color: "blue",
            size: "large",
            addToCart: function() {
                cart.add(this);
            }
        }
});
~~~

4、定义一个名称为 hello 且依赖于 cart.js 的模块

~~~javascript
define("hello",["./cart"],function(cart) {
        //do something
});
~~~

5、兼容 commonJS 模块的写法(使用 require 获取依赖模块，使用 exports 导出 API)

~~~javascript
define(function(require, exports, module) {
        var base = require('base');
        exports.show = function() {
            // todo with module base
        } 
});
~~~

举例，在 lib/a.js 中，我们可以定义模块：

~~~javascript
define(function (){
    var add = function (x,y){
        return x+y;
    };
    return {
        add: add
    };
});
~~~

然后，在 main.js 中使用：

~~~javascript
require(['lib/a'], function (a){
    alert(a.add(1,1));
});
~~~

如果这个模块还依赖其他模块，那么 `define()` 函数的第一个参数，必须是一个数组，指明该模块的依赖性。

例如，lib/b.js 文件如下：

~~~javascript
define(['lib/a'], function(a){
    function fun1(){
        alert(2);
    }
    return {
        fun1: fun1,
        fun2: function(){alert(3)}
    };
});
~~~

定义的模块返回函数个数问题:

- define 的 return 只有一个函数，require 的回调函数可以直接用别名代替该函数名。
- define 的 return 当有多个函数，require 的回调函数必须用别名调用所有的函数。

这时候修改 main.js 内容为：

~~~javascript
require(['lib/a','lib/b'], function(a,b) {
    alert(a.add(0,1))

    b.fun1();
    b.fun2();
});
~~~

然后，在浏览器中打开 project.html 文件，查看输出内容。

## 全局配置

如果你想改变 RequireJS 的默认配置来使用自己的配置，你可以使用 `require.config` 函数。`require.config()` 方法一般写在主模块(main.js)最开始。参数为一个对象，通过对象的键值对加载进行配置: 

- `baseUrl`：用于加载模块的根路径。如果 baseUrl 没有指定，那么就会使用 `data-main` 中指定的路径。
- `paths`：用于映射不存在根路径下面的模块路径。
- `map` : 对于给定的相同的模块名，加载不同的模块，而不是加载相同的模块
- `packages` : 配置从 CommonJS 包来加载模块
- `waitSeconds`：是指定最多花多长等待时间来加载一个 JavaScript 文件，用户不指定的情况下默认为 7 秒。
- `shims`：配置在脚本/模块外面并没有使用 RequireJS 的函数依赖并且初始化函数。
- `deps`：加载依赖关系。

其他可配置的选项还包括 locale、context、callback 等，有兴趣的读者可以在 RequireJS 的官方网站查阅[相关文档](http://www.requirejs.org/docs/api.html#config)。

main.js 中修改如下：

~~~javascript
require.config({
    //By default load any module IDs from scripts/main
    baseUrl: 'scripts',
    paths: {
        "jquery" : ["http://libs.baidu.com/jquery/2.0.3/jquery", "scripts/jquery"],
        "a":"lib/a"
    }
});

//通过别名来引用模块
require(["jquery","a"],function($){
    $(function(){
        alert("load finished");
    })
})
~~~

在这个例子中，通过 baseUrl 把根路径设置为了 scripts，通过 paths 的配置会使我们的模块名字更精炼，paths 还有一个重要的功能，就是可以配置多个路径，如果远程加载没有成功，可以加载本地的库。

上面例子中，先从远程加载 jquery 模块，如果加载失败，则从本地 scripts/jquery 加载；a 模块名称为 lib/a 路径的简称，加载 a 模块时，实际上是加载的 script/lib/a.js 文件。

通过 require加载的模块一般都需要符合 AMD 规范即使用 define 来申明模块，但是部分时候需要加载非 AMD 规范的 JavaScript，这时候就需要用到另一个功能：`shim`。比如我要是用 underscore 类库，但是他并没有实现 AMD 规范，那我们可以这样配置：

~~~javascript
require.config({
    shim: {
        "underscore" : {
            exports : "_";
        }
    }
})
~~~

这样配置后，我们就可以在其他模块中引用 underscore 模块：

~~~javascript
require(["underscore"], function(_){
    _.each([1,2,3], alert);
})
~~~

在新版本的 jquery 中，继承了 AMD 规范，所以可以直接使用 `require["jquery"]`，但是我们经常用到的 jquery 插件基本都不符合AMD规范。

~~~javascript
require.config({
    shim: {
        "underscore" : {
            exports : "_";
        },
        "jquery.form" : {
            deps : ["jquery"]
        }
    }
})
~~~

也可以简写为：

~~~javascript
require.config({
    shim: {
        "underscore" : {
            exports : "_";
        },
        "jquery.form" : ["jquery"]
    }
})
~~~

这样配置之后我们就可以使用加载插件后的 jquery 了：

~~~javascript
require.config(["jquery", "jquery.form"], function($){
    $(function(){
        $("#form").ajaxSubmit({...});
    })
})
~~~

## Require.JS 插件

Require.JS 还提供一系列插件，实现一些特定的功能。

`domready` 插件，可以让回调函数在页面 DOM 结构加载完成后再运行。

~~~javascript
require(['domready!'], function (doc){
    // called once the DOM is ready
});
~~~

tex t和 image 插件，则是允许 Require.JS 加载文本和图片文件。

~~~javascript
define([
    'text!review.txt',
    'image!cat.jpg'
    ],
    function(review,cat){
        console.log(review);
        document.body.appendChild(cat);
    }
);
~~~

类似的插件还有 json 和 mdown，用于加载 json 文件和 markdown 文件。

插件清单：<https://github.com/jrburke/requirejs/wiki/Plugins>

## 其他问题

- 1、循环依赖

在一些情况中，我们可能需要模块 moduleA 和 moduleA 中的函数需要依赖一些应用。这就是循环依赖。

~~~javascript
// js/app/moduleA.js
define( [ "require", "app/app"],
    function( require, app ) {
        return {
            foo: function( title ) {
                var app = require( "app/app" );
                return app.something();
            }
        }
    }
);
~~~

- 2、得到模块的地址

如果你需要得到模块的地址，你可以这么做……

~~~javascript
var path = require.toUrl("./style.css");  
~~~

- 3、JSONP

我们可以这样处理 JSONP：

~~~javascript
require( [ 
    "http://someapi.com/foo?callback=define"
], function (data) {
    console.log(data);
});
~~~

- 4. 代码合并于压缩

请参考 [优化 RequireJS 项目（合并与压缩）](http://blog.jobbole.com/39205/)

## 参考文章

- [使用require.js进行JavaScript模块化编程](http://yuankeqiang.lofter.com/post/8de51_b83cf3)

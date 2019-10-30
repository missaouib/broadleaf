---
layout: post

title: AngularJS PhoneCat代码分析
date: 2015-01-09T08:00:00+08:00

categories: [ web ]

tags: [ angular.js,node.js,bower ]

description:  本文主要分析 AngularJS 官方网站提供的一个用于学习的示例项目 PhoneCat 的构建、测试过程以及代码的运行原理。希望能够对 PhoneCat 项目有一个更加深入全面的认识。

published: true

---

AngularJS 官方网站提供了一个用于学习的示例项目：PhoneCat。这是一个Web应用，用户可以浏览一些Android手机，了解它们的详细信息，并进行搜索和排序操作。

本文主要分析 AngularJS 官方网站提供的一个用于学习的示例项目 PhoneCat 的构建、测试过程以及代码的运行原理。希望能够对 PhoneCat 项目有一个更加深入全面的认识。这其中包括以下内容：

- 该项目如何运行起来的
- 该项目如何进行前端单元测试
- AngularJS 相关代码分析

**以下内容如有理解不正确，欢迎指正！**

# 1. 环境搭建

对于 PhoneCat 项目的开发环境和测试环境的搭建，官方网站上提供了详细的指导：<http://docs.angularjs.org/tutorial>，你可以找到一些中文的翻译。

PhoneCat 项目的源代码托管在 GitHub 上，可以通过下面命令下载源代码：

~~~bash
$ git clone --depth=20 https://github.com/angular/angular-phonecat.git
~~~

`--depth=20` 选项的意思为：仅下载最近20次的代码提交版本；这么做可以减少下载的文件大小，加快下载。

>PhoneCat 是一个 Web 应用程序，因此最好在 Web 服务器中运行，以期获得最佳结果。官方推荐安装 [Node.js](http://nodejs.org/download/)。

PhoneCat 项目的运行与测试依赖一些别的工具，可以在安装 [Node.js](http://www.oschina.net/p/nodejs) 后通过 npm 命令来安装这些依赖包。以下命令需在 angular-phonecat 项目路径下运行：

~~~bash
$ npm install
~~~

运行该命令后，会在 angular-phonecat 项目路径下安装以下依赖包：

- `Bower` 包管理器
- `Http-Server` 轻量级Web服务器
- `Karma`  用于运行单元测试
- `Protractor` 用于运行端到端测试

几乎所有的 AngularJS 学习教程，都会写到用这个命令来启动服务： 

~~~bash
$ node scripts/web-server.js
~~~

但实际上 PhoneCat 项目已经放弃使用 web-server 了，git 上取下来的的项目里没有 scripts/web-server.js 文件了。

我们可以用下面的方式来启动工程：

~~~bash
$ npm start
~~~

然后通过 <http://localhost:8000/app/index.html> 访问。

# 2. 依赖包介绍

在克隆项目之后，目录如下：

~~~bash
➜  angular-phonecat git:(master) ✗ tree -L 2
.
├── LICENSE
├── README.md
├── app
│   ├── bower_components
│   ├── css
│   ├── img
│   ├── index.html
│   ├── js
│   ├── partials
│   └── phones
├── bower.json
├── package.json
├── scripts
│   ├── private
│   └── update-repo.sh
└── test
    ├── e2e
    ├── karma.conf.js
    ├── protractor-conf.js
    └── unit

20 directories, 8 files
~~~

这个目录下存在一个文件 package.json，该文件是做什么用的呢？

>在 NodeJS 项目中，用 package.json 文件来声明项目中使用的模块，这样在新的环境部署时，只要在 package.json 文件所在的目录执行 `npm install` 命令即可安装所需要的模块。

关于 package.json 中可配置的选项请参考 [package.json字段全解](http://blog.csdn.net/woxueliuyun/article/details/39294375) 。

从该文件可以看出 PhoneCat 的依赖：

~~~javascript
  "devDependencies": {
    "karma": "^0.12.16",
    "karma-chrome-launcher": "^0.1.4",
    "karma-jasmine": "^0.1.5",
    "protractor": "~1.0.0",
    "http-server": "^0.6.1",
    "tmp": "0.0.23",
    "bower": "^1.3.1",
    "shelljs": "^0.2.6"
  }
~~~

以及一些脚本：

~~~javascript
"scripts": {
    "postinstall": "bower install",

    "prestart": "npm install",
    "start": "http-server -a 0.0.0.0 -p 8000",

    "pretest": "npm install",
    "test": "node node_modules/karma/bin/karma start test/karma.conf.js",
    "test-single-run": "node node_modules/karma/bin/karma start test/karma.conf.js  --single-run",

    "preupdate-webdriver": "npm install",
    "update-webdriver": "webdriver-manager update",

    "preprotractor": "npm run update-webdriver",
    "protractor": "protractor test/protractor-conf.js",

    "update-index-async": "node -e \"require('shelljs/global'); sed('-i', /\\/\\/@@NG_LOADER_START@@[\\s\\S]*\\/\\/@@NG_LOADER_END@@/, '//@@NG_LOADER_START@@\\n' + cat('bower_components/angular-loader/angular-loader.min.js') + '\\n//@@NG_LOADER_END@@', 'app/index-async.html');\""
  }
~~~

从上可以看出运行 `npm start` 之前会运行 `npm install`，然后运行 `http-server -a 0.0.0.0 -p 8000` 启动一个 web 服务器，最后是运行 `bower install` 安装 bower 管理的包。

bower 管理的包由 bower.json 文件定义：

~~~javascript
{
  "name": "angular-phonecat",
  "description": "A starter project for AngularJS",
  "version": "0.0.0",
  "homepage": "https://github.com/angular/angular-phonecat",
  "license": "MIT",
  "private": true,
  "dependencies": {
    "angular": "1.3.x",
    "angular-mocks": "1.3.x",
    "jquery": "~2.1.1",
    "bootstrap": "~3.1.1",
    "angular-route": "1.3.x",
    "angular-resource": "1.3.x",
    "angular-animate": "1.3.x"
  }
}
~~~

当然，package.json 文件中还定义了一些测试相关的命令。

## bower

关于 [bower](http://bower.io/) 的介绍，参考博客内文章：[bower介绍](/2014/05/10/bower-intro.html)。

在本项目中，bower 下载的包保存在 angular-phonecat/app/bower_components 目录下，依赖如下： 

~~~
├── bower_components
│   ├── angular
│   ├── angular-animate
│   ├── angular-mocks
│   ├── angular-resource
│   ├── angular-route
│   ├── bootstrap
│   └── jquery
~~~

## karma

[Karma](http://karma-runner.github.io/0.12/index.html) 是一个 Javascript 测试运行工具，可以帮助你关闭反馈循环。Karma 可以在特定的文件被修改时运行测试，它也可以在不同的浏览器上并行测试。不同的设备可以指向 Karma 服务器来覆盖实际场景。

关于 Karma 的使用，本文不做介绍。

## http-server

[http-server](https://github.com/nodeapps/http-server) 是一个简单的零配置命令行 HTTP 服务器，基于 [Node.js](http://www.oschina.net/p/nodejs)。

在命令行中使用方式是：

~~~bash
$ node http-server
~~~

在package.json 中定义方式是：

~~~javascript
 "scripts": {
     "start": "http-server -a 0.0.0.0 -p 8000",
 }
 ~~~

 支持的参数：

~~~bash
 -p 端口号 (默认 8080)

-a IP 地址 (默认 0.0.0.0)

-d 显示目录列表 (默认 'True')

-i 显示 autoIndex (默认 'True')

-e or --ext 如果没有提供默认的文件扩展名(默认 'html')

-s or --silent 禁止日志信息输出

--cors 启用 CORS 

-o 在开始服务后打开浏览器

-h or --help 打印列表并退出

-c 为 cache-control max-age header 设置Cache time(秒) ，禁用 caching, 则值设为 -1 .
~~~

## Protractor

[Protractor](http://www.protractortest.org/) 是一个端对端的测试运行工具，模拟用户交互，帮助你验证你的 Angular 应用的运行状况。

Protractor 使用 [Jasmine](http://jasmine.github.io/) 测试框架来定义测试。Protractor 为不同的页面交互提供一套健壮的 API。

当然，也有其他的端对端工具，不过 Protractor 有着自己的优势，它知道怎么和 AngularJS 的代码一起运行，特别是面临 $digest 循环的时候。

关于 Protractor 的使用，本文不做介绍。

## ShellJS

[ShellJS](http://shelljs.org/) 是 [Node.js](http://www.oschina.net/p/nodejs) 扩展，用于实现 Unix shell 命令执行，支持 Windows。

一个示例代码：

~~~javascript
require('shelljs/global');

if (!which('git')) {
  echo('Sorry, this script requires git');
  exit(1);
}

// Copy files to release dir
mkdir('-p', 'out/Release');
cp('-R', 'stuff/*', 'out/Release');

// Replace macros in each .js file
cd('lib');
ls('*.js').forEach(function(file) {
  sed('-i', 'BUILD_VERSION', 'v0.1.2', file);
  sed('-i', /.*REMOVE_THIS_LINE.*\n/, '', file);
  sed('-i', /.*REPLACE_LINE_WITH_MACRO.*\n/, cat('macro.js'), file);
});
cd('..');

// Run external tool synchronously
if (exec('git commit -am "Auto-commit"').code !== 0) {
  echo('Error: Git commit failed');
  exit(1);
}
~~~

在 PhoneCat 中，主要是用在下面：

~~~javascript
"update-index-async": "node -e \"require('shelljs/global'); sed('-i', /\\/\\/@@NG_LOADER_START@@[\\s\\S]*\\/\\/@@NG_LOADER_END@@/, '//@@NG_LOADER_START@@\\n' + cat('bower_components/angular-loader/angular-loader.min.js') + '\\n//@@NG_LOADER_END@@', 'app/index-async.html');\""
~~~

# 3. 测试

## 运行单元测试

PhoneCat 项目中的单元测试是使用 Karma 来完成的，所有的单元测试用例都存放在 test/unit 目录下。可以通过执行以下命令来运行单元测试：

~~~bash
$ npm test
~~~

>值得一提的是，在运行单元测试前，计算机上必须安装 Google Chrome 浏览器，**因为这里用到了 karma-chrome-launcher**。

## 运行端到端测试

PhoneCat 项目使用端到端测试来保证 Web 应用的可操作性，而这个端到端测试是通过使用 Protractor 来实现的，所有的端到端测试用例都存放在test/e2e 目录下。可以通过执行以下步骤来运行端到端测试：

~~~bash
//更新webdriver，此命令只需运行一次
$ npm run update-webdriver
//运行PhoneCat
$ npm start
~~~

打开另一个命令行窗口，在其中运行：

~~~bash
$ npm run protractor
~~~

# 4. 代码分析

在介绍了 PhoneCat 的运行和测试环境后，来看看 PhoneCat 的页面和 js 是怎么组织起来的。

- 首先，从 index.html 内容可以看到 PhoneCat 页面使用 bootstrap 框架，并且引入了 jquery 以及 angular 的相关依赖，包括一些附加模块：`路由`、`动画`、`资源`。
- angular 应用范围由 `ng-app` 定义在 html 节点上，即作用于整个页面，其名称为 `phonecatApp`。
- 通过 `ng-view` 指定加载子视图的位置，这里主要包括 `partials/phone-list.html` 和 `partials/phone-detail.html` 两个视图。
- app.js 是应用的入口，并且依赖 animations.js、controllers.js、filters.js、services.js 等文件。从这里可以看出，一个 angular 应用的 js 大概包括哪几个部分的内容。

app.js 内容如下：

~~~javascript

//JavaScript语法支持严格模式:如果在语法检测时发现语法问题，则整个代码块失效，并导致一个语法异常；如果在运行期出现了违反严格模式的代码，则抛出执行异常。
'use strict';

/* App Module */
//定义一个模块，模块名称和页面 ng-app 中内容一致
var phonecatApp = angular.module('phonecatApp', [
  'ngRoute',
  'phonecatAnimations',
  'phonecatControllers',
  'phonecatFilters',
  'phonecatServices'
]);

//定义路由
phonecatApp.config(['$routeProvider',
  function($routeProvider) {
    $routeProvider.
      when('/phones', {
        templateUrl: 'partials/phone-list.html',
        controller: 'PhoneListCtrl'
      }).
      when('/phones/:phoneId', {
        templateUrl: 'partials/phone-detail.html',
        controller: 'PhoneDetailCtrl'
      }).
      otherwise({
        redirectTo: '/phones'
      });
  }]);
  ~~~

phonecatApp 模块依赖其他几个模块：ngRoute、phonecatAnimations、phonecatControllers、phonecatFilters、phonecatServices。

ngRoute 是内置的路由模块，定义路由规则：

- 当访问 `/phones`，由 `PhoneListCtrl` 控制器处理，并且由 `partials/phone-list.html` 模板渲染显示内容。
- 当访问 `/phones/:phoneId`，由 `PhoneDetailCtrl` 控制器处理，并且由 `partials/phone-detail.html` 模板渲染显示内容。
- 如果不满足上面条件，则重定向到 `/phones`

phonecatAnimations 模块是定义动画效果，没有真个模块不影响程序的主要功能的运行，故不分析这部分代码。

phonecatControllers 模块定义在 controllers.js 文件中：

~~~javascript
'use strict';

/* Controllers */
var phonecatControllers = angular.module('phonecatControllers', []);

// 定义 PhoneListCtrl，并注入 Phone 对象
phonecatControllers.controller('PhoneListCtrl', ['$scope', 'Phone',
  function($scope, Phone) {
    $scope.phones = Phone.query();
    $scope.orderProp = 'age';
  }]);

// 定义 PhoneDetailCtrl，并注入 Phone 对象和 $routeParams，$routeParams 封装了路由参数。
phonecatControllers.controller('PhoneDetailCtrl', ['$scope', '$routeParams', 'Phone',
  function($scope, $routeParams, Phone) {
    $scope.phone = Phone.get({phoneId: $routeParams.phoneId}, function(phone) {
      //回调方法
      $scope.mainImageUrl = phone.images[0];
    });

    $scope.setImage = function(imageUrl) {
      $scope.mainImageUrl = imageUrl;
    }
  }]);
~~~

phonecatFilters 模块定义在 filter.js 文件中，主要是自定义了一个过滤器 `checkmark`：根据输入是否有内容判断返回 `✓` 还是 `✘`。

phonecatServices 模块定义在 services.js 文件中：

~~~javascript
'use strict';

/* Services */
var phonecatServices = angular.module('phonecatServices', ['ngResource']);

// 定义 Phone 服务，并提供了一个 query 方法，还包括一个内置的 get 方法。调用 get 方法实际上就是调用 query 方法，并且可以传递一个参数 phoneId
phonecatServices.factory('Phone', ['$resource',
  function($resource){
    return $resource('phones/:phoneId.json', {}, {
      query: {method:'GET', params:{phoneId:'phones'}, isArray:true}
    });
  }]);
~~~

# 5. 参考文章

- [AngularJS初探：搭建PhoneCat项目的开发与测试环境](http://www.lifelaf.com/blog/?p=1206)
- [Angular 实例项目 angular-phonecat 的一些问题](http://www.cnblogs.com/ElvinLong/p/3939938.html)

---
layout: post
title: Backbone中的模型
description: Backbone中的模型是所有Javascript应用程序的核心，包括交互数据及相关的大量逻辑： 转换、验证、计算属性和访问控制。你可以用特定的方法扩展Backbone.Model，模型也提供了一组基本的管理变化的功能。
category: web
tags: [backbone]
---

# 创建model

模型是所有Javascript应用程序的核心，包括交互数据及相关的大量逻辑： 转换、验证、计算属性和访问控制。你可以用特定的方法扩展`Backbone.Model`，模型也提供了一组基本的管理变化的功能。

~~~javascript
Person = Backbone.Model.extend({
    initialize: function(){
        alert("Welcome to this world");
    }
});

var person = new Person;
~~~

new一个model的实例后就会触发initialize()函数。

# 设置属性

现在我们想设置一些属性，有两种方式，可以在创建model实例时进行传参，也可以在实例生成后通过`model.set(obj)`来进行设置。

~~~javascript
Person = Backbone.Model.extend({
    initialize: function(){
        alert("Welcome to this world");
    }
});

var person = new Person({ name: "Thomas", age: 67});
// or we can set afterwards, these operations are equivelent
var person = new Person();
person.set({ name: "Thomas", age: 67});
~~~
# 获取属性

~~~javascript
Person = Backbone.Model.extend({
    initialize: function(){
        alert("Welcome to this world");
    }
});

var person = new Person({ name: "Thomas", age: 67, child: 'Ryan'});

var age = person.get("age"); // 67
var name = person.get("name"); // "Thomas"
var child = person.get("child"); // 'Ryan'
~~~

# 设置model默认属性
有的时候你可能会想让model有默认属性值，只要在进行model声明的时候设置个`defaults`就行了。

~~~javascript
Person = Backbone.Model.extend({
    defaults: {
        name: 'Fetus',
        age: 0,
        child: ''
    },
    initialize: function(){
        alert("Welcome to this world");
    }
});

var person = new Person({ name: "Thomas", age: 67, child: 'Ryan'});

var age = person.get("age"); // 67
var name = person.get("name"); // "Thomas"
var child = person.get("child"); // 'Ryan'
~~~

# 监听model的属性改变
我们可以通过`model.bind(event,callback)`方法来绑定change事件来监听属性改变。下面的这个例子就是在initialize方法中绑定了一个name属性改变的事件监听。
如果person的name属性改变了，就会弹出个对话框显示新值。

~~~javascript
Person = Backbone.Model.extend({
    defaults: {
        name: 'Fetus',
        age: 0
    },
    initialize: function(){
        alert("Welcome to this world");
        this.on("change:name", function(model){
            var name = model.get("name"); // 'Stewie Griffin'
            alert("Changed my name to " + name );
        });
    }
});

var person = new Person({ name: "Thomas", age: 67});
person.set({name: 'Stewie Griffin'}); // This triggers a change and will alert()
~~~

# 和服务端交互

服务端实现一个RESTful的url例如/user，可以允许我们通过他与后台交互。

~~~javascript
var UserModel = Backbone.Model.extend({
    urlRoot: '/user',
    defaults: {
        name: '',
        email: ''
    }
});
~~~

`model.urlRoot`:如果使用的集合外部的模型，通过指定 urlRoot 来设置生成基于模型 id 的 URLs 的默认 url 函数。 "/[urlRoot]/id"

# 创建一个新model

如果id为null，则会提交一个POST请求到/user。

~~~javascript
var UserModel = Backbone.Model.extend({
    urlRoot: '/user',
    defaults: {
        name: '',
        email: ''
    }
});
var user = new Usermodel();
// Notice that we haven't set an `id`
var userDetails = {
    name: 'Thomas',
    email: 'thomasalwyndavis@gmail.com'
};
// Because we have not set a `id` the server will call
// POST /user with a payload of {name:'Thomas', email: 'thomasalwyndavis@gmail.com'}
// The server should save the data and return a response containing the new `id`
user.save(userDetails, {
    success: function (user) {
        alert(user.toJSON());
    }
})
~~~

`model.save([attributes], [options]) `: 通过委托`Backbone.sync`保存模型到数据库（或可替代的持久层）。 attributes 散列表 (在 set) 应当包含想要改变的属性，不涉及的键不会被修改。 如果模型含有`validate`方法，并且验证失败，模型不会保存。 如果模型`isNew`, 保存将采用 "create" (HTTP POST) 方法, 如果模型已经在服务器存在，保存将采用 "update" (HTTP PUT) 方法.

# 获取一个model

初始化一个model实例并设置其id属性，并调用fetch方法，这样会请求`urlRoot + '/id'`地址到后台。

~~~javascript
// Here we have set the `id` of the model
var user = new Usermodel({id: 1});

// The fetch below will perform GET /user/1
// The server should return the id, name and email from the database
user.fetch({
    success: function (user) {
        alert(user.toJSON());
    }
})
~~~

`model.fetch([options])`: 从服务器重置模型状态。这对模型尚未填充数据，或者服务器端已有最新状态的情况很有用处。 如果服务器端状态与当前属性不同，则触发`change`事件。 选项的散列表参数接受`success`和`error`回调函数， 回调函数中可以传入`(model,response)`作为参数。

~~~javascript
// 每隔 10 秒从服务器拉取数据以保持模型是最新的
setInterval(function() {
  user.fetch();
}, 10000);
~~~
# 更新一个model
当保存的model对象的id不为空时，则会提交一个PUT请求到urlRoot。

~~~javascript
// Here we have set the `id` of the model
var user = new Usermodel({
    id: 1,
    name: 'Thomas',
    email: 'thomasalwyndavis@gmail.com'
});

// Let's change the name and update the server
// Because there is `id` present, Backbone.js will fire
// PUT /user/1 with a payload of `{name: 'Davis', email: 'thomasalwyndavis@gmail.com'}`
user.save({name: 'Davis'}, {
    success: function (model) {
        alert(user.toJSON());
    }
});
~~~

# 删除一个model
调用model的destroy方法时，则会提交请求到urlRoot+"/id"

~~~javascript
// Here we have set the `id` of the model
var user = new Usermodel({
    id: 1,
    name: 'Thomas',
    email: 'thomasalwyndavis@gmail.com'
});

// Because there is `id` present, Backbone.js will fire
// DELETE /user/1 
user.destroy({
    success: function () {
        alert('Destroyed');
    }
});
~~~
`model.destroy([options])`:通过委托`HTTP DELETE`请求到`Backbone.sync`销毁服务器上的模型. 接受`success`和`error`回调函数作为选项散列表参数。将在模型上触发`destroy`事件，该事件可以通过任意包含它的集合向上冒泡。

# 其他方法

model还有一些其他的方法，可以参考api：[Backbone.js API中文文档](http://www.csser.com/tools/backbone/backbone.js.html#manual/Model)

~~~javascript
var person = new Person({ name: "Thomas", age: 67});
var attributes = person.toJSON(); // { name: "Thomas", age: 67}
/* This simply returns a copy of the current attributes. */

var attributes = person.attributes;
/* The line above gives a direct reference to the attributes and you should be careful when playing with it.   Best practise would suggest that you use .set() to edit attributes of a model to take advantage of backbone listeners. */
~~~

# 参考文章

- [what-is-a-model](http://backbonetutorials.com/what-is-a-model/)
- [Backbone.js API中文文档](http://www.csser.com/tools/backbone/backbone.js.html)


---
layout: post

title: 解决固定导航时锚点偏移问题

category: web

tags: [web,javascript]

description:  最近基于Bootstrap修改了博客主题，使其支持响应式布局，并且将导航菜单固定住，这样做带来的影响是，点击锚点链接后，锚点没有正确的定位，有一部分内容被导航遮挡住了。

published: true

---

最近Bootstrap修改了博客主题，使其支持响应式布局，并且将导航菜单固定住，不随滚到条滚动，这样做带来的影响是[Categories](/categories.html)和[Tags](/tags.html)页面点击某一个分类或者标签链接时，`锚点定位必然定位于页面顶部，这样一来就会被固定住的导航遮挡`，例如，我在Categories页面，点击[hbase](/categories.html#hbase)分类，锚点定位最后如下图：

![](/static/images/2015/fix-anchor-offset-when-using-bootstrap-navbar-fixed-top.jpg)

网上查找了一些资料，找到一篇文章[点击锚点让定位偏移顶部](http://www.ldsun.com/1815.html)，这篇文章提到几种解决办法：

第一种，使用css将锚点偏移：

~~~html
<a class="target-fix" ></a>
<artivle>主体内容...</article>
~~~

css如下：

~~~css
.target-fix {
    position: relative;
    top: -44px; /*偏移值*/
    display: block;
    height: 0;
    overflow: hidden;
}
~~~

对于现代浏览器如果支持css的`:target`声明，可以这么设置：

~~~css
article.a-post:target{
    padding-top:44px;
}
~~~

第二种，使用JavaScript去调整scroll值：

~~~javascript
$(function(){
  if(location.hash){
     var target = $(location.hash);
     if(target.length==1){
         var top = target.offset().top-44;
         if(top > 0){
             $('html,body').animate({scrollTop:top}, 1000);
         }
     }
  }
});
~~~

>注意：上面代码中的44为固定的导航所占的像素高度，根据你的实际情况做修改。

当然，你也可以使用jquery-hashchange插件去实现上面的功能，但是需要注意jquery-hashchange是否支持你使用的JQuery版本。

~~~javascript
$(function(){
        /* 绑定事件*/
        $(window).hashchange(function(){
            var target = $(location.hash);
            if(target.length==1){
                 var top = target.offset().top-44;
                 if(top > 0){
                     $('html,body').animate({scrollTop:top}, 1000);
                 }
             } 
        });
        /* 触发事件 */
        $(window).hashchange();
});
~~~

分析上面两种方法，我最后使用的是第二种方法，在core.js文件中添加如下代码：

~~~javascript
$('a[href^=#][href!=#]').click(function() {
  var target = document.getElementById(this.hash.slice(1));
  if (!target) return;
  var targetOffset = $(target).offset().top-70;
  $('html,body').animate({scrollTop: targetOffset}, 400);
  return false;
});
~~~

这里，我是在链接上监听单击事件，获取目标对象的偏移，上面减去70是因为下面的css代码：

~~~css
#wrap {
  min-height: 100%;
  height: auto;
  margin: 0 auto -60px;
  padding: 70px 0 60px;
}
~~~

刷新页面，再次点击目录或者标签，就可以正常的跳到锚点位置了。你可以点击分类[hbase](/categories.html#hbase) 试试效果。

**但是，还没有结束**。如果是从其他页面，例如，在文章页面点击分类或标签时，页面却不会跳转到正确的锚点位置。这是因为上面的javascript代码只是考虑了当前页面，是在当前页面获取目标的偏离，而没有考虑在另外一个页面单击链接跳到目标页面的锚点的情况。

所以，我们需要修改代码：

~~~javascript
var handler=function(hash){
    var target = document.getElementById(hash.slice(1));
    if (!target) return;
    var targetOffset = $(target).offset().top-70;
    $('html,body').animate({scrollTop: targetOffset}, 400);
}

$('a[href^=#][href!=#]').click(function(){
    handler(this.hash)
});

if(location.hash){ handler(location.hash) }
~~~

这样，就大功告成了，希望这篇文章对你有所帮助。

# 参考文章

- [点击锚点让定位偏移顶部](http://www.ldsun.com/1815.html)


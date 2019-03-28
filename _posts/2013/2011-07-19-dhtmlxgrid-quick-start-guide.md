---
layout: post
title: DhtmlxGrid Quick Start Guide
category: web
tags: [javascript, dhtmlxGrid, xml]
keywords: dhtmlxGrid, javascript, dhtmlxTree
description: DhtmlxGrid Quick Start Guide
---
<span style="color: #ff0000;">说明:</span>

本文来源于<a href="http://dhtmlx.com/docs/products/dhtmlxGrid/">http://dhtmlx.com/docs/products/dhtmlxGrid/</a>，本人对其进行翻译整理成下文，贴出此文，紧供分享。

dhtmlxGrid是一个拥有强大的数据绑定、优秀的大数据展示性能并支持ajax的JavaScript表格控件。该组件易于使用并通过富客户端的API提供了很大的扩展性。dhtmlxGrid支持不同的数据源（XML, JSON, CSV, JavaScript 数组和HTML表格），如果需要的话，还可以从自定义的xml中加载数据。


	跨浏览器
	使用JavaScript API进行控制
	Ajax支持
	简单的JavaScript 或者XML 配置
	与HTML集成
	内建过滤、排序、查询、分组功能
	表格 footer/header自动计算
	行内编辑
	准备使用大数据集解决方案：分页，动态加载，智能渲染
	序列化为XML或CSV
	从 XML或CSV加载
	列锁定
	剪贴板支持
	简单的客户端到服务器端配置 (使用 dhtmlxConnector, 可用于 PHP, Java, .NET, ColdFusion)
	支持子表格
	列拖拽和移动
	行或列拖拽
	dhtmlxTree PRO Edition支持拖拽
	可以创建一个编辑器或是列格式化 (使用 eXcell – 继承自 cell 对象)
	组合框，日历以及更多的预定义eXcells
	Cell支持数学方程式
	不同的键盘映射
	简单的CSS风格或是预定义的皮肤
	对于rows/entire grid不可见的数据块 (用户数据)
	客户端排序(string, integer, date, custom)
	服务器端排序
	广泛的事件处理

<h2>Step 1 – 引入文件</h2>

	< link rel ="STYLESHEET" type="text/css" href="codebase/dhtmlxgrid.css" />
	< script src="codebase/dhtmlxcommon.js">< /script>
	< script src="codebase/dhtmlxgrid.js">< /script>
	< script src="codebase/dhtmlxgridcell.js">< /script>
	< script>
	    //we'll write script commands here
	< /script>


<h2>Step 2 – 放置gird</h2>
有两种方式在一个页面放置grid，这里减少最常用的方法：创建一个div并给id熟悉设置一个惟一值。例如：

	< div id="mygrid_container" style="width:600px;height:150px;">< /div>

下面初始化参数，首先定一个mygrid变量，然后定一个doInitGrid方法，方法内部进行mygrid初始化工作：
 
	 var mygrid;
	 function doInitGrid(){
	 }

doInitGrid方法会包括以下代码：

* 使用dhtmlXGridObject构造方法创建一个基于我们之前创建的DIV的grid对象；
* 设置grid图片路径。这个路径包括grid外观需要的所有图片。在大多数情况下该路径为“codebase/imgs/”. 该路径最后面的一个“/”很重要。 随便说一下，这个路径和你处理表格数据所使用的图片没有关系；
* 使用setHeader 方法定义表头；
* 使用setInitWidths (单位为像素) 或setInitWidthsP (单位为百分比)定义列宽。 使用`*`代表让列自动使用所有表格宽度；
* 定义一个列的水平对其方式。 Numeric values is better to align right;
* 使用setSkin方法设置皮肤；
* 最好使用这些设置通过init方法初始化grid。更多的参数之后再讨论。

目前，doInitGrid方法如下：
 
	mygrid = new dhtmlXGridObject('mygrid_container');
	mygrid.setImagePath("codebase/imgs/"); //指定图片路径
	mygrid.setHeader("Model,Qty,Price"); //设置表头显示
	grid.setInitWidths("*,150,150"); //设置列的初始宽度
	grid.setColAlign("left,right,right"); //设置列的水平对其方式
	mygrid.setSkin("light"); //设置皮肤
	grid.init(); //显示调用初始化方法，必须的

现在需要做的是运行该方法，可以将该方法加入body的onload方法里或是使用jquery的方法。下面使用body的onload方法：

	< body onload="doInitGrid();">< /body>

这样在该页面初始化之后会显示如下：

<div class="pic"><img src="http://docs.dhtmlx.com/lib/exe/fetch.php?cache=&amp;media=dhtmlxgrid:step_2_last.png" alt="" /></div>

说明：除了调用set方法之外，还可以如下风格定义：

	mygrid = new dhtmlXGridObject({
			parent:"a_grid",
			image_path:"codebase/imgs",
			columns:[
				{ label: "Sales",           width:50, 	type:"ed" },
				{ label:["Book title",
					 "#text_filter"],   width:150, 	type:"ed" },
				{ label:["Author",
					 "#select_filter"], width:150, 	type:"ed" },
				{ label: "Price",       width:50, 	type:"ed" },
				{ label:"In store" , 	width:80, 	type:"ch" },
				{ label:"Shipping" , 	width:50, 	type:"ed" },
				{ label:"Bestseller" , 	width:50, 	type:"ed" },
				{ label:"Date" , 	width:50, 	type:"ed" }
			],
			xml:"data.xml"
		});

<h2>Step 3 – 填充数据</h2>
你已经知道了dhtmlxGrid可以加载xml或cvs或json数据，这里主要演示dhtmlxGrid加载json数据。

在上面的例子中每行有三列，故我们的json数据如下：

	{
	rows:[
		{
			id: "a",
			data: [Model 1, 100, 399]
		},
		{
		id: "b",
			data: [Model 2, 50, 649]
		},
		{
		    id: "c",
		       data: [ Model 3, 70, 499]
		}
	]
	}
将上面存于data.json文件，然后在doInitGrid方法里调用以下方法：

	mygrid.load ("data.json"，,"json");

这时候页面展示如下：
<div class="pic"><img src="http://docs.dhtmlx.com/lib/exe/fetch.php?cache=&amp;media=dhtmlxgrid:step_3.png" alt="" /></div>

<h2>Step 4 – 客户端排序</h2>
为了能够实习表格的客户端排序，必须调用grid的setColSorting（sortTypesStr）方法。sortTypesStr是一个类型列表，以逗号分隔。

该类型值有以下四种：

* str – 作为字符串排序
* int - 以Integer值排序 (通常可以是任何数字);
* date – 以日期排序
* custom sorting –自定义的更加复杂的排序方式(for example to sort days of week).

接下来我们对上面的例子进行排序。上例中每行有三列，第一列为字符串，后两列为数字，故可以调用以下方法进行排序。注意，该方法应该在init方法之前执行。

	mygrid.setColSorting("str,int,int");

这时候单击最后一列表头，结果如下：
<div class="pic"><img src="http://docs.dhtmlx.com/lib/exe/fetch.php?media=dhtmlxgrid:step_4.png" alt="" /></div>

<h2>Step 5 – 单元格格式化和编辑</h2>
Grid中使用单元格的编辑器（或是eXcells – 继承自 Cells, Cell 或 Columns types）来定义值的格式和编辑方式。你可以根据你的需要创建eXcells。

设定单元格的类型非常容易，其可以用一行代码定义。这里有一些常见的编辑器，如简单的编辑器代码为“ed”，多行编辑“txt”，只读单元格“ro”，复选框“ch”，价格的格式化“price”。
默认情况下所有的列是“ro”，也可以使用以下方法类设置编辑类型：

	mygrid.setColTypes("ed,ed,price");
 
Excells格式化有以下几种：

* link：超链接
* img：图片
* price：价格
* dyn：动态行

Excell 复杂编辑器有以下几种：

* cp：colorpicker
* calck：允许调用grid.setNumberFormat的计算器
* dhxCalendar：日历，日期格式可以通过grid.setDateFormat设置
* dhxCalendarA：日历，日期格式可以通过grid.setDateFormat设置，单元格可以编辑
* calendar：YUI Calendar
* clist：多选组件

使用其他组件作为单元格编辑器:

* grid：使用dhtmlxgrid
* stree ：使用dhtmlxtree
* context：使用dhtmlxmenu
* combo：使用dhtmlxCombo


Excells特别用途
sub_row：允许单元格作为一个可展开的子单元格，就想查看明细一样。

两个扩展:

* sub_row_ajax – 单元格数据被认为是ajax请求的url
* sub_row_grid – 允许创建一个子表作为一个子行的内容

现在你可以双击或是F2进入编辑模式，你可以用tab键在单元格之间导航。
<div class="pic"><img src="http://docs.dhtmlx.com/lib/exe/fetch.php?media=dhtmlxgrid:step_5.png" alt="" /></div>

<h2>Step 6 – 行操作方法</h2>

	function addRow(){
	var newId = (new Date()).valueOf()
	mygrid.addRow(newId,"",mygrid.getRowsNum())
	mygrid.selectRow(mygrid.getRowIndex(newId),false,false,true);
	}
	function removeRow(){
	var selId = mygrid.getSelectedId()
	mygrid.deleteRow(selId);
	}

代码中addRow() 方法的一些说明：
* 创建一个惟一值 (number of millisecond since 1970) 来作为row的标识；
* 在最后一行后面添加一新行，该行有新的id，值为空；
* 选中最近创建的行 (by index), 不掉用 On-Select事件，不掉用选中行之前事件并且聚焦到选中行(如果垂直滚动条存在，则滚动对应位置)。

代码中removeRow() 的一些说明（一行行的）:
* 得到选中行id；
* 删除指定行id的行

<h2>Step 7 – 事件</h2>
添加事件调用attachEvent 方法，如下行选中事件：

	function doOnRowSelected(rowID,celInd){
	alert("Selected row ID is "+rowID+"\nUser clicked cell with index "+celInd);
	}
	mygrid.attachEvent("onRowSelect",doOnRowSelected);

<h2>Step 8 – Code</h2>
最后的代码：

	< title>dhtmlxGrid Sample Page< /title>
	< link rel="STYLESHEET" type="text/css" href="codebase/dhtmlxgrid.css" />
	< script src="codebase/dhtmlxcommon.js">< /script>
	< script src="codebase/dhtmlxgrid.js">< /script>
	< script src="codebase/dhtmlxgridcell.js">< /script>
	< script>
	var mygrid;
	function doInitGrid(){
	mygrid = new dhtmlXGridObject('mygrid_container');
	mygrid.setImagePath("codebase/imgs/");
	mygrid.setHeader("Model,Qty,Price");
	mygrid.setInitWidths("*,150,150");
	mygrid.setColAlign("left,right,right")
	mygrid.setSkin("light");
	mygrid.setColSorting("str,int,int");
	mygrid.setColTypes("ed,ed,price");
	mygrid.attachEvent("onRowSelect",doOnRowSelected);
	mygrid.init();
	mygrid.load ("data.json","json");
	}
	function addRow(){
	var newId = (new Date()).valueOf()
	mygrid.addRow(newId,"",mygrid.getRowsNum())
	mygrid.selectRow(mygrid.getRowIndex(newId),false,false,true);
	}
	function removeRow(){
	var selId = mygrid.getSelectedId()
	mygrid.deleteRow(selId);
	}
	function doOnRowSelected(rowID,celInd){
	alert("Selected row ID is "+rowID+"\nUser clicked cell with index "+celInd);
	}
	< /script>
	< body onload="doInitGrid()">
	< div id="mygrid_container" style="width:600px;height:150px;">< /div>
	< /body>


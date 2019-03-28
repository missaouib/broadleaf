---
layout: post
title: 自定义dhtmlxGrid表头菜单
category: web
tags: [javascript, dhtmlxGrid, xml]
keywords: dhtmlxGrid, javascript
description: dhtmlxGrid可以定义表头菜单以及表格右键菜单，表格右键菜单可以自定义，但是表头菜单只能使用其提供的菜单。dhtmlxGrid默认的表头菜单可以决定表格中每一列是否在表格中显示，并没有提供更多的扩展，如果我想自定义表头菜单，该怎么做呢？本文就是基于自定义表格菜单，说说我的实现方式。
---

dhtmlxGrid可以定义表头菜单以及表格右键菜单，表格右键菜单可以自定义，但是表头菜单只能使用其提供的菜单。dhtmlxGrid默认的表头菜单可以决定表格中每一列是否在表格中显示，并没有提供更多的扩展，如果我想自定义表头菜单，该怎么做呢？本文就是基于自定义表格菜单，说说我的实现方式。
以下是dhtmlxGrid的表头菜单效果：
<div class="pic">
<img class="aligncenter size-medium wp-image-2287" title="dhtmlxgrid-head-menu" src="http://7xnrdo.com1.z0.glb.clouddn.com/2011/07/dhtmlxgrid-head-menu.jpg" alt="" width="300" height="174" /></div>
其功能过于单一，以下是表格右键菜单效果：
<div class="pic"><img class="aligncenter size-medium wp-image-2288" title="dhtmlxgrid-context-menu" src="http://7xnrdo.com1.z0.glb.clouddn.com/2011/07/dhtmlxgrid-context-menu.jpg" alt="" width="300" height="126" /></div>
如果能够像表格菜单一样自定义表头菜单，那会是一件非常有意义的事情，因为dhtmlxGrid菜单都是一些针对行和单元格的操作，没有提过针对列的操作，比如我可能需要在某一列上实现该列的显示与隐藏、排序、改变列属性以及在该列右边添加一新的列，等等。
如何实现表头菜单的自定义呢？可不可将表格右键菜单移到表头上去呢？<!--more-->
首先，来看看context menu的实现方式，下面代码来自dhtmlxGrid Samples中的Context menu例子源码：

	function onButtonClick(menuitemId, type) {
	    var data = mygrid.contextID.split("_");
	    //rowId_colInd;
	    mygrid.setRowTextStyle(data[0], "color:" + menuitemId.split("_")[1]);
	    return true;
	}
	menu = new dhtmlXMenuObject();
	menu.setIconsPath("../common/images/");
	menu.renderAsContextMenu();
	menu.attachEvent("onClick", onButtonClick);
	menu.loadXML("../common/_context.xml");
	mygrid = new dhtmlXGridObject('gridbox');
	mygrid.setImagePath("../../codebase/imgs/");
	mygrid.setHeader("Author,Title");
	mygrid.setInitWidths("250,250");
	mygrid.enableAutoWidth(true);
	mygrid.setColAlign("left,left");
	mygrid.setColTypes("ro,link");
	mygrid.setColSorting("str,str");
	mygrid.enableContextMenu(menu);
	mygrid.init();
	mygrid.setSkin("dhx_skyblue");
	mygrid.loadXML("../common/grid_links.xml");

上面代码创建了一个menu并将其作为context menu附件到grid上面去，下面为最关键的两行行代码：

	menu.renderAsContextMenu();
	mygrid.enableContextMenu(menu);

上面对于context menu提供的方法太少，这时候可以看看dhtmlxMenu api，看看有没有设置context menu生效位置的方法（指定context menu在哪片区域有效）。在dhtmlxMenu API Methods里没有找到需要的方法，这时候在官网论坛搜搜，也许可以找到点什么。
在论坛里可以找到一个例子，大致代码如下：

	function onButtonClick(menuitemId, type) {
	    var data = mygrid.contextID.split("_");
	    //rowId_colInd;
	    mygrid.setRowTextStyle(data[0], "color:" + menuitemId.split("_")[1]);
	    return true;
	}
	menu = new dhtmlXMenuObject();
	menu.setIconsPath("../common/images/");
	menu.attachEvent("onClick", onButtonClick);
	menu.loadXML("../common/_context.xml");

	mygrid = new dhtmlXGridObject('gridbox');
	mygrid.setImagePath("../../codebase/imgs/");
	mygrid.setHeader("Author,Title");
	mygrid.setInitWidths("250,250");
	mygrid.enableAutoWidth(true);
	mygrid.setColAlign("left,left");
	mygrid.setColTypes("ro,link");
	mygrid.setColSorting("str,str");
	//mygrid.enableContextMenu(menu); //使其失效
	mygrid.init();
	mygrid.setSkin("dhx_skyblue");
	mygrid.loadXML("../common/grid_links.xml");

	mygrid.hdr.id = "header_id";
	var header_row = mygrid.hdr.rows[1];
	for ( var i = 0; i &lt; header_row.cells.length; i++) {
	   header_row.cells[i].id = "context_zone_" + i;
	}
	menu.addContextZone("header_id");

上面最关键的代码在最后几行，给dhtmlxGrid表头设置了一个id，然后调用menu的addContextZone()方法指定centext的有效区域。视乎这就是我们所需要的，但是你执行以上代码你会发现onButtonClick方法里mygrid.contextID会报错，原因是mygrid没有contextID属性（在context menu中通过该属性可以获知鼠标焦点在哪一行，但是现在在表头上强加了该menu，所以并不存在该属性了）。
剩下的问题是需要解决，菜单单击事件了。我们可以在表头的contextmenu事件处罚的时候获取鼠标焦点，并将自定义的菜单在该位置显示，该方法如下：

	dhtmlxEvent(mygrid.hdr, "contextmenu", function(ev) {
		ev = ev || event;
		var el = ev.target || ev.srcElement;
		var zel = el;
		while (zel.tagName != "TABLE")
			zel = zel.parentNode;
		var grid = zel.grid;
		if (!grid)
			return;
		grid.setActive();

		el = grid.getFirstParentOfType(el, "TD")

		if ((grid) &amp;&amp; (!grid._colInMove)) {
			grid.resized = null;
			if ((!grid._mCols) || (grid._mCols[el._cellIndex] == "true"))
				colId = el._cellIndex + 1;//获得表头右键菜单焦点所在列索引
		}

		function mouseCoords(ev) {
			if (ev.pageX || ev.pageY) {
				return {
					x : ev.pageX,
					y : ev.pageY
				};
			}
			var d = _isIE &amp;&amp; document.compatMode != "BackCompat" ? 
		            document.documentElement: document.body;
			return {
				x : ev.clientX + d.scrollLeft - d.clientLeft,
				y : ev.clientY + d.scrollTop - d.clientTop
			};
		}

		var coords = mouseCoords(ev);
		menu.addContextZone("header_id");
		menu.showContextMenu(coords.x, coords.y);//强制显示
		return true;
	});

在上面的代码里，我们获得表头右键菜单焦点所在列索引，将其值赋给colId，然后在菜单单击事件的时候添加一新的列并将colId重置：

	function onButtonClick(menuitemId, type, e) {
		mygrid.insertColumn(colId, "12", "ed", 80);
		colId = 0;
		return true;
	}

然后，需要禁止掉表格数据区域的菜单显示：

	mygrid.attachEvent("onBeforeContextMenu", function(rid, cid, e) {
		return false;//禁止数据区域菜单
	});

最后的最后，最后的代码如下：

	var mygrid, colId;

	function onButtonClick(menuitemId, type, e) {
		mygrid.insertColumn(colId, "12", "ed", 80);
		colId = 0;
		return true;
	}

	menu = new dhtmlXMenuObject();
	menu.setIconsPath("../common/images/");
	menu.renderAsContextMenu();
	menu.attachEvent("onClick", onButtonClick);
	menu.loadXML("../common/_context.xml");
	menu.attachEvent("onBeforeContextMenu", function(zoneId, e) {
		var hdr = document.getElementById(zoneId)
		return true;
	});

	mygrid = new dhtmlXGridObject('gridbox');
	mygrid.setImagePath("../codebase/imgs/");
	mygrid.setHeader("Sales,Book Title,Author,Price,In Store,Shipping,Bestseller,
              Date of Publication");
	mygrid.setInitWidths("50,150,100,80,80,80,80,200");
	mygrid.setColAlign("right,left,left,right,center,left,center,center");
	mygrid.setColTypes("dyn,edtxt,ed,price,ch,co,ra,ro");

	mygrid.init();
	mygrid.setSkin("dhx_skyblue");
	//mygrid.enableHeaderMenu();
	mygrid.enableColumnMove(true);
	mygrid.enableContextMenu(menu);
	dhtmlxEvent(mygrid.hdr, "contextmenu", function(ev) {
		ev = ev || event;
		var el = ev.target || ev.srcElement;
		var zel = el;
		while (zel.tagName != "TABLE")
			zel = zel.parentNode;
		var grid = zel.grid;
		if (!grid)
			return;
		grid.setActive();

		el = grid.getFirstParentOfType(el, "TD")

		if ((grid) &#038;& (!grid._colInMove)) {
			grid.resized = null;
			if ((!grid._mCols) || (grid._mCols[el._cellIndex] == "true"))
                                //获得表头右键菜单焦点所在列索引
				colId = el._cellIndex + 1;
		}

		function mouseCoords(ev) {
			if (ev.pageX || ev.pageY) {
				return {
					x : ev.pageX,
					y : ev.pageY
				};
			}
			var d = _isIE &#038;& document.compatMode != "BackCompat" ? 
                             document.documentElement: document.body;
			return {
				x : ev.clientX + d.scrollLeft - d.clientLeft,
				y : ev.clientY + d.scrollTop - d.clientTop
			};
		}

		var coords = mouseCoords(ev);
		menu.addContextZone("header_id");
		menu.showContextMenu(coords.x, coords.y);//强制显示
		return true;
	});

	mygrid.attachEvent("onBeforeContextMenu", function(rid, cid, e) {
		return false;//禁止数据区域菜单
	});

	mygrid.loadXML("../common/grid_ml_16_rows_columns_manipulations.xml");

	mygrid.hdr.id = "header_id";
	var header_row = mygrid.hdr.rows[1];
	for ( var i = 0; i < header_row.cells.length; i++) {
		header_row.cells[i].id = "context_zone_" + i;
	}

效果图如下;
<div class="pic">
<img src="http://7xnrdo.com1.z0.glb.clouddn.com/2011/07/dhtmlxgrid-custom-head-menu.jpg" alt="" title="dhtmlxgrid-custom-head-menu" width="300" height="154" class="aligncenter size-medium wp-image-2291" /></div>


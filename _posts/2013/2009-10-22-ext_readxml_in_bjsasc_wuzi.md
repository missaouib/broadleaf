---
layout: post
title: Extjs读取xml文件生成动态表格和表单
category: web
tags: [extjs, xml]
keywords: extjs, xml
description: Extjs读取xml文件生成动态表格和表单
---
最近开发项目，需要动态读取xml文件，生成Extjs界面，xml文件通过前台页面的按钮事件传进来，可以在网上查找【javascript 弹出子窗口】的相关文章</a>
获取弹出窗口url后的参数方法：

~~~javascript
	// 获取url后的参数值
	function getQueryStringValue(name) {
		var url = window.location.search;
		if (url.indexOf('?') < 0) {
			return null
		}
		var index = url.indexOf(name + "=");
		if (index < 0) {
			return null
		}
		var args = url.indexOf('&', index);
		var value;
		if (args > 0) {
			value = url.substring(index + name.length + 1, args);
		} else {
			value = url.substring(index + name.length + 1, url.length);
		}
		return value;
	}
	// 获取xml的服务器路径
	function getXmlUrl(xmlFile) {
		return '../bjsasc_dictionary/' + getQueryStringValue('xmlFile');
	}
~~~

用到的一些辅助方法：

~~~javascript
	// 去掉Dom节点中的空白字符
	function cleanWhitespaces(elem) {
		var elem = elem || document;
		var childElem = elem.childNodes;
		var childElemArray = new Array;
		for (var i = 0; i < childElem.length; i++) {
			if (childElem[i].nodeType == 1) {
				childElemArray.push(childElem[i]);
			}
		}
		return childElemArray;
	}
	// 取得父窗口表单中键值对
	function getParentFormValues() {
		var formObj = window.opener.document.forms["frmMain"].elements;
		var formValues = "";
		for (var i = 0; i < formObj.elements.length; i++) {
			if (formObj.elements[i].value != null
					&& formObj.elements[i].value != ""
					&& formObj.elements[i].value.length != 0) {
				formValues += '_' + formObj.elements[i].name.toUpperCase() + '{'
						+ formObj.elements[i].value.toUpperCase() + '}'
						+ formObj.elements[i].name.toUpperCase() + '_ ';
			}
		}
		formValues += opener.getBindValue(formObj.elements);
		return formValues;
	}
	// 取得过滤条件表单的键值对
	function getCondictionValues() {
		var condictionString = "";
		var formObj = form.getForm().getEl().dom;
		for (var i = 0; i < formObj.elements.length; i++) {
			if (formObj.elements[i].value != null
					&& formObj.elements[i].value != ""
					&& formObj.elements[i].value.length != 0) {
				condictionString += '_' + formObj.elements[i].name + '{'
						+ formObj.elements[i].value + '}'
						+ formObj.elements[i].name + '_ ';
			}
		}
		// alert("condictionString"+condictionString);
		return condictionString;
	}
	// 判读Ext表单是否有输入
	function isFormInputed(ExtForm) {
		var flag = false;
		var formObj = ExtForm.getEl().dom;
		for (var i = 0; i < formObj.elements.length; i++) {
			if (formObj.elements[i].value != null
					&& formObj.elements[i].value != ""
					&& formObj.elements[i].value.length != 0) {
				flag = true;
				break;
			}
		}
		return flag;
	}
	// 将计算得到的结果四舍五入
	/* * ForDight(Dight,How):数值格式化函数，Dight要 * 格式化的 数字，How要保留的小数位数。 */
	function ForDight(Dight, How) {
		var Dight = Math.round(Dight * Math.pow(10, How)) / Math.pow(10, How);
		return Dight;
	}
~~~

xml文件格式：

~~~xml
	<?xml version="1.0" encoding="gb2312"?>
	<dictionary>
		<title>领用出库-物资选择</title>
		<sql>
		select V_stores_list.* 
		from V_stores_list where WHID='+$getform(WHID)+' AND PROJECTNO='+$getform(PROJECTNO)+'
			AND CANUSEQTY>0 AND ??? and isblock=0
		</sql>
		<fromtable>V_stores_list</fromtable>
		<targettable>BO_IC_EXPORT_S</targettable>
		<line>20</line>
		<!-- 条件区开始-->
		<condition>
			<fieldname>MTRNAME</fieldname>
			<fieldtitle>物资名称</fieldtitle>
			<fieldtype>文本</fieldtype>
			<comparetype><![CDATA[like
			MTRNAME
			单行
			<![CDATA[]]>		
			</comparetype>
		</ condition>
	</ dictionary>
~~~

然后，弹出窗口页面Ext入口代码：

~~~javascript
	// 全局变量
	var result = {};
	var grid;
	var form;
	var viewport;
	var store;
	var sm = new Ext.grid.CheckboxSelectionModel();
	var autoStore;
	var tempItems1 = [];
	var tempItems2 = [];
	var tempItems3 = [];
	var flag = 1;
	// 程序入口
	Ext.onReady(function() {
		Ext.QuickTips.init();// 初始化
		Ext.form.Field.prototype.msgTarget = 'qtip';// 统一指定错误信息提示方式
		Ext.util.CSS	.swapStyleSheet('theme', '../aws_js/extjs2/css/xtheme-gray.css');// 更换皮肤
		Ext.BLANK_IMAGE_URL = '../aws_js/extjs2/images/default/s.gif';
		Ext.Ajax.request({
			url : getXmlUrl(getQueryStringValue('xmlFile')), // 访问数据字典
			method : 'post',
			success : function(res, opt) {
				var xmlObj = res.responseXML;
				initStoreData(xmlObj); // 访问成功后执行后续工作
			}
		})
	});
	function initStoreData(xmlObj) {
		getInitData(xmlObj);
		document.title = result.winTitle;

		var dataRecorder = Ext.data.Record.create(result.gridRecords);// 指定记录集格式
		// 获取表格数据部分
		store = new Ext.data.Store({
			idProperty : 'ID',
			proxy : new Ext.data.HttpProxy({
				url : '../search.do?method=findAll',
				failure : function() {
					// Ext.Msg.alert("Notice", "网路问题");
				},
				success : function(response) {
					// Ext.Msg.alert("Notice", response.responseText);
				}
			}),

			// baseParams : {
			// parentFormValues : getParentFormValues(),// 请求发送的参数：父表单值和xml文件名
			// xmlFile : getQueryStringValue('xmlFile')
			// // cmd:'search'
			// },
			reader : new Ext.data.JsonReader({
				totalProperty : 'totalCount',
				root : 'data'
			}, dataRecorder)
		});
		// 要分页，第一次加载数据必须传start和limit两参数
		// store.load({
		// params : {
		// start : 0,
		// limit : result.limit
		// }
		// });
		initViewport();
	}
	// 获得界面初始化的一些数据
	function getInitData(xmlObj) {
		// result.formItems = {};
		result.columnHeaders = [];
		result.gridRecords = [];
		result.dbFilterRecords = [];
		result.winTitle = xmlObj.getElementsByTagName("title")[0].firstChild.nodeValue; // 窗口title名称
		result.limit = xmlObj.getElementsByTagName("line")[0].firstChild.nodeValue;// 分页数据
		result.fromTable = xmlObj.getElementsByTagName("fromTable")[0].firstChild.nodeValue;// 来自哪个表
		// 获取过滤条件表单的界面数据
		var conections = xmlObj.getElementsByTagName("condition");
		var row = ForDight(conections.length / 3, 0);
		for (var i = 0; i < conections.length; i++) {
			var item = {};
			var condition = cleanWhitespaces(conections[i]);
			item.id = condition[0].firstChild.nodeValue;
			item.fieldLabel = condition[1].firstChild.nodeValue;
			item.name = condition[4].firstChild.nodeValue;
			item.anchor = '95%';
			if (condition[6].firstChild.nodeValue == '单行') {
				item.xtype = 'textfield';
			} else if (condition[6].firstChild.nodeValue == '日期') {
				item.xtype = 'datefield';
				item.format = 'Y-m-d';
			} else if (condition[6].firstChild.nodeValue == '数值') {
				item.xtype = 'numberfield';
				item.minValue = 0;
				item.minText = '请输入有效的数字';
				item.decimalPrecision = 6;
			} else if (condition[6].firstChild.nodeValue == '自动填充') {
				var autoStore = new Ext.data.SimpleStore({
					proxy : new Ext.data.HttpProxy({// 读取远程数据的代理
						url : '../ajax/autoComplete.do?method=autoComplete',
						failure : function() {
							Ext.Msg.alert("Notice", "no records");
						}
					}),
					fields : ['property'],
					baseParams : {
						'sqlString' : condition[4].firstChild.nodeValue + ' | '
								+ result.fromTable
					}
				});
				item.xtype = 'combo';
				item.store = autoStore;
				item.displayField = 'property';
				item.typeAhead = true;
				item.allQuery = 'all';// 查询信息的查询字符串
				item.queryParam = 'keyword';// 查询的名字
				item.mode = 'remote';
				item.minChars = 3;// 默认最少输入4
				item.forceSelection = true;
				item.queryDelay = 0;// 查询延迟时间
				item.triggerAction = 'all';
				item.emptyText = '';
				item.resizable = true;
				item.selectOnFocus = true;
			}
			if (i / row < 1) {
				tempItems1.push(item);
			}
			if (i / row < 2 && i / row >= 1) {
				tempItems2.push(item);
			} else if (i / row >= 2) {
				tempItems3.push(item);
			}
		}
		// alert(Ext.util.JSON.encode(result));

		// 获取表格表头的界面数据和rcord记录的数据格式
		var fields = xmlObj.getElementsByTagName("field");
		result.columnHeaders.push(sm);// 插入多选框
		result.columnHeaders.push(new Ext.grid.RowNumberer({
			width : 20
		}));// 插入行号
		for (var i = 0; i < fields.length; i++) {
			var item = {};
			var record = {};
			var array = [];
			var field = cleanWhitespaces(fields[i]);
			var renderDate = function(value) {
				return value ? value.dateFormat('Y-m-d') : '';
			}
			// 生成grid表格中store数据记录
			record.name = field[0].firstChild.nodeValue;
			record.mapping = field[0].firstChild.nodeValue;
			if (field[1].firstChild.nodeValue == '日期') {
				record.type = 'date';
				record.dateFormat = 'Y-m-d';
				item.renderer = Ext.util.Format.dateRenderer('Y-m-d')
			} else if (field[1].firstChild.nodeValue == '数值') {
				record.type = 'auto';
			} else {
				record.type = 'string';
			}
			result.gridRecords.push(record);

			// 生成grid表格表头数据记录
			item.dataIndex = field[0].firstChild.nodeValue;
			item.header = field[2].firstChild.nodeValue;
			// item.width=field[3].firstChild.nodeValue;
			item.sortable = true;
			if (field.length == 7
					&& field[5].firstChild.nodeValue.toUpperCase() == 'TRUE') {
				item.hidden = true;
				// item.hideable=false;
			}
			if (field.length == 6) {
				item.hidden = false;
			}
			result.columnHeaders.push(item);

			// 生成模糊过滤store的记录
			if (field[4].firstChild.nodeValue.toUpperCase() == 'TRUE') {
				array.push(field[2].firstChild.nodeValue);// fieldName
				array.push(field[0].firstChild.nodeValue);// fieldValue
			}
			result.dbFilterRecords.push(array);
		}
		return result;
	};
~~~

渲染Ext界面代码：

~~~javascript
	function initViewport() {
		if (!form) {
			form = getInsertForm();
		}

		if (!grid) {
			grid = getInsertGrid();
		}

		if (!viewport) {
			var formPanel = new Ext.Panel({
				title : '查询条件',
				region : 'north',
				split : true,
				frame : true,
				border : true,
				layout : 'fit',
				height : 280,
				collapsible : true,
				items : [form]

			});
			viewport = new Ext.Viewport({
				layout : 'border',
				modal : true,// 是否为模式窗口
				border : false,
				items : [formPanel, grid]
			});
		}
	}

	function searchByFilter() {
		var dbfilter = Ext.get("dbFilter").getValue();
		var fieldMame = Ext.get("search-type").getValue();
		if (dbfilter == null || dbfilter == "") {
			alert("请输入一个关键字");
			Ext.get("dbFilter").focus();
		} else if (fieldMame == "==选择过滤字段==") {
			alert("请选择一个过滤字段");
			Ext.get("search-type").focus();
		} else {
			form.getForm().reset();
			if (flag == 1) {
				store.baseParams = {
					dbfilter : dbfilter,
					parentFormValues : getParentFormValues(),
					fieldMame : Ext.get("hiddenValue").dom.value,
					xmlFile : getQueryStringValue('xmlFile'),
					cmd : 'filter'
				};
				store.load({
					params : {
						start : 0,
						limit : result.limit
					}
				});
				form.getForm().reset();
				flag = 0;
			} else {
				store.baseParams = {
					dbfilter : dbfilter,
					parentFormValues : getParentFormValues(),
					fieldMame : Ext.get("hiddenValue").dom.value,
					xmlFile : getQueryStringValue('xmlFile'),
					cmd : 'filter'
				};
				store.reload();

			}
			Ext.get("dbFilter").dom.value = "";
		}
	}
	// 获取过滤条件部分的表单控件
	function getInsertForm() {
		form = new Ext.form.FormPanel({
			name : 'frmMain',
			height : 260,
			labelAlign : 'left',
			labelWidth : 110,
			layout : 'fit',
			waitMsgTarget : true,
			items : [{
				xtype : 'fieldset',
				frame : true,
				title : '高级查询',
				autoHeight : true,
				layout : 'column',
				items : [{
					columnWidth : .333,
					layout : 'form',
					items : tempItems1
				}, {
					columnWidth : .333,
					layout : 'form',
					items : tempItems2
				}, {
					columnWidth : .333,
					layout : 'form',
					items : tempItems3
				}]
			}],
			tbar : ['请输入模糊值: ', ' ', {
				xtype : 'textfield',
				width : 200,
				id : 'dbFilter',
				listeners : {
					specialkey : function(field, e) {
						if (e.getKey() == Ext.EventObject.ENTER) {
							searchByFilter();
						}
					}
				}
			}, '-', {
				xtype : 'combo',
				id : 'search-type',
				anchor : '60%',
				hiddenName : 'hiddenValue',
				width : 120,
				triggerAction : 'all',// 单击触发按钮显示全部数据
				store : new Ext.data.SimpleStore({// 定义组合框中显示的数据源
					fields : ['fieldName', 'fieldValue'],
					data : result.dbFilterRecords
				}),// 设置数据源
				displayField : 'fieldName',// 定义要显示的字段
				valueField : 'fieldValue',// 定义值字段
				mode : 'local',// 本地模式
				forceSelection : true,// 要求输入值必须在列表中存在
				typeAhead : true,// 允许自动选择匹配的剩余部分文本
				// value : '==选择过滤字段==',
				value : '==选择过滤字段==',
				handleHeight : 10
					// 下拉列表中拖动手柄的高度
					}, '-', {
						xtype : 'button',
						text : '筛选',
						tooltip : '先选择查询条件，再输入模糊值',
						iconCls : 'find',
						handler : searchByFilter
					}, '->', {
						pressed : true,
						xtype : 'button',
						text : '确认插入',
						enableToggle : true,
						tooltip : '请选中一行或多行记录，再选择确认插入',
						handler : function() {
							if (sm.hasSelection()) {
								var records = sm.getSelections();
								var jsonObj = "{data:[";
								for (var i = 0; i < records.length; i++) {
									jsonObj += Ext.encode(records[i].data);
									if (i != records.length - 1) {
										jsonObj += ",";
									}
								}
								jsonObj += "]}"
								Ext.Ajax.request({
									url : '../search.do?method=insertChoices',
									method : 'post',
									params : {
										xmlFile : getQueryStringValue('xmlFile')
												.toString(),
										jsonObj : jsonObj,
										parentFormValues : getParentFormValues()
									},
									callback : function(options, success, response) {
										if (response.responseText == "success") {

											Ext.Msg.alert("提示", "插入成功", function() {
												window.close();
												// opener.location.reload();
		                                    opener.saveForm();
											});
										} else {
											Ext.Msg.alert("提示", "插入失败");
										}
									}
								})

							} else {
								alert("请选择一行或多行数据");
							}
						},
						scope : this
					}, '-', {
						pressed : true,
						xtype : 'button',
						text : '取消',
						tooltip : '取消选择，直接退出',
						handler : function() {
							Ext.Msg.confirm('Notice', '确认退出？', function(id) {
								if (id == "yes")
									window.close();
							});
						},
						scope : this
					}],
			buttons : [{
				text : '执行查询条件',
				handler : function() {
					var connections = getCondictionValues();
					if (!form.getForm().isValid()) {
						return;
					};
					if (isFormInputed(form.getForm()) == false) {
						alert("请输入查询条件");
						form.getForm().focus();
						return;
					} else {
						Ext.get("dbFilter").dom.value = "";
						if (flag == 1) {
							store.baseParams = {
								xmlFile : getQueryStringValue('xmlFile'),
								condictions : connections,
								parentFormValues : getParentFormValues(),
								cmd : 'search'
							};
							store.load({
								params : {
									start : 0,
									limit : result.limit
								}
							});
							form.getForm().reset();
							flag = 0;
						} else {
							store.baseParams = {
								xmlFile : getQueryStringValue('xmlFile'),
								condictions : connections,
								parentFormValues : getParentFormValues(),
								cmd : 'search'
							};
							store.reload();
						}

						form.getForm().reset();
					}
				}
			}, {
				text : '重置',
				handler : function() {
					form.getForm().reset();
				}
			}]
		});
		return form;
	}
~~~

最后做成的效果图，如下：

![bjsasc](http://7xnrdo.com1.z0.glb.clouddn.com/2014/bjsasc.bmp)

如果你想要获取更详细说明，请移步：[Extjs读取xml文件生成动态表格和表单(续)](/2009/10/31/ext_readxml_in_bjsasc_wuzi_continue/)

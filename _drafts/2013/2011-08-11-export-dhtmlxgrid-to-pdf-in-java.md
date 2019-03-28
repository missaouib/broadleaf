---
layout: post
title: Export DhtmlxGrid to PDF in Java
category: web
tags: [javascript, dhtmlxGrid, xml]
keywords: dhtmlxGrid, javascript, pdf, java
description: Export DhtmlxGrid to PDF in Java
---
将DhtmlxGrid数据导出到pdf这是很常见的需求，dhtmlx官网提供了php和java版本的例子，你可以去官网查看这篇文章《<a href="http://www.dhtmlx.com/blog/?p=855">Grid-to-Excel, Grid-to-PDF Available for Java</a>》，你可以从以下地址下载导出程序源码：
<a href="http://www.dhtmlx.com/x/download/regular/export/XML2Excel.war">Export to Excel</a>
<a href="http://www.dhtmlx.com/x/download/regular/export/XML2PDF.war">Export to PDF</a>
当然，还有一个示例工程：<a href="http://www.dhtmlx.com/x/download/regular/export/javaexport_sample.zip"> .zip archive with an example</a>

XML2PDF和XML2Excel工程内代码很相似，XML2PDF内部使用了PDFjet.jar导出PDF，而XML2Excel使用JXL导出Excel。
需要说明的是，还需要引入dhtmlxgrid_export.js文件，该文件是导出grid的js源码，主要用于将表格数据，包括表头、样式等，序列化为xml字符串，然后模拟一个Form表单提交数据。

将上面三个工程导入到一个工程然后打开sample.html页面，效果如下：
<div class="pic">
<img src="http://7xnrdo.com1.z0.glb.clouddn.com/2011/08/export-dhtmlxgrid-to-pdf.png" alt="" title="export dhtmlxgrid to pdf" width="300" height="166" class="aligncenter size-medium wp-image-2385" />
</div>
点击Get as PDF按钮，你会发现会打开一个新的窗口，然后页面什么都没有，而eclipse控制台报空指针异常。异常的主要原因在于下段代码：。
<pre lang="java">
DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance ();
DocumentBuilder db = dbf.newDocumentBuilder();
Document dom = null;
try {
     dom = db.parse(new InputSource(new StringReader(xml)));
}catch(SAXException se) {
     se.printStackTrace();
}catch(IOException ioe) { 
     ioe.printStackTrace();
}
root = dom.getDocumentElement();
</pre>

上面的代码，DocumentBuilder解析xml字符串后dom对象内并没有数据。
为了能够看到DhtmlxGrid导出pdf的效果，决定将上面的代码用dom4j改写，于是有了下面的代码：
<pre lang="java">
public class PDFXMLParser {
	Element root;
	PDFColumn[][] columns;
	PDFRow[] rows;
	double[] widths;
	private Boolean header = false;
	private Boolean footer = false;
	private String profile = "gray";
	private double[] orientation = null;

	public void setXML(String xml) {
		SAXReader saxReader = new SAXReader();

		Document document = null;
		try {
			document = saxReader.read(new ByteArrayInputStream(xml.getBytes()));
		} catch (DocumentException e) {
			e.printStackTrace();
		}
		root = document.getRootElement();

		if ((root.attributeValue("header") != null)
				&amp;&amp; (root.attributeValue("header").equalsIgnoreCase("true") == true)) {
			header = true;
		}
		String footer_string = root.attributeValue("footer");
		if ((footer_string != null)
				&amp;&amp; (footer_string.equalsIgnoreCase("true") == true)) {
			footer = true;
		}
		String profile_string = root.attributeValue("profile");
		if (profile_string != null) {
			profile = profile_string;
		}

		String orientation_string = root.attributeValue("orientation");
		if (orientation_string != null) {
			if (orientation_string.equalsIgnoreCase("landscape")) {
				orientation = A4.LANDSCAPE;
			} else {
				orientation = A4.PORTRAIT;
			}
		} else {
			orientation = Letter.PORTRAIT;
		}
	}

	public PDFColumn[][] getColumnsInfo() {
		PDFColumn[] colLine = null;
		List n1 = root.element("head").elements("columns");
		if ((n1 != null) &amp;&amp; (n1.size() &gt; 0)) {
			columns = new PDFColumn[n1.size()][];
			for (int i = 0; i &lt; n1.size(); i++) {
				Element cols = (Element) n1.get(i);
				List n2 = cols.elements("column");
				if ((n2 != null) &amp;&amp; (n2.size() &gt; 0)) {
					colLine = new PDFColumn[n2.size()];
					for (int j = 0; j &lt; n2.size(); j++) {
						Element col_xml = (Element) n2.get(j);
						PDFColumn col = new PDFColumn();
						col.parse(col_xml);
						colLine[j] = col;
					}
				}
				columns[i] = colLine;
			}
		}
		createWidthsArray();
		optimizeColumns();
		return columns;
	}
        public PDFRow[] getGridContent() {
		List nodes = root.elements("row");
		if ((nodes != null) &amp;&amp; (nodes.size() &gt; 0)) {
			rows = new PDFRow[nodes.size()];
			for (int i = 0; i &lt; nodes.size(); i++) {
				rows[i] = new PDFRow();
				rows[i].parse((Element) nodes.get(i));
			}
		}
		return rows;

	}

       *****
}
</pre>

还需要修改PDFRow类的parse方法和PDFColumn的parse方法。
<pre lang="java">
public class PDFRow {

	private String[] cells;

	public void parse(Element parent) {
		List nodes = ((Element) parent).elements("cell");
		if ((nodes != null) &amp;&amp; (nodes.size() &gt; 0)) {
			cells = new String[nodes.size()];
			for (int i = 0; i &lt; nodes.size(); i++) {
				cells[i] = ((Element) nodes.get(i)).getTextTrim();
			}
		}
	}

	public String[] getCells() {
		return cells;
	}
}

public class PDFColumn {

	public void parse(Element parent) {
		colName = parent.getText();
		String width_string = parent.attributeValue("width");
		if (width_string!=null&&width_string.length() > 0) {
			width = Integer.parseInt(width_string);
		}
		type = parent.attributeValue("type");
		align = parent.attributeValue("align");
		String colspan_string = parent.attributeValue("colspan");
		if (colspan_string!=null&&colspan_string.length() > 0) {
			colspan = Integer.parseInt(colspan_string);
		}
		String rowspan_string = parent.attributeValue("rowspan");
		if (rowspan_string!=null&&rowspan_string.length() > 0) {
			rowspan= Integer.parseInt(rowspan_string);
		}
	}
}
</pre>

这样xml字符串就能正常解析了，然后使用pdfjet.jar包就可以导出pdf了，最后的效果如下：
<div class="pic">
<img src="http://7xnrdo.com1.z0.glb.clouddn.com/2011/08/export-dhtmlx-to-pdf-pdf.png" alt="" title="export dhtmlx to pdf -pdf" width="300" height="134" class="aligncenter size-medium wp-image-2386" />
</div>

<h2>结论：</h2>

* 1.导出pdf和导出Excel代码差不多，这里不做说明。
* 2.使用上面的工具，可以将dhtmlxgrid的数据导出到pdf，并且导出的pdf还保持了grid表格的样式（包括颜色、多表头、表头合并、复选框等等），这点很不错。
* 3.导出的pdf为多页显示，每页有表头
* 4.导出后的pdf页面可以直接打印，当然如果在代码上做点处理，可以直接将pdf保存为一个文件，让用户下载。



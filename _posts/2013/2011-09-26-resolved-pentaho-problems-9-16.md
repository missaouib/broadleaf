---
layout: post
title: Pentaho现场支持遇到问题及解决办法
category: pentaho
tags: [pentaho]
description: Pentaho现场支持遇到问题及解决办法
---
<p>很久没写文章了，最近在关注Pentaho。<br />
 以下是9月16日现场提出的问题解决办法：<br />
      1、PDF预览中文没显示，txt预览中文乱码：<br />
           1）、设置File->Configuration ->output-pageable-pdf的encoding 为Identity-H<br />
           2）、将需要输出中文的报表项目的字体设置为中文字体，例如宋体<br />
           3）、如要发布到服务器，需要修改如下的配置：<br />
             pentaho/server/biserver-ee/tomcat/webapps/pentaho/WEB-INF/classes/classic-engine.properties：<br />
             org.pentaho.reporting.engine.classic.core.modules.output.pageable.pdf.Encoding=Identity-H<br />
     2、实现文件拷贝方式发布报表<br />
           可以通过文件方式发布，只要将报表的prpt文件拷贝到Solution的目录（Pentaho安装路径的server\biserver-ee\pentaho-solutions）下就可以了<br />
     3、报表链接参数传递问题<br />
          由于参数带中文造成的，可以对参数的值URLENCODE("value"; "utf-8")来解决<br />
     4、查询参数缺省值问题<br />
          关于日期的默认值。可以使用报表系统提供的日期变量设置，如TODAY，DATE，YEAR。。。<br />
     5、实现在pie chart上显示文字<br />
          以把label默认显示的百分比改为文字：label-formate = {0}， 但是label显示百分比，同时在pie图的划分区域显示文字是不能的。<br />
     6、报表集成时候垂直滚动条是否可以去掉<br />
          改变报表的高度：报表设计器 file-page setup<br />
     7、报表中的chart不能导出到Excel2007<br />
          目前为系统bug，excel2003能够正常导出<br />
     8、实现隔行换色<br />
          选中Details中的field再attribute面板上设置name的名称（如“row-band”），然后通过Format-->Row-Banding，可以设置Visible Color 、Inisible Color，再Element中输入"row-band"<br />
     9、显示top N  ：托一个message field，在里面输入表达式，如，$（topn）,topn为传入的参数</p>

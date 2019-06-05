---
layout: post
title: The execution process of kettle’s job
category: pentaho
tags: [kettle,pentaho]
keywords: kettle,pentaho
description: kettle执行过程
---

<p>How to execute a kettle job in Spoon GUI or command line after we create a job in Spoon GUI? In Spoon GUI,the main class is "org.pentaho.di.ui.spoon.Spoon.java".This class handles the main window of the Spoon graphical transformation editor.Many operations about a job or transformation such as run,debug,preview,zoomIn,etc,are all in this class.This post just writes about the code execution process.</p>

<p>When we start a job or transformation,Spoon invokes the method runFile(),and then is distributed to executeTransformation() or executeJob().At now,we mainly study about executeJob() method.</p>

<p>This is a simple sequence diagram below.It contains several classes for Starting to execute a job using execute(int nr, Result result) in Job.java.We can see the relation of these classes from it.</p>

<p><div class="pic">
<a href="http://www.javachen.com/wp-content/uploads/2012/02/spoon-execute-sequence.jpg" target="_blank"><img src="http://www.javachen.com/wp-content/uploads/2012/02/spoon-execute-sequence.jpg" alt="" title="spoon execute sequence" width="300" height="180" class="aligncenter size-medium wp-image-2511" /></a>
</div></p>

<p>What is the detail process of job execution? You should look into the Job.run() method for detail information.</p>

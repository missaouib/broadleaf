---
layout: post
title: 使用SaltStack安装JDK1.6
date: 2014-04-01T08:00:00+08:00
description: 使用SaltStack安装JDK1.6
categories: [ devops ]
tags: [saltstack]
---

# 创建states文件

在`/srv/salt`目录下创建jdk目录，并在jdk目录创建init.sls文件，init.sls文件内容如下：

~~~python
jdk-file:
 file.managed:
   - source: salt://jdk/files/jdk1.6.0_39.tar.gz
   - name: /usr/java/jdk1.6.0_39.tar.gz
   - include_empty: True
 
jdk-install:
 cmd.run:
   - name: '/bin/tar -zxf jdk1.6.0_39.tar.gz && /bin/ln -s jdk1.6.0_39  latest '
   - cwd: /usr/java
   - unless: 'test -e jdk1.6.0_39'
   - require:
     - file: jdk-file
 
jdk-rmzip:
  file.absent:
    - name: /usr/java/jdk1.6.0_39.tar.gz
 
/root/.bashrc:
  file.append:
    - text:
      - export JAVA_HOME=/usr/java/latest
      - export PATH=$JAVA_HOME/bin:$PATH
~~~

上面sls文件需要引用`jdk1.6.0_39.tar.gz`文件，故需要下载jdk1.6.0_39.bin安装之后将其打包成`jdk1.6.0_39.tar.gz`拷贝到`/srv/salt/jdk/files`目录。

init.sls文件执行过程包括以下几个步骤：

- jdk-file，将`salt://jdk/files/jdk1.6.0_39.tar.gz`文件拷贝到`/usr/java`
- jdk-install，解压文件
- jdk-rmzip，删除压缩包
- /root/.bashrc，设置JAVA_HOME

修改top.sls文件（该步骤为可选），添加jdk.init:

~~~python
base:
  '*':
    - jdk.init
~~~

# 测试运行

在master上运行下面命令，并观察运行结果：

~~~bash
[root@sk1 vagrant]# salt '*' state.sls jdk
sk2:
----------
          ID: jdk-file
    Function: file.managed
        Name: /usr/java/jdk1.6.0_39.tar.gz
      Result: True
     Comment: File /usr/java/jdk1.6.0_39.tar.gz updated
     Changes:  
              ----------
              diff:
                  New file
              mode:
                  0644
----------
          ID: jdk-install
    Function: cmd.run
        Name: /bin/tar -zxf jdk1.6.0_39.tar.gz && /bin/ln -s jdk1.6.0_39  latest
      Result: True
     Comment: unless execution succeeded
     Changes:  
----------
          ID: jdk-rmzip
    Function: file.absent
        Name: /usr/java/jdk1.6.0_39.tar.gz
      Result: True
     Comment: Removed file /usr/java/jdk1.6.0_39.tar.gz
     Changes:  
              ----------
              removed:
                  /usr/java/jdk1.6.0_39.tar.gz
----------
          ID: /root/.bashrc
    Function: file.append
      Result: True
     Comment: Appended 0 lines
     Changes:  
Summary
------------
Succeeded: 4
Failed:    0
------------
Total:     4
~~~

从上可以看出成功了4个，失败为0。

安装了jdk之后，需要重启minion(还需要**修改minion启动脚本，让minion加载上系统环境变量**，详细说明，见[安装SaltStack和halite](/images/11/11/install-saltstack-and-halite.html))才能通过下面脚本运行java相关的命令，如java、jps等等：

~~~python
salt '*' cmd.run 'jps'
~~~

否则，你需要通过下面脚本来执行：

~~~python
salt '*' cmd.run 'source /root/.bashrc ;jps'
~~~

# 设置pillar

将上面的`jdk/init.sls`文件修改为通过pillar引用变量

a.首先在`/srv/pillar`目录创建jdk目录，并在jdk目录下创建init.sls文件，内容如下：

~~~python
jdk:
  name: jdk1.6.0_39
  srvpath: salt://jdk/files 
  homepath: /usr/java
~~~

b.在`/srv/pillar/top.sls`中添加jdk.init

~~~python
base:
  '*':
    - jdk.init
~~~

c.修改`/srv/salt/jdk/init.sls`文件为从pillar引入变量，内容如下：

{% raw %}
~~~
jdk-file:
  file.managed:
    - source: {{pillar['jdk']['srvpath']}}/{{pillar['jdk']['name']}}.tar.gz
    - name: {{pillar['jdk']['homepath']}}/{{pillar['jdk']['name']}}.tar.gz
    - makedirs: True
 
jdk-install:
  cmd.run:
    - name: 'unzip -q {{pillar['jdk']['name']}}.tar.gz'
    - cwd: {{pillar['jdk']['homepath']}}
    - unless: 'test -e {{pillar['jdk']['name']}}'
    - require:
      - file: jdk-file
jdk-rmzip:
  file.absent:
    - name: {{pillar['jdk']['homepath']}}/{{pillar['jdk']['name']}}.tar.gz
{{pillar['userhome']}}/.bashrc:
  file.append:
    - text:
      - export JAVA_HOME={{pillar['jdk']['homepath']}}/{{pillar['jdk']['name']}}
      - export PATH=$JAVA_HOME/bin:$PATH
~~~
{% endraw %}

d.参考上面，再次测试一遍

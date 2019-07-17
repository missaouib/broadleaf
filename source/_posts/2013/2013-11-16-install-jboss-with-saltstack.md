---
layout: post
title: 使用SaltStack安装JBoss
description: 使用SaltStack安装jboss。SaltStack是一个具备puppet与func功能为一身的集中化管理平台，其基于python实现，功能十分强大，各模块融合度及复用性极高。SaltStack 采用 zeromq 消息队列进行通信，和 Puppet/Chef 比起来，SaltStack 速度快得多。
category: devops
tags: [saltstack]
---

SaltStack是一个具备puppet与func功能为一身的集中化管理平台，其基于python实现，功能十分强大，各模块融合度及复用性极高。SaltStack 采用 zeromq 消息队列进行通信，和 Puppet/Chef 比起来，SaltStack 速度快得多。

在开始使用SaltStack之前，首先要对SaltStack的基础进行一系列的学习，这里，强烈推荐官网的[Tutorial](http://docs.saltstack.com/topics/tutorials/walkthrough.html),在完成了整个Tutorial之后，通过Module Index页面，我们能够快速查阅Salt所有模块的功能与用法:[http://docs.saltstack.com/py-modindex.html](http://docs.saltstack.com/py-modindex.html)

# 安装saltstack

安装过程请参考：[安装saltstack和halite](/linux/images/11/11/install-saltstack-and-halite/)

# 添加pillar

你可以执行下面命令查看minion拥有哪些Pillar数据：

~~~
$ salt '*' pillar.data
~~~

saltstack的默认states目录为`/srv/salt`，默认为`/srv/pillar`，如果不存在请先创建。

~~~
[root@sk1 /]# tree /srv/ -L 3
/srv/
├── pillar
│   ├── jboss
│       ├── params.sls
│   └── top.sls
├── salt
│   ├── jboss
│   ├── _modules
│   └── top.sls
~~~

在`/srv/pillar/`下创建top.sls，该文件引入jboss下的params.sls：

~~~python
 base:
  '*':
    - jboss.params
~~~

创建jboss目录并添加params.sls如下：

~~~python
 jboss_home: /home/jboss/jboss-eap-5.1/jboss-as
 profile_port:
  default1: 
    http_port: ports-default
    jmx_port: 1099
  default2: 
    http_port: ports-01
    jmx_port: 1199
  default3: 
    http_port: ports-02
    jmx_port: 1299
  default4: 
    http_port: ports-03
    jmx_port: 1399

 jmx:
  username: admin
  password: admin
~~~

该文件定义了如下变量，你可以按需要定义自己的变量：

- jboss_home：mimion机器上jboss的home目录
- profile_port：定义有多少个profile以及每个profile下的http端口和jmx端口
- jmx:定义jmx-console用户名和密码

定义变量之后，你可以在sates文件中这样引用：

~~~python
pillar['profile_port']['default1']
~~~

下面是个复杂的例子，使用了python中的模板引擎语言：

{% raw %}
~~~python
{% for profile, port in pillar.get('profile_port', {}).items() %}
    {{profile}}
{% endfor %}
~~~
{% endraw %}

你还可以在python脚本中或者是saltstack自定义module中这样引用变量：

~~~
__pillar__['jboss_home']
__pillar__['profile_port']['default1']['jmx_port']
~~~

在master上修改Pilla文件后，需要用以下命令刷新minion上的数据：

~~~
$ salt '*' saltutil.refresh_pillar
~~~

如果定义好的pillar不生效，建议刷新一下或者重启salt试试。

# 编写states

/srv/salt目录如下：

~~~
[root@sk1 salt]# tree -L 3
.
├── jboss
│   ├── files
│   │   └── jboss-eap-5.1.zip
│   └── init.sls

├── _modules
│   └── jboss.py
├── top.sls
~~~

top.sls为sates入口，定义如下：

~~~
 base:
  *:
    - jboss
~~~

创建jboss目录并编写init.sls文件：

{% raw %}
~~~python
 unzip:
  pkg.installed
 jboss:
  file.managed:
    - name:  /home/jboss/jboss-eap-5.1.zip
    - source: salt://jboss/files/jboss-eap-5.1.zip
    - include_empty: True
    - user: jboss
    - group: jboss
    - mode: 655
  cmd.run:
    - name: 'unzip jboss-eap-5.1.zip'
    - cwd: /home/jboss
    - user: jboss
    - unless: 'test -e jboss-eap-5.1'
    - require:
      - file.managed: jboss

{% for profile, port in pillar.get('profile_port', {}).items() %}
 {{profile}}:
  cmd.run:
    - name: '\cp -r default {{profile}}'
    - cwd:  /home/jboss/jboss-eap-5.1/jboss-as/server
    - user: jboss
    - unless: 'test -e {{profile}}'
    - require:
      - file.managed: jboss
{% endfor %}
~~~
{% endraw %}

说明：

1.上面文件中创建了jboss ID，其包括两部分：拷贝文件和解压缩，分别对应file.managed和cmd.run。

2.然后通过脚本语言读取pillar中定义的变量并以依次遍历生成多个ID，ID名称由变量中值定义。本例中，是读取`profile_port`的值，然后创建多个profile。`profile_port`变量在`/srv/pillar/jboss/params.sls`中定义。

编写完sates文件之后，你可以通过执行以下命令让所有minion执行sates文件中定义的state：

~~~
$ salt '*' state.highstate
~~~

你也可以单独执行jboss这个states：

~~~
$ salt '*' state.sls jboss
~~~

# 自定义grains_module

自定义的`grains_module`存放在`/srv/salt/_grains`目录，下面定义一个获取`max_open_file`的grains：

~~~python
import os,sys,commands
 
def Grains(): 
    grains = {}
    max_open_file=65536 
    try: 
        getulimit=commands.getstatusoutput('source /etc/profile;ulimit -n')  
    except Exception,e: 
        pass  
    if getulimit[0]==0: 
        max_open_file=int(getulimit[1])  
    grains['max_open_file'] = max_open_file 
    return grains
~~~

然后，同步grains模块：

~~~bash
$ salt '*' saltutil.sync_all
sk2:
    ----------
    grains:
        - grains.max_open_file 
    modules:
    outputters:
    renderers:
    returners:
    states:

~~~

刷新模块(让minion编译模块)：

~~~
$ salt '*' sys.reload_modules
~~~

然后，验证max open file的value：

~~~
$ salt '*' grains.item max_open_file
sk2:
  max_open_file: 1024
~~~

# 自定义module

你通过执行states可以完成bao的安装、配置和部署，如果你想对他们做管理，你可以自定义module来执行一些远程命令。

自定义的module需要存放在`/srv/salt/_modules`目录下，为了对jboss实例进行启动、停止、查看运行状态，编写jboss.py模块：

~~~python
def _simple_cmd_retcode(cmd):
    home = __pillar__['jboss_home']+'/bin'
    out = __salt__['cmd.retcode'](cmd,cwd=home)
    ret = {}
    ret['Cmd']=cmd
    ret['Msg']=out
    ret['Result']=True
    return ret

def _simple_cmd(cmd):
    home = __pillar__['jboss_home']+'/bin'
    out = __salt__['cmd.run'](cmd,cwd=home).splitlines()
    ret = {}
    ret['Cmd']=cmd
    ret['Msg']=out
    ret['Result']=True
    return ret

def running(profile):
    ret =_simple_cmd("ps -ef|grep -v grep|grep java|grep "+profile+" |grep "+__pillar__['profile_port'][profile]['http_port'])
    if ret['Msg']=='' or len(ret['Msg'])==0:
        return False
    return True

def start(profile):
    ip = __grains__['id'][0]
    port = __pillar__['profile_port'][profile]['http_port']
    cmd = 'nohup ./run.sh -b '+ip+' -c '+profile+' -Djboss.service.binding.set='+port+' &'
 
    ret={}
    if running(profile):
        ret['Cmd']=cmd
	ret['Msg']=profile+' has started'
        ret['Result']=False
        return ret
    
    return _simple_cmd_retcode(cmd)

def status(profile):
    ip = __grains__['id'][0]
    port = __pillar__['profile_port'][profile]['jmx_port']
    username = __pillar__['jmx']['username']
    password = __pillar__['jmx']['password']
    cmd="./twiddle.sh -s "+ip+":"+str(port)+" -u "+username+" -p "+password+" get jboss.system:type=Server Started"
    
    ret=_simple_cmd(cmd)
    for line in ret['Msg']:
        if not line:
            continue
        if 'ERROR' in line:
 	    ret['Result']=False
	    ret['Msg']=ret['Msg'][0:2]
            break
    return ret
    
def stop(profile):
    ip = __grains__['id'][0]
    port = __pillar__['profile_port'][profile]['jmx_port']
    username = __pillar__['jmx']['username']
    password = __pillar__['jmx']['password']
    cmd="./shutdown.sh -S -s "+ip+":"+str(port)+" -u "+username+" -p "+password
    return _simple_cmd(cmd)
~~~

以上python脚本定义了对单个profile的启动、停止和查看运行状态的方法，你可以修改或者扩增代码，添加更多的方法。

然后运行下面命令同步所有模块：

~~~
$ salt '*' saltutil.sync_all
sk2:
    ----------
    grains:
    modules:
        - modules.jboss
    outputters:
    renderers:
    returners:
    states:
~~~

刷新自定义模块(让minion编译模块)：

~~~
$ salt '*' sys.reload_modules
~~~

如果你想启动jboss的default1实例，只需要执行以下方法：

~~~
$ salt '*' jboss.start default1
~~~

同样，查看状态：

~~~
$ salt '*' jboss.status default1
~~~

jboss为自定义模块的名称，也是jboss.py的名称，start或者status为jboss.py中定义的方法。

如果运行出错，请查看minion的日志，路径为`/var/log/salt/minion`

# 同步配置文件

现在需要修改jmx-console-users.properties文件中的用户名和密码并将其同步到所有jboss实例中。

将jmx-console-users.properties文件放置在`/srv/salt/jboss/files`目录下，并修改该文件如下：

~~~
 #A sample users.properties file for use with the UsersRolesLoginModule
 pillar['jmx']['username']= pillar['jmx']['password']
~~~

上面文件中使用了pillar获取变量，你还可以使用模板语言如if、for语句来丰富你的文件内容，saltstack支持的模板引擎有`jinja`等。

然后在init.sls中添加：

~~~python
 jmx-console-users.properties:
   file.managed:
     - name: /home/jboss/jboss-eap-5.1/jboss-as/server/default/conf/props/jmx-console-users.properties
     - source: salt://jboss/files/jmx-console-users.properties
     - template: jinja
~~~


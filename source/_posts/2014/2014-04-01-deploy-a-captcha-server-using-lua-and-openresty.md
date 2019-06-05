---
layout: post
title: 使用Lua和OpenResty搭建验证码服务器
description: 使用Lua和OpenResty搭建验证码服务器
category: devops
tags: 
 - lua
 - nginx
 - redis
published: true
---

[Lua](http://www.lua.org/)下有个[Lua-GD](http://lua-gd.luaforge.net/)图形库，通过简单的Lua语句就能控制、生成图片。

**环境说明：**

- 操作系统：RHEL6.4
- RHEL系统默认已安装RPM包的[Lua-5.1.4](http://www.lua.org/ftp/lua-5.1.4.tar.gz)，但其只具有Lua基本功能，不提供 `lua.h` 等，但 Lua-GD 编译需要用到 `lua.h`，故 Lua 需要编译安装。
- Lua-GD 版本号格式为`X.Y.XrW`，其中`X.Y.Z`代表gd版本，`W`代表效力版本，所以 lua-gd 版本：`lua-gd-2.0.33r2` 相对应 gd 版本为：`gd-2.0.33`，须注意保持一致。
- 因生成gif的lua脚本中用到md5加密，故需编译安装md5。
- 因为生成图片需要唯一命名，故依赖 UUID

**另外：**

以下操作均以root用户运行，并且以下脚本的当前目录为`/opt`，即所有的下载的文件都会保存在`/opt`目录下。

需要安装的软件如下：

- OpenResty：WEB应用服务器，部署lua代码，提供URL供用户调用和访问
- LuaJIT：LUA代码解释器，使用OpenResty中集成的版本
- GD库：C图形库
- Lua-GD库：Lua绑定的C图形库，使得lua可调用gd
- Lua-Resty-UUID库：用于生成UUID，保证图片命名唯一性
- LuaSocket：lua 的 socket 库


# 安装lua

安装编译所需软件包:

~~~ bash
$ yum install -y make gcc
~~~

下载并编译安装 lua-5.1：

~~~bash
$ yum install -y readline-devel
$ wget http://www.lua.org/ftp/lua-5.1.4.tar.gz
$ tar lua-5.1.4.tar.gz
$ cd lua-5.1.4
$ make linux
$ make linux install 
~~~

# 安装 gd

GD版本：gd-2.0.33

下载地址: <http://www.boutell.com/gd/http/gd-2.0.33.tar.gz>


~~~bash
$ yum install -y libjpeg-devel libpng-devel freetype-devel fontconfig-devel libXpm-devel

$ wget http://www.boutell.com/gd/http/gd-2.0.33.tar.gz
$ tar zvxf gd-2.0.33.tar.gz
$ cd gd-2.0.33
$ ./configure
$ make && make install
~~~

# 安装 Lua-gd 库

Lua-GD版本：lua-gd-2.0.33r2

下载地址: <http://jaist.dl.sourceforge.net/project/lua-gd/lua-gd/lua-gd-2.0.33r2%20%28for%20Lua%205.1%29/lua-gd-2.0.33r2.tar.gz>

开发手册可参考: <http://ittner.github.io/lua-gd/manual.html>

>说明：
>
>须先完成gd的安装，且版本号必须为gd-2.0.33 
>调用Lua-GD库的lua代码须由OpenResty中集成的LuaJIT解释执行


~~~bash
$ wget http://sourceforge.net/projects/lua-gd/files/lua-gd/lua-gd-2.0.33r2%20(for%20Lua%205.1)/lua-gd-2.0.33r2.tar.gz/download?use_mirror=jaist
$ tar zvxf lua-gd-2.0.33r2.tar.gz
$ cd lua-gd-2.0.33r2
~~~

接写来修改Makefile文件：

- 注释第36～42行
- 打开第48～52行注释，并做如下修改

~~~
OUTFILE=gd.so
CFLAGS=-Wall `gdlib-config --cflags` -I/usr/local/include/lua -O3    //第49行，修改 lua 的 C 库头文件所在路径
GDFEATURES=`gdlib-config --features |sed -e "s/GD_/-DGD_/g"`
LFLAGS=-shared `gdlib-config --ldflags` `gdlib-config --libs` -llua -lgd  //第51行，取消lua库版本号51
INSTALL_PATH=/usr/local/lib/lua/5.1    //第52行，设置 gd.so 的安装路径

$(CC) -fPIC -o ...  //第70行，gcc 编译，添加 -fPIC 参数
~~~

然后编译：

~~~bash
$ make && make install
~~~

# 安装 md5

~~~bash
$ yum install unzip

$ wget https://github.com/keplerproject/md5/archive/master.zip -O md5-master.zip
$ unzip md5-master.zip
$ cd md5-master
$ make && make install
~~~

# 安装 Lua-resty-UUID 库 

调用系统的UUID模块生成的由32位16进制（0-f）数组成的的串，本模块进一步压缩为62进制。正如你所想，生成的UUID越长，理论冲突率就越小，请根据业务需要自行斟酌。 基本思想为把系统生成的16字节（128bit）的UUID转换为62进制（a-zA-Z0-9），同时根据业务需要进行截断。


下载地址: <https://github.com/dcshi/lua-resty-UUID/archive/master.zip>


~~~bash
$ yum -y install libuuid-devel
$ wget https://github.com/dcshi/lua-resty-UUID/archive/master.zip -O lua-resty-UUID-master.zip
$ unzip lua-resty-UUID-master.zip
$ cd lua-resty-UUID-master/clib
$ make
~~~

# 下载nginx sysguard模块

>如果nginx被攻击或者访问量突然变大，nginx会因为负载变高或者内存不够用导致服务器宕机，最终导致站点无法访问。
>今天要谈到的解决方法来自淘宝开发的模块nginx-http-sysguard，主要用于当负载和内存达到一定的阀值之时，会执行相应的动作，比如直接返回503,504或者其他的。一直等到内存或者负载回到阀值的范围内，站点恢复可用。简单的说，这几个模块是让nginx有个缓冲时间，缓缓。

~~~bash
$ wget https://github.com/alibaba/nginx-http-sysguard/archive/master.zip -O nginx-http-sysguard-master.zip
$ unzip nginx-http-sysguard-master.zip
~~~

# 安装 OpenResty

>OpenResty（也称为 ngx_openresty）是一个全功能的 Web 应用服务器。它打包了标准的 Nginx 核心，很多的常用的第三方模块，以及它们的大多数依赖项。 
>OpenResty 中的 LuaJIT 组件默认未激活，需使用 `--with-luajit` 选项在编译 OpenResty 时激活,使用`--add-module`，添加上sysguard模块

安装的版本：1.2.7.6

下载地址：

- <http://openresty.org/#Download>
- <http://openresty.org/download/ngx_openresty-1.2.7.6.tar.gz>

先安装依赖软件，然后在编译代码，编译时使用`--perfix`选项指定 OpenResty 的安装目录，`--with-luajit` 选项激活 LuaJIT 组件。

~~~bash
$ yum -y install gcc make gmake openssl-devel pcre-devel readline-devel zlib-devel

$ wget http://openresty.org/download/ngx_openresty-1.2.7.6.tar.gz
$ tar zvxf ngx_openresty-1.2.7.6.tar.gz
$ cd ngx_openresty-1.2.7.6
$ ./configure --with-luajit --with-http_stub_status_module --add-module=/opt/nginx-http-sysguard-master/
$ gmake && gmake install
~~~

创建软连接：

~~~
$ ln -s /usr/local/openresty/nginx/sbin/nginx /usr/sbin/nginx
~~~

# 安装 Redis Server

> Lua 脚本功能是 Reids 2.6 版本的最大亮点， 通过内嵌对 Lua 环境的支持， Redis 解决了长久以来不能高效地处理 CAS （check-and-set）命令的缺点， 并且可以通过组合使用多个命令， 轻松实现以前很难实现或者不能高效实现的模式。

~~~bash
$ wget http://redis.googlecode.com/files/redis-2.6.14.tar.gz
$ tar zvxf redis-2.6.14.tar.gz
$ cd redis-2.6.14
$ make && make install

$ mkdir -p /usr/local/redis/conf
$ cp redis.conf /usr/local/redis/conf/
~~~ 

# 安装 LuaSocket 库

> LuaSocket是一个Lua扩展库，它能很方便地提供SMTP、HTTP、FTP等网络议访问操作。

LuaSocket版本：luasocket-2.0-beta2

下载地址: <http://files.luaforge.net/releases/luasocket/luasocket/luasocket-2.0-beta2/luasocket-2.0-beta2.tar.gz>


~~~bash
$ wget http://files.luaforge.net/releases/luasocket/luasocket/luasocket-2.0.2/luasocket-2.0.2.tar.gz
$ tar zvxf luasocket-2.0.2.tar.gz
$ cd luasocket-2.0.2
$ make -f makefile.Linux
~~~

# 安装 redis-lua 库

Redis-Lua版本：2.0

下载地址: <https://github.com/nrk/redis-lua/archive/version-2.0.zip>


~~~bash
$ wget https://github.com/nrk/redis-lua/archive/version-2.0.zip
$ unzip redis-lua-version-2.0.zip
$ cd redis-lua-version-2.0
~~~

然后，拷贝redis.lua至所需目录。

lua调用方式如下：

~~~
local redis = require(“redis”)
~~~

# 安装 zklua

> zklua 仅依赖 zookeeper c API 实现，一般存在于 `zookeeper-X.Y.Z/src/c`， 因此你需要首先安装 zookeeper c API。

zookeeper c API 安装:

~~~bash
$ wget http://mirrors.cnnic.cn/apache/zookeeper/zookeeper-3.4.5/
$ tar zvxf zookeeper-3.4.5
$ cd zookeeper-3.4.5/src/c
$ ./configure
$ make && make install
~~~

然后安装zklua：

~~~bash
$ wget https://github.com/forhappy/zklua/archive/master.zip -O zklua-master.zip
$ unzip zklua-master.zip
$ cd zklua-master
$ make  && make install
~~~

# 修改配置文件

## 配置openresty

openresty安装在`/usr/local/openresty`目录，在其目录下创建lualib，用于存放上面安装的一些动态连接库

~~~
mkdir -p  /usr/local/openresty/lualib/captcha
cp lua-resty-UUID-master/clib/libuuidx.so /usr/local/openresty/lualib/captcha/  #拷贝uuid的库文件
cp -r lua-resty-UUID-master/lib/* /usr/local/openresty/lualib/captcha/

cp luasocket-2.0.2/luasocket.so.2.0 /usr/local/openresty/lualib/captcha/		#拷贝luasocket的库文件到/usr/local/openresty/lualib/captcha/
ln -s  /usr/local/openresty/lualib/captcha/luasocket.so.2.0 /usr/local/openresty/lualib/captcha/socket.so

cp redis-lua-version-2.0/src/redis.lua /usr/local/openresty/lualib/captcha/     #拷贝reis.lua到/usr/local/openresty/lualib/captcha/

mkdir -p /usr/local/openresty/lualib/zklua										#拷贝zklua文件到/usr/local/openresty/lualib/captcha/
cp cd zklua-master/zklua.so /usr/local/openresty/lualib/zklua/
~~~


## 配置nginx

创建www用户：

~~~
useradd -M -s /sbin/nologin www
~~~

编辑ngnix.conf，内容如下：

~~~
    user  www;
    worker_processes  31;
    error_log  logs/error.log;
    pid        logs/nginx.pid;
    worker_rlimit_nofile 65535;
    events {
    	worker_connections 1024;
    	use epoll;
	   }

    http {
	include       	mime.types;
	default_type 	application/octet-stream;
	log_format  	main  '$remote_addr - $remote_user [$time_local] "$request" '
			      '$status $body_bytes_sent "$http_referer" '
	               	      '"$http_user_agent" "$http_x_forwarded_for"';
	access_log  	logs/access.log  main;
	sendfile        on;
	tcp_nopush      on;
	tcp_nodelay     on;
	keepalive_timeout  65;
	gzip  		on;
	gzip_min_length 1K;
	gzip_buffers 4 	8k;
	gzip_comp_level 2;
	gzip_types 	text/plain image/gif image/png image/jpg application/x-javascript text/css application/xml text/javascript;
	gzip_vary 	on;
	
	upstream redis-pool{
	        server 127.0.0.1:10005;
		keepalive 1024;
        }

    server {
        sysguard on;
        sysguard_load load=90 action=/50x.html;
        server_tokens off;
        listen       10002;
        server_name  localhost;
        charset utf-8;

        location / {
        root   html;
        index  index.html index.htm;
        }

	#-----------------------------------------------------------------------------------------
	
	# 验证码生成
	location /captcha {
		set $percent 0;
		set $modecount 1;
		content_by_lua_file /usr/local/openresty/nginx/luascripts/luajit/captcha.lua;
	}

	#-----------------------------------------------------------------------------------------
	
	# 验证码校验	
	location /captcha-check {
	        content_by_lua_file /usr/local/openresty/nginx/luascripts/luajit/captcha-check.lua;
        }

        # 验证码删除	
	location /captcha-delete {
		content_by_lua_file /usr/local/openresty/nginx/luascripts/luajit/captcha-delete.lua;
	}
	
	#-----------------------------------------------------------------------------------------

	# 样式1-静态图片
	location /mode1 {
		content_by_lua_file /usr/local/openresty/nginx/luascripts/luajit/mode/mode1.lua;
	} 
	
	#-----------------------------------------------------------------------------------------

	# redis中添加key-value
	location /redisSetQueue {
		internal;
		set_unescape_uri $key $arg_key;
		set_unescape_uri $val $arg_val; 
		redis2_query rpush $key $val;
		redis2_pass redis-pool;
	}
	# redis中获取captcha-string
	location /redisGetStr {
		internal;
		set_unescape_uri $key $arg_key;
		redis2_query lindex $key 0;
		redis2_pass redis-pool;
	}
	# redis中获取captcha-image
	location /redisGetImg {
		internal;
		set_unescape_uri $key $arg_key;
		redis2_query lindex $key 1;
		redis2_pass redis-pool;
	}
	
	#-----------------------------------------------------------------------------------------

        location ~.*.(gif|jpg|png)$ {
        expires 10s;
        }

        error_page  404              /404.html;
        error_page  500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
    }

}
~~~

上面将 ngnix 的端口修改为10002。

/usr/local/openresty/nginx/luascripts/luajit/captcha.lua 是用于生成验证码，内容如下：

~~~lua
--中控脚本
--
--部分应用预先生成
--部分应用实时生成，并且随机选择生成样式
--

----------------------------------------------------------------------------------------------
package.path = "/usr/local/openresty/lualib/?.lua;/usr/local/openresty/lualib/captcha/?.lua;"
package.cpath = "/usr/local/openresty/lualib/?.so;/usr/local/openresty/lualib/captcha/?.so;"
----------------------------------------------------------------------------------------------

--设置随机种子
local resty_uuid=require("resty.uuid")
math.randomseed(tonumber(resty_uuid.gennum20()))

-----------------------------------------------------------------------------------------
--
--[[ 预先生成 ]]
--
if math.random(1,99)<tonumber(ngx.var.percent) then
        
    --在redis的预先生成key中随机选择keyid
    local kid=math.random(1,ngx.var.pregencount)
        local res = ngx.location.capture('/redisGetImg',{ args = { key = kid } })
        
    if res.status==200 then
            local parser=require("redis.parser")
                local pic=parser.parse_reply(res.body)
                ngx.header.content_type="application/octet-stream"
        
        --在header中返回用于去redis中查找记录的key
                ngx.header.picgid=kid
        
        --在body中返回captcha
                ngx.say(pic)

                ngx.exit(200)
        end
end

-----------------------------------------------------------------------------------------
--
--[[ 实时生成 ]]
--

--随机选择captcha模式X
local mode=math.random(1,ngx.var.modecount)

--调用modeX.lua，生成captcha
local res = ngx.location.capture("/mode"..mode)
if res.status==200 then
    ngx.header.content_type="application/octet-stream"

    --在header中返回用于去redis中查找记录的key
    ngx.header.picgid=res.header.picgid
        
    --在body中返回captcha
    ngx.say(res.body)

        ngx.exit(200)
end
~~~

/usr/local/openresty/nginx/luascripts/luajit/captcha-check.lua 用于校验验证码：

~~~lua
--[[captcha check]]

----------------------------------------------------------------------------------------------
package.path = "/usr/local/openresty/lualib/?.lua;/usr/local/openresty/lualib/captcha/?.lua;"
package.cpath = "/usr/local/openresty/lualib/?.so;/usr/local/openresty/lualib/captcha/?.so;"
----------------------------------------------------------------------------------------------

--获取请求中参数
local uriargs = ngx.req.get_uri_args()
local picgid = uriargs["image"]
local ustr=string.lower(uriargs["str"])

--查找redis中key为picgid的记录
local res = ngx.location.capture('/redisGetStr',{ args = { key = picgid } })
if res.status==200 then
    local parser=require("redis.parser")
    local reply=parser.parse_reply(res.body)
    local rstr=string.lower(reply)
    
    --匹配用户输入字符串与redis中记录的字符串，一致返回True，否则返回False
    ngx.header.content_type="text/plain"
    if ustr == rstr then
        ngx.say("True")
    else
        ngx.say("False")
    end
    
    --匹配操作后删除redis中该key记录
    local redis = require('redis')
    local client = redis.connect('127.0.0.1', 10005)
    client:del(picgid)
end
~~~

/usr/local/openresty/nginx/luascripts/luajit/mode/mode1.lua 是生成静态验证码图片：

~~~lua
--静态图片

------------------------------------------------------------------------------------------------
package.path = "/usr/local/openresty/lualib/?.lua;/usr/local/openresty/lualib/captcha/?.lua;"
package.cpath = "/usr/local/openresty/lualib/?.so;/usr/local/openresty/lualib/captcha/?.so;"
------------------------------------------------------------------------------------------------

--Redis中插入记录方法
function setRedis(skey, sval)
        local res = ngx.location.capture('/redisSetQueue', {args= {key=skey,val=sval}})
        if res.status == 200 then
                return true
        else
                return false
        end
end

--设置随机种子
local resty_uuid=require("resty.uuid")
math.randomseed(tonumber(resty_uuid.gennum20()))

--在32个备选字符中随机筛选4个作为captcha字符串
local dict={'A','B','C','D','E','F','G','H','J','K','L','M','N','P','Q','R','S','T','U','V','W','X','Y','Z','2','3','4','5','6','7','8','9'}
local stringmark=""
for i=1,4 do
       stringmark=stringmark..dict[math.random(1,32)]
end

--图片基本info
--picgid
local filename= "1"..resty_uuid.gen20()..".png"
--图片78x26
local xsize = 78
local ysize = 26
--字体大小
local wsize = 17.5
--干扰线(yes/no)
local line = "yes"

--加载模块
local gd=require('gd')
--创建面板
local im = gd.createTrueColor(xsize, ysize)
--定义颜色
local black = im:colorAllocate(0, 0, 0)
local grey = im:colorAllocate(202,202,202)
local color={}
for c=1,100 do
        color[c] = im:colorAllocate(math.random(100),math.random(100),math.random(100))
end
--画背景
x, y = im:sizeXY()
im:filledRectangle(0, 0, x, y, grey)
--画字符
gd.useFontConfig(true)
for i=1,4 do
    k=(i-1)*16+3
    im:stringFT(color[math.random(100)],"Arial:bold",wsize,math.rad(math.random(-10,10)),k,22,string.sub(stringmark,i,i))
end
--干扰线点
if line=="yes" then
    for j=1,math.random(3) do
        im:line(math.random(xsize),math.random(ysize),math.random(xsize),math.random(ysize),color[math.random(100)])
    end
    for p=1,20 do
            im:setPixel(math.random(xsize),math.random(ysize),color[math.random(100)])
    end

end
--流输出
local fp=im:pngStr(75)

--redis中添加picgid为key,string为value的记录
setRedis(filename,stringmark)

--response header中传参picgid
ngx.header.content_type="text/plain"
ngx.header.picgid=filename

--页面返回pic
ngx.say(fp)

--nginx退出
ngx.exit(200)
~~~

## 配置redis

在`/usr/local/openresty/redis/conf/`创建redis-10005.conf文件，内容如下：

~~~
daemonize yes
pidfile /usr/local/openresty/redis/redis-10005.pid
port 10005
timeout 300
tcp-keepalive 10
loglevel notice
logfile /usr/local/openresty/redis/redis-10005.log
databases 16
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump-10005.rdb
dir /usr/local/openresty/redis
slave-serve-stale-data yes
slave-read-only yes
repl-disable-tcp-nodelay no
slave-priority 100
appendonly no
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
lua-time-limit 5000
slowlog-log-slower-than 10000
slowlog-max-len 128
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
list-max-ziplist-entries 512
list-max-ziplist-value 64
set-max-intset-entries 512
zset-max-ziplist-entries 128
zset-max-ziplist-value 64
activerehashing yes
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit slave 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60
hz 10
~~~

## 配置验证码服务器

在`/etc/ld.so.conf.d/`目录创建captcha.conf，内容如下：

~~~
$ vim /etc/ld.so.conf.d/captcha.conf
/usr/local/lib
/usr/local/openresty/lualib
/usr/local/openresty/lualib/captcha
/usr/local/openresty/lualib/zklua
/usr/local/openresty/luajit/lib
~~~

# 测试

## 生成验证码

URL：http://IP:10002/captcha

然后从响应Header中获取图片的picgid=XXXXX

## 验证码校验

URL：http://IP:10002/captcha-check?image=XXXXX&str=ABCD
http://IP:10002/captcha-check?image=XXXXX&str=ABCD&delete=true
或
http://IP:10002/captcha-check?image=XXXXX&str=ABCD&delete=false

参数说明如下：

- 参数image：要校验的验证码图片的picgid。
- 参数str：用户输入的验证码字符串。
- 参数delete：当且仅当传该参数且参数值为false时，校验完成之后该验证码记录不被删除，验证码未过期之前可多次校验，用于异步校验应用中；否则，若不传该参数或者其值为true，校验完成之后该验证码记录删除。

## 验证码删除

URL：http://IP:10002/captcha-delete?image=XXXXX

其中image为要删除的验证码图片的picgid。


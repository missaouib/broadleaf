---
layout: post
title: 使用Vagrant创建虚拟机
description: Vagrant是一款用来构建虚拟开发环境的工具，非常适合 php/python/ruby/java 这类语言开发 web 应用，使用Vagrant可以快速的搭建虚拟机并安装自己的一些应用。
category: devops
tags: [ vagrant]

---

# 1、安装VirtualBox

下载地址：[https://www.virtualbox.org/wiki/Downloads/](https://www.virtualbox.org/wiki/Downloads/)

>提示：虽然 Vagrant 也支持 VMware，不过 VMware 是收费的，对应的 Vagrant 版本也是收费的

# 2、安装Vagrant并添加镜像

下载安装包：[http://downloads.vagrantup.com/](http://downloads.vagrantup.com/)，然后安装。

vagrant提供了很多已经打包的box，你可以去[网站](https://app.vagrantup.com/boxes/search)搜索你想要的box,例如`centos/7` 的box，可以通过`vagrant`自动下载：

~~~bash
$ mkdir centos7
$ vagrant init centos/7
~~~

也可以手动下载再添加：

~~~bash
$ wget https://github.com/CommanderK5/packer-centos-template/\
releases/download/0.7.2/vagrant-centos-7.2.box

$ vagrant box add centos7.2 vagrant-centos-7.2.box
~~~

镜像都被安装在 `~/.vagrant.d/boxes` 目录下面，可以查看安装了哪些镜像：

~~~bash
vagrant box list
centos/7          (virtualbox, 1902.01)
~~~

# 3、创建一个虚拟机

先创建一个目录：

~~~bash
$ mkdir -p ~/vagrant/centos7
~~~

初始化:

~~~bash
$ cd ~/vagrant/centos7

# 如果本地没有centos/7镜像，则第一次使用会从远程下载
$ vagrant init centos/7
A `Vagrantfile` has been placed in this directory. You are now
ready to `vagrant up` your first virtual environment! Please read
the comments in the Vagrantfile as well as documentation on
`vagrantup.com` for more information on using Vagrant.
~~~

在当前目录生成了 Vagrantfile 文件。

```bash
# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  config.vm.box = "centos/7"

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # NOTE: This will enable public access to the opened port
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine and only allow access
  # via 127.0.0.1 to disable public access
  # config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  # config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
  #   # Customize the amount of memory on the VM:
  #   vb.memory = "1024"
  # end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  # config.vm.provision "shell", inline: \<<-SHELL
  #   apt-get update
  #   apt-get install -y apache2
  # SHELL
end
```

启动虚拟机：

```bash
$ vagrant up
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Importing base box 'centos/7'...
==> default: Matching MAC address for NAT networking...
==> default: Checking if box 'centos/7' version '1902.01' is up to date...
==> default: Setting the name of the VM: centos7_default_1560316234686_30302
==> default: Fixed port collision for 22 => 2222. Now on port 2202.
==> default: Clearing any previously set network interfaces...
==> default: Preparing network interfaces based on configuration...
    default: Adapter 1: nat
==> default: Forwarding ports...
    default: 22 (guest) => 2202 (host) (adapter 1)
==> default: Booting VM...
==> default: Waiting for machine to boot. This may take a few minutes...
    default: SSH address: 127.0.0.1:2202
    default: SSH username: vagrant
    default: SSH auth method: private key
    default:
    default: Vagrant insecure key detected. Vagrant will automatically replace
    default: this with a newly generated keypair for better security.
    default:
    default: Inserting generated public key within guest...
    default: Removing insecure key from the guest if it\'s present...
    default: Key inserted! Disconnecting and reconnecting using new SSH key...
==> default: Machine booted and ready!
==> default: Checking for guest additions in VM...
    default: No guest additions were detected on the base box for this VM! Guest
    default: additions are required for forwarded ports, shared folders, host only
    default: networking, and more. If SSH fails on this machine, please install
    default: the guest additions and repackage the box to continue.
    default:
    default: This is not an error message; everything may continue to work properly,
    default: in which case you may ignore this message.
==> default: Rsyncing folder: /Users/june/vagrant/centos7/ => /vagrant
```

你会看到终端显示了启动过程，启动完成后，我们就可以用 SSH 登录虚拟机了，剩下的步骤就是在虚拟机里配置你要运行的各种环境和参数了。

```bash
$ vagrant ssh  
$ cd /vagrant  
```


```bash
$ vagrant ssh-config
Host default
  HostName 127.0.0.1
  User vagrant
  Port 2222
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  PasswordAuthentication no
  IdentityFile /Users/june/workspace/vagrant/devops/.vagrant/machines/default/virtualbox/private_key
  IdentitiesOnly yes
  LogLevel FATAL
```

>注意：vagrant将PasswordAuthentication设置为no了，这样就无法通过密码登陆，也不能设置root用户无密码登陆到其他节点，需要改成false

scp 拷贝文件到虚拟机：

``` bash
scp -i /Users/june/workspace/vagrant/devops/.vagrant/machines/default/virtualbox/private_key test.sql vagrant@192.168.56.100:~
```

# 4、Vagrantfile配置说明

Vagrant 初始化成功后，会在初始化的目录里生成一个 Vagrantfile 的配置文件，可以修改配置文件进行个性化的定制。

- `config.vm.box`：使用的镜像名称
- `config.vm.hostname`：配置虚拟机主机名
- `config.vm.network`：这是配置虚拟机网络，由于比较复杂，我们其后单独讨论
- `config.vm.synced_folder`：除了默认的目录绑定外，还可以手动指定绑定
- `config.ssh.username`：默认的用户是vagrant，从官方下载的box往往使用的是这个用户名。如果是自定制的box，所使用的用户名可能会有所不同，通过这个配置设定所用的用户名。
- `config.vm.provision`：我们可以通过这个配置在虚拟机第一次启动的时候进行一些安装配置。

## box设置

```
config.vm.box = "centos/7"
```

该名称是再使用` vagrant init` 中后面跟的名字。

## **hostname设置**

```
config.vm.hostname = "node1"
```

设置hostname非常重要，因为当我们有很多台虚拟服务器的时候，都是依靠hostname來做识别的。比如，我安装了node1、node2两台虚拟机，再启动时，我可以通过vagrant up node1来指定只启动哪一台。

## 虚拟机网络设置

Vagrant的网络连接方式有三种：
- `NAT` : 缺省创建，用于让vm可以通过host转发访问局域网甚至互联网。
- `host-only` : 只有主机可以访问vm，其他机器无法访问它。
- `bridge` : 此模式下vm就像局域网中的一台独立的机器，可以被其他机器访问。
- `forwarded_port`：端口转发

说明：

- 默认所有主机都会创建一个NAT网络作为eth0的网络，ip地址是自动分配的。

- 写了ip就是静态ip地址，没写ip就会dhcp自动分配一个地址。

- 如果写了多条网络配置，那么就是配置多个网络，服务器会自动多几个网卡。当然，默认的NAT网络的eth0还在（作为vagrant ssh命令登录使用的网络，还有yum更新的网络），自己写的配置文件，从上到下依次匹配eth1、eth2等。

配置host-only网络：

```bash
# 指定ip
config.vm.network :private_network, ip: "192.168.56.10"

# IP可以不指定，而是采用dhcp自动生成的方式
config.vm.network "private_network", type: "dhcp"
```

创建一个bridge桥接网络：

```bash
# 指定IP
config.vm.network "public_network", ip: "192.168.56.17"

#创建一个bridge桥接网络，指定桥接适配器
config.vm.network "public_network", bridge: "en0: Wi-Fi (AirPort)"

#创建一个bridge桥接网络，不指定桥接适配器
config.vm.network "public_network"
```

端口转发设置：

```bash
config.vm.network :forwarded_port, guest: 80, host: 8080
```

上面的配置把宿主机上的8080端口映射到客户虚拟机的80端口，例如你在虚拟机上使用nginx跑了一个Go应用，那么你在host上的浏览器中打开 http://localhost:8080 时，Vagrant就会把这个请求转发到虚拟机里跑在80端口的nginx服务上。不建议使用该方法，因为涉及端口占用问题，常常导致应用之间不能正常通信，建议使用Host-only和Bridge方式进行设置。

guest和host是必须的，还有几个可选属性：

- `guest_ip`：字符串，vm指定绑定的Ip，缺省为`0.0.0.0`
- `host_ip`：字符串，host指定绑定的Ip，缺省为`0.0.0.0`
- `protocol`：字符串，可选TCP或UDP，缺省为TCP

### 宿主机与虚机共享同步目录

默认宿主机**项目目录**和虚拟机下的`**/vagrant**`目录同步。

如果还想自定义共享目录，可以参照下面用法：

```
config.vm.synced_folder "宿主机目录", "虚机机目录"
    create: true|false, owner: "用户", group: "用户组"
```

-  **宿主机目录**一般是写的相对路径。相对的路径是相对的**项目根目录**。例如项目目录为test，那么宿主机目录写`"www/"`指的就是就是`test/www`目录。
-  **虚拟目录**是虚拟机上目录，一般写绝对路径。
-  **create: true|false**指的是是否在虚拟机**创建**此目录。
-  **owner: "用户", group: "用户组"**指的是指定目录的拥有者和拥有组。

```
config.vm.synced_folder "www/", "/var/www/",
  create: true, owner: "root", group: "root"
```

## 定义虚拟机节点名称

```bash
config.vm.define :mysql do |mysql_config|
# ...
end
```

表示在config配置中，定义一个名为mysql的vm配置，该节点下的配置信息命名为mysql_config； 如果该Vagrantfile配置文件只定义了一个vm，这个配置节点层次可忽略。

还可以在一个Vagrantfile文件里建立多个虚拟机，一般情况下，你可以用多主机功能完成以下任务：

```bash
Vagrant.configure("2") do |config|
 
  config.vm.define "web" do |web|
    web.vm.box = "apache"
  end
 
  config.vm.define "db" do |db|
    db.vm.box = "mysql"
  end
end
```

当定义了多主机之后，在使用vagrant命令的时候，就需要加上主机名，例如vagrant ssh web；也有一些命令，如果你不指定特定的主机，那么将会对所有的主机起作用，比如vagrant up；你也可以使用表达式指定特定的主机名，例如vagrant up /follower[0-9]/。

## 通用数据 

设置一些基础数据，供配置信息中调用。

```
app_servers = {
    :service1 => '192.168.33.20',
    :service2 => '192.168.33.21'
}
```

这里是定义一个hashmap，以key-value方式来存储vm主机名和ip地址。

## 配置信息

```bash
#指定vm的语言环境，缺省地，会继承host的locale配置
ENV["LC_ALL"] = "en_US.UTF-8" 

Vagrant.configure("2") do |config|
    # ...
end
```

参数2，表示的是当前配置文件使用的vagrant configure版本号为Vagrant 1.1+,如果取值为1，表示为Vagrant 1.0.x Vagrantfiles，旧版本暂不考虑，记住就写2即可。

## 提供者配置

```
config.vm.provider :virtualbox do |vb|
     # ...
end
```

虚机容器提供者配置，对于不同的provider，特有的一些配置，此处配置信息是针对virtualbox定义一个提供者，命名为vb，跟前面一样，这个名字随意取，只要节点内部调用一致即可。

配置信息又分为通用配置和个性化配置，通用配置对于不同provider是通用的，常用的通用配置如下：

```bash
vb.name = "centos7"
#指定vm-name，也就是virtualbox管理控制台中的虚机名称。如果不指定该选项会生成
#一个随机的名字，不容易区分。
vb.gui = true
# vagrant up启动时，是否自动打开virtual box的窗口，缺省为false
vb.memory = "1024"
#指定vm内存，单位为MB
vb.cpus = 2
#设置CPU个数
```

上面的provider配置是通用的配置，针对不同的虚拟机，还有一些的个性的配置，通过vb.customize配置来定制。

对virtual box的个性化配置，可以参考：VBoxManage modifyvm 命令的使用方法。详细的功能接口和使用说明，可以参考virtualbox官方文档。

```bash
#修改vb.name的值
v.customize ["modifyvm", :id, "--name", "mfsmaster2"]
 
#如修改显存，缺省为8M，如果启动桌面，至少需要10M，如下修改为16M：
vb.customize ["modifyvm", :id, "--vram", "16"]
 
#调整虚拟机的内存
 vb.customize ["modifyvm", :id, "--memory", "1024"]
 
#指定虚拟CPU个数
 vb.customize ["modifyvm", :id, "--cpus", "2"]
 
#增加光驱：
vb.customize ["storageattach",:id,"--storagectl", "IDE Controller",
"--port","0","--device","0","--type","dvddrive","--medium",
"/Applications/VirtualBox.app/Contents/MacOS/VBoxGuestAdditions.iso"]

#注：meduim参数不可以为空，如果只挂载驱动器不挂在iso，指定为“emptydrive”。
# 如果要卸载光驱，medium传入none即可。
# 从这个指令可以看出，customize方法传入一个json数组，按照顺序传入参数即可。
 
#json数组传入多个参数
vb.customize ["modifyvm", :id, "--name", “mfsserver3", "--memory", “2048"]
```

## 一组相同配置的vm

前面配置了一组vm的hash map，定义一组vm时，使用如下节点遍历。

```bash
#遍历app_servers map，将key和value分别赋值给app_server_name和app_server_ip
app_servers.each do |app_server_name, app_server_ip|
     #针对每一个app_server_name，来配置config.vm.define配置节点
     config.vm.define app_server_name do |app_config|
          # 此处配置，参考config.vm.define
     end
end
```

如果不想定义app_servers，下面也是一种方案：

```bash
(1..3).each do |i|
        config.vm.define "app-#{i}" do |app_config|
        app_config.vm.hostname = "app-#{i}.vagrant.internal"
        app_config.vm.provider "virtualbox" do |vb|
            vb.name = app-#{i}
        end
  end
end
```

## provision任务

你可以编写一些命令，让vagrant在启动虚拟机的时候自动执行，这样你就可以省去手动配置环境的时间了。

**脚本何时会被执行**

● 第一次执行`vagrant up`命令
● 执行`vagrant provision`命令
● 执行`vagrant reload --provision`或者`vagrant up --provision`命令
● 你也可以在启动虚拟机的时候添加`--no-provision`参数以阻止脚本被执行

**provision任务是什么？**

provision任务是预先设置的一些操作指令，格式：

```bash
config.vm.provision 命令字 json格式参数
 
config.vm.provion 命令字 do |s|
    s.参数名 = 参数值
end
```

根据任务操作的对象，provisioner可以分为：

- Shell
- File
- Ansible
- CFEngine
- Chef
- Docker
- Puppet
- Salt

根据vagrantfile的层次，分为：

- configure级：它定义在 Vagrant.configure("2") 的下一层次，形如： config.vm.provision ...

- vm级：它定义在 config.vm.define "web" do |web| 的下一层次，web.vm.provision ...

执行的顺序是先执行configure级任务，再执行vm级任务，即便configure级任务在vm定义的下面才定义。例如:

```bash
Vagrant.configure("2") do |config|
  config.vm.provision "shell", inline: "echo 1"
 
  config.vm.define "web" do |web|
    web.vm.provision "shell", inline: "echo 2"
  end
 
  config.vm.provision "shell", inline: "echo 3"
end
```

输出结果：

```html
==> default: "1"
==> default: "2"
==> default: "3"
```

**如何使用**

1、单行脚本


helloword只是一个开始，对于inline模式，命令只能在写在一行中。

单行脚本使用的基本格式：

```bash
config.vm.provision "shell", inline: "echo fendo"
```

shell命令的参数还可以写入do ... end代码块中，如下：

```bash
config.vm.provision "shell" do |s|
  s.inline = "echo hello provision."
end
```

2、内联脚本


如果要执行脚本较多，可以在Vagrantfile中指定内联脚本，在Vagrant.configure节点外面，写入命名内联脚本：

```bash
$script = <<SCRIPT
    echo I am provisioning...
    echo hello provision.
SCRIPT
```


然后，inline调用如下：

```bash
config.vm.provision "shell", inline: $script
```

3、外部脚本


也可以把代码写入代码文件，并保存在一个shell里，进行调用：

```bash
config.vm.provision "shell", path: "script.sh"
```

# 5、插件

插件安装方法：

```bash
vagrant plugin install xxxx
```

### 5.1、 vagrant-hostmanager

可以实现虚机之间用主机名互相访问，也可以实现宿主机用主机名访问虚机。

安装：

```bash
vagrant plugin install vagrant-hostmanager
```

修改Vagrantfile文件

```bash
Vagrant.configure("2") do |config|

  config.vm.box = "centos/7"
  config.hostmanager.enabled = true       # 启用hostmanager
  config.hostmanager.manage_guest = true  # 允许更新虚拟机上的文件
  config.hostmanager.manage_host = true   # 允许更新主机上的文件，需要输入密码

  config.vm.define "node1" do |v|
    v.vm.network "private_network", ip: "192.168.56.11"
    v.vm.network "public_network"
    v.vm.hostname = "node1.example.com"
  end

  config.vm.define "node2" do |v|
    v.vm.network "private_network", ip: "192.168.56.12"
    v.vm.hostname = "node2.example.com"
  end

  config.vm.define "node3" do |v|
    v.vm.network "private_network", ip: "192.168.56.13"
    v.vm.hostname = "node3.example.com"
  end

end
```

启动虚拟机以后会自动更新虚拟机的主机名，同时也会更新本地主机上的 hosts 文件里的内容。

或者我们也可以手工的去更新，执行命令：

```
vagrant hostmanager
```

返回：

```
[manager1] Updating /etc/hosts file...
[worker1] Updating /etc/hosts file...
[worker2] Updating /etc/hosts file...
```

### 5.2、vagrant-vbguest

有时候我们发现有些virtualbox无法使用自定义的共享目录，这时候就需要安装vbguest客户端（类似于VMware的client）

```bash
vagrant vbguest --status
vagrant vbguest --do install node1
vagrant vbguest --do install node2
vagrant vbguest --do install node3
vagrant vbguest --status
```

每次启动虚机都会检查vbguest插件的更新，如果不想更新，修改Vgrantfilew文件，加上这样一条：

```bash
config.vbguest.auto_update = false
```

### 5.3、vagrant-bindfs 

插件bindfs可以支持多种共享模式，如nfs，samba

命令行下输入：

```bash
vagrant plugin install vagrant-bindfs
```

修改Vgrantfile文件：

```bash
config.vm.define "node1" do |v|
  v.vm.network "private_network", ip: "192.168.56.11"
  v.vm.hostname="node1.example.com"
  v.vm.synced_folder "./app" "/mnt/app-data", type: "nfs"
  v.bindfs.bind_folder "/mnt/app-data" "/app"
    force_user: "root", force_group: "root", o: "noempty"
```

# 6、实验例子

### 6.1、搭建一个每台机器不同配置的实验环境

用自己做的镜像最好，首先是已经安装了一些常用的包，二是如果是初始镜像，一开始需要安装几个包，比较耽误时间，自己打包的镜像已经安装好了。

```bash
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Vagrant Global Config
  config.vm.box = "centos/7"
  config.vm.provision :shell, :path => "bootstrap.sh"
  
  config.vm.define "node1" do |config|
    config.vm.network "private_network", ip: "192.168.56.11"
    #添加一个桥接网络
    config.vm.network "public_network", bridge: "en0: Wi-Fi (AirPort)"
    config.vm.hostname = "server"
  end
  
  config.vm.define "node2" do |config|
    v.vm.network "private_network", ip: "192.168.56.12"
    v.vm.hostname = "node1"
  end
  
  config.vm.define "node3" do |config|
    config.vm.network "private_network", ip: "192.168.56.13"
    config.vm.hostname = "node2"
  end

end
```

bootstrap.sh：

```bash
#!/usr/bin/env bash

#root密码为root
echo 'root'|passwd root --stdin >/dev/null 2>&1
sudo yum install -y wget vim net-tools

cat > /etc/hosts <<EOF
127.0.0.1       localhost
192.168.56.11 node1 node1.example.com
192.168.56.12 node2 node2.example.com
192.168.56.13 node3 node3.example.com
EOF

# 关闭selinux
sudo setenforce 0
# 永久禁止selinux
sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
# 删除网卡的信息，否则在其他地方启动会有问题
sudo rm -rf /etc/udev/rules.d/70-persistent-net.rules

sudo echo 'GATEWAY=192.168.56.1' >> /etc/sysconfig/network-scripts/ifcfg-eth1
```

### 6.2、批量搭建一组服务器

```bash
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"
  config.vm.provision :shell, :path => "bootstrap.sh"

  (1..3).each do |i|
    config.vm.define "node#{i}" do |config|
        config.vm.provider "virtualbox" do |v|
        v.customize ["modifyvm", :id, "--name", "node#{i}", 
        "--memory", "1024",'--cpus', 1]
        v.gui = false
      end
      config.vm.network "private_network", ip: "192.168.56.1#{i}"
      config.vm.hostname = "node#{i}"
    end
  end
end
```

查看node1网卡：

```bash
$ ifconfig
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.0.2.15  netmask 255.255.255.0  broadcast 10.0.2.255
        inet6 fe80::5054:ff:fe26:1060  prefixlen 64  scopeid 0x20<link>
        ether 52:54:00:26:10:60  txqueuelen 1000  (Ethernet)
        RX packets 93  bytes 10565 (10.3 KiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 76  bytes 9099 (8.8 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

eth1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.56.11  netmask 255.255.255.0  broadcast 192.168.56.255
        inet6 fe80::a00:27ff:feff:2ad1  prefixlen 64  scopeid 0x20<link>
        ether 08:00:27:ff:2a:d1  txqueuelen 1000  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 11  bytes 836 (836.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

eth0：NAT模式

eth1：是hostonly模式

> 说明：如果需要配置一个外网ip，可以停机后在virtualbox的设置里面添加网卡3为桥接模式，然后再起到虚拟机。

**修改虚拟机网络**

删除每个节点的网卡1，并修改eth0为静态IP：

修改node1节点/etc/sysconfig/network-scripts/ifcfg-eth0：

```bash
DEVICE="eth0"
BOOTPROTO="static"
ONBOOT="yes"
TYPE="Ethernet"
PERSISTENT_DHCLIENT="yes"
IPADDR=192.168.56.11
NETMASK=255.255.255.0
```

node1节点添加一个网卡2设置为桥接模式，并行修改IP为静态IP：

```bash
$ cat /etc/sysconfig/network-scripts/ifcfg-eth1
DEVICE="eth1"
BOOTPROTO="static"
ONBOOT="yes"
TYPE="Ethernet"
PERSISTENT_DHCLIENT="yes"
IPADDR=172.20.10.8
NETMASK=255.255.255.0
```

修改node2节点/etc/sysconfig/network-scripts/ifcfg-eth0：

```bash
DEVICE="eth0"
BOOTPROTO="static"
ONBOOT="yes"
TYPE="Ethernet"
PERSISTENT_DHCLIENT="yes"
IPADDR=192.168.56.12
NETMASK=255.255.255.0
GATEWAY=192.168.56.11
```

修改node3节点/etc/sysconfig/network-scripts/ifcfg-eth0：

```bash
DEVICE="eth0"
BOOTPROTO="static"
ONBOOT="yes"
TYPE="Ethernet"
PERSISTENT_DHCLIENT="yes"
IPADDR=192.168.56.13
NETMASK=255.255.255.0
GATEWAY=192.168.56.11
```

修改完成之后，需要重启网卡：

```bash
ifdown eth0

ifup eth0
```

因为vagrant ssh`需要连接NAT网卡，故现在无法执行成功，这个时候可以这样访问：

```bash
$ ssh vagrant@192.168.56.11  -o StrictHostKeyChecking=no -o\
 UserKnownHostsFile=/dev/null -i .vagrant/machines/node1/virtualbox/private_key

$ ssh vagrant@192.168.56.12  -o StrictHostKeyChecking=no -o\
UserKnownHostsFile=/dev/null -i .vagrant/machines/node2/virtualbox/private_key

$ ssh vagrant@192.168.56.13  -o StrictHostKeyChecking=no -o\
UserKnownHostsFile=/dev/null -i .vagrant/machines/node3/virtualbox/private_key
```

配置yum源：

下载CentOS-7-x86_64-DVD-1810.iso拷贝到vagrant共享目录，在node1节点上配置yum：

```bash
mount /vagrant/CentOS-7-x86_64-DVD-1810.iso /mnt/
rm -rf /etc/yum.repos.d/*
echo "
[base]
name=CentOS
baseurl=file:///mnt/
gpgcheck=0
"  > /etc/yum.repos.d/centos7.repo

yum install vsftpd
cp -r /mnt/* /var/ftp/pub
chkconfig vsftpd on
service vsftpd start


echo "
[base]
name=CentOS
baseurl=ftp://192.168.56.11/pub/
gpgcheck=0
"  > /etc/yum.repos.d/centos7.repo
```

在node2和node3上配置centos7.repo。

# 7、参考文章

[Vagrant--快速搭建实验环境利器](https://www.jianshu.com/p/d56d42b8d97f)
---
layout: post
title: Vagrant搭建Docker开发环境
date: 2019-08-04T08:00:00+08:00
categories: [ docker ]
tags: [docker,vagrant]
description:  Vagrant搭建Docker开发环境

---



# 安装Virtual Box

Virtual Box 下载地址 [https://www.virtualbox.org/wiki/Downloads](https://yq.aliyun.com/go/articleRenderRedirect?url=https%3A%2F%2Fwww.virtualbox.org%2Fwiki%2FDownloads)

# 安装Vagrant

Vagrant 是一款可以结合 Virtual Box 进行虚拟机安装、 管理的软件，基于 Ruby ，因为已经编译为应用程序，所以可以不用安装 Ruby 环境。
Vagrant 下载地址：[https://www.vagrantup.com/downloads.html](https://yq.aliyun.com/go/articleRenderRedirect?url=https%3A%2F%2Fwww.vagrantup.com%2Fdownloads.html)，可以参考文章 [使用Vagrant创建虚拟机](/2014/02/23/create-virtualbox-by-vagrant/)

**1、添加box**

```bash
vagrant add box centos/7
```

**2、创建目录**

```bash
mkdir centos-docker
cd centos-docker
```

**3、安装centos7**

```bash
vagrant init centos/7
```

**4、启动**

```bash
vagrant up
```

**5、查看状态**

```bash
$ vargant status

Current machine states:

default                   running (virtualbox)

The VM is running. To stop this VM, you can run `vagrant halt` to
shut it down forcefully, or you can run `vagrant suspend` to simply
suspend the virtual machine. In either case, to restart it again,
simply run `vagrant up`.
```

**6、登录虚拟机**

```bash
vagrant ssh
```

**7、安装常用软件**

```bash
sudo yum install -y wget vim net-tools
```

# 安装docker

添加Docker所需依赖

```bash
sudo yum install -y yum-utils device-mapper-persistent-data lvm2 
```

添加Docker源

```bash
sudo wget -O /etc/yum.repos.d/docker-ce.repo https://download.docker.com/linux/centos/docker-ce.repo

sudo sed -i 's+download.docker.com+mirrors.cloud.tencent.com/docker-ce+' /etc/yum.repos.d/docker-ce.repo
```

安装最新的 Docker-ce

```bash
sudo yum install docker-ce -y
```

配置/etc/docker/daemon.json：

```bash
cat > /etc/docker/daemon.json <<EOF
{
    "oom-score-adjust": -1000,
    "log-driver": "json-file",
    "log-opts": {
      "max-size": "100m",
      "max-file": "3"
    },
    "bip": "172.17.10.1/24",
    "registry-mirrors": [
      "https://hub.daocloud.io",
      "https://docker.mirrors.ustc.edu.cn/",
      "https://registry.docker-cn.com"
    ],
    "graph":"/data/docker",
    "exec-opts": ["native.cgroupdriver=systemd"],
    "storage-driver": "overlay2",
    "storage-opts": [
      "overlay2.override_kernel_check=true"
    ]
}
EOF
```

开启路由转发功能：

```bash
echo 1 > /proc/sys/net/ipv4/ip_forward
```

添加内核配置参数以启用这些功能。

```
$ sudo tee -a /etc/sysctl.conf <<-EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
```

然后重新加载 `sysctl.conf` 即可

```bash
sudo sysctl -p
```



开放2375端口

编辑docker文件：/usr/lib/systemd/system/docker.service，修改ExecStart行添加"-H tcp://0.0.0.0:2375 -H unix://var/run/docker.sock"

```
sed -i '/containerd.sock.*/ s/$/ -H tcp:\/\/0.0.0.0:2375 -H unix:\/\/var\/run\/docker.sock /'  /usr/lib/systemd/system/docker.service
```

启动Docker

```bash
sudo systemctl start docker
```

设置开启启动：

```bash
sudo systemctl enable docker
```

解决权限问题

```bash
sudo groupadd docker
sudo usermod -aG docker vagrant
```

退出再登陆，查看docker版本：

```bash
$ docker version
Client: Docker Engine - Community
 Version:           19.03.1
 API version:       1.40
 Go version:        go1.12.5
 Git commit:        74b1e89
 Built:             Thu Jul 25 21:21:07 2019
 OS/Arch:           linux/amd64
 Experimental:      false

Server: Docker Engine - Community
 Engine:
  Version:          19.03.1
  API version:      1.40 (minimum version 1.12)
  Go version:       go1.12.5
  Git commit:       74b1e89
  Built:            Thu Jul 25 21:19:36 2019
  OS/Arch:          linux/amd64
  Experimental:     false
 containerd:
  Version:          1.2.6
  GitCommit:        894b81a4b802e4eb2a91d1ce216b8817763c29fb
 runc:
  Version:          1.0.0-rc8
  GitCommit:        425e105d5a03fabd737a126ad93d62a9eeede87f
 docker-init:
  Version:          0.18.0
  GitCommit:        fec3683
```

看到 Client 和 Server 都有显示，说明Docker启动正常。

运行 hello-world

```bash
$ docker run hello-world

Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
9bb5a5d4561a: Pull complete
Digest: sha256:f5233545e43561214ca4891fd1157e1c3c563316ed8e237750d59bde73361e77
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash

Share images, automate workflows, and more with a free Docker ID:
 https://hub.docker.com/

For more examples and ideas, visit:
 https://docs.docker.com/engine/userguide/
```

看到有 Hello from Docker! 输出即可证明 Docker 安装正确并能运行。

# 安装私有仓库

可以通过获取官方 `registry` 镜像来运行。

```bash
docker run -d -p 5000:5000 --restart=always --name registry registry
```

这将使用官方的 `registry` 镜像来启动私有仓库。默认情况下，仓库会被创建在容器的 `/var/lib/registry` 目录下。你可以通过 `-v` 参数来将镜像文件存放在本地的指定路径。例如下面的例子将上传的镜像放到本地的 `/opt/registry` 目录。

```bash
docker run -d \
    -p 5000:5000 \
    -v /usr/local/docker/registry:/var/lib/registry \
    --restart=always --name registry registry
```

# 安装docker-compose

在 Linux 上的也安装十分简单，从 [官方 GitHub Release](https://github.com/docker/compose/releases) 处直接下载编译好的二进制文件即可。

例如，在 Linux 64 位系统上直接下载对应的二进制包。

```bash
sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-`uname -s`-`uname -m` \
  > /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose
```

查看版本：

```bash
$ docker-compose -v
docker-compose version 1.24.1, build 6d101fb
```

# 环境打包

## 关闭虚拟机

```bash
# 退出虚拟机
exit
# 关闭虚拟机
vagrant halt
```

## 打包

```bash
# 打包
vagrant package --output centos-docker.box
```

## 添加box

```
vagrant box add centos-docker ./centos-docker.box
```

## 查看box

```bash
$ vagrant box list
centos-docker (virtualbox, 0)
centos/7      (virtualbox, 1902.01)
```

# 测试Box

## 创建VM目录，并初始化

```bash
mkdir centos-docker && cd centos-docker && vagrant init centos-docker
```

## 添加私有网络

```bash
 ...
config.vm.box = "centos-docker"
config.vm.network "private_network", ip: "192.168.56.222"
...
```

## 登录VM测试

```bash
vagrant up
```

出现错误：

```
Vagrant was unable to mount VirtualBox shared folders. This is usually
because the filesystem "vboxsf" is not available. This filesystem is
made available via the VirtualBox Guest Additions and kernel module.
Please verify that these guest additions are properly installed in the
guest. This is not a bug in Vagrant and is usually caused by a faulty
Vagrant box. For context, the command attempted was:

mount -t vboxsf -o uid=1000,gid=1000 vagrant /vagrant

The error output from the command was:

mount: unknown filesystem type 'vboxsf'
```

解决办法，参考 https://www.cnblogs.com/fengchi/p/6549784.html

可能大家在使用vagrant的时候经常遇到以上提示，这个时候只是共享目录无法使用，虚拟机已经在运行了

```
vagrant ssh # 进入虚拟机
```

更新：

```
sudo yum update -y
sudo yum install gcc kernel-devel -y
```

退出虚拟机:

```
exit
vagrant halt # 关闭虚拟机
```

再次启动：

```
vagrant up
```

在virtualbox界面加载 **VBoxGuestAdditions.iso** 镜像并挂载

该镜像位于VirtualBox安装文件夹下，可以全文件搜索

```
sudo find / -name VBoxGuestAdditions.iso 
```

将CD进行挂载

```
mkdir /cdrom
sudo mount /dev/cdrom /cdrom #(该cdrom是我在/目录下创建的文件夹)
```

进入cdrom并运行相关程序。

```
cd /cdrom
sudo sh ./VBoxLinuxAdditions.run
```

等待程序安装完毕，VirtualBox增强功能软件就在系统中安装完毕

另外一种解决方法：

```
vagrant plugin install vagrant-vbguest

vagrant reload --provision
```

## 重启虚拟机

```
vagrant up
```

这个时候再次启动，应该就不会再报这个错误了

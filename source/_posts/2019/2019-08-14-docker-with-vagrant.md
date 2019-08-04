---
layout: post
title: Vagrant搭建Docker开发环境
category: devops
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
mkdir test
cd test
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
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
```

安装最新的 Docker-ce

```bash
sudo yum install docker-ce -y
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
sudo gpasswd -a vagrant docker
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
sudo curl -L https://github.com/docker/compose/releases/download/1.24.1/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose

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

#### 添加box

```
vagrant box add centos-docker ./centos-docker.box
```

## 查看box

```bash
vagrant box list
centos-docker (virtualbox, 0)
centos/7      (virtualbox, 1902.01)
```



# 测试Box

#### 创建VM目录，并初始化

```bash
mkdir centos-docker && cd centos-docker && vagrant init centos-docker
```

#### 编辑Vagrantfile文件，添加私有网络

```bash
 ...
config.vm.box = "centos-docker"
config.vm.network "private_network", ip: "192.168.56.222"
...
```

#### 登录VM测试

```bash
vagrant up
vagrant ssh
```
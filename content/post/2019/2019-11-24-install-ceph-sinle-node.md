---
layout: post
title: 安装单节点Ceph集群
date: 2019-11-24T08:00:00+08:00
categories: [ ceph ]
tags: [ceph]
---

本文主要记录在虚拟机中安装Ceph单节点集群的过程，其实多配置几个节点，也就是安装集群的过程。

Ceph中午文档：http://docs.ceph.org.cn/

# 集群规划

集群环境：

| 主机            | IP             | 操作系统       | 软件        | 组件                  |
| --------------- | -------------- | -------------- | ----------- | --------------------- |
| k8s-rke-node001 | 192.168.56.111 | Centos7.7.1908 | Ceph 14.2.4 | ceph_deploy、OSD、MON |
| k8s-rke-node002 | 192.168.56.112 | Centos7.7.1908 | Ceph 14.2.4 | OSD、MON              |
| k8s-rke-node003 | 192.168.56.113 | Centos7.7.1908 | Ceph 14.2.4 | OSD、MON              |

安装用户：chenzj

# 准备环境

## 安装 CEPH 部署工具

把 Ceph 仓库添加到 `ceph-deploy` 管理节点，然后安装 `ceph-deploy` 。

安装包管理工具：

```bash
sudo yum install -y yum-utils 
sudo yum-config-manager --add-repo https://dl.fedoraproject.org/pub/epel/7/x86_64/  
sudo yum install --nogpgcheck -y epel-release 
sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7 
sudo rm /etc/yum.repos.d/dl.fedoraproject.org*
```

配置yum源，注意：这里ceph使用的是nautilus版本。

```bash
cat << EOF > ceph.repo
[Ceph-noarch]
name=Ceph noarch packages
baseurl=http://mirrors.163.com/ceph/rpm-nautilus/el7/noarch
enabled=1
gpgcheck=0
type=rpm-md
gpgkey=https://mirrors.163.com/ceph/keys/release.asc
priority=1
EOF

sudo mv ceph.repo /etc/yum.repos.d/
```

设置环境变量，使ceph-deploy使用163源。

```bash
export CEPH_DEPLOY_REPO_URL=https://mirrors.163.com/ceph/rpm-nautilus/el7
export CEPH_DEPLOY_GPG_URL=http://mirrors.163.com/ceph/keys/release.asc
```

更新软件库并安装 `ceph-deploy`

```bash
sudo yum update && sudo yum install ceph-deploy
```

## CEPH 节点安装

你的管理节点必须能够通过 SSH 无密码地访问各 Ceph 节点。如果 `ceph-deploy` 以某个普通用户登录，那么这个用户必须有无密码使用 `sudo` 的权限。

### 设置hosts

```bash
192.168.56.111 k8s-rke-node001
192.168.56.112 k8s-rke-node002
192.168.56.113 k8s-rke-node003
```

### 创建部署 CEPH 的用户

`ceph-deploy` 工具必须以普通用户登录 Ceph 节点，且此用户拥有无密码使用 `sudo` 的权限，因为它需要在安装软件及配置文件的过程中，不必输入密码。

在各 Ceph 节点创建新用户并设置密码。

```bash
USER=chenzj
useradd -G docker -d /home/$USER -m $USER 
echo $USER|passwd $USER --stdin >/dev/null 2>&1
```

确保各 Ceph 节点上新创建的用户都有 `sudo` 权限。

```bash
sudo echo "$USER ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$USER
sudo chmod 0440 /etc/sudoers.d/$USER
```

### 允许无密码 SSH 登录

正因为 `ceph-deploy` 不支持输入密码，你必须在管理节点上生成 SSH 密钥并把其公钥分发到各 Ceph 节点。 `ceph-deploy` 会尝试给初始 monitors 生成 SSH 密钥对。

生成 SSH 密钥对，但不要用 `sudo` 或 `root` 用户。提示 “Enter passphrase” 时，直接回车，口令即为空：

```bash
su - $USER
yes|ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ""
```

把公钥拷贝到各 Ceph 节点

```bash
ssh-copy-id $USER@k8s-rke-node001
ssh-copy-id $USER@k8s-rke-node002
ssh-copy-id $USER@k8s-rke-node003
```

修改 `ceph-deploy` 管理节点上的 `~/.ssh/config` 文件，这样 `ceph-deploy` 就能用你所建的用户名登录 Ceph 节点了，而无需每次执行 `ceph-deploy` 都要指定 `--username`

```bash
cat << EOF >> ~/.ssh/config
Host      	k8s-rke-node001
	Hostname  k8s-rke-node001
	User      $USER

Host      	k8s-rke-node002
	Hostname  k8s-rke-node002
	User      $USER

Host      	k8s-rke-node003
	Hostname  k8s-rke-node003
	User      $USER
EOF

chmod 644 ~/.ssh/config
```

### 配置时钟同步

### 设置SELINUX

在 CentOS 和 RHEL 上， SELinux 默认为 `Enforcing` 开启状态。为简化安装，我们建议把 SELinux 设置为 `Permissive` 或者完全禁用，也就是在加固系统配置前先确保集群的安装、配置没问题。用下列命令把 SELinux 设置为 `Permissive` ：

```bash
sudo setenforce 0
```

### 设置TTY

在 CentOS 和 RHEL 上执行 `ceph-deploy` 命令时可能会报错。如果你的 Ceph 节点默认设置了 `requiretty` ，执行 `sudo visudo` 禁用它，并找到 `Defaults requiretty` 选项，把它改为 `Defaults:ceph !requiretty` 或者直接注释掉，这样 `ceph-deploy` 就可以用之前创建的用户（[创建部署 Ceph 的用户](http://docs.ceph.org.cn/start/quick-start-preflight/#id3) ）连接了。

```bash
sed -i 's/Defaults *requiretty/#Defaults requiretty/g' /etc/sudoers
sed -i 's/Defaults *!visiblepw/Defaults   visiblepw/g' /etc/sudoers
```

### 安装yum-plugin-priorities

确保你的包管理器安装了优先级/首选项包且已启用。

```bash
sudo yum install yum-plugin-priorities -y
```

### 加载rbd模块

```
sudo modprobe rbd
```

# 创建集群

先在ceph-deploy管理节点上创建一个目录，用于保存 `ceph-deploy` 生成的配置文件和密钥对。

```bash
# 创建集群配置目录
mkdir ceph-cluster && cd ceph-cluster
```

`ceph-deploy` 会把文件输出到当前目录，所以请确保在此目录下执行 `ceph-deploy` 。

## 创建集群

在管理节点上，进入刚创建的放置配置文件的目录，用 `ceph-deploy` 执行如下步骤，安装规划在k8s-rke-node001节点初始化Monitor。

1、创建集群

```bash
ceph-deploy new k8s-rke-node001 \
  --public-network 192.168.56.0/24 \
  --cluster-network 192.168.56.0/24 
```

> 注意：public-network要和当前ip的网段保持对应。

2、在当前目录下用 `ls` 和 `cat` 检查 `ceph-deploy` 的输出，应该有一个 Ceph 配置文件、一个 monitor 密钥环和一个日志文件。

```bash
-rw-r--r-- 1 root root    291 9月  17 22:15 ceph.conf
-rw-r--r-- 1 root root 212100 9月  17 22:16 ceph-deploy-ceph.log
-rw------- 1 root root     73 9月  16 09:40 ceph.mon.keyring
```

3、如果出现异常：

```bash
Traceback (most recent call last):
  File "/usr/bin/ceph-deploy", line 18, in <module>
    from ceph_deploy.cli import main
  File "/usr/lib/python2.7/site-packages/ceph_deploy/cli.py", line 1, in <module>
    import pkg_resources
ImportError: No module named pkg_resources
```

安装相关依赖即可：

```bash
sudo yum install python-pkg-resources python-setuptools -y
```

4、把 Ceph 配置文件里的默认副本数从 `3` 改成 `2` ，这样只有两个 OSD 也可以达到 `active + clean` 状态。把下面这行加入 `[global]` 段：

```
echo "
osd_pool_default_size =2

[mon]
mon_allow_pool_delete = true
mon_max_pg_per_osd = 1024
#时钟同步
mon_clock_drift_allowed = 2
mon_clock_drift_warn_backoff = 30
" >> ceph.conf
```

5、通过 ceph-deploy 在各个节点安装 ceph：

```bash
ceph-deploy install k8s-rke-node001 k8s-rke-node002 k8s-rke-node003
```

6、此过程需要等待一段时间，因为 ceph-deploy 会 SSH 登录到各 node 上去，依次执行安装 ceph 依赖的组件包。

如果下载太慢，可以设置镜像：

```bash
sudo rpm --import http://mirrors.163.com/ceph/keys/release.asc
ceph-deploy install --repo-url http://mirrors.163.com/ceph/rpm-nautilus k8s-rke-node001
```

如果还是太慢，则在**每个节点配置ceph的yum源**，然后通过yum安装：

```bash
sudo yum -y install ceph ceph-radosgw
```

7、安装成功之后，检查每个节点的ceph版本是否一致：

```
sudo ceph --version
ceph version 14.2.4 (75f4de193b3ea58512f204623e6c5a16e6c1e1ba) nautilus (stable)
```

8、配置初始 monitor(s)、并收集所有密钥

```
ceph-deploy mon create-initial
```

完成上述操作后，当前目录里应该会出现这些密钥：

```
ceph.client.admin.keyring
ceph.bootstrap-mgr.keyring
ceph.bootstrap-osd.keyring
ceph.bootstrap-mds.keyring
ceph.bootstrap-rgw.keyring
ceph.bootstrap-rbd.keyring
ceph.bootstrap-rbd-mirror.keyring
```

如果出现下面异常：

```
[ceph_deploy.mon][ERROR ] Some monitors have still not reached quorum:
[ceph_deploy.mon][ERROR ] k8s-rke-node001
```

可能原因：

- ceph版本不一致
- hostname没设置正确

查看仲裁信息：

```
ceph quorum_status --format json-pretty
```

## 初始化OSD

1、添加两个 OSD 。为了快速地安装，这篇快速入门把目录而非整个硬盘用于 OSD 守护进程。如何为 OSD 及其日志使用独立硬盘或分区，请参考 [ceph-deploy osd](http://docs.ceph.org.cn/rados/deployment/ceph-deploy-osd) 。登录到 Ceph 节点、并给 OSD 守护进程创建一个目录。

```bash
ssh k8s-rke-node001 "sudo mkdir -p /data/ceph/osd"
ssh k8s-rke-node002 "sudo mkdir -p /data/ceph/osd"
ssh k8s-rke-node003 "sudo mkdir -p /data/ceph/osd"
```

然后，从管理节点执行 `ceph-deploy` 来准备 OSD 。

```
ceph-deploy osd create --data /data/ceph/osd k8s-rke-node001
ceph-deploy osd create --data /data/ceph/osd k8s-rke-node002
ceph-deploy osd create --data /data/ceph/osd k8s-rke-node003
```

查看创建的osd：

```
ceph-deploy osd list k8s-rke-node001
ceph-deploy osd list k8s-rke-node002
ceph-deploy osd list k8s-rke-node003
```



如果是想用磁盘，则必须先格式化：

```bash
sudo mkfs /dev/sdb
```

列出节点所有磁盘信息：

```bash
ceph-deploy disk list k8s-rke-node001
ceph-deploy disk list k8s-rke-node002
ceph-deploy disk list k8s-rke-node003
```

清除磁盘分区和内容：

```
ceph-deploy disk zap k8s-rke-node001 /dev/sdb
ceph-deploy disk zap k8s-rke-node002 /dev/sdb
ceph-deploy disk zap k8s-rke-node003 /dev/sdb
```

2、用 `ceph-deploy` 把配置文件和 admin 密钥拷贝到管理节点和 Ceph 节点，这样你每次执行 Ceph 命令行时就无需指定 monitor 地址和 `ceph.client.admin.keyring` 了。

```bash
ceph-deploy admin k8s-rke-node001 k8s-rke-node002 k8s-rke-node003
```

3、确保你对 `ceph.client.admin.keyring` 有正确的操作权限。

```bash
sudo chmod +r /etc/ceph/ceph.client.admin.keyring
```

4、检查集群的健康状况。

```
ceph health
```

等 peering 完成后，集群应该达到 `active + clean` 状态。

# 操作集群

用 `ceph-deploy` 部署完成后它会自动启动集群。Ceph 集群部署完成后，你可以尝试一下管理功能、 `rados` 对象存储命令，之后可以继续快速入门手册，了解 Ceph 块设备、 Ceph 文件系统和 Ceph 对象网关。

## 集群扩容

一个基本的集群启动并开始运行后，下一步就是扩展集群。在 k8s-rke-node004 上添加一个 OSD 守护进程和一个元数据服务器。然后分别在 k8s-rke-node002 和 k8s-rke-node003 上添加 Ceph Monitor ，以形成 Monitors 的法定人数。

### 添加 OSD

在 k8s-rke-node004 上添加一个 OSD：

```bash
ssh k8s-rke-node004 "sudo mkdir -p /data/ceph/osd"
ceph-deploy osd create --data /data/ceph/osd k8s-rke-node004
```

一旦你新加了 OSD ， Ceph 集群就开始重均衡，把归置组迁移到新 OSD 。可以用下面的 `ceph` 命令观察此过程：

```
ceph -w
```

你应该能看到归置组状态从 `active + clean` 变为 `active` ，还有一些降级的对象；迁移完成后又会回到 `active + clean` 状态（ Control-C 退出）。

### 添加 MONITORS

Ceph 存储集群需要至少一个 Monitor 才能运行。为达到高可用，典型的 Ceph 存储集群会运行多个 Monitors，这样在单个 Monitor 失败时不会影响 Ceph 存储集群的可用性。Ceph 使用 PASOX 算法，此算法要求有多半 monitors（即 1 、 2:3 、 3:4 、 3:5 、 4:6 等 ）形成法定人数。

k8s-rke-node002 和 k8s-rke-node003 上添加 Ceph Monitor

```
ceph-deploy mon add k8s-rke-node002
ceph-deploy mon add k8s-rke-node003
```

新增 Monitor 后，Ceph 会自动开始同步并形成法定人数。你可以用下面的命令检查法定人数状态：

```
ceph quorum_status --format json-pretty
```

- 请确保ntp时钟同步

### 添加 MDS

至少需要一个元数据服务器才能使用 CephFS ，执行下列命令创建元数据服务器：

```
ceph-deploy mds create k8s-rke-node001
```

>注意：
>
>当前生产环境下的 Ceph 只能运行一个元数据服务器。

### 添加 RGW 例程

要使用 Ceph 的 [*Ceph 对象网关*](http://docs.ceph.org.cn/glossary/#term-34)组件，必须部署 [*RGW*](http://docs.ceph.org.cn/glossary/#term-rgw) 例程。用下列方法创建新 RGW 例程：

```
ceph-deploy rgw create k8s-rke-node001
```

[*RGW*](http://docs.ceph.org.cn/glossary/#term-rgw) 例程默认会监听 7480 端口，可以更改该节点 ceph.conf 内与 [*RGW*](http://docs.ceph.org.cn/glossary/#term-rgw) 相关的配置，如下：

```bash
[client]
rgw frontends = civetweb port=80
```

浏览器访问：http://192.168.56.111:7480

## 操作数据

要把对象存入 Ceph 存储集群，客户端必须做到：

1. 指定**对象名**
2. 指定**存储池**

Ceph 客户端检出最新集群运行图，用 CRUSH 算法计算出如何把对象映射到**归置组**，然后动态地计算如何把归置组分配到 OSD 。要定位对象，只需要对象名和存储池名字即可，例如：

```bash
ceph osd map {poolname} {object-name}
```

作为练习，我们先创建一个对象，用 `rados put` 命令加上对象名、一个有数据的测试文件路径、并指定存储池。例如：

```bash
echo {Test-data} > testfile.txt
rados put {object-name} {file-path} --pool=data
rados put test-object-1 testfile.txt --pool=data
```

为确认 Ceph 存储集群存储了此对象，可执行：

```bash
rados -p data ls
```

现在，定位对象：

```bash
ceph osd map {pool-name} {object-name}
ceph osd map data test-object-1
```

Ceph 应该会输出对象的位置，例如：

```bash
osdmap e537 pool 'data' (0) object 'test-object-1' -> pg 0.d1743484 (0.4) -> up [1,0] acting [1,0]
```

用``rados rm`` 命令可删除此测试对象，例如：

```bash
rados rm test-object-1 --pool=data
```

随着集群的运行，对象位置可能会动态改变。 Ceph 有动态均衡机制，无需手动干预即可完成。
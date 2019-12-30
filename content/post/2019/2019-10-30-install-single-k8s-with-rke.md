---
layout: post
title: 使用RKE安装单节点kubernetes
date: 2019-10-30T08:00:00+08:00
categories: [ kubernetes ]
tags: [kubernetes]
---



Kubernetes 是Google的一种基于容器的开源服务编排解决方案。在我们进行Kubernetes的学习前，为了对Kubernetes的工作原理有一个大概的认识，我们需要先安装一个单节点的实例服务，用于平常的开发与测试。由于本地环境内存有限，所以只能在虚拟机里面使用单节点安装。



# 环境准备

## 创建虚拟机

使用Vagrant创建一个虚拟机，关于Vagrant的使用，本文不做说明。



创建一个k8s-rke-single目录，编写Vagrantfile内容如下：

```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "centos7"
  config.vm.box_check_update = false

  (1..1).each do |i|
    config.vm.define vm_name="k8s-rke-node00#{i}" do |node|
      node.vm.provider "virtualbox" do |v|
        v.customize ["modifyvm", :id, "--name", vm_name, "--memory", "4096",'--cpus', 2]
        v.gui = false
      end
      ip = "192.168.56.11#{i}"
      node.vm.network "private_network", ip: ip
      node.vm.hostname = vm_name
      #node.vm.provision :shell, :path => "setup_system.sh", args: [ip,vm_name]
      #node.vm.provision :shell, :path => "setup_k8s.sh"
      #node.vm.provision :shell, :path => "setup_rancher.sh"
      #node.vm.provision :shell, :path => "setup_ceph.sh"
      #node.vm.provision "shell", privileged: false, path: "post_setup_k8s.sh"
    end
  end
end
```

注意：

- 我使用的是centos7操作系统，centos7是Vagrant的box名称，可以替换成其他的。
- 这里是创建一个虚拟机，虚拟机名称为k8s-rke-node001，内存分配4G，CPU安装k8s要求的至少为2。
- 使用私有网络，固定IP为192.168.56.111。注意：在虚拟机创建之后，该IP会绑定的eth1网卡，eth0网卡绑定是Vagrant创建NAT网络。

## 设置虚拟机

### 设置root密码

```bash
echo 'root'|passwd root --stdin >/dev/null 2>&1
```

### 设置hosts

```bash
cat > /etc/hosts <<EOF
192.168.56.111 k8s-rke-node001
EOF
```

### 设置hostname

```bash
hostnamectl set-hostname k8s-rke-node001
cat > /etc/sysconfig/network<<EOF
HOSTNAME=$(hostname)
EOF
```

### 关闭selinux

```bash
setenforce 0  >/dev/null 2>&1
sed -i -e 's/^SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
sed -i -e 's/^SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
```

### 关闭防火墙

```bash
systemctl stop firewalld.service && systemctl disable firewalld.service
yum -y install iptables-services  && systemctl start iptables  \
	&&  systemctl enable iptables&& iptables -F && service iptables save
```

### 配置时区

```bash
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
timedatectl set-timezone Asia/Shanghai
timedatectl set-local-rtc 0

systemctl restart crond
```

### 禁用邮件服务

```bash
systemctl stop postfix && systemctl disable postfix
```

### 优化设置 journal 日志相关

优化设置 journal 日志相关，避免日志重复搜集，浪费系统资源

```bash
sed -ri 's/^\$ModLoad imjournal/#&/' /etc/rsyslog.conf
sed -ri 's/^\$IMJournalStateFile/#&/' /etc/rsyslog.conf

sed -ri 's/^#(DefaultLimitCORE)=/\1=100000/' /etc/systemd/system.conf
sed -ri 's/^#(DefaultLimitNOFILE)=/\1=100000/' /etc/systemd/system.conf

systemctl restart systemd-journald
systemctl restart rsyslog
```

### 配置系统语言

```bash
sudo echo 'LANG="en_US.UTF-8"' >> /etc/profile && source /etc/profile
```

### 禁用fastestmirror插件

```bash
sed -i 's/^enabled.*/enabled=0/g' /etc/yum/pluginconf.d/fastestmirror.conf
sed -i 's/^plugins.*/plugins=0/g' /etc/yum.conf
```

### 安装常用软件

```bash
yum install -y curl
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
curl -s -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
sed -i -e '/aliyuncs/d' /etc/yum.repos.d/CentOS-Base.repo
curl -k -s -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
yum install -y wget vim ntp yum-utils git expect
```

### 设置时钟同步

```bash
sed -i "/^server/ d" /etc/ntp.conf
echo "
#在与上级时间服务器联系时所花费的时间，记录在driftfile参数后面的文件
driftfile /var/lib/ntp/drift
#默认关闭所有的 NTP 联机服务
restrict default ignore
restrict -6 default ignore
#如从loopback网口请求，则允许NTP的所有操作
restrict 127.0.0.1
restrict -6 ::1
#使用指定的时间服务器
server ntp1.aliyun.com
#允许指定的时间服务器查询本时间服务器的信息
restrict ntp1.aliyun.com nomodify notrap nopeer noquery
#其它认证信息
includefile /etc/ntp/crypto/pw
keys /etc/ntp/keys
" > /etc/ntp.conf

systemctl start ntpd
systemctl enable ntpd

echo '* */6 * * * /usr/sbin/ntpdate -u ntp1.aliyun.com&&/sbin/hwclock --systohc > /dev/null 2>&1' \
	>>/var/spool/cron/root
```

### 设置命名服务

```bash
echo "nameserver 114.114.114.114" | tee -a /etc/resolv.conf
```

### 加载内核模块

```bash
lsmod | grep br_netfilter
modprobe br_netfilter
```

### 关闭NOZEROCONF

```bash
sed -i 's/^NOZEROCONF.*/NOZEROCONF=yes/g' /etc/sysconfig/network
```

更改系统网络接口配置文件，设置该网络接口随系统启动而开启

```bash
sed -i -e '/^HWADDR=/d' -e '/^UUID=/d' /etc/sysconfig/network-scripts/ifcfg-eth0
sed -i -e 's/^ONBOOT.*$/ONBOOT=yes/' /etc/sysconfig/network-scripts/ifcfg-eth0
sed -i -e 's/^NM_CONTROLLED.*$/NM_CONTROLLED=no/' /etc/sysconfig/network-scripts/ifcfg-eth0
```

### 设置内核参数

```bash
cat > kubernetes.conf <<EOF
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1

#ip转发
net.ipv4.ip_nonlocal_bind = 1
net.ipv4.ip_forward = 1
# 开启重用。允许将TIME-WAIT sockets重新用于新的TCP连接，默认为0，表示关闭；
net.ipv4.tcp_tw_reuse = 1
#开启TCP连接中TIME-WAIT sockets的快速回收，默认为0，表示关闭
net.ipv4.tcp_tw_recycle=0
net.ipv4.neigh.default.gc_thresh1=4096
net.ipv4.neigh.default.gc_thresh2=6144
net.ipv4.neigh.default.gc_thresh3=8192
net.ipv4.neigh.default.gc_interval=60
net.ipv4.neigh.default.gc_stale_time=120

#配置网桥的流量
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.netfilter.nf_conntrack_max=2310720

vm.swappiness=0
vm.overcommit_memory=1
vm.panic_on_oom=0

fs.inotify.max_user_instances=8192
fs.inotify.max_user_watches=1048576
fs.file-max=52706963
fs.nr_open=52706963
EOF
cp kubernetes.conf /etc/sysctl.d/kubernetes.conf
sysctl -p /etc/sysctl.d/kubernetes.conf
```

如果kube-proxy使用ipvs的话为了防止timeout需要设置下tcp参数：

```bash
# https://github.com/moby/moby/issues/31208 
# ipvsadm -l --timout
# 修复ipvs模式下长连接timeout问题 小于900即可
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 10
```

docker官方的内核检查脚本建议`(RHEL7/CentOS7: User namespaces disabled; add 'user_namespace.enable=1' to boot command line)`,使用下面命令开启

```bash
grubby --args="user_namespace.enable=1" --update-kernel="$(grubby --default-kernel)"
```

### 设置文件最大打开数

```bash
cat>/etc/security/limits.d/kubernetes.conf<<EOF
*       soft    nproc   131072
*       hard    nproc   131072
*       soft    nofile  131072
*       hard    nofile  131072
root    soft    nproc   131072
root    hard    nproc   131072
root    soft    nofile  131072
root    hard    nofile  131072
EOF
```

### 关闭交换空间

```bash
swapoff -a && sed -i '/swap/s/^/#/' /etc/fstab
sed -i '/ \/ .* defaults /s/defaults/defaults,noatime,nodiratime,nobarrier/g' /etc/fstab
sed -i 's/tmpfs.*/tmpfs\t\t\t\/dev\/shm\t\ttmpfs\tdefaults,nosuid,noexec,nodev 0 0/g' /etc/fstab
```

### 解决透明大页面问题

```bash
echo "echo never > /sys/kernel/mm/redhat_transparent_hugepage/defrag" >/etc/rc.local
echo "echo never > /sys/kernel/mm/redhat_transparent_hugepage/enabled" >/etc/rc.local
```

### 设置sudo

关闭远程sudo执行命令需要输入密码和没有终端不让执行命令问题

```bash
sed -i 's/Defaults *requiretty/#Defaults requiretty/g' /etc/sudoers
sed -i 's/Defaults *!visiblepw/Defaults   visiblepw/g' /etc/sudoers
```

### 设置ssh

```bash
sed -i '/PasswordAuthentication/s/^/#/'  /etc/ssh/sshd_config
sed -i 's/^[ ]*StrictHostKeyChecking.*/StrictHostKeyChecking no/g' /etc/ssh/ssh_config
#禁用sshd服务的UseDNS、GSSAPIAuthentication两项特性
sed -i -e 's/^#UseDNS.*$/UseDNS no/' /etc/ssh/sshd_config
sed -i -e 's/^GSSAPIAuthentication.*$/GSSAPIAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd
```

### 生成ssh私钥和公钥

```bash
[ ! -d ~/.ssh ] && ( mkdir ~/.ssh )
[ ! -f ~/.ssh/id_rsa.pub ] && (yes|ssh-keygen -f ~/.ssh/id_rsa -t rsa -N "")
( chmod 600 ~/.ssh/id_rsa.pub ) && cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
```

### 关闭NUMA

```bash
sed -i 's/rhgb quiet/rhgb quiet numa=off/g' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub
```

### 升级内核到4.44

```bash
sudo rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-4.el7.elrepo.noarch.rpm
sudo yum --enablerepo=elrepo-kernel install -y kernel-lt kernel-lt-devel 
sudo awk -F\' '$1=="menuentry " {print i++ " : " $2}' /etc/grub2.cfg
sudo grub2-set-default 0
sudo sed -i 's/GRUB_DEFAULT=saved/GRUB_DEFAULT=0/g' /etc/default/grub
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
reboot

#重启后，删除3.10内核
#sudo rpm -qa | grep kernel
#sudo yum remove kernel*-3.10*
#sudo yum --enablerepo=elrepo-kernel install -y kernel-lt-headers
```

# 安装docker

## 检查系统内核和模块

检查系统内核和模块是否适合运行 docker (仅适用于 linux 系统)

```bash
curl -s https://raw.githubusercontent.com/docker/docker/master/contrib/check-config.sh > check-config.sh
bash ./check-config.sh
```

现在docker存储驱动都是使用的overlay2(不要使用devicemapper，这个坑非常多)，我们重点关注overlay2是否不是绿色

## 安装Docker-ce

```bash
yum install -y yum-utils device-mapper-persistent-data lvm2

wget -O /etc/yum.repos.d/docker-ce.repo https://download.docker.com/linux/centos/docker-ce.repo
sudo sed -i 's+download.docker.com+mirrors.cloud.tencent.com/docker-ce+' /etc/yum.repos.d/docker-ce.repo

yum install docker-ce -y
```

## 启动Docker

```bash
systemctl enable docker && systemctl start docker
```

## 修改配置文件

### `registry-mirrors`

Docker镜像：

1. [Daocloud](https://www.daocloud.io/mirror#accelerator-doc)，具体用法见网站。
2. [中科大](http://mirrors.ustc.edu.cn/help/dockerhub.html)，具体用法见网站。

### `dns`

Docker内置了一个DNS Server，它用来做两件事情：

1. 解析docker network里的容器或Service的IP地址
2. 把解析不了的交给外部DNS Server解析（`dns`参数设定的地址）

默认情况下，`dns`参数值为Google DNS nameserver：`8.8.8.8`和`8.8.4.4`。我们得改成国内的DNS地址，比如：

1. `1.2.4.8`
2. 阿里DNS：`223.5.5.5`和`223.6.6.6`
3. 114DNS：`114.114.114.114`和`114.114.115.115`

比如：

```json
{
  "dns": ["223.5.5.5", "223.6.6.6"]
}
```

### `log-driver`

[Log driver](https://docs.docker.com/config/containers/logging/configure/)是Docker用来接收来自容器内部`stdout/stderr`的日志的模块，Docker默认的log driver是[JSON File logging driver](https://docs.docker.com/config/containers/logging/json-file/)。这里只讲`json-file`的配置，其他的请查阅相关文档。

`json-file`会将容器日志存储在docker host machine的`/var/lib/docker/containers//-json.log`（需要root权限才能够读），既然日志是存在磁盘上的，那么就要磁盘消耗的问题。下面介绍两个关键参数：

1. `max-size`，单个日志文件最大尺寸，当日志文件超过此尺寸时会滚动，即不再往这个文件里写，而是写到一个新的文件里。默认值是-1，代表无限。
2. `max-files`，最多保留多少个日志文件。默认值是1。

根据服务器的硬盘尺寸设定合理大小，比如：

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-files":"5"
  }
}
```

### `cgroup driver`

根据文档[CRI installation](https://kubernetes.io/docs/setup/cri/)中的内容，对于使用systemd作为init system的Linux的发行版，使用systemd作为docker的cgroup driver可以确保服务器节点在资源紧张的情况更加稳定，因此这里修改各个节点上docker的cgroup driver为systemd。

```bash
"exec-opts": ["native.cgroupdriver=systemd"]
```

### `storage-driver`

Docker推荐使用[overlay2](https://docs.docker.com/storage/storagedriver/overlayfs-driver/#configure-docker-with-the-overlay-or-overlay2-storage-driver)作为Storage driver。你可以通过`docker info | grep Storage`来确认一下当前使用的是什么：

```bash
$ docker info | grep 'Storage'
Storage Driver: overlay2
```

如果结果不是overlay2，那你就需要配置一下了：

```json
{
  "storage-driver": "overlay2"
}
```

创建或修改`/etc/docker/daemon.json`：

```bash
cat > /etc/docker/daemon.json <<EOF
{
    "oom-score-adjust": -1000,
    "log-driver": "json-file",
    "log-opts": {
      "max-size": "100m",
      "max-file": "5"
    },
    "bip": "172.17.10.1/24",
    "registry-mirrors": ["https://hub.daocloud.io","http://hub-mirror.c.163.com/",
      "https://docker.mirrors.ustc.edu.cn/",
      "https://registry.docker-cn.com"],
    "graph":"/data/docker",
    "exec-opts": ["native.cgroupdriver=systemd"],
    "storage-driver": "overlay2",
    "storage-opts": [
      "overlay2.override_kernel_check=true"
    ]
}
EOF

sed -i '/containerd.sock.*/ s/$/ -H tcp:\/\/0.0.0.0:2375 -H unix:\/\/var\/run\/docker.sock /' \
	/usr/lib/systemd/system/docker.service
```

防止FORWARD的DROP策略影响转发,给docker daemon添加下列参数修正，当然暴力点也可以`iptables -P FORWARD ACCEPT`

```bash
mkdir -p /etc/systemd/system/docker.service.d/
cat>/etc/systemd/system/docker.service.d/10-docker.conf<<EOF
[Service]
ExecStartPost=/sbin/iptables -I FORWARD -s 0.0.0.0/0 -j ACCEPT
ExecStopPost=/bin/bash -c '/sbin/iptables -D FORWARD -s 0.0.0.0/0 -j ACCEPT &> /dev/null || :'
EOF
```



## 重新加载配置

```bash
systemctl enable --now docker
systemctl daemon-reload && systemctl restart docker
```

如果enable docker的时候报错开启debug，如何开见 https://github.com/zhangguanzhang/Kubernetes-ansible/wiki/systemctl-running-debug

# 安装k8s

## 下载RKE

rke当前发布列表 https://github.com/rancher/rke/releases ，这里下载最新的

```bash
curl -s -L -o /usr/local/bin/rke \
	https://github.com/rancher/rke/releases/latest/download/rke_linux-amd64

sudo chmod 777 /usr/local/bin/rke
```

## 配置yum源

```bash
cat <<EOF > kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
  http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

sudo mv kubernetes.repo /etc/yum.repos.d/
sudo yum install kubectl -y
```

## 创建非root用户

实际生产环境不允许用root用户操作，故创建一个普通用户chenzj

```bash
USER=chenzj

useradd -G docker $USER
echo $USER|passwd $USER --stdin >/dev/null 2>&1
echo "$USER ALL=(ALL) ALL" >> /etc/sudoers
chown $USER:docker /var/run/docker.sock
```

## 配置无密码登陆

```bash
sudo -u $USER ssh-keygen -f /home/$USER/.ssh/id_rsa -t rsa -N ""
sudo -u $USER ./ssh_nopassword.expect $(hostname) $USER $USER
```

这里用到了一个脚本ssh_nopassword.expect：

```bash
#! /usr/bin/expect -f

set host [lindex $argv 0]
set user [lindex $argv 1]
set password [lindex $argv 2]

spawn ssh-copy-id -i /home/$user/.ssh/id_rsa.pub $user@$host
expect {
yes/no  {send "yes\r";exp_continue}
-nocase "password:" {send "$password\r"}
}
expect eof
```

## k8s docker镜像

### gcr.io/google-containers

使用[中科大的镜像](https://github.com/ustclug/mirrorrequest/issues/187)

```
docker pull image gcr.io/google-containers/xxx:yyy
或
docker pull image gcr.io/google_containers/xxx:yyy
=>
docker pull image gcr.mirrors.ustc.edu.cn/google-containers/xxx:yyy
```

也可以使用[anjia0532的搬运仓库](https://github.com/anjia0532/gcr.io_mirror)

### k8s.gcr.io

k8s.gcr.io等价于gcr.io/google-containers，因此同上可以使用中科大镜像或者anjia0532的搬运仓库。

使用[中科大的镜像](https://github.com/ustclug/mirrorrequest/issues/187)

```
docker pull image k8s.gcr.io/xxx:yyy
=>
docker pull image gcr.mirrors.ustc.edu.cn/google-containers/xxx:yyy
```

使用[anjia0532的搬运仓库](https://github.com/anjia0532/gcr.io_mirror)

### quay.io

使用[中科大的镜像](https://github.com/ustclug/mirrorrequest/issues/135)

```
docker pull image quay.io/xxx/yyy:zzz
=>
docker pull image quay.mirrors.ustc.edu.cn/xxx/yyy:zzz
```

## 创建RKE配置文件

RKE使用群集配置文件，称为cluster.yml确定群集中的节点以及如何部署Kubernetes。有许多配置选项，可以在设置cluster.yml。

有两种简单的方法可以创建`cluster.yml`：

- 使用最小值[ cluster.yml](https://rancher.com/docs/rke/latest/en/example-yamls/#minimal-cluster-yml-example) 并根据实际情况进行编辑。
- 使用`rke config`来查询所需的所有信息。

查看RKE支持的K8S版本：

```bash
rke config --system-images --all |grep version
```

可以查看某一个k8s版本依赖的系统镜像，然后手动下载：

```bash
$ rke config --system-images --version v1.16.2-rancher1-1
rancher/coreos-etcd:v3.3.15-rancher1
rancher/rke-tools:v0.1.50
rancher/k8s-dns-kube-dns:1.15.0
rancher/k8s-dns-dnsmasq-nanny:1.15.0
rancher/k8s-dns-sidecar:1.15.0
rancher/cluster-proportional-autoscaler:1.7.1
rancher/coredns-coredns:1.6.2
rancher/hyperkube:v1.16.2-rancher1
rancher/coreos-flannel:v0.11.0-rancher1
rancher/flannel-cni:v0.3.0-rancher5
rancher/calico-node:v3.8.1
rancher/calico-cni:v3.8.1
rancher/calico-kube-controllers:v3.8.1
rancher/calico-pod2daemon-flexvol:v3.8.1
rancher/coreos-flannel:v0.11.0
weaveworks/weave-kube:2.5.2
weaveworks/weave-npc:2.5.2
rancher/pause:3.1
rancher/nginx-ingress-controller:nginx-0.25.1-rancher1
rancher/nginx-ingress-controller-defaultbackend:1.5-rancher1
rancher/metrics-server:v0.3.4
```

获取最新的支持的kubernetes版本：

```bash
kubernetes_version=`rke config --system-images --all|grep rancher/hyperkube|awk -F ':' '{print $2}'|sort -n|tail -n 1`
```

切换到普通用户chenzj，创建RKE配置文件cluster.yml

```bash
su - $USER

mkdir -p install/k8s && cd install/k8s
cat > cluster.yml <<EOF
nodes:
  - address: 192.168.56.111
    user: $USER
    role: [controlplane,etcd,worker]

services:
  etcd:
    snapshot: true
    creation: 6h
    retention: 24h
  kube-api:
    service_cluster_ip_range: 10.43.0.0/16
    service_node_port_range: 30000-32767
  kubelet:
    cluster_domain: cluster.local
    cluster_dns_server: 10.43.0.10
    fail_swap_on: false
    extra_args:
      max-pods: 100

cluster_name: k8s-test
kubernetes_version: "${kubernetes_version}"
network:
    plugin: calico
EOF
```

注意：

- 这里是创建一个节点，所以该节点具有三种角色：controlplane、etcd、worker
- kubernetes版本指定的是 v1.16.2-rancher1-1，可以通过下面命令查看当前RKE支持的kubernetes版本，如果没有找到你想要的版本，可以升级RKE版本。
- RKE支持Kubernetes集群HA方式部署，您可以在cluster.yml文件中指定多个controlplane节点。RKE将在这些节点上部署master组件，并且kubelet配置为默认连接127.0.0.1:6443，这是nginx-proxy代理向所有主节点请求的服务的地址

## 创建集群

在创建集群

```bash
rke up --config cluster.yml
```

在安装过程中，RKE会自动生成一个kube_config_cluster.yml与RKE二进制文件位于同一目录中的配置文件。此文件很重要，它可以在Rancher Server故障时，利用kubectl通过此配置文件管理Kubernetes集群。复制此文件将其备份到安全位置。

## 与Kubernetes集群的交互

为了开始与Kubernetes集群进行交互，需要在本地计算机上安装kubectl。

```bash
# sudo 没权限，手动创建
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg 
  http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

yum install kubectl -y
```

RKE会在配置文件所在的目录下部署一个本地文件，该文件中包含kube配置信息以连接到新生成的群集。默认情况下，kube配置文件被称为kube_config_cluster.yml。将这个文件复制到你的本地~/.kube/config，就可以在本地使用kubectl了。

```bash
mkdir ~/.kube/
cp kube_config_cluster.yml ~/.kube/config
```

需要注意的是，部署的本地kube配置名称是和集群配置文件相关的。例如，如果您使用名为mycluster.yml的配置文件，则本地kube配置将被命名为.kube_config_mycluster.yml。

## 查看集群状态

查看集群上下文：

```bash
$ kubectl config get-contexts
CURRENT   NAME               CLUSTER         AUTHINFO            NAMESPACE
*         k8s-test  			 k8s-test  		 kube-admin-k8s-test
```

查看集群配置视图：

```bash
$ kubectl config view
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: DATA+OMITTED
    server: https://192.168.1.113:6443
  name: k8s-test
contexts:
- context:
    cluster: k8s-test
    user: kube-admin-k8s-test
  name: k8s-test
current-context: k8s-test
kind: Config
preferences: {}
users:
- name: kube-admin-k8s-test
  user:
    client-certificate-data: REDACTED
    client-key-data: REDACTED
```

查看集群信息：

```bash
$ kubectl cluster-info
Kubernetes master is running at https://192.168.56.111:6443
CoreDNS is running at https://192.168.56.111:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

查看节点信息：

```
kubectl get nodes
NAME             STATUS   ROLES                      AGE    VERSION
192.168.56.111   Ready    controlplane,etcd,worker   122m   v1.16.2
```

查看所有：

```bash
kubectl get all  -A
```

查看pod状态：

```bash
$ kubectl get pods -A
NAMESPACE       NAME                                       READY   STATUS      RESTARTS   AGE
ingress-nginx   default-http-backend-67cf578fc4-d9mrp      1/1     Running     0          5m25s
ingress-nginx   nginx-ingress-controller-xlr9f             1/1     Running     0          5m25s
kube-system     calico-kube-controllers-569544ddbd-5844j   1/1     Running     0          123m
kube-system     calico-node-hp6jx                          1/1     Running     0          123m
kube-system     coredns-5c59fd465f-5nx9c                   1/1     Running     0          5m36s
kube-system     coredns-autoscaler-d765c8497-gq8hn         1/1     Running     0          5m35s
kube-system     metrics-server-64f6dffb84-srcct            1/1     Running     0          5m31s
kube-system     rke-coredns-addon-deploy-job-xklhm         0/1     Completed   0          5m37s
kube-system     rke-ingress-controller-deploy-job-pps2m    0/1     Completed   0          5m27s
kube-system     rke-metrics-addon-deploy-job-9xh4t         0/1     Completed   0          5m32s
kube-system     rke-network-plugin-deploy-job-88nnb        0/1     Completed   0          123m
```

pod的状态只有Running、Completed两种状态为正常状态，若有其他状态则需要查看pod日志：

```
kubectl logs rke-ingress-controller-deploy-job-2vmvp -n kube-system
```

可以看到RKE创建了ingress：

```bash
kubectl describe pod -n ingress-nginx default-http-backend-67cf578fc4-d9mrp 
kubectl describe pod -n ingress-nginx nginx-ingress-controller-xlr9f 
```

## 测试集群DNS是否可用

```bash
kubectl run curl --image=radial/busyboxplus:curl -it
```

进入后执行`nslookup kubernetes.default`确认解析正常:

```bash
nslookup kubernetes.default
```

## 设置Bash自动完成

```bash
sudo yum install -y bash-completion 

echo "Configure Kubectl to autocomplete"

source /usr/share/bash-completion/bash_completion
source <(kubectl completion bash) #
echo 'source <(kubectl completion bash)' >> ~/.bashrc
```

# 集群调优

参考 https://www.rancher.cn/docs/rancher/v2.x/cn/install-prepare/best-practices/

# 删除集群

```bash
rke remove

# 删除每个节点所有容器
docker rm -f `docker ps -qa`

# 删除每个节点所有容器卷
docker volume rm `docker volume ls -q`
#cmd.sh 'docker volume rm `docker volume ls -q`'

# 卸载每个节点mount目录
for mount in $(sudo mount | grep tmpfs | grep '/var/lib/kubelet' | awk '{ print $3 }') ; do 
sudo umount $mount; 
done
 
# 删除残留路径
sudo rm -rf ~/.kube/ /etc/cni \
  /opt/cni \
  /run/secrets/kubernetes.io \
  /run/calico \
  /run/flannel \
  /var/lib/calico \
  /var/lib/cni \
  /var/lib/kubelet \
  /var/log/containers \
  /var/log/pods \
  /var/run/calico

# 清理网络接口
network_interface=`ls /sys/class/net`
for net_inter in $network_interface;
do
	if ! echo $net_inter | grep -qiE 'lo|docker0|eth*|ens*';then
		sudo ip link delete $net_inter
	fi
done

# 清理残留进程
port_list='80 443 6443 2376 2379 2380 8472 9099 10250 10254'

for port in $port_list
do
pid=`netstat -atlnup|grep $port|awk '{print $7}'|awk -F '/' '{print $1}'|grep -v -|sort -rnk2|uniq`
	if [[ -n $pid ]];then
		sudo kill -9 $pid
	fi
done

pro_pid=`ps -ef |grep -v grep |grep kube|awk '{print $2}'`

if [[ -n $pro_pid ]];then
	sudo kill -9 $pro_pid
fi

# 清理Iptables表
## 注意：如果节点Iptables有特殊配置，以下命令请谨慎操作
sudo iptables --flush
sudo iptables --flush --table nat
sudo iptables --flush --table filter
sudo iptables --table nat --delete-chain
sudo iptables --table filter --delete-chain

systemctl restart docker 
```

另外，清理docker镜像：

```bash
#删除虚悬镜像
docker image prune --force

#删除Rancher中指定版本的镜像
version="v0.1.42|v2.2.8|v2.3.1|v2.3.0|v3.4.0|v3.7.4|v0.10.0|v0.11.0|v1.15.3-rancher1|v3.3.10-rancher1|1.6.1|1.9.1|1.10.0-rc2"
docker rmi $(docker images|grep -E ${version} | awk '{ print $3}')

docker rmi $(docker images |grep -E 'hello-world|minio-minio|wordpress|postgresq|tomcat|maven|dev/ads|tiller' | awk '{ print $3}')

```

删除自动创建的pvc的rbd块：

```bash
rbd list k8s

#rbd rm k8s/kubernetes-dynamic-pvc-2bca2c25-549d-4512-846d-167052bfed75
```

# 升级K8S

升级RKE：

```bash
curl -s -L -o /usr/local/bin/rke \
	https://github.com/rancher/rke/releases/latest/download/rke_linux-amd64

sudo chmod 777 /usr/local/bin/rke
```

查看RKE支持的K8S版本：

```bash
rke config --system-images --all |grep version
```

修改cluster.yml文件中kubernetes的版本号：

```yaml
nodes:
  - address: 192.168.56.111
    user: chenzj
    port: 22
    role: [controlplane,etcd,worker]

services:
  etcd:
    snapshot: true
    creation: 6h
    retention: 24h
  kube-api:
    service_cluster_ip_range: 10.43.0.0/16
    service_node_port_range: 30000-32767
  kubelet:
    cluster_domain: cluster.local
    cluster_dns_server: 10.43.0.10
    fail_swap_on: false
    extra_args:
      max-pods: 100

cluster_name: k8s-test
kubernetes_version: "v1.16.3-rancher1-1"
network:
    plugin: calico
```

然后执行下面命令：

```bash
rke up --config cluster.yml
```

# 原生K8S参数

参考 https://www.rancher.cn/docs/rancher/v2.x/cn/install-prepare/k8s-parameter/

# 总结

以上是使用RKE安装单节点k8s的记录，其实稍加修改配置文件，就可以安装集群。

这里，我把上面的所有命令整理了一下，提交到了 [github](https://github.com/javachen/vagrant/tree/master/k8s-rke-single)，供大家参考。

# 参考文章

- [应大多数人要求写下kubeadm的基础使用](https://zhangguanzhang.github.io/2019/11/24/kubeadm-base-use/)
---
layout: post
title: 一些有用的Docker镜像
date: 2019-12-26T08:00:00+08:00
categories: [ docker ]
tags: [docker]
---

## 1、watchtower：自动更新 Docker 容器

Watchtower 监视运行容器并监视这些容器最初启动时的镜像有没有变动。当 Watchtower 检测到一个镜像已经有变动时，它会使用新镜像自动重新启动相应的容器。我想在我的本地开发环境中尝试最新的构建镜像，所以使用了它。

Watchtower 本身被打包为 Docker 镜像，因此可以像运行任何其他容器一样运行它。要运行 Watchtower，你需要执行以下命令：

```
docker run -d --name watchtower --rm -v /var/run/docker.sock:/var/run/docker.sock  v2tec/watchtower --interval 30
```

在上面的命令中，我们使用一个挂载文件 /var/run/docker.sock 启动了 Watchtower 容器。这么做是有必要的，为的是使 Watchtower 可以与 Docker 守护 API 进行交互。我们将 30 秒传递给间隔选项 interval。此选项定义了 Watchtower 的轮询间隔。Watchtower 支持更多的选项，你可以根据文档中的描述来使用它们。

我们现在启动一个 Watchtower 可以监视的容器。

```
docker run -p 4000:80 --name friendlyhello shekhargulati/friendlyhello:latest
```

现在，Watchtower 将开始温和地监控这个 friendlyhello 容器。当我将新镜像推送到 Docker Hub 时，Watchtower 在接下来的运行中将检测到一个新的可用的镜像。它将优雅地停止那个容器并使用这个新镜像启动容器。它将传递我们之前传递给这条 run 命令的选项。换句话说，该容器将仍然使用 4000:80 发布端口来启动。

默认情况下，Watchtower 将轮询 Docker Hub 注册表以查找更新的镜像。通过传递环境变量 REPO_USER 和 REPO_PASS 中的注册表凭据，可以将 Watchtower 配置为轮询私有注册表。

GitHub 地址 ：https://github.com/v2tec/watchtower

## 2、docker-gc：容器和镜像的垃圾回收

Docker-gc 工具通过删除不需要的容器和镜像来帮你清理 Docker 主机。它会删除存在超过一个小时的所有容器。此外，它还删除不属于任何留置容器的镜像。

```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -e DRY_RUN=1 spotify/docker-gc
```

上述命令中，我们加载了 docker.sock 文件，以便 docker-gc 能够与 Docker API 交互。我们传递了一个环境变量 DRY_RUN=1 来查找将被删除的容器和镜像。如果不提供该参数，docker-gc 会删除所有容器和镜像。最好事先确认 docker-gc 要删除的内容。

如果你认同 docker-gc 清理方案， 可以不使用 DRY_RUN 再次运行 docker-gc 执行清空操作。

```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock spotify/docker-gc
```

GitHub 地址：https://github.com/spotify/docker-gc

## 3、docker-slim：镜像瘦身

如果你担心你的 Docker 镜像的大小，docker-slim 可以帮你排忧解难。

下载安装：

- [Latest Mac binaries](https://downloads.dockerslim.com/releases/1.26.1/dist_mac.zip)
- [Latest Linux binaries](https://downloads.dockerslim.com/releases/1.26.1/dist_linux.tar.gz)
- [Latest Linux ARM binaries](https://downloads.dockerslim.com/releases/1.26.1/dist_linux_arm.tar.gz)



使用示例：

```bash
git clone https://github.com/docker-slim/examples.git

cd examples/node_ubuntu

docker build -t my/sample-node-app .

sudo docker-slim build my/sample-node-app

# 如果镜像没有暴露一个web端口，则添加 --http-probe=false
# sudo docker-slim build my/sample-node-app --http-probe=false

# 可选
# curl http://<YOUR_DOCKER_HOST_IP>:<PORT>

docker images

docker run -it --rm -p 8080:8000 my/sample-node-app.slim
```

## 4、ctop：容器监控工具

安装：

Linux：

```
sudo wget https://github.com/bcicen/ctop/releases/download/v0.7.2/ctop-0.7.2-linux-amd64 -O /usr/local/bin/ctop
sudo chmod +x /usr/local/bin/ctop
```

 OS X：

```
brew install ctop
```

或者

```
sudo curl -Lo /usr/local/bin/ctop https://github.com/bcicen/ctop/releases/download/v0.7.2/ctop-0.7.2-darwin-amd64
sudo chmod +x /usr/local/bin/ctop
```

Docker：

```
docker run --rm -ti \
  --name=ctop \
  --volume /var/run/docker.sock:/var/run/docker.sock:ro \
  quay.io/vektorlab/ctop:latest
```

`ctop` is also available for Arch in the [AUR](https://aur.archlinux.org/packages/ctop-bin/)

一旦完成安装，就可以开始使用 ctop 了。现在，你只需要配置 DOCKER_HOST 环境变量。



使用docker方式运行：

```bash
docker run --rm -ti   --name=ctop   --volume /var/run/docker.sock:/var/run/docker.sock:ro   quay.io/vektorlab/ctop:latest
```

看到内容：

![image-20191226104538150](https://tva1.sinaimg.cn/large/006tNbRwly1ga9xikzapjj31r207ugmy.jpg)

你可以运行 ctop 命令，查看所有容器的状态。

GitHub 地址：https://github.com/bcicen/ctop



## 参考文章

- [推荐5款好用的开源Docker工具丨编程兵器谱](https://mp.weixin.qq.com/s?__biz=MzI5ODQ2MzI3NQ==&mid=2247488650&idx=1&sn=1422e3c661d01e98008bf)


---
layout: post
title: Git配置和一些常用命令
date: 2013-12-27T00:00:00+08:00
description: Git是一个分布式版本控制／软件配置管理软件，原来是linux内核开发者林纳斯·托瓦兹（Linus Torvalds）为了更好地管理linux内核开发而创立的。本文主要记录我的一些git配置和一些常用命令。
hadoop: [devops]
tags: [git]
---

Git是一个分布式版本控制／软件配置管理软件，原来是linux内核开发者林纳斯·托瓦兹（Linus Torvalds）为了更好地管理linux内核开发而创立的。

# Git配置

~~~bash
git config --global user.name "javachen"
git config --global user.email "junecloud@163.com"
git config --global color.ui true
git config --global alias.co checkout
git config --global alias.ci commit
git config --global alias.st status
git config --global alias.br branch
git config -l  # 列举所有配置
~~~

用户的git配置文件在`~/.gitconfig`，我的配置：


~~~bash
$ cat .gitconfig 
[user]
	email = junecloud@163.com
	name = javachen
[color]
    ui = auto
[color "branch"]
    current = yellow reverse
    local = yellow
    remote = green
[color "diff"]
    meta = yellow bold
    frag = magenta bold
    old = red bold
    new = green bold
[color "status"]
    added = yellow
    changed = green
    untracked = cyan
[alias]
    st = "status"
    co = checkout
    ls = "ls-files"
    ci = commit
    br = branch
    rt = reset --hard
    unstage = reset HEAD
    uncommit = reset --soft HEAD^
    l = log --pretty=oneline --abbrev-commit --graph --decorate
    amend = commit --amend 
    who = shortlog -n -s --no-merges 
    g = grep -n --color -E 
    cp = cherry-pick -x 
    cb = checkout -b 
[core]
    filemode = true
~~~

# Git常用命令


## 查看、帮助命令

~~~bash
git help <command>  # 显示command的help
git show            # 显示某次提交的内容
git show $id
~~~

## 查看提交记录

~~~bash
git log
git log <file>      # 查看该文件每次提交记录
git log -p <file>   # 显示版本历史，以及版本间的内容差异
git log -p -2       # 查看最近两次详细修改内容的diff
git log --stat      # 查看提交统计信息
git log --since="6 hours"  # 显示最近6小时提交
git log --before="2 days"  # 显示2天前提交
git log -1 HEAD~3          # 显示比HEAD早3个提交的那个提交
git log -1 HEAD^^^

git log Branch1 ^Branch2 #commit历史中显示Branch1有的，但是Branch2没有commit

#展示简化的 commit 历史
git log --pretty=oneline --graph --decorate --all

#通过 grep 查找，given-text：所需要查找的字段
git log --all --grep='<given-text>'
#查询字符串
git grep 'admin'

git reflog				   # 查看操作记录

git blame <file-name> #查看某段代码是谁写的

git status --ignored #展示忽略的文件#

git shortlog -sn #统计每个人提交的次数

git whatchanged --since="2 weeks ago"
~~~

# 修改文件

~~~bash
git add <file>      # 将工作文件修改提交到本地暂存区
git add .           # 将所有修改过的工作文件提交暂存区

git add -p 					# 交互式选择部分修改
~~~

~~~bash
git co  -- <file>   # 抛弃工作区修改
git co  .           # 抛弃工作区修改
git co HEAD <file>  # 抛弃工作目录区中文件的修改
git co HEAD~3       # 回退三个版本
~~~

~~~bash
git ci <file>
git ci .
git ci -a           # 将git add, git rm和git ci等操作都合并在一起做
git ci -am "some comments"
git ci --amend      # 修改最后一次提交记录
git ci --amend --author='Author Name <email@address.com>' #修改作者名
~~~

~~~bash
git rm <file>       		# 从版本库中删除文件
git rm <file> --cached  # 从版本库中删除文件，但不删除文件
~~~

~~~bash
git mv <file1>  <file2>    # 重命名文件
~~~

~~~bash
git reset --hard origin/master #回到远程仓库的状态
git reset --hard  HEAD^ # 恢复最近一次提交过的状态，即放弃上次提交后的所有本次修改
git reset --hard <commit id>  # 恢复到某一次提交的状态
git reset HEAD <file> # 抛弃暂存区中文件的修改
git reset <file>    # 从暂存区恢复到工作文件
git reset -- .      # 从暂存区恢复到工作文件

git reset –soft HEAD~3  #回退至三个版本之前，只回退了commit的信息，暂存区和工作区与回退之前保持一致。如果还要提交，直接commit即可 
~~~

~~~bash
git revert <$id>    # 恢复某次提交的状态，恢复动作本身也创建了一次提交对象
git revert HEAD     # 恢复最后一次提交的状态
~~~

```bash
#把所有的改动都重新放回工作区，并清空所有的 commit，这样就可以重新提交第一个 commit 了
git update-ref -d HEAD
```



## 查看文件diff

~~~bash
git diff <file>     # 比较当前文件和暂存区文件差异
git diff
git diff <$id1> <$id2>   	# 比较两次提交之间的差异
git diff <branch1> <branch2>   # 在两个分支之间比较 
git diff --staged   # 比较暂存区和版本库差异
git diff --cached   # 比较暂存区和版本库差异
git diff --stat     # 仅仅比较统计信息
git diff HEAD 	#输出工作区、暂存区和本地最近的版本的不同

git diff "@{yesterday}"     # 查看昨天的改变
git diff 1b6d "master~2"    # 查看一个特定版本与倒数第二个变更之间的改变
~~~

# 分支管理

## 查看、切换、创建和删除分支

~~~bash
git br -r           # 查看远程分支
git br -v           # 查看各个分支最后提交信息
git br -a           # 列出所有分支
git br --merged     # 查看已经被合并到当前分支的分支
git br --no-merged  # 查看尚未被合并到当前分支的分支
git br <new_branch> # 基于当前分支创建新的分支
git br <new_branch>  <start_point>		# 基于另一个起点（分支名称，提交名称或则标签名称），创建新的分支
git br -m <new-branch-name>	#重命名本地分支
git br -f <existing_branch>  <start_point>	# 创建同名新分支，覆盖已有分支
git br -d <branch>  # 删除某个分支
git br -D <branch>  # 强制删除某个分支 (未被合并的分支被删除的时候需要强制)

git branch -vv 			#展示本地分支关联远程仓库的情况

#删除远程分支
git push origin --delete <branch>
git push origin :<branch>

#删除已经合并到 master 的分支
git branch --merged master | grep -v '^\*\|  master' | xargs -n 1 git branch -d
~~~

切换分支：

~~~bash
git co -							# 快速切换分支
git co <branch>     	# 切换到某个分支
git co -b <new_branch> 	# 创建新的分支，并且切换过去
git co -b <new_branch> <branch>  	  # 基于branch创建新的new_branch
git co -m <existing_branch> <new_branch>  # 移动或重命名分支，当新分支不存在时
git co -M <existing_branch> <new_branch>  # 移动或重命名分支，当新分支存在时就覆盖

git co $id         		 # 把某次历史提交记录checkout出来，但无分支信息，切换到其他分支会自动删除
git co $id -b <new_branch>       # 把某次历史提交记录checkout出来，创建成一个分支
~~~

## 分支合并和rebase

~~~bash
git merge <branch>                  # 将branch分支合并到当前分支
git merge origin/master --no-ff     # 不要Fast-Foward合并，这样可以生成merge提交
git merge --no-commit <branch>      # 合并但不提交
git merge --squash <branch>         # 把一条分支上的内容合并到另一个分支上的一个提交

git rebase master <branch>          # 将master rebase到branch，相当于：
git co <branch> && git rebase master && git co master && git merge <branch>
~~~

## Git补丁管理

~~~bash
git diff > ../sync.patch         # 生成补丁
git apply ../sync.patch          # 打补丁
git apply --check ../sync.patch  # 测试补丁能否成功
git format-patch -X              # 根据提交的log生成patch，X为数字，表示最近的几个日志

git diff --name-only --diff-filter=U | uniq  | xargs $EDITOR  #一次性查看所有冲突文件
~~~

## Git暂存管理

~~~bash
git stash                        # 暂存
git stash list                   # 列所有stash
git stash apply                  # 恢复暂存的内容
git stash drop                   # 删除暂存区

git stash -u										 # 储藏未跟踪的文件
git stash -p 										 # 交互式的处理储藏中文件的每个部分
~~~

## Git远程分支管理

拉取分支：

~~~bash
git pull                         # 抓取远程仓库所有分支更新并合并到本地
git pull --no-ff                 # 抓取远程仓库所有分支更新并合并到本地，不要快进合并
git fetch origin                 # 抓取远程仓库所有更新
git fetch origin remote-branch:local-branch #抓取remote-branch分支的更新
git fetch origin --tags 		 # 抓取远程上的所有分支
git checkout -b <new-branch> <remote_tag> # 抓取远程上的分支
git merge origin/master          # 将远程主分支合并到本地当前分支
git co --track origin/branch     # 跟踪某个远程分支创建相应的本地分支
git co -b <local_branch> origin/<remote_branch>  # 基于远程分支创建本地分支，功能同上
~~~

推送分支：

~~~bash
git push                         # push所有分支
git push origin master           # 将本地主分支推到远程主分支
git push -u origin master        # 将本地主分支推到远程(如无远程主分支则创建，用于初始化远程仓库)
git push origin <local_branch>   # 创建远程分支， origin是远程仓库名
git push origin <local_branch>:<remote_branch>  # 创建远程分支
git push origin :<remote_branch>  #先删除本地分支(git br -d <branch>)，然后再push删除远程分支
~~~

## Git远程仓库管理

~~~bash
git remote -v                    # 查看远程服务器地址和仓库名称
git remote show origin           # 查看远程服务器仓库状态
git remote add origin git@github:XXX/test.git         # 添加远程仓库地址
git remote set-url origin git@github.com:XXX/test.git # 设置远程仓库地址(用于修改远程仓库地址)
git remote rm <repository>       # 删除远程仓库
git remote set-head origin master   # 设置远程仓库的HEAD指向master分支

git branch --set-upstream master origin/master
git branch --set-upstream develop origin/develop
~~~

# 标签管理

## 列出标签

```bash
git tag

git tag -l 'v1.8.5*'

#展示当前分支的最近的 tag
git describe --tags --abbrev=0

#查看标签详细信息
git tag -ln
```



## 创建标签

```bash
#附注标签
git tag -a v1.4 -m "my version 1.4"

#轻量标签
git tag v1.4

#后期打标签
git log --pretty=oneline
15027957951b64cf874c3557a0f3547bd83b3ff6 Merge branch 'experiment'
a6b4c97498bd301d84096da251c98a07c7723e65 beginning write support

git tag -a v1.2 a6b4c9
```



## 推送标签

```bash
git push origin v1.5

#强制推送，覆盖远程的
git push origin -f v1.5

git push origin --tags
```

## 删除标签

```bash
#删除本地
git tag -d v1.4

#强制删除，如果本地有
git tag -d v1.4

#删除远程
git push origin :refs/tags/v1.4
```

## 检出标签

```bash
git checkout v2.0.0

#在“分离头指针”状态下，如果你做了某些更改然后提交它们，标签不会发生变化，但你的新提交将不属于任何分支，并且将无法访问，除非确切的提交哈希。因此，如果你需要进行更改——比如说你正在修复旧版本的错误——这通常需要创建一个新分支：
git checkout -b version2 v2.0.0
```



# Git 提交规范

先来看看公式：

```shell
<type>(<scope>): <subject>
```

type
用于说明 commit 的类别，只允许使用下面 7 个标识。

> - feat：新功能（feature）
> - fix：修补 bug
> - docs：文档（documentation）
> - style： 格式（不影响代码运行的变动）
> - refactor：重构（即不是新增功能，也不是修改 bug 的代码变动）
> - test：增加测试
> - chore：构建过程或辅助工具的变动

scope

> 用于说明 commit 影响的范围，比如数据层、控制层、视图层等等，视项目不同而不同。

subject

> - 是 commit 目的的简短描述，不超过 50 个字符。
> - 以动词开头，使用第一人称现在时，比如 change，而不是 changed 或 changes
> - 第一个字母小写
> - 结尾不加句号 (.)
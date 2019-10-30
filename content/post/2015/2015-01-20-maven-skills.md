---
layout: post

title: Maven的一些技巧
date: 2015-01-20T08:00:00+08:00

categories: [ java ]

tags: [ java,maven ]

description: 本文主要收集一些 Maven 的使用技巧，包括 Maven 常见命令、创建多模块项目、上传本地 jar 到插件以及常用的插件等等，本篇文章会保持不停的更新。

published: true

---

本文主要收集一些 Maven 的使用技巧，包括 Maven 常见命令、创建多模块项目、上传本地 jar 到插件以及常用的插件等等，本篇文章会保持不停的更新。

# 创建 maven 项目

~~~bash
$ mvn archetype:generate -DgroupId=com.javachen -DartifactId=spark-examples -DarchetypeArtifactId=maven-archetype-quickstart -DinteractiveMode=false
~~~

Maven安装本地jar到本地仓库，举例：

~~~bash
$ mvn install:install-file -DgroupId=com.gemstone.gemfire -DartifactId=gfsh -Dversion=6.6 -Dpackaging=jar -Dfile=/backup/gfsh-6.6.jar
~~~

# 解决m2e插件maven-dependency-plugin问题：

~~~xml
<build>
    <pluginManagement>
        <plugins>
            <plugin>
                <groupId>org.eclipse.m2e</groupId>
                <artifactId>lifecycle-mapping</artifactId>
                <version>1.0.0</version>
                <configuration>
                    <lifecycleMappingMetadata>
                        <pluginExecutions>
                            <pluginExecution>
                                <pluginExecutionFilter>
                                    <groupId>org.apache.maven.plugins</groupId>
                                    <artifactId>maven-dependency-plugin</artifactId>
                                    <versionRange>[2.0,)</versionRange>
                                    <goals>
                                        <goal>copy-dependencies</goal>
                                    </goals>
                                </pluginExecutionFilter>
                                <action>
                                    <ignore />
                                </action>
                            </pluginExecution>
                        </pluginExecutions>
                    </lifecycleMappingMetadata>
                </configuration>
            </plugin>
        </plugins>
    </pluginManagement>

    <plugins>
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-dependency-plugin</artifactId>
            <executions>
                <execution>
                    <id>copy-dependencies</id>
                    <phase>package</phase>
                    <goals>
                        <goal>copy-dependencies</goal>
                    </goals>
                    <configuration>
                        <outputDirectory>${project.build.directory}/lib</outputDirectory>
                        <excludeTransitive>false</excludeTransitive>
                        <stripVersion>true</stripVersion>
                    </configuration>
                </execution>
            </executions>
        </plugin>
    </plugins>
</build>
~~~

# 使用Maven构建多模块项目

创建system-parent目录，然后在该目录下执行：

    mvn archetype:generate -DgroupId=com.javachen -DartifactId=system-parent -DarchetypeArtifactId=maven-archetype-quickstart -DinteractiveMode=false

将src文件夹删除，然后修改pom.xml文件，将`<packaging>jar</packaging>`修改为`<packaging>pom</packaging>`，pom表示它是一个被继承的模块，修改后的内容如下：


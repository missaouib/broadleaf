---
layout: post

title: Maven的一些技巧

category: java

tags: [ java,maven ]

description: 本文主要收集一些 Maven 的使用技巧，包括 Maven 常见命令、创建多模块项目、上传本地 jar 到插件以及常用的插件等等，本篇文章会保持不停的更新。

published: true

---

本文主要收集一些 Maven 的使用技巧，包括 Maven 常见命令、创建多模块项目、上传本地 jar 到插件以及常用的插件等等，本篇文章会保持不停的更新。

命令行创建 maven 项目：

~~~bash
$ mvn archetype:generate -DgroupId=com.javachen.spark -DartifactId=spark-examples -DarchetypeArtifactId=maven-archetype-quickstart -DinteractiveMode=false
~~~

Maven安装本地jar到本地仓库，举例：

~~~bash
$ mvn install:install-file -DgroupId=com.gemstone.gemfire -DartifactId=gfsh -Dversion=6.6 -Dpackaging=jar -Dfile=/backup/gfsh-6.6.jar
~~~

解决m2e插件maven-dependency-plugin问题：

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

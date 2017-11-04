---
layout: post
title: Ant 打包 Android 应用
date: 2013-11-16
categories: blog
tags: [iOS]
description: Ant 打包 Android 应用

---

测试环境： Mac 使用工具：命令行

### 安装Java环境

下载[jdk6.0][1]。下载完后，把bin文件添加执行权限：

    chmod +x jdk6.bin
    

执行自动安装程序

    ./jdk6.bin
    

配置jdk环境变量

    vi /etc/profile
    export JAVA_HOME=/opt/jdk1.6.0_38
    export PATH=$JAVA_HOME/bin:$PATH
    export CLASSPATH=$JAVA_HOME/lib
    

刷新profile文件，使修改立即生效

    source /etc/profile
    

测试：

java -version

### 安装Android开发环境

下载 [android sdk][2]，选择 Linux 32 & 64-bit

    wget http://dl.google.com/android/android-sdk_r22.0.1-linux.tgz
    

解压安装

    tar xzvf   android-sdk_r22.0.1-linux.tgz
    

配置环境变量：

    vi etc/profile
    export ANDROID_HOME=/opt/android/android-sdk-linux
    export  PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
    source /etc/profile
    

更新android 开发环境：

    // 显示可以被安装的包
    android list sdk
    
    android update sdk --no-ui --filter 1,2,37,tools,platform-tool,add-on,extra,doc
    

执行adb，如果出错，有可能是因为android是在32位机器上开发的，linux64环境缺少相关配置。根据出错提示，安装相应的包（root 权限执行）

    yum whatprovides ld-linux.so.2
    yum install glibc-2.12-1.107.el6.i686
    

测试开发环境：

    android create project --target 4 --name test --path .  --activity test --package com.motnt.test
    android update project -t 4 -p .
    

### 安装ant，自动打包

在官网下载最新的ant，如果已经安装了，确保已经更新到最新的版本：

    // 移除旧版本的ant
    yum -y remove ant
    

配置ant环境变量

    vi /etc/profile
    export ANT_HOME=/opt/ant/apache-ant-1.9.1
    export PATH=$PATH::$ANT_HOME/bin
    source /etc/profile
    

测试ant：

    ant -version
    

这时，你还可以进入你android工程所在的目录下，执行

    ant debug
    

等待执行完成，如果出现 “BUILD SUCCESSFUL” 字样，说明打包成功

### 打包发布版本

在你的主工程目录下，创建一个 ant.properties文件，填入类似下面的信息：

    key.store=/home/test/app/your_project_key
    key.alias=name
    key.store.password=(实际密码)
    key.alias.password=(实际密码)
    

其中第一行指定了我们项目的keystore文件的路径，至于如何生成自己项目的keystore，可以google一下。

最后，编译 release版本的项目：

    // 导航到android项目的主工程目录下（我们可能会有一些第三方的library，单独一个工程，但这些不是主工程目录）
    cd ./main_project
    // 如果你修改了项目的某些文件，可以在编译之前，先清理项目工程
    ant clean > /dev/null
    ant release
    

最后，在bin目录下，可以找到 .apk 文件

 [1]: http://download.java.net/jdk6/6u38/promoted/b04/binaries/jdk-6u38-ea-bin-b04-linux-amd64-31_oct_2012.bin?q=download/jdk6/6u38/promoted/b04/binaries/jdk-6u38-ea-bin-b04-linux-amd64-31_oct_2012.bin
 [2]: http://developer.android.com/sdk/index.html
---
layout: post
title: Jenkins 编译包含Watch OS2 App Target的应用时报错
date: 2016-06-05
categories: blog
tags: [iOS]
description: Jenkins 的错

---

## 错误重现

我们使用Jenkins 来进行我们的代码集成编译，当应用内添加了 Watch OS2 App的支持时，提交上去的代码会编译失败。失败提示如下：

![](http://images2015.cnblogs.com/blog/406864/201607/406864-20160704102405421-603382803.png)

找不到 Watch App。


## 错误分析

我们发现其实是编译出来了，只是路径没有找对。分析我们的编译脚本：

    xcodebuild -scheme ${SCHEME_NAME} -workspace test.workspace -configuration ${CONFIGURATION_MODE} clean build CONFIGURATION_BUILD_DIR=$(PWD)/build

我们指定了 CONFIGURATION_BUILD_DIR ，但是编译器并没有按照我们的设置到该目录下寻找编译好的 Watch App 产物，而是到：

    xxx/test-ios/build/Build/Products/Debug-watchos/test watch.app  

去寻找我们的构建产物，看来问题应该出在jenkins的设置上。

## 解决

如下链接指明了问题的所在，解决方法就是，抛弃CONFIGURATION_BUILD_DIR，使用 SYMROOT来指定编译路径。

但是这样其它编译出来的产物会跑到 SYMROOT/Debug-iphoneos/下 (Release 和 Test版下目录会不同)，如果你要收集奔溃信息的，还需
要到这个目录下拷贝相应的.dSYM 和 .app 文件保存，也算是瑕疵吧。

https://forums.developer.apple.com/thread/15202
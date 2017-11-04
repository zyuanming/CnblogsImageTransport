---
layout: post
title: Failed to install WatchKit App, error:Application Verification Failed
date: 2015-07-13
categories: blog
tags: [iOS]
description: 写不是义务，写本身就是写的报酬。

---

> 本文翻译自[Failed to install WatchKit App, error: Application Verification Failed][1]

![](http://images2015.cnblogs.com/blog/406864/201509/406864-20150913110408387-1655507888.png)

WatchKit 刚发布没有多久，它的文档还非常少。这样有好也有坏，并因祸得福得使我对这方面的知识挖得比平时更深，学到了也许我不会学到的知识。

我之前遇到一个问题，就是用xcrun 命令而不是使用Xcode的 Archive和导出功能来打包一个iOS 和 WatchKit 包到一个  .ipa格式的安装文件中。有可能到头来你也会遇到这种情况，那就是在你的Apple Watch 设备上安装你的WatchKit app 时，会弹出以下的错误信息：

     'Failed to install WatchKit App, error:
    Application Verification Failed'.

你获取不到任何的堆栈信息，没有控制台输出.... 这种情况就变得非常特殊了。

我的情形是在这个特定的工程中，使用一些花哨的构建脚本来自动进行Archived，签名和导出app。这在团队中似乎是一个共同的过程，让整个团队能够更深入地控制他们的持续集成。

### xcode-build

这个xcode-build 命令是用来编译Xcode 项目并生出一个 .app 后缀的文件。你不能把这个 .app 的文件直接分发，因为这个文件没有包含任何的 provision profiles 文件或者开发者的证书。

### xrun

当Xcode 项目被编译到一个 .app 文件后，xcrun 命令就是用来把这个 .app文件打包进一个 .ipa 文件中。这个 .ipa文件包括了前面的那个 .app文件以及 provision profiles 文件和开发者证书，这个 .ipa文件就可以安装到用户 的iOS 设备上了。

## WatchKitSupport/ WK Required

直到现在我才意识到，一个 .ipa 包在任何时候都必须有一个固定的内存结构：

    /Payload/
    /Payload/Application.app
    /WatchKitSupport/WK


### /Payload/

这个目录包含了你的 .app文件，这个 .app文件本身包含了所有你的iOS 应用的资源， .xibs, .plist 。

### /Payload/MyApp.app/Plugins

这个目录下包含了一个 `MyApp_WatchKitExtension.appex` 文件，它本身包含了所有你的WatchKit extension 扩展的资源。

### /Payload/MyApp.app/Plugins/MyApp_WatchKitExtension.appex/

这个目录下包含了一个 `MyApp_WatchKitApp.app` 文件，它本身包含了所有你的WatchKit App（不是extension 扩展）相关的文件，例如Storyboards，Assets和以及一切在你的Watch 设备上存活的资源。 它同时也包含了 WatchKit Extension 的可执行文件。


### /WatchKitSupport/

无文档。 应用如果提供一个 WatchKit 应用，那么就需要这个WatchKitSupport目录以及这个目录里面的一个WK 二进制文件

## xcrun vs Xcode

知道这些后，我对比了xcrun 命令和 Xcode自带的Archive和导出功能所生成的文件目录。

### Xcode

    /Payload/
    /Payload/Application.app
    /WatchKitSupport/WK

### xcrun

    /Payload/
    /Payload/Application.app

然后我发现了一个苹果工程师在 [开发者论坛][2] 上发表的一篇帖子，无意中描述了xcrun 无法支持打包一个提供 WatchKit 应用的 .ipa 包。他和[Kassem Wridan][3]的解决方法似乎是唯一的解决方法了。

这肯定不是一个永久性的解决问题的方法，对我来说，这是一个[提交bug报告][4]的绝佳机会。如果你读到这篇文章，你也应该这么做，希望在个问题有一天会修复。


## 更新

在最新的 Xcode 7 beta版中，已经修复了这个问题。太好了。


[1]: http://phillfarrugia.com/2015/06/01/xcrun-watchkit/
[2]:https://devforums.apple.com/message/1119973#1119973
[3]:http://www.matrixprojects.net/p/watchkit-command-line-builds
[4]:https://openradar.appspot.com/radar?id=5021668984487936

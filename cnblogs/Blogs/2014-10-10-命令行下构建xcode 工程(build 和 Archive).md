---
layout: post
title: 命令行下构建xcode 工程(build 和 Archive)
date: 2014-10-10
categories: blog
tags: [图像]
description: 命令行下构建xcode 工程(build 和 Archive)

---

## mac 10.9 以前的做法

* * *

1、首先需要解锁mac 系统的keychain 工具，然后导入签名证书：

    // 解锁钥匙串
    security unlock-keychain -p password "$HOME/Library/Keychains/login.keychain" 
    
    // -k 指定证书导入到登录钥匙串中
    // -P 导入证书时，需要的密码（是导出这个p12格式的证书时输入的密码）
    // -A 表示允许任何应用程序访问导入的密钥，不提示警告信息（不安全，不推荐！）
    security import $basepath/$p12File -k ~/Library/Keychains/login.keychain -P password -A
    

如果想了解更多关于这个security import 和 unlock-keychain 命令的参数，可以在命令行中，输入：

    security unlock-keychain -h
    security import -h
    

2、构建我们的app

    // 清理工程
    xcodebuild clean 
    
    // $2变量是证书的名称，注意，不是证书文件的名字，而是证书名字
    // $3变量是MobileProvision配置文件对应的UUID
    xcodebuild -target yooke -configuration Release build PLATFORM_NAME=iphoneos \
        BUILDSDK=/Developer-SDK8 CODE_SIGN_IDENTITY="$2" PROVISIONING_PROFILE="$3"
    

关于获取UUID和证书名称的，可参考我的另一篇文章《[Xcode 运行时配置][1]》

3、对生成的app文件，重新签名，并导出ipa格式的文件

    // $mpFile变量是MobileProvision配置文件所在的路径，比如：/tmp/yooke.mobileprovision
    xcrun -sdk iphoneos PackageApplication -v  $basepath/build/Release-iphoneos/"$4".app \
        -o  $basepath/build/Release-iphoneos/"$4".ipa --sign "$2" --embed $mpFile
    

4、如果你每次打包时都需要不同的证书，可能你会想要删除一些证书：

    // $2同上
    security delete-certificate -c "$2" login.keychain
    

## mac 10.10 后可行的做法（当然，兼容前面的系统版本）

* * *

在mac os 10.10，需要使用另外的方法创建ipa。如果你继续执行上面的命令，你会得到：

![][2]

mac os 10.10不支持通过.app文件中的ResourcesRule.plist文件获取相关的打包资源，因为这个文件压根没有被build进.app文件里。这里我们通过生成xcarchive文件，再从这个文件中导出ipa包

1、跟上面的第一步一样，这里就不多说了。

2、构建xcarchive文件（指定签名文件和配置文件）

    // 指定生成 test.xcarchive 文件
    xcodebuild -scheme yooke archive -archivePath /tmp/test.xcarchive \
        -configuration Release build PLATFORM_NAME=iphoneos   BUILDSDK=/Developer-SDK8 \
        CODE_SIGN_IDENTITY="$2" PROVISIONING_PROFILE="$3"
    

3、通过这个xcarchive文件，签名并导出ipa文件

    // -exportWithOriginalSigningIdentity 参数表示使用这个xcarchive文件内部的签名证书和配置文件重新签名
    // 当然你可以通过 -exportProvisioningProfile 指定配置文件名称
    // 通过 -exportSigningIdentity 指定签名证书 （注意，两者都不是指文件的名称，而是内部的名称）
    xcodebuild -exportArchive -exportFormat ipa -archivePath /tmp/test.xcarchive \
        -exportPath /tmp/test.ipa -exportWithOriginalSigningIdentity
    

如果你想了解更多的关于xcodebuild 命令的信息，可以在命令行下输入：

    xcodebuild -h
    

### 参考文档

<http://stackoverflow.com/questions/2664885/xcode-build-and-archive-from-command-line/4198166#4198166>

 [1]: http://www.yming9.com/?p=62
 [2]: http://images.cnitblog.com/blog/406864/201410/281612302534401.png

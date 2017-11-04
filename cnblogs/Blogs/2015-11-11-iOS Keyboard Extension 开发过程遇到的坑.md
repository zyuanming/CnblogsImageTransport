---
layout: post
title: iOS Keyboard Extension 开发过程遇到的坑
date: 2015-11-11
categories: blog
tags: [iOS]
description: iOS Keyboard Extension 开发过程遇到的坑

---

## 功能按键使用图片

每个键盘都需要有一个按钮，那就是切换“下一个键盘”的按钮。在系统键盘，这个按钮使用了一个Emoji表情中的  🌐表情来显示。但是对于其它的功能按键，却没有对应的Unicode编码，因此在字体库中也找不到对应的图形，而且Unicode 中的这个图形集合的展示是不统一的： 🌐⇪⌫⌨? 。 

所以最好还是叫UE重新设计一下这些功能按键的图片吧。

当然，你也可以自己绘制这个按钮了。可以参考这个开源项目。[tasty-imitation-keyboard][1]，这个开源项目里面的所有Function key 样式都是自己绘制的

## Audio

要想在键盘播放声音，你需要开启键盘的权限。当你可能会想，至少可以直接调用`AudioServicesPlaySystemSound` 这个标准函数来在键盘上播放声音。但是事实上，如果用户没有开启权限，那么这个方法会卡住键盘，我们可以这样调用：

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
        AudioServicesPlaySystemSound(1104)
    })

当然，如果你在调用这个`AudioServicesPlaySystemSound` 函数之前先判断一下用户是否开启了权限，那么就需要上面这样做了。

另外，我们如果只是想播放系统默认的按键点击声音，也可以像下面那么做（记住，调用之前，记得先检查用户是否有权限，否则会卡住键盘）：

    extension UIInputView: UIInputViewAudioFeedback {
 
        public var enableInputClicksWhenVisible: Bool { get { return true } }
 
        func playInputClick​() {
            UIDevice​.currentDevice​().playInputClick​()
        }
    }

需要注意的是，如果你使用 `AudioServicesPlaySystemSound` 这个来播放声音，那么你在声音播放期间是不能取消的，而且多处同时调用还会造成声音重叠。如果你想精确控制声音的播放，还是使用AVPlayer框架吧。

## 兼容iPad

是的，你的键盘必须适配所有的iOS设备，否则苹果不会审核通过你的APP，不过你的容器APP不一定要适配iPad。其实这是可以理解的，假设你的容器APP不适配iPad，但是用户仍然可以在iPad上从AppStore 下载你的APP，此时，用户还是可以从设置中添加你的键盘Extension，所有你的键盘Extension必须设配iPad。

同时，如果用户在iPad上装了iphone版的应用，而应用中又有相关依赖设备型号的业务逻辑或界面逻辑，则要小心不要只是用UIDevice类提供的方法来判断设备，还要结合UIView的大小来判断，否则就会可能出错，甚至崩溃。


## 线的绘制

如果你要绘制一个像素宽的线，则要小心，代码里设置UIView的frame的Width或Height为1只是表明一个屏幕点而已，在渲染时，会转换为像素。

1. 在1x缩放的设备上（非高清屏），1个点代表   ->   1个像素
2. 在2x缩放的设置上（iphone 4，4s，5，5s，6，7），  1个点代表    ->  2个像素
3. 在3x缩放的设置上（iphone 6 plus，7 plus），  1个点代表    ->  3个像素

另外注意，在ihone 6 以上的设备，都有一个放大模式，这个放大模式，其实就是屏幕的长宽点数降级：

1. iphone 6 plus, 7 plus  放大模式：   相当于按 ihpone 6 和 7的屏幕点来显示   2x,   1个点代表    ->  2个像素
2. iphone 6, 7 放大模式：   相当于按 ihpone 5的屏幕点来显示  2x,  1个点代表    ->  2个像素

所以，要获得一个像素宽的线，只需要计算

     1 ／ （一个点对应的像素）


## Size Class

苹果在iOS 8开始，强烈推荐我们使用Size Class来开发界面。一个这么优雅的解决方案，在开发键盘扩展时，却行不通。因为，对于键盘来说，Size Class 并没有用。例如，在6+ 的横屏下，键盘在两个方向上都是严格的`Compact`，即使在竖屏时，这个两个方向的layout constant 有很大的不同。对于iPad，键盘在两个方向上都是`Regular`。

## 自动布局 AutoLayout

是的，AutoLayout是比较好的方式来布局和约束我们的键盘界面，但是如果约束很多，设置不合理，或者有多余的约束，会比直接用`layoutSubviews `带来大量的性能损耗。

## 虚拟机经常弹不起键盘

那么快捷键 `Command + K`可以帮到你

![](http://images2015.cnblogs.com/blog/406864/201601/406864-20160101143726292-56636875.png)


## 系统的键盘设置

对于第三方的键盘，我们不能获取用户在系统的键盘设置内容，例如首字母自动大写、自动更正、取消Shift功能等等设置。我们只能要不假设一个默认值，要不就自己管理一份自己的键盘设置。

## 第三方APP与第三方键盘的兼容性

在某一些APP中使用第三方键盘，会出现一些诡异的问题，例如崩溃、键盘高度更新失败（只显示了一部分）。

如果你跟踪`UIInputViewController` 的生命周期，你会发现更加诡异的问题。例如:

1. 尽管`viewWillAppear` 被调用了，但是 `viewDidAppear ` 却没有被调用。如果你更新键盘的高度操作放在 `viewDidAppear` 方法中，则会导致键盘显示不全。幸好这个问题目前好像只在iOS 8 中出现，iOS 9 中并没有这个问题。


## 诡异的崩溃

没错，有时候你的键盘就会无缘无故地崩溃了，有时是因为你的键盘启动太慢了，有时却没有任何理由，对于这些崩溃，你可以不用管。

## 不支持物理键盘

是的，如果你的iOS设备外接了物理键盘，那么第三方键盘都是不可用的。

## UIMenuController 不支持

没错，如果你想实现类似系统复制、粘贴的popup menu，你必须得自己实现一套了。

## 参考文章：

1. http://beta-blog.archagon.net/2014/11/08/the-trials-and-tribulations-of-writing-a-3rd-party-ios-keyboard/
2. http://norbertlindenberg.com/2014/12/developing-keyboards-for-ios/
3. http://www.appdesignvault.com/ios-8-custom-keyboard-extension/


[1]:https://github.com/archagon/tasty-imitation-keyboard
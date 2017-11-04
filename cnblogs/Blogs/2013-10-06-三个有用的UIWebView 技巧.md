---
layout: post
title: 三个有用的UIWebView 技巧
date: 2013-10-06
categories: blog
tags: [iOS]
description: 三个有用的UIWebView 技巧

---

> 本文翻译自：[Three useful UIWebView tweaks][1]

在iOS开发者中一个众所周知的事实就是，创建复杂的格式化文本是一件麻烦事。像UILabel，UITextView这些控件都不是被设计来实现这个目的的。克服这些局限性的替代方案是多用途的UIWebView结合一些本地HTML内容和CSS样式。

在这篇文章中，我们将分享三个小技巧，可能在结合使用UIWebView和其他界面元素时有所帮助。

### 使用UIWebView 的 flashScrollIndicators

有时候明确地让用户知道屏幕上还有更多的内容没有显示是件非常有意义的。在UIScrollView中，有一个`flashScrollIndicators`方法正可以解决这个问题。它暂时显示滚动的指标，不幸的是，UIWebView内部是依托UIScrollView的，但是并没有暴露这个方法。但是无论如何，使用它的技巧非常简单：

    for (id subView in [webView subviews]) {
        if ([subView respondsToSelector:@selector(flashScrollIndicators)]) {
            [subView flashScrollIndicators];
        }
    }
    

在你的UIWebView渲染好内容后，调用上面的代码来让UIWebView的滚动条暂时显示。

### 移除UIWebView的背景阴影

比方说，你有一个白色背景的UIWebView，上面有一些黑色的文字。你的app的用户会知道你正在使用UIWebView来显示这些内容，因为那些iOS自动添加的背景阴影，但是向下拉动这个视图时，会出现下面的情况：

![][2]

因此，我们所需要做的就是移除这个阴影，同时设置背景颜色为白色：

    if ([[webView subviews] count] > 0) {
        // hide the shadows
        for (UIView* shadowView in [[[webView subviews] objectAtIndex:0] subviews]) {
            [shadowView setHidden:YES];
        }
        // show the content
        [[[[[webView subviews] objectAtIndex:0] subviews] lastObject] setHidden:NO];
     }
     webView.backgroundColor = [UIColor whiteColor];
    

这样，当我们向下拉动这个视图时，会变成下面这样：

![][3]

效果很好，这样用户就不知道我们正在使用UIWebView显示了。

### 预加载UIWebView的内容

有一个东西让我们很头痛，就是UIWebView被绘制在屏幕上时才开始加载它的内容，即使我们使用本地HTML和CSS。用户首先在屏幕上看到的是空白的UIWebView，然后过了几毫秒（有时几秒钟），内容才开始显示，这给用户的体验不是很好。

我们的解决方法就是在包含这个UIWebView的父视图中添加一个`preLoadView`方法。比如我们在一个UITableView cell被点击时需要跳到这个UIWebView所在的视图控制器上，我们不直接调用`pushViewController`，而是：

    - (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
        // check indexPath...
        myWebView = [[MyWebViewController alloc] init];
        myWebView.delegate = self;
        [myWebView preLoadView];
    }
    

然后在UIWebView加载完内容后，我们才push这个视图控制器：

    - (void)webViewDidFinishLoad:(UIWebView *)webView {
        [self.navigationController pushViewController:myWebView animated:YES];
        [myWebView release];    
    }
    

当然，上面的方法还需要很多准备，比如你要设置UIWebView的委托，还有确保在预加载时不阻塞UI等等，我们只是说明一下思路，相信你会知道细节怎么处理。

 [1]: http://ios.biomsoft.com/2012/04/26/three-useful-uiwebview-tweaks/
 [2]: http://images.cnitblog.com/blog/406864/201411/061014287203228.png
 [3]: http://images.cnitblog.com/blog/406864/201411/061017166276331.png
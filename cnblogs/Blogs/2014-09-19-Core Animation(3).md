---
layout: post
title: Core Animation（3）
date: 2014-09-19
categories: blog
tags: [iOS]
description: Core Animation（3）

---

* * *

## Transitions 转换

一个图层的转换动画涉及到对一个图层的两次“复制”，第二次“复制”出现来取代第一次。这个转换由CATransition（一个CAAnimation的子类）来描述，主要有一下的主要属性来描述动画：

type

你的选择是：

*   kCATransitionFade

*   kCATransitionMoveIn

*   kCATransitionPush

*   kCATransitionReveal

subtype

如果type不是kCATransitionFade，那么你的选择可以有：

*   kCATransitionFromRight

*   kCATransitionFromLeft

*   kCATransitionFromTop

*   kCATransitionFromBottom

（由于历史原因，在subtype设置中，“bottom” 和 “top” 的名字在实际中有着刚好相反的意思）

为了理解这个图层的转换，第一个例子中，并没有修改图层的任何内容：

    CATransition* t = [CATransition animation];
    t.type = kCATransitionPush;
    t.subtype = kCATransitionFromBottom;
    [layer addAnimation: t forKey: nil];
    

![][1]

整个layer会从原来的地方向下移动来退出，另一个复制原来layer内容的layer会从上面向下移动。如果同一时间里，我们改变了layer的内容，那么旧的内容仍然会出现在向下移动退出的layer上，直到从上面移动下来的layer出现，新的内容才会出现。

一种通用的做法是让layer在一个同样大小的父layer上进行转换，而且这个父layer的masksToBounds属性是YES。确保了layer只能在父layer范围内可见，否则退出和进入的layer会在父layer范围之外可见。

在下面的例子中，当使用一个从bottom开始的push转换（就是从上面向下移动）时，我们改变子layer的内容图片，从火星图像到一个笑脸图像。看起来就像是笑脸推动火星图向下移动：

    CATransition* t = [CATransition animation];
    t.type = kCATransitionPush;
    t.subtype = kCATransitionFromBottom;
    t.duration = 2;
    [CATransaction setDisableActions:YES];
    lay.contents = (id)[UIImage imageNamed: @"Smiley"].CGImage;
    [lay addAnimation: t forKey: nil];
    

* * *

## The Animations List 动画列表

CALayer 的 addAnimation:forKey: 方法可以请求执行一个显式动画。为了明白这个方法是如何工作的，你需要直到动画列表。

一个动画就是一个修改layer如何绘制的对象，实际的绘制仍然是layer做的。 一个layer管理一个当前执行的动画列表。为了添加动画到这个列表中，你需要调用 addAnimation:forKey: 。当到了重绘时刻，这个layer会遍历这个列表，并按照它发现的动画来绘制自己。

这个列表并不是一个字典，但是行为很像一个dictionary。一个动画会有一个key，如果添加的动画对应的key已经在列表中存在了，那么会移除原来的动画，这就是为什么有时候可以取消一个正在执行的动画的原因。当然也可以添加一个没有key的动画（key 是nil），可以有多个key为nil的动画在列表中。

动画就像是一个“动画电影”，只要这个动画还在列表中，那么这个“电影”就还在展示，不管是等待执行或者正在执行。一个动画结束执行后，通常需要从列表中移除，所以动画 有一个 removedOnCompletion 属性，默认是YES，但“电影”结束时，动画会移除出列表。

当然，你可以设置removedOnCompletion 为NO，但是对于一个已经结束的动画，并不会造成layer的外观有什么不同，因为动画的fillMode 是kCAFillModeRemoved，当“电影”结束时，从layer的绘制中移除这个动画。另外，把一个已经执行完的动画继续留在列表中也不会产生什么副作用，但这不是一个好主意，因为这样会让绘制系统多一份担心，因此我们通常是使用默认值。

你可能会设置removedOnCompletion 为NO，fillMode 为 kCAFillModeForwards 或者kCAFillModeBoth，来让动画结束时，把最后一帧画面留下来，不移除这个“动画电影”，防止layer跳回到动画开始前的状态。这是错误的做法，正确的方法是，修改layer的属性来匹配动画的最后一帧。

只能有一个转换动画在列表中，我们添加CATransition动画到列表中时，key会被忽略，key总是kCATransition（也就是“transition”）

 [1]: http://images.cnitblog.com/blog/406864/201410/142305599043641.png
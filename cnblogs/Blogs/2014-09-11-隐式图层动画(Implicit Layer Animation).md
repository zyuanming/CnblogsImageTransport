---
layout: post
title: 隐式图层动画（Implicit Layer Animation）
date: 2014-09-11
categories: blog
tags: [iOS]
description: 隐式图层动画（Implicit Layer Animation）

---

如果一个图层已经存在于界面上，而且不是一个视图的根图层，使它执行动画就如设置属性一样简单。文档中所说的动画属性的更改会自动解释为要求动态显示变化。换句话说，图层属性更改默认是执行动画的！多个属性的变化被认为是同一个动画的一部分。这种机制被称为隐式动画。

你不能在视图的根图层中使用隐式动画。你可以直接使这个根图层执行动画，但是你必须使用显式的动画，后面会讲到。

视图的根图层都是没有任何实际的绘画的，因此改变非根图层的属性都是会自动执行动画。

### 图层的frame属性是不会执行动画的，为了使图层的frame执行动画，你可以选择改变它的bounds 和 position 属性。很多初学者都没有意识到这一点。

* * *

## Animation Transactions 动画事务

隐式动画的执行需要一个事务（CATransaction），把所有的动画请求都包含在一个单一的动画中。每个动画请求都是在这个事务上下文中执行的。当然，你也可以包装你的动画请求在CATransacation类方法的 begin 和 commit 之间来显式执行你的动画，结果是一个 transaction block。 另外，有一个隐式事务上下文在你代码的地方，你可以不需要把你的动画请求用 begin 和 commit 包围起来，就能在这个隐式事务上下文中执行你的代码。

为了改变隐式动画的特性，你可以修改这个事务的属性：

*   setAnimationDuration:
    
    动画的时间

*   setAnimationTimingFunction:
    
    一个 CAMediaTimingFunction，后面会讲到。

*   setCompletionBlock:
    
    当动画结束时这个block会被调用。这个block没有任何参数。即使在这个事务期间没有动画，这个block也会被调用。

为了嵌套多个事务blocks，你可以在不同的动画元素上提供不同的动画特性。但是，你也可以在任何的事务blocks外面使用事务的命令：

    [CATransaction setAnimationDuration:0.8];
    arrow.transform = CATransform3DRotate(arrow.transform, M_PI/4.0, 0, 0, 1);
    

另一个非常有用的动画事务功能就是把隐式动画关闭，因为隐式动画是默认的，有时候这并不是你想要的。你可以调用 CATransaction 类方法 setDisableActions: 传递YES参数。还有其它的方法来关闭隐式动画，后面会讲到，但这个是最简单的。

* * *

## The Truth About Transactions 事务的真相

我们在之前的文章中谈到的重绘时刻，其实就是当前事务的结束时刻（通常是隐式事务）。 你设置一个view 的 backgroundColor， 当事务结束时，view 的背景颜色改变； 你调用 setNeedsDisplay方法，当事务结束时，drawRect: 方法会被调用；你调用setNeedsLayout方法，当事务结束时，界面会重新布局； 你请求一个动画，当事务结束时，动画开始执行。

你的代码运行在一个隐式事务中，但你的代码运行结束，这个事务提交自己，作为这个事务提交步骤的一部分，屏幕会被更新：先是布局，然后是绘制，接着确定属性的变化，开始动画。当动画在执行时，事务会继续在后台线程，当动画结束时，它的 completion block 会被调用。

setCompletionBlock: 非常有用，也是一个很强大的工具。这个事务的 completion block 是结束的信号，不仅仅表示你自己提供给这个事务的隐式图层属性的动画结束，还表示在这个事务期间所有的动画的结束，包括 Cocoa 自己的动画。例如，下面的代码：

    [myPopoverController dismissPopoverAnimated: YES];
    

这里没有 completion block，而且不是你自己的动画，那么你怎么知道动画什么时候结束呢？ 一个 事务的completion block 可以解决这个问题。

CGTransaction实现了KVC，让你可以通过一个key来设置和获取相应的值，下面会有一个例子。

一个显式的事务 block 会向一个图层请求动画。如果这个block并没有改变图层的任何内容，这会导致当CAtransaction类方法 commit被调用时，立刻执行动画，即使还不是重绘时刻，而此时你的代码还在运行，这样会造成很大的迷惑，应该避免使用显式的事务block。

* * *

## Media Timing Functions

setAnimationTimingFunction: 需要传递一个CAMediaTimingFunction 类型的函数。 这个类是我们之前讲过的动画曲线的普通描述（淡入－淡出， 淡入， 淡出，线性），你可以通过CAMediaTimingFunction 类方法 functionWithName: ，传递下面的参数之一：

*   kCAMediaTimingFunctionLinear
*   kCAMediaTimingFunctionEaseIn
*   kCAMediaTimingFunctionEaseOut
*   kCAMediaTimingFunctionEaseInEaseOut
*   kCAMediaTimingFunctionDefault

CAMediaTimingFunction是由两个点定义的贝塞尔曲线， 左下角坐标是｛0，0｝，右上角坐标是｛1，1｝。例如，这个淡入－淡出 的方程是由0.42, 0.0, 0.58, 1.0 这四个值描述的。定义了一个贝塞尔曲线的一个端点为｛0，0｝的控制点为｛0.42，0｝，一个端点为｛1，1｝的控制点为｛0。58，1｝。 functionWithControlPoints:::: 这个函数是Objective－C方法中少有的其中一个参数没有名字的函数。

![][1]

    CAMediaTimingFunction* clunk =
        [CAMediaTimingFunction functionWithControlPoints:.9 :.1 :.7 :.9];
    [CATransaction setAnimationTimingFunction: clunk];
    arrow.transform = CATransform3DRotate(arrow.transform, M_PI/4.0, 0, 0, 1);

 [1]: http://images.cnitblog.com/blog/406864/201410/112321144682848.png
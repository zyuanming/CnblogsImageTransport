---
layout: post
title: iOS Animation 学习（3）
date: 2014-09-07
categories: blog
tags: [iOS]
description: iOS Animation 学习（3）

---

### View Animation Options

UIView的类方法 nimateWithDuration:animations: 和 animateWithDuration:animations:completion: 都是 animateWith- Duration:delay:options:animations:completion: 的缩减版，参数解析如下：

*   duration
    
    动画的播放时间：从开始到结束需要多长时间（以秒为单位）来运行。你也可以认为这是动画的速度。显然，如果两个视图被告知同样时间里移动至不同的距离，移动距离更远的速度更快。

*   delay
    
    动画开始之前的延时。默认在缩减版方法中时没有延时的。

*   options
    
    额外选项值结合起来的位掩码（使用按位或运算符）。

*   animations
    
    这个block包含属性变化的动画。

*   completion
    
    当动画结束时会执行这个block（可以是nil）。它有一个BOOL类型的参数来指定动画是否结束了。即使在上面的动画block中没有触发任何动画，这个block仍然会被传入YES参数来调用。你也可以在这个block中执行另外的动画。

下面是第三个参数选项的一些值，你可能会用到：

*   Animation curve
    
    动画曲线描述了动画变化的过程中，如何加快。 “ease”一词意味着动画在开始和结束时，由零速度和中心速度之间会有一个逐渐加速和逐渐减速的过程。最多选择一个值;如果你不指定任何值（或如果您使用的是简化形式，在没有选择：参数），默认使用UIViewAnimationOptionCurveEaseInOut。你可以选择下面的值之一：
    
    （1） UIViewAnimationOptionCurveEaseInOut
    
    （2） UIViewAnimationOptionCurveEaseIn
    
    （3）UIViewAnimationOptionCurveEaseOut
    
    （4）UIViewAnimationOptionCurveLinear (constant speed throughout)

*   UIViewAnimationOptionRepeat
    
    如果包括这个值，动画将无限重复。没有办法可以指定重复一定的数量;你要么永远重复要么不重复。

*   UIViewAnimationOptionAutoreverse
    
    如果包括的话，动画将从开始运行到终点（在给定持续时间），并且随后将从终点（在给定的持续时间也）运行到开始。按照文档的说法，你只能自动翻转，如果你还重复是不正确的;你可以使用一种或两种（或没有）。
    
    当使用UIViewAnimationOptionAutoreverse时，你可能会想要在动画终点做一些清理工作，以便在动画结束时，视图回到它的初始位置。为了明白我什么意思，可以看看下面的代码：
    
    NSUInteger opts = UIViewAnimationOptionAutoreverse; [UIView animateWithDuration:1 delay:0 options:opts animations:^{ CGPoint p = self.v.center; p.x += 100; self.v.center = p; } completion:nil];

这个视图会以动画形式向右移动100点，然后再移动会原来的位置 －－然后就会跳到右边的100点位置。因为我们最后实际赋值给这个视图的center 的x 轴是向右100点，所以但动画结束时，这个“动画电影”被移除时，这个视图仍然在右边100点上。解决方法就是在 completion 处理block中把视图移回它原来的位置：

    CGPoint pOrig = self.v.center;
    NSUInteger opts = UIViewAnimationOptionAutoreverse;
    [UIView animateWithDuration:1 delay:0 options:opts animations:^{
        CGPoint p = self.v.center;
        p.x += 100;
        self.v.center = p;
    } completion:^(BOOL finished) {
        self.v.center = pOrig;
    }];
    

下面是使用递归链的指定动画次数的方法：

    - (void) animate: (int) count {
        CGPoint pOrig = self.v.center;
        NSUInteger opts = UIViewAnimationOptionAutoreverse;
        [UIView animateWithDuration:1 delay:0 options:opts animations:^{
            CGPoint p = self.v.center;
            p.x += 100;
            self.v.center = p;
        } completion:^(BOOL finished) {
            self.v.center = pOrig;
            if (count)
                [self animate:count-1];
        }]; 
    }
    

但你传递一个2给这方法来调用，动画会执行3次，然后停止。但这种方式是很危险的，如果数值很大，很容易用完内存。

还有其他一些选项指定如果另一个动画已经在执行了该怎么做：

*   UIViewAnimationOptionBeginFromCurrentState
    
    如果这个动画修改的属性同样被一个已经执行的动画修改，这时，不会取消之前的动画，这个动画会使用展示层（presentation layer）来决定从哪里开始执行动画，如果可能，还会混合之前的动画。

*   UIViewAnimationOptionOverrideInheritedDuration
    
    防止从已经在执行的动画中继承动画的持续时间（默认是继承的）。

*   UIViewAnimationOptionOverrideInheritedCurve
    
    防止从已经在执行的动画中继承动画曲线（默认是继承的）。

为了说明 UIViewAnimationOptionBeginFromCurrentState ，考虑下面的代码：

    [UIView animateWithDuration:1 animations:^{
        CGPoint p = self.v.center;
        p.x += 100;
        self.v.center = p;
    }];
    NSUInteger opts = 0;
    [UIView animateWithDuration:1 delay:0 options:opts animations:^{
        CGPoint p = self.v.center;
        p.x = 0;
        self.v.center = p;
    } completion:nil];
    

结果就是视图跳到右边的100点位置，然后向左边开始动画，移动。 这是因为第二个动画使第一个动画被取消了，向右是瞬间完成，而不是动画。但是，如果我们设定options为UIViewAnimationOptionBeginFromCurrentState，其结果是，该视图的动画从它的当前位置向左执行，并没有跳跃。

如果我们在第二个动画中把改变x变为改变y，会发生很有趣的事情。如果options为0，那么视图会跳到右边，然后向上移动。如果options为UIViewAnimationOptionBeginFromCurrentState，两个动画会结合起来，视图斜向移动（右上角）。

为了解析 UIViewAnimationOptionOverrideInheritedDuration，看下面的代码：

    [UIView animateWithDuration:2 animations:^{
        CGPoint p = self.v.center;
        p.x += 100;
        self.v.center = p;
        NSUInteger opts = 0;
        [UIView animateWithDuration:0.5 delay:0 options:opts animations:^{
            self.v.backgroundColor = [UIColor blackColor];
        } completion:nil];
    }];
    

如果options为0，那么颜色动画的时间跟x轴的动画时间一样，继承了x轴的动画时间。但是如果options为UIViewAnimationOptionOverrideInheritedDuration，每个动画都有自己的执行时间。

为了停止正在执行的动画，我们可以提供一个冲突的动画，设置视图的位置为最终的位置。

    -(void) animate {
        CGPoint p = self.v.center;
        p.x += 100;
        self.pFinal = p;
        [UIView animateWithDuration:4 animations:^{
            self.v.center = p;
        }];
    }
    -(void) cancel {
        [UIView animateWithDuration:0 animations:^{
            CGPoint p = self.pFinal;
            p.x += 1;
            self.v.center = p;
        } completion:^(BOOL finished) {
            CGPoint p = self.pFinal;
            self.v.center = p;
        }]; 
    }
    

为了停止一个重复执行的动画，我们可以：

    -(void) animate {
        CGPoint p = self.v.center;
        self.pOrig = p;
        p.x += 100;
        NSUInteger opts = UIViewAnimationOptionAutoreverse |
        UIViewAnimationOptionRepeat;
        [UIView animateWithDuration:1 delay:0 options:opts animations:^{
            self.v.center = p;
        } completion: nil];
    }
    -(void) cancel {
        [UIView animateWithDuration:0 animations:^{
            self.v.center = self.pOrig;
        }];
    }
    

如果你希望动画的停止不那么突然，可以：

    -(void) cancel {
        NSUInteger opts = UIViewAnimationOptionBeginFromCurrentState;
        [UIView animateWithDuration:0.1 delay:0 options:opts animations:^{
            self.v.center = self.pOrig;
        } completion:nil];
    }
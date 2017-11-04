---
layout: post
title: iOS Animation 学习（4）
date: 2014-09-08
categories: blog
tags: [iOS]
description: iOS Animation 学习（4）

---

## Springing 弹性

在iOS 7中，有一个内置的动画曲线，好像挤压弹簧：

    [UIView animateWithDuration:0.8 delay:0
        usingSpringWithDamping:0.7 initialSpringVelocity:0
                       options:0 animations:^{
        CGPoint p = self.v.center;
        p.y += 100;
        self.v.center = p;
    } completion:nil];
    

这个 damping:（阻尼）和initialSpringVelocity:（弹簧速度）参数会改变这个动画的行为，如果这个damping 阻尼系数小于1， 那么这个动画视图会在它的最终位置上来回摆动，如果小于0.7，那么视图会摆动比较厉害，如果使0.3，视图在固定位置之前，会摆动得更加激烈。

这个弹簧的初始速度（initialSpringVelocity）表示视图在开始位置倾向于结束位置的初始移动速度，考虑到这个动画时间和衰减量，这个值可能需要调到很大才能明显看到之间的不同。试着设置为20看看。当你的阻尼系数很小，而初始速度很大时，事情会变得很有趣。

这个options参数跟上一篇文章讲过的options参数一样，设置为UIViewAnimationOptionCurveEaseIn可能会比较好看。

## Keyframe View Animations 关键帧视图动画

在iOS 7 中，一个视图的动画可以用一系列的关键帧来设置。（在之前的版本中，只能在 CALayer层次上才能实现，我会在后面见解）。

你可以调用 animateKeyframesWithDuration: delay: options:animations: ,在block里面，多次调用addKeyFrame 方法来指定每一个状态。每一个帧的开始时间和持续时间都是在0和1之间。

    __block CGPoint p = self.v.center;
    [UIView animateKeyframesWithDuration:4 delay:0 options:0 animations:^{
        [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:.25
                                      animations:^{
            p.x += 100;
            p.y += 50;
            self.v.center = p;
        }];
        [UIView addKeyframeWithRelativeStartTime:.25 relativeDuration:.25
                                      animations:^{
            p.x -= 100;
            p.y += 50;
            self.v.center = p;
        }];
        [UIView addKeyframeWithRelativeStartTime:.5 relativeDuration:.25
                                      animations:^{
            p.x += 100;
            p.y += 50;
            self.v.center = p;
        }];
        [UIView addKeyframeWithRelativeStartTime:.75 relativeDuration:.25
                                      animations:^{
            p.x -= 100;
            p.y += 50;
            self.v.center = p;
        }]; 
    }];
    

动画的路径和时间由以UIViewKeyframeAnimationOptionCalculationMode开头的选项决定。默认，这个options是0，是线性的。在上面的例子中，这意味着这个视图的移动路径是类似尖锐的Z字，左右两边好像有一面无形的墙。但是如果这个计算模式是Cubic（三次方），我们的视图像S曲线移动。

在我们的例子中，我们还可以使用 Paced模式（类似于线性）和CubicPaced（类似于Cubic）来达到同样的效果。这两个选项会简单地忽略帧相应的开始时间和持续时间，你可以同样设置它们为0。

最后，Discrete计算模式表示对于改变的属性不执行动画，而是跳到下一个帧。

你还可以添加一个动画曲线给这个选项（文档并没有说清楚）：

    NSUInteger opts =
        UIViewKeyframeAnimationOptionCalculationModeLinear |
        UIViewAnimationOptionCurveLinear;
    [UIView animateKeyframesWithDuration:4 delay:0 options:opts animations:^{
    

这是两种不同意义的“线性”。第一个表示视图沿路径的移动是线性的。第二个表示视图沿路径移动的速度是稳定的。

* * *

## Transitions 转换，过度

过渡是强调内容在视图中的变化的一种动画。你可以使用两种方法中的一种。第一种就是transitionWithView:duration:options:animations:completion:。这个过渡类型有下面几种：

*   UIViewAnimationOptionTransitionFlipFromLeft
*   UIViewAnimationOptionTransitionFlipFromRight
*   UIViewAnimationOptionTransitionCurlUp
*   UIViewAnimationOptionTransitionCurlDown
*   UIViewAnimationOptionTransitionCrossDissolve
*   UIViewAnimationOptionTransitionFlipFromBottom
*   UIViewAnimationOptionTransitionFlipFromTop
    
    记住，千万不要跟旧的过渡选项UIViewAnimationTransitionFlipFromLeft搞混了。

在下面的例如中，UIImageView包含一张火星的图片，翻转这个UIImageView，内容会变成一张笑脸，看起来这个UIImageView 有两面：

    [UIView transitionWithView:self.iv duration:0.8
            options:UIViewAnimationOptionTransitionFlipFromLeft animations:^{
        self.iv.image = [UIImage imageNamed:@"Smiley"];
    } completion:nil];
    

在这个例子中，我把内容的变化放在了动画 block里。这其实是一种误导，事实是，如果所有的改变都是内容，不需要在block里写任何代码。改变的内容可以在任意地方，在整行代码的前面或者后面都可以。执行的动画只是这个翻转过程。

你也可以通过写一个自定义的视图来实现这个功能。假设我有一个UIView的子类，MyView，根据BOOL类型的reverse参数来决定是绘制矩形还是椭圆形：

    - (void)drawRect:(CGRect)rect {
        CGRect f = CGRectInset(self.bounds, 10, 10);
        CGContextRef con = UIGraphicsGetCurrentContext();
        if (self.reverse)
            CGContextStrokeEllipseInRect(con, f);
        else
            CGContextStrokeRect(con, f);
    }
    

然后通过下面代码来翻转这个视图：

    self.v.reverse = !self.v.reverse;
    [UIView transitionWithView:self.v duration:1
            options:UIViewAnimationOptionTransitionFlipFromLeft animations:^{
        [self.v setNeedsDisplay];
    } completion:nil];
    

在这个转变过程中，默认的，视图的内容会直接改变为最终的内容；实际上，在动画之前，已经生成了一个视图的最终外观的快照。如果这不是你想要的，可以添加UIViewAnimationOptionAllowAnimatedContent 这个选项。

在下面的例子中，outer是一个使用过渡动画的视图，inner是这个outer的子视图，占了父视图宽度的一部分，在这个过渡过程中，我们增加这个inner视图的宽度到父视图的宽度：

    [UIView transitionWithView:self.outer duration:1
            options:opts animations:^{
        CGRect f = self.inner.frame;
        f.size.width = self.outer.frame.size.width;
        f.origin.x = 0;
        self.inner.frame = f;
    } completion:nil];
    

如果opts是UIViewAnimationOptionTransitionFlipFromLeft，我们看到outer在翻转过程中仍然显示原来的外观，然后inner视图的改变是瞬间的。 如果 opts 同时包含了UIViewAnimationOptionAllowAnimatedContent，那么我们就会看到在outer翻转的过程中，inner的宽度也在变化。

另一个动画过渡方法是 transitionFromView:toView:duration:options: completion:。第一个视图会被第二个视图所取代，有两种配置，根据下面的选项决定：

*   Remove one subview, add the other 移除一个子view，添加另一个
    
    如果UIViewAnimationOptionShowHideTransitionViews不是其中一个选项，那么第二子视图不在视图层次上，当我们开始这个过渡动画后，将删除它的父类第一子视图，并增加了第二子视图到这个父类中。

*   Hide one subview, show the other 隐藏一个子view，显示另一个
    
    如果UIViewAnimationOptionShowHideTransitionViews为其中一个选项，然后两个子视图都在视图层次上，当我们开始动画，就会设置第一个view的hidden为NO，第二个view的hidden为YES，然后过渡动画会翻转这些值。

```objc
    UILabel* lab2 = [[UILabel alloc] initWithFrame:self.lab.frame];
     lab2.text = @"Howdy";
     [lab2 sizeToFit];
     [UIView transitionFromView:self.lab toView:lab2 duration:0.8 options:UIViewAnimationOptionTransitionFlipFromLeft completion:nil];
```
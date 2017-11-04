---
layout: post
title: Motion Effects & Animation 和 Autolayout
date: 2014-10-02
categories: blog
tags: [iOS]
description: Motion Effects & Animation 和 Autolayout

---

## Motion Effects

在iOS7中，当用户倾斜设备时，一个视图可以实时地响应。通常情况下，视图的响应将是稍微改变其位置。这被用于，例如，在该界面的各部分，让界面有种层叠感。当UIAlertView存在时，如果使用者倾斜装置，该UIAlertView会移动其位置;效果有点微妙，但足以表明UIAlertView稍微在屏幕的前面漂浮。

你自己的视图也可以用同样的方式来表现。一个视图如果有一个或多个motion effects动画效果（UIMotionEffect）。这个动画效果通过addMotionEffect:添加到视图上，motionEffects方法可以列举所有视图上的motion effect，removeMotionEffect:可以从视图上移除指定的motion effect。

该UIMotionEffect类是抽象的：它的工作是被继承。提供的主要子类是UIInterpolatingMotionEffect。UIInterpolatingMotionEffect有一个简单的键值路径，也就是使用键-值编码来指定它所影响的属性。它也有一个类型，指定受到设备倾斜的哪个方向（水平倾斜或垂直倾斜）影响。最后，它有一个最大和最小相对值，即认为受影响的属性对于设备倾斜的偏移值。相关的的motion effects应该合并成一个UIMotionEffectGroup（也是一个UIMotionEffect 子类），然后把它添加到视图中：

    UIInterpolatingMotionEffect* m1 =
        [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x"
        type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    m1.maximumRelativeValue = @5.0;
    m1.minimumRelativeValue = @-5.0;
    UIInterpolatingMotionEffect* m2 =
        [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y"
        type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    m2.maximumRelativeValue = @5.0;
    m2.minimumRelativeValue = @-5.0;
    UIMotionEffectGroup* g = [UIMotionEffectGroup new];
    g.motionEffects = @[m1,m2];
    [self.mars addMotionEffect:g];
    

你也可以实现自己的UIMotionEffect子类，通过实现一个简单的方法keyPathsAndRelativeValuesForViewerOffset:即可。当一般很少需要这么做。

* * *

## Animation and Autolayout

动画和自动布局之间的相互影响可能会非常棘手。作为动画的一部分，你可能会改变一个视图的frame（bounds 或者center）。但当你使用自动布局时，是不应该改变frame的。结果是，动画可能不执行，或者动画执行正常，但是布局却没有发生；但是布局是完全有可能会发生的，这样就会伴随产生不良的影响。

正如我在前面的文章说过，当布局是自动布局管理的，那么视图的约束是关键。如果约束在布局时不能解决视图的大小和位置问题，那么视图就会跳出约束的限制。这是你不想要结果。

为了说明这将会是一个问题，仅仅以动画方式改变一个视图的位置，然后立刻调用layoutIfNeeded来布局：

    CGPoint p = self.v.center;
    p.x += 100;
    [UIView animateWithDuration:1 animations:^{
        self.v.center = p;
    } completion:^(BOOL b){
        [self.v layoutIfNeeded]; // this is what will happen at layout time
    }];
    

如果我们使用自动布局，视图滑向右侧，然后跳回到左边。这是不好的。我们应该保持约束与实际同步，这样当布局发生时，我们的视图就不会跳进一个不确定的状态。

一种选择是修改被违反的约束，以符合新的实际情况。如果我们想得更远一点，我们可以提前拿到这些约束的引用；这种情况下我们的代码就可以移除和替换这些约束----或者，如果唯一需要改变是一个约束的常量值，我们可以改变这个值（记得，常量是现有约束的唯一可写属性）。否则，当发现有什么违反了约束是，再获得对它们的引用，是很不容易的。

另一种方法，在需要改变的仅仅是一个约束常量的情况下，我们可以直接驱动这个约束的常量值的变化来执行动画，而不是改变视图的位置来执行动画。要做到这一点，我们需要设置这个约束常量一个新值，然后对布局行为执行动画。这是假定我们拿到了这个约束的引用的情况下。

    // con is the constraint
    con.constant += 100;
    [UIView animateWithDuration:1 animations:^{
        [self.v layoutIfNeeded];
    }];
    

另一个问题是怎么处理视图的变换transforms。正如我前面文章说过的，提供给视图一个变换会立刻触发布局，约束就会负责定位这个视图。因此，在自动布局下对视图进行变换会发生一些意想不到的事情。

例如，你可能会觉得下面的动画在自动布局下会正常工作，但是你错了，即使这个简单的拉伸动画也会在自动布局下被打断---结果不是简单的拉伸动画，而是视图可能会不时跳到不同的位置：

    [UIView animateWithDuration:0.3 delay:0
            options:UIViewAnimationOptionAutoreverse animations:^{
        self.v.transform = CGAffineTransformMakeScale(1.1, 1.1);
    } completion:^(BOOL finished) {
        self.v.transform = CGAffineTransformIdentity;
    }];
    

这种情况下，我们的解决方法是使用Core Animation；因为提供给图层一个变换动画，是不会触发布局的：

    CABasicAnimation* ba =
        [CABasicAnimation animationWithKeyPath:@"transform"];
    ba.autoreverses = YES;
    ba.duration = 0.3;
    ba.toValue =
        [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.1, 1.1, 1)];
    [self.v.layer addAnimation:ba forKey:nil];
    

另一种可能的做法是使用原始视图的快照，把这个快照临时添加到界面上---不使用自动布局，然后把原来的视图隐藏，最后驱动这个快照指定动画：

    UIView* snap = [self.v snapshotViewAfterScreenUpdates:YES];
    snap.frame = self.v.frame;
    [self.v.superview addSubview:snap];
    self.v.hidden = YES;
    [UIView animateWithDuration:0.3 delay:0
             options:UIViewAnimationOptionAutoreverse animations:^{
        snap.transform = CGAffineTransformMakeScale(1.1, 1.1);
    } completion:^(BOOL finished) {
        snap.transform = CGAffineTransformIdentity;
        self.v.hidden = NO;
        [snap removeFromSuperview];
    }];
    

但是，如果动画的意图是，真正的视图最终需要被转移到新的永久位置上，那么它的约束仍然要进行修改。

另一个有用的技巧是认清一个事实，就是“动画电影”只是实际的一个面具。下面的例子是我缩小视图（english）到没有：

    CABasicAnimation* ba = [CABasicAnimation animationWithKeyPath:@"opacity"];
    self.english.layer.opacity = 0;
    ba.duration = 0.2;
    [self.english.layer addAnimation:ba forKey:nil];
    CABasicAnimation* ba2 = [CABasicAnimation animationWithKeyPath:@"bounds"];
    ba2.duration = 0.2;
    ba2.toValue = [NSValue valueWithCGRect:self.english.layer.bounds];
    [self.english.layer addAnimation:ba2 forKey:nil];
    

这在自动布局下并不会被中断，因为我从来没有做过任何违反现有约束的事，我没有改变视图的bounds！我让这个图层不可见，通过改变它的opacity为0。另一方面，动画仍然驱动这个视图缩小到没有，这是一个假象，用户不会发现其实它仍处于原来的尺寸。

自动布局从iOS6开始出现，那时候就是与动画不兼容的，这个不兼容是iOS的一个严重缺陷，而苹果却刻意掩饰它，避谈这两者的不兼容。
---
layout: post
title: Core Animation（1）
date: 2014-09-14
categories: blog
tags: [iOS]
description: Core Animation（1）

---

Core Animation 是iOS动画技术的根本。 视图动画和隐式图层动画都仅仅是Core Animation的方便包装。 Core Animation 是显式图层动画，让你创造更加绚丽的动画。

让视图的根图层执行动画是一种图层动画，而不是视图动画－－因此不会对视图的子视图进行自动布局，所以我们常常喜欢使用视图动画，而不是图层动画。

* * *

## CABasicAnimation and Its Inheritance

通过Core Animation驱动一个属性执行动画的最简单方法就是使用CABasicAnimation对象。通过继承CABasicAnimation，可以发挥它的强大力量，所以下面我只会讲解CABasicAnimation的继承，你可以体会到所有目前我们看到的属性动画都体现在CABasicAnimation实例中。

### CAAnimation

CAAnimation是一个抽象类，这意味着你将永远只能用它的一个子类。有些CAAnimation的功能来自于它实现的CAMediaTiming协议，协议中定义了8个属性。

*   animation
    
    一个类方法，创建一个动画对象的方便形式

*   delegate
    
    这个委托的消息是 animationDidStart: and animationDidStop:finished:。
    
    一个CAAnimation实例会保留它的委托; 这是非常不寻常的行为，如果你不明白它（我的经验之谈可能会导致麻烦。另外，为了让你的代码在动画结束时调用，不要设置一个委托，而是在配置动画之前，调用CATransaction 的类方法setCompletionBlock:。

*   duration, timingFunction
    
    动画的长度和它的时间函数（一个 CAMediaTiming 函数）。 持续时间为0（默认值）表示 0.25秒，除非通过事务来覆盖。

*   autoreverses, repeatCount, repeatDuration, cumulative
    
    前两个是类似与UIView的动画。该repeatDuration属性是用不同的方式来管理重复，指定重复应该持续多久而不是应该重复多少次;不要同时指定repeatCount和repeatDuration。如果cumulative属性时YES，一个重复的动画时从上一个重复的动画结束的地方开始每个重复（而不是每次都跳到开始的值来重复）。

*   beginTime
    
    动画开始前的延时。为了从现在开始延时一个动画，调用 CACurrentMediaTime 和添加一个指定的延时秒数。这个延时不会计算在动画的持续时间里。

*   timeOffset
    
    timeOffset属性有点难理解，它对时间进行偏移（offset）。具体的内容，又一篇文章做了解析： http://www.cocoachina.com/programmer/20131218/7569.html

CAAnimation，连同其所有的子类，实现了KVC，允许您通过一个key来设置和获取任意值，类似的CALayer和CATransaction。

### CAPropertyAnimation

CAPropertyAnimation是CAAnimation的一个子类，也是抽象的，添加了下面的：

*   keyPath
    
    通过CAPropertyAnimation类方法 animationWithKeyPath: ，传入一个keyPath来创建一个实例。

*   additive
    
    如果是YES，由动画所提供的值将会被添加到当前显示层的值。

*   valueFunction
    
    转换一个你提供的简单标量值到一个transform。

### CABasicAnimation

CABasicAnimation是CAPropertyAnimation的一个子类（不是抽象的），添加了下面的：

*   fromValue, toValue
    
    动画的起始和结束值。这些值必须是对象，所以数字和结构体将必须使用NSNumber和NSValue包装。如果不设置fromValue和toValue，将会使用以前和现在的值。如果只是提供fromValue或toValue的一个，另一个使用该属性的当前值。

*   byValue
    
    通过设置这个值和 fromValue 、toValue中的中的一个，系统会自动帮你通过加法或减法来算出另一个值。如果你只设置了byValue，那么fromValue就是属性的当前值。

* * *

## Using a CABasicAnimation

既然已经构造和配置了一个CABasicAnimation，那么我们执行它的方式就是把它添加到一个图层上。 通过CALayer的实例方法 addAnimation:forKey:（后面会讲这个key的作用，现在我们只需传nil就可以了）。

但是，CAAnimation只是一个动画，动画播放完了，你的图层仍然会在动画开始前的位置，什么都没有改变，你需要保证图层与动画的结束值对应上。毕竟我们是使用显式动画，更加底层，需要多加小心。

一般的步骤是：

1.  捕获需要改变的图层属性的开始和结束值。

2.  改变图层的属性为它的动画结束值，如果需要防止隐式动画，可以首先调用

setDisableActions:方法。

1.  使用你刚刚捕获的值和这个属性对应的keyPath来构造显式动画。

2.  添加显式动画到图层上。

下面就是对我们的箭头执行旋转动画：

    // capture the start and end values
    CATransform3D startValue = arrow.transform;
    CATransform3D endValue =
        CATransform3DRotate(startValue, M_PI/4.0, 0, 0, 1);
    // change the layer, without implicit animation
    [CATransaction setDisableActions:YES];
    arrow.transform = endValue;
    // construct the explicit animation
    CABasicAnimation* anim =
        [CABasicAnimation animationWithKeyPath:@"transform"];
    anim.duration = 0.8;
    CAMediaTimingFunction* clunk =
        [CAMediaTimingFunction functionWithControlPoints:.9 :.1 :.7 :.9];
    anim.timingFunction = clunk;
    anim.fromValue = [NSValue valueWithCATransform3D:startValue];
    anim.toValue = [NSValue valueWithCATransform3D:endValue];
    // ask for the explicit animation
    [arrow addAnimation:anim forKey:nil];
    

一旦你知道了完整形式，你会发现，在许多情况下，它可以浓缩。例如，当fromValue和toValue都没有设置，该属性的以前和现在值会自动使用（这是可能的，因为在表现层有了新的值时，它仍然由原来的属性的值）。因此，在这种情况下，没有必要对其进行设置，因此没有必要事先捕捉开始和结束值。这里的浓缩版：

    [CATransaction setDisableActions:YES];
    arrow.transform =
        CATransform3DRotate(arrow.transform, M_PI/4.0, 0, 0, 1);
    CABasicAnimation* anim =
        [CABasicAnimation animationWithKeyPath:@"transform"];
    anim.duration = 0.8;
    CAMediaTimingFunction* clunk =
        [CAMediaTimingFunction functionWithControlPoints:.9 :.1 :.7 :.9];
    anim.timingFunction = clunk;
    [arrow addAnimation:anim forKey:nil];
    

让我们的箭头出现快速振动：

    // capture the start and end values
    CATransform3D nowValue = arrow.transform;
    CATransform3D startValue =
        CATransform3DRotate(nowValue, M_PI/40.0, 0, 0, 1);
    CATransform3D endValue =
        CATransform3DRotate(nowValue, -M_PI/40.0, 0, 0, 1);
    // construct the explicit animation
    CABasicAnimation* anim =
        [CABasicAnimation animationWithKeyPath:@"transform"];
    anim.duration = 0.05;
    anim.timingFunction =
        [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    anim.repeatCount = 3;
    anim.autoreverses = YES;
    anim.fromValue = [NSValue valueWithCATransform3D:startValue];
    anim.toValue = [NSValue valueWithCATransform3D:endValue];
    // ask for the explicit animation
    [arrow addAnimation:anim forKey:nil];
    

的确，上面的代码还可以简化，我们可以无需基于当前新的旋转值方向计算下一个旋转值，只需设置additive为YES;这意味着，动画的属性值被添加到我们现有的属性值，所以它们是相对的，不是绝对的。

    CABasicAnimation* anim =
        [CABasicAnimation animationWithKeyPath:@"transform"];
    anim.duration = 0.05;
    anim.timingFunction =
        [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    anim.repeatCount = 3;
    anim.autoreverses = YES;
    anim.additive = YES;
    anim.valueFunction =
        [CAValueFunction functionWithName:kCAValueFunctionRotateZ];
    anim.fromValue = @(M_PI/40);
    anim.toValue = @(-M_PI/40);
    [arrow addAnimation:anim forKey:nil];
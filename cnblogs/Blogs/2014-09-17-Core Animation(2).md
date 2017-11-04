---
layout: post
title: Core Animation（2）
date: 2014-09-17
categories: blog
tags: [iOS]
description: Core Animation（2）

---

* * *

## Keyframe Animation 关键帧动画

关键帧动画（CAKeyframeAnimation）是一种可以替代基本动画的动画（CABasicAnimation）;它们都是CAPropertyAnimation的子类，它们都以相同的方式使用。不同的是，关键帧动画，除了可以指定起点和终点的值，也可以规定该动画的各个阶段（帧）的值。这相当于设置动画的属性值（一个NSArray）那么简单。

下面是箭头来回摆动的动画更复杂的版本：动画包括开始和结束状态，并且摇动的程度变得越来越小：

    NSMutableArray* values = [NSMutableArray array];
    [values addObject: @0.0f];
    int direction = 1;
    for (int i = 20; i &lt; 60; i += 5, direction *= -1) { // alternate directions
        [values addObject: @(direction*M_PI/(float)i)];
    }
    [values addObject: @0.0f];
    CAKeyframeAnimation* anim = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    anim.values = values;
    anim.additive = YES;
    anim.valueFunction = [CAValueFunction functionWithName: kCAValueFunctionRotateZ];
    [arrow addAnimation:anim forKey:nil];
    

下面是一些CAKeyframeAnimation 属性：

*   values
    
    动画采用的值的数组，包括开始和结束值。

*   timingFunctions
    
    一个计时函数的数组。

*   keyTimes
    
    一个与 values 值数组对应的时间数组，定义了动画在什么时间应该到达什么值。时间以0开始，1结束。

*   calculationMode
    
    描述了 values值数组如何被用来生成所有需要的值。
    
    1、 默认是kCAAnimationLinear，一个值到值的简单直线插入。
    
    2、kCAAnimationCubic通过所有的值（和其他高级特性，tensionValues​​，continuityValues​​和biasValues​​，让你改进曲线）构建一个平滑的曲线。
    
    3、kCAAnimationPaced和kCAAnimationCubicPaced表示的计时函数和关键时间数组会被忽略，并且速度在整个动画过程中都是常数。
    
    4、kCAAnimationDiscrete意味着没有插入：我们直接在相应的关键时间点上跳到对应的值。

*   path
    
    当你对属性执行动画的值是多个CGPoint类型的值，还有另一种方式来表示这些值，除了用值数组，我们可以把所有值作为一个简单的 CGPathRef。用来绘制这个路径的点就是关键帧的值，因此你仍然可以提供计时函数和关键时间点。如果你对位置执行动画，这个 rotationMode 属性让执行动画的对象旋转，来始终垂直与这个路径。

下面的例子， values 数组是5个图片的数组，在图层中重复的内容，类似于我们之前讲过的UIImageView 和UIImage的动画：

    CAKeyframeAnimation* anim = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
    anim.values = self.images;
    anim.keyTimes = @[@0,@0.25,@0.5,@0.75,@1];
    anim.calculationMode = kCAAnimationDiscrete;
    anim.duration = 1.5;
    anim.repeatCount = HUGE_VALF;
    [self.sprite addAnimation:anim forKey:nil];
    

* * *

## Making a Property Animatable 让一个属性可以执行动画

到目前为止，我们让内建的可执行动画的属性执行了动画。如果你在CALayer的子类中定义了自己的属性，你可以使用CAPropertyAnimation（CABasicAnimation 或者CAKeyframeAnimation）来让你的属性可执行动画。例如，下面我们驱动increase 和 decrease属性：

    CALayer* lay = self.v.layer;
    CABasicAnimation* ba = [CABasicAnimation animationWithKeyPath:@"thickness"];
    ba.toValue = [NSNumber numberWithFloat: 10.0];
    ba.autoreverses = YES;
    [lay addAnimation:ba forKey:nil];
    

为了让我们的图层响应这个属性的动画命令，我们需要一个声明为@dynamic的 thickness属性（以便让Core Animation可以创建它的访问器），同时在类方法 needsDisplayForKey：中必须返回YES，这个可以就是这个属性的名字：

    @interface MyLayer ()
    @property CGFloat thickness;
    @end
    
    @implementation MyLayer
    @dynamic thickness;
    + (BOOL) needsDisplayForKey:(NSString *)key {
        if ([key isEqualToString: @"thickness"])
            return YES;
        return [super needsDisplayForKey:key];
    }
    // ...
    @end
    

needsDisplayForKey:中返回YES，导致当thickness这个属性改变时，可以触发这个图层重新显示。所以，为了看到这个动画，这个图层需要根据这个thickness属性来绘制自己。这里我会实现图层的drawInContext: 方法，让红色矩形有一个thickness值的黑色边框：

    - (void) drawInContext:(CGContextRef)con {
        CGRect r = CGRectInset(self.bounds, 20, 20);
        CGContextSetFillColorWithColor(con, [UIColor redColor].CGColor);
        CGContextFillRect(con, r);
        CGContextSetLineWidth(con, self.thickness);
        CGContextStrokeRect(con, r);
    }
    

* * *

## Grouped Animations 组合动画

一个组合动画（CAAnimationGroup）将多个动画包含在一起，通过它的animations属性（一个NSArray的动画数组）来实现。

CAAnimationGroup自己就是一个动画，它是CAAnimation的子类，所以它也有duration持续时间等其他的动画功能。想象这个CAAnimationGroup是一个父亲，它的animations都是孩子，那么孩子就是从父亲中继承默认的值，另外，如果你没有显式地设置孩子的duration，它会继承父亲的duration。 同样，确保父亲的duration足够包括所有你想执行动画。

下面我们组合剪头的旋转和摆动动画：

    // capture current value, set final value
    CGFloat rot = M_PI/4.0;
    [CATransaction setDisableActions:YES];
    CGFloat current = [[arrow valueForKeyPath:@"transform.rotation.z"] floatValue];
    [arrow setValue: @(current + rot) forKeyPath:@"transform.rotation.z"];
    // first animation (rotate and clunk)
    CABasicAnimation* anim1 = [CABasicAnimation animationWithKeyPath:@"transform"];
    anim1.duration = 0.8;
    CAMediaTimingFunction* clunk = [CAMediaTimingFunction functionWithControlPoints:.9 :.1 :.7 :.9];
    anim1.timingFunction = clunk;
    anim1.fromValue = @(current);
    anim1.toValue = @(current + rot);
    anim1.valueFunction = [CAValueFunction functionWithName:kCAValueFunctionRotateZ];
    // second animation (waggle)
    NSMutableArray* values = [NSMutableArray array];
    [values addObject: @0.0f];
    int direction = 1;
    for (int i = 20; i &lt; 60; i += 5, direction *= -1) { // alternate directions
        [values addObject: @(direction*M_PI/(float)i)];
    }
    [values addObject: @0.0f];
    CAKeyframeAnimation* anim2 = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    anim2.values = values;
    anim2.duration = 0.25;
    anim2.beginTime = anim1.duration;
    anim2.additive = YES;
    anim2.valueFunction = [CAValueFunction functionWithName:kCAValueFunctionRotateZ];
    // group
    CAAnimationGroup* group = [CAAnimationGroup animation];
    group.animations = @[anim1, anim2];
    group.duration = anim1.duration + anim2.duration;
    [arrow addAnimation:group forKey:nil];
    

下面创建一个如图的动画，一个小船沿着S型曲线前行，每次转弯的时候，船头也会跟着转，然后我会不断的摇动小船，似乎有波浪。

![][1]

1、第一个动画，船沿着S型曲线前行：

    CGFloat h = 200;
    CGFloat v = 75;
    CGMutablePathRef path = CGPathCreateMutable();
    int leftright = 1;
    CGPoint next = self.v.layer.position;
    CGPoint pos;
    CGPathMoveToPoint(path, nil, next.x, next.y);
    for (int i = 0; i &lt; 4; i++) {
        pos = next;
        leftright *= -1;
        next = CGPointMake(pos.x+h*leftright, pos.y+v);
        CGPathAddCurveToPoint(path, nil, pos.x, pos.y+30, next.x, next.y-30,
                              next.x, next.y);
    }
    CAKeyframeAnimation* anim1 = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    anim1.path = path;
    anim1.calculationMode = kCAAnimationPaced;
    

2、第二个动画，船转弯

    NSArray* revs = @[@0.0f,
                      @M_PI,
                      @0.0f,
                      @M_PI];
    CAKeyframeAnimation* anim2 = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    anim2.values = revs;
    anim2.valueFunction = [CAValueFunction functionWithName:kCAValueFunctionRotateY];
    anim2.calculationMode = kCAAnimationDiscrete;
    

3、第三个动画

    NSArray* pitches = @[@0.0f,
                         @(M_PI/60.0),
                         @0.0f,
                         @(-M_PI/60.0),
                         @0.0f];
    CAKeyframeAnimation* anim3 = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    anim3.values = pitches;
    anim3.repeatCount = HUGE_VALF;
    anim3.duration = 0.5;
    anim3.additive = YES;
    anim3.valueFunction = [CAValueFunction functionWithName:kCAValueFunctionRotateZ];
    

4、最后组合三个动画

    CAAnimationGroup* group = [CAAnimationGroup animation];
    group.animations = @[anim1, anim2, anim3];
    group.duration = 8;
    [self.v.layer addAnimation:group forKey:nil];
    [CATransaction setDisableActions:YES];
    self.v.layer.position = next;
    

下面是一些CAAnimation属性（来自CAMediaTiming协议），当动画被组合在一起时，这些属性起作用：

*   speed
    
    子动画的时间尺度及父亲的时间尺度之间的比率。例如，如果一个父动画和子动画有相同的持续时间duration，但子动画的速度是1.5，它的动画运行速度是父的1.5倍。

*   fillMode
    
    假设子动画在父动画之前开始，或者在父动画之前结束，或者两者都有。那么在子动画范围之外的这些属性应该怎么显示？答案取决于子动画的fillMode：
    
    1、kCAFillModeRemoved 表示当子动画不运行时移除子动画，恢复图层属性到它当前的实际值。
    
    2、kCAFillModeForwards 表示子动画最后展示图层的值保留
    
    3、kCAFillModeBackwards 表示从一开始就显示子动画初始展示图层的值。
    
    4、kCAFillModeBoth 把上面连个结合起来。

CALayer也实现了CAMediaTiming 协议，一个图层也可以有speed属性，例如一个图层的speed是2，表示它在5秒内执行一个10秒的动画，图层也可以有timeOffset属性，改变动画的显示。

 [1]: http://images.cnitblog.com/blog/406864/201410/132308177947213.png
---
layout: post
title: iOS CALayer 学习（2）
date: 2014-08-08
categories: blog
tags: [iOS]
description: iOS CALayer 学习（2）

---

* * *

## Content Resizing and Positioning

layer的下面的属性决定着缓存中的内容如何拉伸，如何定位，如何剪切等等。

1. contentsGravity

这个属性对应UIView的contentMode属性，描述了layer内容的位置和如何根据bounds来拉伸内容。例如，kCAGravityCenter 表示内容居中在bounds中，不拉伸；kCAGravityResize （默认的值）表示内容拉伸来适应bounds。

2. contentsRect

一个CGRect类型的数据，用来说明即将显示的内容区域，默认是 `{ {0,0},{1,1} }`，表示所有的内容都将显示。指定的显示部分会根据上面的contentsGravity属性来绘制。

你可以使用contentsRect来缩放内容，通过指定一个大于layer的bounds的contentRects来实现，如 `{ {-.5, -.5}, {1.5, 1.5} }` 。

3. contentsCenter

也是一个CGRect类型，描述contentsRect指定的区域内的九宫格内容如何根据contentsGravity来拉伸。中间区域的内容向两个方向拉伸，其它八个区域中，四个角区域不拉伸，四个边缘的区域向一个方向拉伸。类似于我们前面见过的image的拉伸。


## Layers that Draw Themselves， 懂得如何绘制自己的Layer


有几个内建的CALayer子类，提供了一些很有用的绘制方法：

1. CATextLayer

CATextLayer有一个 string 属性，可以是NSString类型或者NSAttributedString类型。这个layer会绘制这个string值。默认的文本和前景颜色是白色。这个文本与内容是不同的，独立的，也就是只能绘制其中一个，所以一般你不应该给CATextLayer任意的图像内容。

2. CAShapeLayer

CAShapeLayer有一个 path 属性，CGPath类型。它会填充或者描边这个路径，也可以两者都绘制，这取决于它的 fillColor 和 strokeColor值。默认fillColor是黑色，strokeColor没有设置。一个CAShapeLayer也可以有内容，那么这个形状就会被绘制在内容图像的顶部，但是没有其它属性允许你指定一个特定的绘制模式。

3. CAGradientLayer

CAGradientLayer有一个简单的线性渐变覆盖在它的背景中，另外，它也很容易用来在你的界面中绘制渐变（如何你有更加特殊的需求，可以一直使用Core Graphics来绘制）。这个与我们前面用Core Graphics来绘制渐变的定义很类似，都是有一个位置的数组，一个与之对应的颜色值的数组（都是NSArray类型，不是c 类型的数组）还有一个起始点和结束点。为了裁切这个渐变的形状，你可以添加一个 mask 遮罩给这个CAGradientLayer（遮罩会在下面解析）。CAGradientLayer的内容不会被绘制。

这个颜色值数组要求CGColor类型，而不是UIColor类型，但是CGColorRef不是一个对象类型，而NSArray要求添加的都是对象类型，所以我们需要对每个颜色都进行类型转换。


## Transforms

layer绘制的方式可以通过一个转换来改变。由于UIView也有转换，可能你觉得没什么，但是layer的转换比view的转换强大得多了，它可以完成view通过转换无法完成的很多东西。

当一个转换是二维的时候，你可以使用layer的 CGAffineTransform。这个转换是围绕 anchorPoint 描点来进行的。

现在让我们来绘制下面这个图案：

![][1]

在代码中，self表示CompassLayer，它不绘制内容，只是仅仅配置它的子layer。四个方向点上的文字都是由CATextLayer绘制，然后使用转换来放置在各自的位置上。它们都是绘制在同一个坐标系上，只是它们有不同的旋转转换而已，虽然CATextLayer 只有40x40，很小，而且在圆边界附近，但是它们都是固定的，所以它们的旋转都是围绕圆心。为了生成这个箭头，我们设置箭头layer的委托为自己，然后调用setNeedsDisplay，这样会导致CompassLayer调用 drawLayer：inContext:。
```
    // the gradient
    CAGradientLayer* g = [CAGradientLayer new];
    g.contentsScale = [UIScreen mainScreen].scale;
    g.frame = self.bounds;
    g.colors = @[(id)[UIColor blackColor].CGColor, (id)[UIColor redColor].CGColor];
    g.locations = @[@0.0f, @1.0f];
    [self addSublayer:g];
    // the circle
    CAShapeLayer* circle = [CAShapeLayer new];
    circle.contentsScale = [UIScreen mainScreen].scale;
    circle.lineWidth = 2.0;
    circle.fillColor =
    [UIColor colorWithRed:0.9 green:0.95 blue:0.93 alpha:0.9].CGColor;
    circle.strokeColor = [UIColor grayColor].CGColor;
    CGMutablePathRef p = CGPathCreateMutable();
    CGPathAddEllipseInRect(p, nil, CGRectInset(self.bounds, 3, 3));
    circle.path = p;
    [self addSublayer:circle];
    circle.bounds = self.bounds;
    circle.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    // the four cardinal points
    NSArray* pts = @[@"N", @"E", @"S", @"W"];
    for (int i = 0; i &lt; 4; i++) {
        CATextLayer* t = [CATextLayer new];
        t.contentsScale = [UIScreen mainScreen].scale;
        t.string = pts[i];
        t.bounds = CGRectMake(0,0,40,40);
        t.position = CGPointMake(CGRectGetMidX(circle.bounds),
        CGRectGetMidY(circle.bounds));
        CGFloat vert = CGRectGetMidY(circle.bounds) / CGRectGetHeight(t.bounds);
        t.anchorPoint = CGPointMake(0.5, vert);
        t.alignmentMode = kCAAlignmentCenter;
        t.foregroundColor = [UIColor blackColor].CGColor;
        t.affineTransform = CGAffineTransformMakeRotation(i*M_PI/2.0);
        [circle addSublayer:t];
    }
    // the arrow
    CALayer* arrow = [CALayer new];
    arrow.contentsScale = [UIScreen mainScreen].scale;
    arrow.bounds = CGRectMake(0, 0, 40, 100);
    arrow.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    arrow.anchorPoint = CGPointMake(0.5, 0.8);
    arrow.delegate = self;
    arrow.affineTransform = CGAffineTransformMakeRotation(M_PI/5.0);
    [self addSublayer:arrow];
    [arrow setNeedsDisplay];
```

 [1]: http://images.cnitblog.com/blog/406864/201410/052237500973622.png


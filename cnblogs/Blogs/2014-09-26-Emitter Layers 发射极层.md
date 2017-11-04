---
layout: post
title: Emitter Layers 发射极层
date: 2014-09-26
categories: blog
tags: [iOS]
description: Emitter Layers 发射极层

---

发射极层（CAEmitterLayer）是在一定程度上与动画图像相提并论的：一旦你建立了一个发射极层，它会自己执行所有的动画。该动画的性质是相当窄的：一个发射极层发射的粒子，是CAEmitterCell实例。但是，通过发射极层的属性和它的发射单元的巧妙设置，可以实现一些惊人的效果。此外，使用Core Animation的动画本身就是动画。

下面是CAEmitterCell一些有用的基本属性：

### contents, contentsRect

这些都是仿照同名的CALayer的属性，虽然CAEmitterLayer不是CALayer的子类;对应于一个图像（CGImageRef）和一个CGRect指定这个图像的区域。他们定义了单元格将要绘制的图像。

### birthrate, lifetime

分别表示，每秒钟发射多少个单元，每个单元存活多少时间。

### velocity

一个单元移动的速度，文档中没有说明单位是什么，可能是每秒钟移动多少个点。

### emissionLatitude, emissionLongitude

单元从发射层射出来的角度，相对于垂直的变化。Longitude是平面内的角度，latitude是平面上的角度。

下面的代码构造了一个基本的发射单元：

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(10,10), NO, 1);
    CGContextRef con = UIGraphicsGetCurrentContext();
    CGContextAddEllipseInRect(con, CGRectMake(0,0,10,10));
    CGContextSetFillColorWithColor(con, [UIColor grayColor].CGColor);
    CGContextFillPath(con);
    UIImage* im = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    CAEmitterCell* cell = [CAEmitterCell emitterCell];
    cell.birthRate = 5;
    cell.lifetime = 1;
    cell.velocity = 100;
    cell.contents = (id)im.CGImage;
    

在第一行中，我们没有在双分辨率的屏幕中把scale 乘以2，因为CAEmitterLayer就像CALayer一样，没有contentsScale属性。我们将从这个image中得到一个CGImage，我们不想它的大小增加一倍。

其结果是，灰色小圆圈缓慢而稳定地每秒钟射出5个，每一个都存活5秒钟。现在我们需要构造一个发射这些小圆圈的发射极层。下面是一些CAEmitterLayer的基本属性（是从CALayer继承之外的），这些属性定义了一个假想的发射器，会产生发射极单元：

### emitterPosition

该发射器应该是在superlayer的坐标内。你可以选择性地为这个点添加一个三维立体位置，emitterZPosition。

### emitterSize

发射器的大小

### emitterShape

发射器的形状。形状的尺寸依赖于发射器的大小;长方体形状也依赖于第三个尺寸的大小，emitterDepth。你可以选择：

*   kCAEmitterLayerPoint

*   kCAEmitterLayerLine

*   kCAEmitterLayerRectangle

*   kCAEmitterLayerCuboid

*   kCAEmitterLayerCircle

*   kCAEmitterLayerSphere

### emitterMode

在发射器形状的哪个区域发射这些单元，你可以选择：

*   kCAEmitterLayerPoints

*   kCAEmitterLayerOutline

*   kCAEmitterLayerSurface

*   kCAEmitterLayerVolume

让我们从一个最简单的情况开始吧，就是一个点的发射器：

    CAEmitterLayer* emit = [CAEmitterLayer new];
    emit.emitterPosition = CGPointMake(30,100);
    emit.emitterShape = kCAEmitterLayerPoint;
    emit.emitterMode = kCAEmitterLayerPoints;
    

我们要告诉发射器要发射什么类型的单元，通过设置它的emitterCells属性（一个CAEmitterCell 的数组）。然后我们把这个发射器添加到我们的界面上，最后开始发射：

![][1]

    emit.emitterCells = @[cell];
    [self.view.layer addSublayer:emit];
    

其结果是从点{30,100}发出的灰色圆圈络绎不绝，每个圆圈稳步前进到右侧，一秒钟后消失

现在，我们已经成功地创造了一个无聊的发射极层，我们可以开始改变一些参数。emissionRange属性定义了一个锥形，单元会从这个锥形发射出来;如果我们增加birthRate和扩大emissionRange，我们得到的东西看起来像水从水管流出来：

    cell.birthRate = 100;
    cell.lifetime = 1.5;
    cell.velocity = 100;
    cell.emissionRange = M_PI/5.0;
    

另外，当单元移动时，它可以每个维度上进心加速或者减速，利用其xAcceleration，yAcceleration和zAcceleration属性。在这里，我们把水流变成沿梯形留下，像瀑布一样从左边留下来：

    cell.xAcceleration = -40;
    cell.yAcceleration = 200;
    

单元行为的所有方面都可以是随机的，使用下面CAEmitterCell属性：

### lifetimeRange, velocityRange

单元存活时间和速度的随机变化范围

### scale

### scaleRange, scaleSpeed

单元大小改变的范围，这个range 和 speed 决定了在单元存活时间里，它的大小变化的范围和速度

### color

### redRange, greenRange, blueRange, alphaRange

### redSpeed, greenSpeed, blueSpeed, alphaSpeed

这color是根据单元内容图像的不透明度绘制的颜色，它结合了图像的颜色，因此，如果我们希望这个颜色是完全纯色，我们的内容图像应该只能用白色。range和speed决定了颜色的每个分量改变的范围和速度。

### spin, spinRange

spin是自转的速度（弧度每秒）；range决定了在单元存活时间里速度的变化范围

在这里，我们添加一些变化，使得圆圈表现稍微彼此独立。有些存活比别的更长，一些发射的初始速度比别的更快。他们都开始于蓝色的底色，然后在流的一半时变成绿色：

![][2]

    cell.lifetimeRange = .4;
    cell.velocityRange = 20;
    cell.scaleRange = .2;
    cell.scaleSpeed = .2;
    cell.color = [UIColor blueColor].CGColor;
    cell.greenRange = .5;
    cell.greenSpeed = .75;
    

一旦发射极层显示和在执行动画，你可以通过KVC来改变单元的属性和发射极层自己的属性。你可以通过发射极层的@"emitterCells"键路径来访问发射单元，为了指定一个单元类型，可以使用它的name属性。例如，我们设置 cell.name = @"circle"，现在我们改变cell 的greenSpeed，让每个单元在生命周期的早期就开始从蓝色变为绿色：

    [emit setValue:@3.0f
        forKeyPath:@"emitterCells.circle.greenSpeed"];
    

这样做的意义是，这样的变化可以自己进行动画！在这里，我们将给发射极层添加一个重复动画让每个单元的Greenspeed在两个值间来回变化。其结果是，这个流中，随着时间的推移，单元的颜色介于蓝色和绿色之间：

    NSString* key = @"emitterCells.circle.greenSpeed";
    CABasicAnimation* ba = [CABasicAnimation animationWithKeyPath:key];
    ba.fromValue = @-1.0f;
    ba.toValue = @3.0f;
    ba.duration = 4;
    ba.autoreverses = YES;
    ba.repeatCount = HUGE_VALF;
    [emit addAnimation:ba forKey:nil];
    

一个CAEmitterCell自身也可以作为一个发射器---就是说，它可以有自己的单元。 CAEmitter和CAEmitterCell都实现了CAMediaTiming协议，它们的beginTime 和 duration可以用来管理执行的次数，尽可能地在一个组合动画里。例如，下面的代码会导致我们现有的瀑布式流在“喷嘴”的区域（发射极）会喷射微小液滴：

    CAEmitterCell* cell2 = [CAEmitterCell emitterCell];
    cell.emitterCells = @[cell2];
    cell2.contents = (id)im.CGImage;
    cell2.emissionRange = M_PI;
    cell2.birthRate = 200;
    cell2.lifetime = 0.4;
    cell2.velocity = 200;
    cell2.scale = 0.2;
    cell2.beginTime = .04;
    cell2.duration = .2;
    

但是，如果我们改变beginTime太大，微小液滴会发生在梯级的底部附近。这时我们还必须增加duration，或两个属性都不设置，因为如果持续时间duration小于beginTime，将没有发射发生：

![][3]

    cell2.beginTime = .7;
    cell2.duration = .8;
    

我们还可以通过改变发射器本身的行为来改变图像。这种变化会把发射器变成一条线，让我们的梯级变宽：

![][4]

    emit.emitterPosition = CGPointMake(100,25);
    emit.emitterSize = CGSizeMake(100,100);
    emit.emitterShape = kCAEmitterLayerLine;
    emit.emitterMode = kCAEmitterLayerOutline;
    cell.emissionLongitude = 3*M_PI/4;

 [1]: http://images.cnitblog.com/blog/406864/201410/162212580765447.png
 [2]: http://images.cnitblog.com/blog/406864/201410/162232098262247.png
 [3]: http://images.cnitblog.com/blog/406864/201410/162304137486248.png
 [4]: http://images.cnitblog.com/blog/406864/201410/162305278264247.png
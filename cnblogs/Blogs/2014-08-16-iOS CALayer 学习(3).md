---
layout: post
title: iOS CALayer 学习（3）
date: 2014-08-16
categories: blog
tags: [iOS]
description: iOS CALayer 学习（3）

---

* * *

## Depth

有两种方法来把layer放置在不同的深度。一个是通过zPosition属性，一个是通过转换来改变layer在z轴方向上的位置。 zPosition和在z轴上的转换是有联系的，从某种意义上，zPosition是z轴方向上的转换的一种速记方式（如果你同时提供zPosition和z轴的转换，只会令你迷惑）。

在现实世界中，改变一个对象的zPosition会让这个对象变得更大或者更小，就像一个东西放近一点和放远一点，但是，默认情况下，layer的绘制并不是这样。layer会按照本身实际大小来绘制，然后拍扁了在一起，没有距离上的混淆。（这称为正射投影，或者是平行投影）。

例如，我们给箭头一个翻页的效果：我们固定住右边，然后在y轴方向上旋转。这里，我们需要旋转的子layer是 渐变layer，那么它的圆形和箭头是这个渐变layer的子layer，也会一起旋转。

    self.rotationLayer.anchorPoint = CGPointMake(1,0.5);
    self.rotationLayer.position =
    CGPointMake(CGRectGetMaxX(self.bounds), CGRectGetMidY(self.bounds));
    self.rotationLayer.transform = CATransform3DMakeRotation(M_PI/4.0, 0, 1, 0);
    

![][1]

但是上面的结果让我们有点失望，感觉这个指南针像是被挤压了，而不是旋转了。现在，我们提供距离映射上的转换。这个superlayer就是self：

    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = -1.0/1000.0;
    self.sublayerTransform = transform;
    

![][2]

这个结果就好多了。

另一个绘制layers的深度的方法就是使用CATransformLayer。这个CALayer的子类没有做什么实际的绘制，只是其它layer的一个宿主。它有一个很厉害的功能，就是你可以提供一个转换给它，它会帮你管理好它自己的子layers之间的深度关系，例如：

    // lay1 is a layer, f is a CGRect
    CALayer* lay2 = [CALayer layer];
    lay2.frame = f;
    lay2.backgroundColor = [UIColor blueColor].CGColor;
    [lay1 addSublayer:lay2];
    CALayer* lay3 = [CALayer layer];
    lay3.frame = CGRectOffset(f, 20, 30);
    lay3.backgroundColor = [UIColor greenColor].CGColor;
    lay3.zPosition = 10;
    [lay1 addSublayer:lay3];
    lay1.transform = CATransform3DMakeRotation(M_PI, 0, 1, 0);
    

上面的代码中，父layer lay1有两个子layer，lay2和lay3.根据添加的顺序，lay3绘制在lay2的前面。那么我们提供一个转换给lay1来实现类似翻页的效果。如果lay1是一个普通的CALayer，它的子layer的绘制顺序不会改变，lay3仍然绘制在lay2的前面，即使添加了这个转换后。但是，如果lay1是一个CATransformLayer，在转换后，lay3绘制在lay2之后，它们都是lay1的子layer，所以它们的深度关系被管理好了。

![][3]

上图展示了CATransformLayer的效果,为了区分各个子layer，特意添加了阴影：

    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = -1.0/1000.0;
    self.sublayerTransform = transform;
    CATransformLayer* master = [CATransformLayer layer];
    master.frame = self.bounds;
    [self addSublayer: master];
    self.rotationLayer = master;
    circle.zPosition = 10;
    arrow.shadowOpacity = 1.0;
    arrow.shadowRadius = 10;
    arrow.zPosition = 20;
    

你可以清楚地看到这个渐变layer与这个圆形layer的偏移，而且我还在箭头中添加了一个白色条：

    CAShapeLayer* peg = [CAShapeLayer new];
    peg.contentsScale = [UIScreen mainScreen].scale;
    peg.bounds = CGRectMake(0,0,3.5,50);
    CGMutablePathRef p2 = CGPathCreateMutable();
    CGPathAddRect(p2, nil, peg.bounds);
    peg.path = p2;
    CGPathRelease(p2);
    peg.fillColor =
    [UIColor colorWithRed:1.0 green:0.95 blue:1.0 alpha:0.95].CGColor;
    peg.anchorPoint = CGPointMake(0.5,0.5);
    peg.position =
    CGPointMake(CGRectGetMidX(master.bounds), CGRectGetMidY(master.bounds));
    [master addSublayer: peg];
    [peg setValue:@(M_PI/2) forKeyPath:@"transform.rotation.x"];
    [peg setValue:@(M_PI/2) forKeyPath:@"transform.rotation.z"];
    peg.zPosition = 15;
    

* * *

## Shadows，Borders，and Masks

一个CALayer有shadowColor，shadowOpacity，shadowRadius和shadowOffset属性，可以用来绘制阴影，为了显示阴影，需要设置shadowOpacity为非零值。这个阴影通常是根据layer的不透明区域来绘制的，但是计算这个不透明区域需要大量的计算（所以在早期版本的iOS系统，layer的阴影是没有实现的）。为了提高绘制阴影的效率，你可以定义一个形状，然后把这个形状包装成CGPath，赋值给shadowPath属性。

一个CALayer可以有一个边框（borderWidth，borderColor）；这个borderWidth是绘制在bounds的内边框的。

一个CALayer可以有一个遮罩，遮罩本身也是一个layer，只是必须提供内容。遮罩内容在一些特别的点上的透明度就是layer在该点的透明度，与遮罩颜色的色调是不相关的，只有透明度有关。

下面,有一个灰色的圆形layer在我们的箭头layer后面。箭头layer还加上了一个遮罩，这个遮罩很简单，但是非常好地解析了遮罩是如何工作的：是一个椭圆，不透明填充，有一个半透明的，很粗大的描边。

    CAShapeLayer* mask = [CAShapeLayer new];
    mask.frame = arrow.bounds;
    CGMutablePathRef p2 = CGPathCreateMutable();
    CGPathAddEllipseInRect(p2, nil, CGRectInset(mask.bounds, 10, 10));
    mask.strokeColor = [UIColor colorWithWhite:0.0 alpha:0.5].CGColor;
    mask.lineWidth = 20;
    mask.path = p2;
    arrow.mask = mask;
    CGPathRelease(p2);
    

![][4]

下面是一个产生圆角矩形遮罩的layer的帮助方法：

    - (CALayer*) maskOfSize:(CGSize)sz roundingCorners:(CGFloat)rad {
        CGRect r = (CGRect){CGPointZero, sz};
        UIGraphicsBeginImageContextWithOptions(r.size, NO, 0);
        CGContextRef con = UIGraphicsGetCurrentContext();
        CGContextSetFillColorWithColor(con,[UIColor colorWithWhite:0 alpha:0].CGColor);
        CGContextFillRect(con, r);
        CGContextSetFillColorWithColor(con,[UIColor colorWithWhite:0 alpha:1].CGColor);
        UIBezierPath* p = [UIBezierPath bezierPathWithRoundedRect:r cornerRadius:rad];
        [p fill];
        UIImage* im = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        CALayer* mask = [CALayer layer];
        mask.frame = r;
        mask.contents = (id)im.CGImage;
        return mask;
    }
    

返回的这个layer可以当作一个遮罩添加到一个layer中，只要指定frame和设置layer的 mask即可。产生的结果是，所有layer中内容和它的子layer都会被剪切成圆角形状，在这个形状外面的部分都不会绘制。

 [1]: http://images.cnitblog.com/blog/406864/201410/052243009562423.png
 [2]: http://images.cnitblog.com/blog/406864/201410/052243319878003.png
 [3]: http://images.cnitblog.com/blog/406864/201410/052244047065899.png
 [4]: http://images.cnitblog.com/blog/406864/201410/052244397849182.png
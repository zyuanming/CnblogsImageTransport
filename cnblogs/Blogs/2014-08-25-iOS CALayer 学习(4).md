---
layout: post
title: iOS CALayer 学习（4）
date: 2014-08-25
categories: blog
tags: [iOS]
description: iOS CALayer 学习（4）

---

* * *

## Layer Efficiency

绘制一个圆形的image

    // clip to rounded rect
    CGRect r = CGRectInset(rect, 1, 1);
    [[UIBezierPath bezierPathWithRoundedRect:r cornerRadius:6] addClip];
    // draw image
    UIImage* im = [UIImage imageNamed: @"linen.jpg"];
    // simulate UIViewContentModeScaleAspectFill
    // make widths the same, image height will be too tall
    CGFloat scale = im.size.width/rect.size.width;
    CGFloat y = (im.size.height/scale - rect.size.height) / 2.0;
    CGRect r2 = CGRectMake(0,-y,im.size.width/scale, im.size.height/scale);
    r2 = CGRectIntegral(r2); // looks a whole lot better if we do this
    [im drawInRect:r2];
    

* * *

## Layer and Key-Value Coding

所有的layer属性都可以用键值编码的方式来访问。例如 layer.mask = mask;

我们可以写成： [layer setValue: mask forKey: @"mask"];

此外，CATransform3D和 CGAffineTransform值也可以通过键值编码的方式来访问：

    self.rotationLayer.transform = CATransform3DMakeRotation(M_PI/4.0, 0, 1, 0);
    

我们可以写成：

    [self.rotationLayer setValue:[NSNumber numberWithFloat:M_PI/4.0] forKeyPath:@"transform.rotation.y"];
    

但是由于CATransform3D没有rotation属性，所以你不能这样写：

    self.rotationLayer.transform.rotation.y = //... No, sorry
    

这个转换的键路径，可以使用：rotation.x, rotation.y, rotation.z, rotation(same as rotation.z), scale.x, scale.y, scale.z, translation.x, translation.y, translation.z, and translation (two-dimensional, a CGSize).

上次我们说到，layer没有像view的tag这样的属性，没有 viewWithTag：这样的方法，我们如果需要识别layer，可以使用键值编码：

    [myLayer1 setValue:@"Manny" forKey:@"name"];
    [myLayer2 setValue:@"Moe" forKey:@"name"];
    

注意layer没有name属性。

CALayer还有一个类方法：defaultValueForKey: 为了实现它，你需要子类化CALayer，并重写这个方法。如果你想为某个键提供默认的值，你可以在这个方法里，返回你想要的值，否则，调用父类的方法。
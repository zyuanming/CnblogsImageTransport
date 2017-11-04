---
layout: post
title: iOS Actions
date: 2014-09-23
categories: blog
tags: [iOS]
description: iOS Actions

---

为了完整起见，我现在会解释隐式动画是如何工作的 - 也就是隐式动画如何在后台转换成显式动画。隐式动画的基础是动作机制。

* * *

## 什么是动作 Action？

一个动作是一个实现了CAAction 协议的对象。意味着这个对象实现了 runActionForKey:object:arguments:。这个动作对象可以做任何事情来响应这个消息。实际上，只有CAAnimation 实现了CAAction这个协议。

你不能直接向一个动画发送runActionForKey:object:arguments:消息，而是作为一个基本的隐式动画，系统会为你向一个动画发送这个消息。key就是你设置的属性，object就是你要设置的这个图层。当一个动画收到runActionForKey:object:arguments:这个消息，会假设第二个参数object 是一个layer，然后把它自己添加到这个layer的动画列表中。另外，对于一个动画来说，收到runActionForKey:object:arguments: 这个消息就像被告知：“执行你自己”。

之前我说过，如果一个动画的keyPath是nil，那么会使用添加到动画列表中对应的key来作为keyPath。当一个动画收到runActionForKey:object:arguments:消息，它会调用[object addAnimation:self forKey:key]来回复，key就是这个要设置的属性的名字。对于一个隐式图层动画来说，它的keyPath实际上经常是nil。

* * *

## 动作搜索

当你设置一个图层的属性，引发一个隐式动画时，你实际上就触发了东作搜索。通常意味着图层会搜索能够发送runActionForKey:object:arguments: 这个消息的动作对象，因为这个动作对象将是一个动作，而且它会通过添加自己到这个图层的动画列表中来响应这个消息。通俗点讲，就是图层搜索一个跟自己相关的动画来执行。

当你做了某些事情，让图层发送actionForKey: 消息，会导致开始搜索一个动作对象。假设你现在改变一个可执行动画的属性，动作机制会把这个属性当作key，图以这key为参数的actionForKey:消息，动作搜索开始。

在动作搜索的各个阶段中，返回值遵循下面的规则：

一个动作对象：

如果一个动作对象被生成，那么搜索结束。动作机制会向这个动画发送runActionForKey:object:arguments:消息，这个动画会添加自己到图层的动画列表中来响应。

[NSNull null]

如果产生[NSNull null]，那么搜索结束。将不会有隐式动画，[NSNull null] 意味着：什么都不要做了，停止搜索。

nil

如果产生nil，那么搜索继续下一个阶段。

动作搜索会经历下面的阶段：

1.  图层的actionForKey: 可能会在搜索之前就中断了。例如，这个图层时视图的根图层，或者属性设置为同样的值。在这种情况下，将不会有隐私动画，跟前面返回一个nil的情况时一样的。

2.  如果图层有一个实现了actionForLayer:forKey:的委托，那么消息会发送给这个委托对象。如果返回一个动画或者[NSNull null]，搜索结束。

3.  图层有一个字典类型的actions 属性，如果在这个字典中有对应key的实体存在，那么会使用这个value，搜索结束。

4.  图层有一个字典类型的style属性。如果这个字典中有一个key为actions的实体，被认为是字典类型，如果这个actions字典有给定的key对应的值，那么会返回这个值，搜索结束。如果有一个叫做style的实体在这个style属性中，会递归地在这个style里面也执行搜索，直到找到一个给定key对应的动作实体或者全部都没有style实体（搜索继续）。

5.  这个图层类会收到defaultActionForKey:消息，如果返回一个动作或者[NSNull null]，搜索结束。

6.  如果搜索到达最后一个阶段，会提供一个默认的动画，对于一个属性动画，这是一个普通的CABasicAnimation。

* * *

## 挂接动作搜索 Hooking into the Actions

你可以在搜索被触发后的各个阶段中，影响这个动作搜索。实际中会用来对某些特定的属性关闭隐式动画。通过在actionForKey:中返回nil。下面就是禁用图层的position属性的隐式动画：

    -(id<CAAction>)actionForKey:(NSString *)event {
        if ([event isEqualToString:@"position"])
            return nil;
        return [super actionForKey:event];
    }
    

为了更加灵活，我们可以充分利用CALayer可以像字典一样的优势－－－嵌入一个开关到我们的CALayer子类里面，用它来控制开和关：

    -(id<CAAction>)actionForKey:(NSString *)event {
        if ([event isEqualToString:@"position"] &&
                [self valueForKey:@"suppressPositionAnimation"])
            return nil;
        return [super actionForKey:event];
    }
    

为了关闭这个position属性的隐式动画，我们可以：

    [layer setValue:@YES forKey:@"suppressPositionAnimation"];
    

另外，如果你没有设置动画的某些属性，你可以通过CATransaction来设置。然而，如果你设置了动画的属性，那么不能通过CATransaction来覆盖这个属性。

    CABasicAnimation* ba = [CABasicAnimation animation];
    ba.duration = 5;
    layer.actions = @{@"position": ba};
    [CATransaction setAnimationDuration:1];
    layer.position = CGPointMake(100,100); // 动画仍然执行5秒
    

使用图层的actions字典设置默认的动画是一个挂接到动作搜索中不太灵活的方式，它一般有一个缺点，就是你必须预先编写动画。相反，如果你设置图层的委托，以一个实例来响应actionForLayer：forKey：，你的代码可以在需要动画时运行，并且可以访问这个执行动作的图层。所以，你可以动态创建动画，可能针对目前的情况修改它。

此外，CATransaction（如CALayer的）实现KVC，让您可以设置和检索任意键的值。我们可以利用这一点优势，从设置的属性值代码中传递更多的信息到提供动作的代码中（因为它们都在同一个事务中运行），然后触发动作搜索。

在这个例子中，我使用图层的委托来改变默认的position属性动画，不再是一条直线，而是有点轻微摆动的线。为了达到这个目的，这个委托构造了一个关键帧动画。

动画取决于旧位置值和新的位置值;委托可以直接从该层得到前者，但后者必须以某种方式交给委托。在这里，一个CATransaction键@“NEWP”用于传达此信息。当我们设置图层的位置时，我们传入所在的委托可以检索的position未来值，像这样：

    CGPoint newP = CGPointMake(300,300);
    [CATransaction setValue: [NSValue valueWithCGPoint: newP] forKey: @"newP"];
    layer.position = newP;
    

委托会被动作搜索调用，构造的动画：

    - (id <CAAction >)actionForLayer:(CALayer *)layer forKey:(NSString *)key {
        if ([key isEqualToString: @"position"]) {
            CGPoint oldP = layer.position;
            CGPoint newP = [[CATransaction valueForKey: @"newP"] CGPointValue];
            CGFloat d = sqrt(pow(oldP.x - newP.x, 2) + pow(oldP.y - newP.y, 2));
            CGFloat r = d/3.0;
            CGFloat theta = atan2(newP.y - oldP.y, newP.x - oldP.x);
            CGFloat wag = 10*M_PI/180.0;
            CGPoint p1 = CGPointMake(oldP.x + r*cos(theta+wag),
                                     oldP.y + r*sin(theta+wag));
            CGPoint p2 = CGPointMake(oldP.x + r*2*cos(theta-wag),
                                     oldP.y + r*2*sin(theta-wag));
            CAKeyframeAnimation* anim = [CAKeyframeAnimation animation];
            anim.values = @[
                           [NSValue valueWithCGPoint:oldP],
                           [NSValue valueWithCGPoint:p1],
                           [NSValue valueWithCGPoint:p2],
                           [NSValue valueWithCGPoint:newP]
                           ];
            anim.calculationMode = kCAAnimationCubic;
            return anim;
        }
        return nil; 
    }
    

最后，我讲一下覆盖defaultActionForKey:方法。这个代码在CALayer的子类中，设置这个图层的内容现在会自动触发一个从左边push的转换动画：

    + (id<CAAction >)defaultActionForKey:(NSString *)aKey {
        if ([aKey isEqualToString:@"contents"]) {
            CATransition* tr = [CATransition animation];
            tr.type = kCATransitionPush;
            tr.subtype = kCATransitionFromLeft;
            return tr;
         }
         return [super defaultActionForKey: aKey];
    }
    

* * *

## 非属性动作 Nonproperty Actions

改变一个属性值并不是触发动作搜索的唯一方式，一个图层添加到父图层（key 为 kCAOnOrderIn）或者一个图层的子图层添加或删除了一个子子图层（key 为 @“sublayers”）也会触发动作搜索。

在这个例子中，我们使用图层委托，当我们的图层被添加到一个父图层，它会“pop”进视图中。我们通过迅速把图层的不透明度减少为0，同一时间，拉伸这个图层的变换，让它变得有点大：

    - (id <CAAction >)actionForLayer:(CALayer *)lay forKey:(NSString *)key {
        if ([key isEqualToString:kCAOnOrderIn]) {
            CABasicAnimation* anim1 =
                [CABasicAnimation animationWithKeyPath:@"opacity"];
            anim1.fromValue = @0.0f;
        anim1.toValue = @(lay.opacity);
            CABasicAnimation* anim2 =
                [CABasicAnimation animationWithKeyPath:@"transform"];
            anim2.toValue =
                [NSValue valueWithCATransform3D:
                    CATransform3DScale(lay.transform, 1.1, 1.1, 1.0)];
            anim2.autoreverses = YES;
            anim2.duration = 0.1;
            CAAnimationGroup* group = [CAAnimationGroup animation];
            group.animations = @[anim1, anim2];
            group.duration = 0.2;
            return group;
        } 
    }
    

文档中说，当一个图层从父图层中被移除时，会搜索一个key为kCAOnOrderOut的动作。这是真的，但是没有什么用处，因为在搜索动作时，图层已经被移除了，所以返回的动画没有可视的效果。同样的，当一个图层的hidden 为YES时，返回的动画也是不会执行。一个解决方法是通过opacaity 属性触发动画，也许可以结合CATransaction的键值功能来作为一个开关。

    [CATransaction setCompletionBlock: ^{
        [layer removeFromSuperlayer];
    }];
    [CATransaction setValue:@YES forKey:@"byebye"];
    layer.opacity = 0;
    

现在，委托的actionForLayer:forKey: 方法中可以判断是否有key @“opacity”和 这个CATransaction 的 key@“byebye”，然后返回一个适合于图层被移除的动画。

    if ([key isEqualToString:@"opacity"]) {
        if ([CATransaction valueForKey:@"byebye"]) {
            CABasicAnimation* anim1 =
                [CABasicAnimation animationWithKeyPath:@"opacity"];
            anim1.fromValue = @(layer.opacity);
            anim1.toValue = @0.0f;
            CABasicAnimation* anim2 =
                [CABasicAnimation animationWithKeyPath:@"transform"];
            anim2.toValue =
                [NSValue valueWithCATransform3D:
                    CATransform3DScale(layer.transform, 0.1, 0.1, 1.0)];
            CAAnimationGroup* group = [CAAnimationGroup animation];
            group.animations = @[anim1, anim2];
            group.duration = 0.2;
            return group;
        }
     }
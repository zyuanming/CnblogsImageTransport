---
layout: post
title: CIFilter Transitions & UIKit Dynamics
date: 2014-09-29
categories: blog
tags: [iOS]
description: CIFilter Transitions & UIKit Dynamics

---

## CIFilter Transitions : CIFilter 转换

Core Image 过滤器包含了转换。你提供两张图片和一个介于0到1的帧时间；过滤器提供一秒内从第一张图片转换到第二张图片的相应帧。例如下图显示了在0.75秒时的帧画面，正在从纯红色的图片通过星光发射转换动画转换到我自己的图片。（你看不到这张我的图片，因为这个转换，默认会先把第一张图片“爆炸”成纯白色，然后迅速消失，出现第二张图片）

![][1]

驱动一个Core Image 转换过滤器执行动画是由你决定。因此，我们需要反复快速调用相同方法的途径;在该方法中，我们将请求并绘制转换的每个帧。这可以用NSTimer来做，但是还有一种更好的方法，就是使用 CADisplayLink，这是定时器的一种高效形式，特别是涉及到重复绘制的时候，因为它是直接与显示刷新相关联的（字面上）。显示刷新速率通常为约60分之一秒;实际值是作为CADisplayLink的持续时间，并会进行小幅波动。像一个计时器，CADisplayLink在每次触发时会调用我们的指定方法。我们可以通过设置CADisplayLink的frameInterval属性来减慢这个调用速率。例如，当frameInterval为2时，表示每30分之一秒调用我们的方法。我们还可以通过timestamp属性知道CADisplayLink运行了多长时间。

    UIImage* moi = [UIImage imageNamed:@"moi"];
    CIImage* moi2 = [[CIImage alloc] initWithCGImage:moi.CGImage];
    self->_moiextent = moi2.extent;
    CIFilter* col = [CIFilter filterWithName:@"CIConstantColorGenerator"];
    CIColor* cicol = [[CIColor alloc] initWithColor:[UIColor redColor]];
    [col setValue:cicol forKey:@"inputColor"];
    CIImage* colorimage = [col valueForKey: @"outputImage"];
    CIFilter* tran = [CIFilter filterWithName:@"CIFlashTransition"];
    [tran setValue:colorimage forKey:@"inputImage"];
    [tran setValue:moi2 forKey:@"inputTargetImage"];
    CIVector* center =
        [CIVector vectorWithX:self->_moiextent.size.width/2.0
                            Y:self->_moiextent.size.height/2.0];
    [tran setValue:center forKey:@"inputCenter"];
    self->_con = [CIContext contextWithOptions:nil];
    self->_tran = tran;
    self->_timestamp = 0.0;
    

我们创建了CADisplayLink，设置它调用我们的nextFrame:方法，然后把它添加到run loop中：

    CADisplayLink* link =
        [CADisplayLink displayLinkWithTarget:self
            selector:@selector(nextFrame:)];
    

[link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];

我们的nextFrame:方法的参数是CADisplayLink。我们把初始化的timestamp保存在一个实例变量中，然后根据当前时间和这个timestamp的差异，计算出我们想要的帧。当这个frame值到达1时，动画结束，我们把这个CADisplayLink失效（就像一个定时器），从run loop中移除：

    if (self->_timestamp &lt; 0.01) { // pick up and store first timestamp
        self->_timestamp = sender.timestamp;
        self->_frame = 0.0;
    } else { // calculate frame
        self->_frame = sender.timestamp - self->_timestamp;
    }
    sender.paused = YES; // 防止帧丢失
    [_tran setValue:@(self->_frame) forKey:@"inputTime"];
    CGImageRef moi = [self->_con createCGImage:_tran.outputImage
                                      fromRect:_moiextent];
    [CATransaction setDisableActions:YES];
    self.v.layer.contents = (__bridge id)moi;
    CGImageRelease(moi);
    if (_frame > 1.0) {
        [sender invalidate];
    }
    sender.paused = NO;
    

* * *

## UIKit Dynamics

UIKit Dynamics 是一系列类的组合，提供了很方便的API来提供在让人联想到现实世界的物理行为的方式制作动画。例如，视图可以受到重力，碰撞，以及瞬时力的作用。

UIKit dynamics 不应该被视为一个游戏引擎。这是有意让它非常卡通化和简单，把视图当作一个矩形块，只能让它们的position（center）和二维空间旋转变换执行动画。而且UIKit dynamics也不是供扩展使用的。就像是实现动画的另一种方式，它只是短暂强调或澄清你的界面功能转换的方式。

使用UIKit dynamics 需要依次配置三个东西：

### a dynamic animator 动态动画制作器

一个动态动画，就是一个UIDynamicAnimator实例，是你创建的物理世界的规则。它有一个参考视图，是将要执行动画的视图的父视图，定义了在这个物理世界中的坐标系统。你可以保留这个animator的强引用。你可以让一个animator一直为空，知道你需要；一个animator所在的世界是空的，没有运行，也不占用CPU时间。

### a behavior 一个行为

一个UIDynamicBehavior定义了一个视图行为的规则。您通常会使用一个内置的子类，如UIGravityBehavior或UICollisionBehavior。一个animator有一些属性可以控制它的行为，例如addBehavior:, behaviors, removeBehavior:, 和 removeAllBehaviors。一个行为的配置是可以被改变的，即使当动画正在执行，行为也可以添加到动画器上或者从动画器上移除。

### An item

一个item 可以是实现了UIDynamicItem协议的任何对象。UIView就是这样的一个对象！你添加一个UIView（是你的动画器参考视图的一个子视图）到一个行为上（属于这个动画器的），从那时起，视图受到了来自这个行为的影响。如果这个行为触发了运动，同时又没有其它的行为阻止，那么视图将会移动（动画器开始执行）。

一些行为可以接收多个items，它提供了addItem:, items, 和 removeItem:这个的方法。其它的可以有一个或者两个items，而且必须从一开始就初始化。

下面我们一起实践一下，我将创建我的动画器和保存它到一个属性中：

    self.anim = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    

现在我要让一个self.view 的子视图（一个UIImageView，self.iv）在重力的作用下从屏幕上掉下来。我创建一个UIGravityBehavior，添加到一个动画器，然后把self.iv添加给它：

    UIGravityBehavior* grav = [UIGravityBehavior new];
    [self.anim addBehavior:grav];
    [grav addItem:self.iv];
    

但是这个落下的视图会永远向下落，这个很浪费内存和CPU资源的。如果在视图离开了屏幕后，我们不需要了，那我们应该移除这个行为（我们也可以从父视图中移除这个视图）。我们可以直接调用removeAllBehaviors把所有的行为移除。

但是我们怎么知道视图已经离开了屏幕呢？UIDynamicBehavior可以有一个action block，会被驱动这个动画的动画器不断重复调用。我将使用这个block来检查self.iv是否还在参考视图的bounds范围内，调用这个动画器的itemsInRect: 方法可以做到（需要注意循环引用）：

    grav.action = ^{
        NSArray* items = [self.anim itemsInRect:self.view.bounds];
        if (NSNotFound == [items indexOfObject:self.iv]) {
            [self.anim removeAllBehaviors];
            [self.iv removeFromSuperview];
        }
    };
    

让我们添加一些进一步的行为，如果只是直线落下太无聊，我们可以添加一个UIPushBehavior，来创造一种在开始下落时有种轻微向右的冲动：

    UIPushBehavior* push =
        [[UIPushBehavior alloc] initWithItems:@[self.iv]
            mode:UIPushBehaviorModeInstantaneous];
    push.pushDirection = CGVectorMake(2, 0);
    [self.anim addBehavior:push];
    

现在视图会以抛物线向右落下。

接下来，让我们添加一个UICollisionBehavior来使我们的视图撞击屏幕底部“地板”：

    UICollisionBehavior* coll = [UICollisionBehavior new];
    coll.collisionMode = UICollisionBehaviorModeBoundaries;
    [coll addBoundaryWithIdentifier:@"floor"
        fromPoint:CGPointMake(0,self.view.bounds.size.height)
        toPoint:CGPointMake(self.view.bounds.size.width,
                            self.view.bounds.size.height)];
    [self.anim addBehavior:coll];
    [coll addItem:self.iv];
    

现在视图以抛物线落在屏幕的“地板”上，稍微反弹一点点，然后就停止了。如果反弹更多一点可能会更好。

一个动态item的物理特性是内部的特性，例如反弹力（弹性），这些是由UIDynamicItemBehavior配置的：

    UIDynamicItemBehavior* bounce = [UIDynamicItemBehavior new];
    bounce.elasticity = 0.4;
    [self.anim addBehavior:bounce];
    [bounce addItem:self.iv];
    

我们的视图弹跳得更高了，然而，当它击中地面时，它停止向右移动，所以最终会在地面停止。我更喜欢的效果是，它反弹后，开始转到右边，最后离开屏幕。UICollisionBehavior有一个委托，当碰撞发生时，这个委托会发送消息。我让self作为这个collision行为的委托，当这个委托的消息到达时，我将添加旋转速度到已存在的动态item行为的反弹上，使得我们的视图按顺时针旋转：

    -(void)collisionBehavior:(UICollisionBehavior *)behavior
            beganContactForItem:(id&lt;UIDynamicItem>)item
            withBoundaryIdentifier:(id&lt;NSCopying>)identifier
            atPoint:(CGPoint)p {
        for (UIDynamicBehavior* b in self.anim.behaviors) {
            if ([b isKindOfClass: [UIDynamicItemBehavior class]]) {
                UIDynamicItemBehavior* bounce = (UIDynamicItemBehavior*) b;
                CGFloat v = [bounce angularVelocityForItem:self.iv];
                if (v &lt;= 0.1) // do this just once
                    [bounce addAngularVelocity:30 forItem:self.iv];
                break;
        } }
    }
    

让我们把上面的动画封装到一个UIDynamicBehavior的子类上，这样我们可以像下面这样方便使用：

    [self.anim addBehavior:
        [[MyDropBounceAndRollBehavior alloc] initWithView:self.iv]];
    

UIDynamicBehavior 通过实现willMoveToAnimator:方法，来在被添加到动画器之前，收到这个动画器的一个参考对象

    -(void)willMoveToAnimator:(UIDynamicAnimator *)anim {
        if (!anim)
            return;
        UIView* sup = self.v.superview;
        UIGravityBehavior* grav = [UIGravityBehavior new];
        __weak MyDropBounceAndRollBehavior* wself = self;
        grav.action = ^{
            MyDropBounceAndRollBehavior* sself = wself;
            if (sself) {
                NSArray* items = [anim itemsInRect:sup.bounds];
                if (NSNotFound == [items indexOfObject:sself.v]) {
                    [anim removeBehavior:sself];
                    [sself.v removeFromSuperview];
                }
            } 
        };
    
        [self addChildBehavior:grav];
        [grav addItem:self.v];
        UIPushBehavior* push =
            [[UIPushBehavior alloc] initWithItems:@[self.v]
                mode:UIPushBehaviorModeInstantaneous];
        push.pushDirection = CGVectorMake(2, 0);
        [self addChildBehavior:push];
        UICollisionBehavior* coll = [UICollisionBehavior new];
        coll.collisionMode = UICollisionBehaviorModeBoundaries;
        coll.collisionDelegate = self;
        [coll addBoundaryWithIdentifier:@"floor"
                              fromPoint:CGPointMake(0,sup.bounds.size.height)
                                toPoint:CGPointMake(sup.bounds.size.width,
                                                    sup.bounds.size.height)];
        [self addChildBehavior:coll];
        [coll addItem:self.v];
        UIDynamicItemBehavior* bounce = [UIDynamicItemBehavior new];
        bounce.elasticity = 0.4;
        [self addChildBehavior:bounce];
        [bounce addItem:self.v];
    }
    
    
    -(void)collisionBehavior:(UICollisionBehavior *)behavior
            beganContactForItem:(id&lt;UIDynamicItem>)item
            withBoundaryIdentifier:(id&lt;NSCopying>)identifier
            atPoint:(CGPoint)p {
        for (UIDynamicBehavior* b in self.childBehaviors) {
            if ([b isKindOfClass: [UIDynamicItemBehavior class]]) {
                UIDynamicItemBehavior* bounce = (UIDynamicItemBehavior*) b;
                CGFloat v = [bounce angularVelocityForItem:item];
                if (v &lt;= 0.1) {
                    [bounce addAngularVelocity:30 forItem:item];
                }
                break; 
             }
         }
    }
    

下面是一些UIDynamicAnimator的方法和属性：

### delegate

这个委托发送dynamicAnimatorDidPause: 和 dynamicAnimatorWillResume:消息，当动画器没有什么可以做的，会暂停。

### running

如果是YES，这个动画器不会暂停，一些动态item 会执行动画

### elapsedTime

动画器从开始运行到现在总共执行的时间，如果动画器暂停了，这个属性的值不会增加。

### updateItemUsingCurrentState

一旦你的动态item已经在动画器的影响下了，这个动画器是有责任负责这个动态item的位置。如果你的代码又手动地改变了位置或者相关的属性，调用这个方法来让动画器知道这些改变。

下面是一些内建的UIDynamicBehavior子类：

### UIGravityBehavior

规定了其动态项的加速度。默认情况下，该加速度是向下以1为幅度（专门定义为每一秒1000点）。

### UIPushBehavior

瞬时地或者持续地施加一个力，后者构成加速度。这个力怎么影响这个对象取决于这个对象的“质量”，由它的大小和密度定位。默认一个小的视图更容易被push。这个push 行为可以通过active属性来触发和关闭。瞬时施加的力每次重复时都会把这active属性设置为YES。

为了指定一个方向和大小，一个push可以设置一个距离item中心的偏移。这将适用于额外的角加速度。例如，我可以这样顺时针旋转：

    [push setTargetOffsetFromCenter:UIOffsetMake(0, -200) forItem:self.iv];
    

### UICollisionBehavior

碰撞的行为可以有很多界限，两个点连成的之间或者一个UIBezierPath都可以视为边界，或者你可以把视图的边界视为边界（setTranslatesReferenceBoundsIntoBoundaryWithInsets:）。当碰撞开始和结束时，collisionDelegate会被调用。

### UISnapBehavior

让一个item像拉弹簧一样甩到某个点。它的damping（阻尼）属性描述了当一个item落在某个点上时应该振荡多少。这是一个很简单的行为：当添加到动画器时，会立刻发生，而且只发生一次，结束的时候没有通知。

### UIAttachmentBehavior

有一个阻力或者拉力附着在一个item（`initWithItem:attachedToItem:`）或者参考视图的某个点（`initWithItem:attachedToAnchor:`）上，这个附着点默认是item的center，为了改变它，可以使用初始化方法：`initWithItem:offsetFromCenter:attachedToItem:offsetFromCenter:`或者 `initWithItem:offsetFromCenter:attachedToAnchor:`

附着介质的物理特性是由行为的长度length，频率frequency，和阻尼damping决定。当你初始化这个行为时，它会帮你设置这些，但你也可以在行为的生命周期中修改它们，还有anchorPoint （如果附着介质是一个锚点）。

当其它的item或者锚点移动的时候，这个item也会根据附着介质的物理特性跟着移动。anchorPoint在一个动画的世界实现拖动视图是特别有用的。

### UIDynamicItemBehavior

赋予其item具有内部物理特性，如密度（相对于大小变化），弹性（弹跳碰撞），摩擦和阻力，以及喷射线速度和角速度。

 [1]: http://images.cnitblog.com/blog/406864/201410/162305278264247.png
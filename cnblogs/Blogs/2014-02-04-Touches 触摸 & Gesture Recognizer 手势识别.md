---
layout: post
title: Touches 触摸 & Gesture Recognizer 手势识别
date: 2014-02-04
categories: blog
tags: [iOS]
description: Touches 触摸 & Gesture Recognizer 手势识别

---

1.  每个UITouch对象对应一个手指。反过来说，每一个手指触摸屏幕时是由在UIEvent里的一个UITouch对象表示的。

2.  对于给定的UITouch对象（请记住，一个特定的手指），只有五件事情可能发生。这些被称为接触阶段，并通过一个UITouch实例的相位特性进行了说明：
    
    *UITouchPhaseBegan*
    
    手指第一次触摸屏幕，这个UITouch对象刚刚被创建。这总是第一个阶段，而且只会进入一次。
    
    *UITouchPhaseMoved*
    
    手指在屏幕上滑动
    
    *UITouchPhaseStationary*
    
    手指仍然在屏幕上，但是没有移动。为什么需要报告这个阶段？记住，一旦一个UITouch实例被创建，那么每次UIEvent到来时，这个UITouch实例必须存在。所以，当某些东西发生时（一个新的手指触摸屏幕）导致UIEvent出现，我们必须报告这个手指做了什么，即使它什么也没有做。
    
    *UITouchPhaseEnded*
    
    手指离开屏幕。跟UITouchPhaseBegan一样，只会到达依次。这个UITouch实例将会被销毁，而且不会出现在UIEvents中。
    
    *UITouchPhaseCancelled*
    
    系统终止了这个多点触摸序列，因为某些东西打断了它。例如用户按下home键，电话打来，本地通知出现等等。

3.  UITouch有一些很有用的方法和属性：
    
    *locationInView:, previousLocationInView:*
    
    相对于一个给定视图的坐标系中该触摸的当前和以前的位置。通常感兴趣的是self 和 self.superview。传入nil可以得到相对于window来说这个触摸的位置。
    
    *timestamp*
    
    触摸最后一次改变的时间。当一个触摸被创建和每次它移动时都会记录这个时间戳。实际的触摸发生到传给这个UITouch之间会有一个延时，所以我们一般用这个属性来知道触摸的时间。
    
    *tapCount*
    
    在同一位置快速触摸多次，默认是1。
    
    *view*
    
    这个触摸相关联的视图

我们使用原生的方法来判断一个长按事件

    - (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
        self->_time = [(UITouch*)touches.anyObject timestamp];
        [self performSelector:@selector(touchWasLong)
                   withObject:nil afterDelay:0.4];
    }
    - (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
        NSTimeInterval diff = event.timestamp - self->_time;
        if (diff < 0.4) {
            NSLog(@"short");
            [NSObject cancelPreviousPerformRequestsWithTarget:self
                selector:@selector(touchWasLong) object:nil];
        } 
    }
    - (void) touchWasLong {
        NSLog(@"long");
    }
    

我们使用原生的方法来判断一个单击和双击事件

    - (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
        int ct = [(UITouch*)touches.anyObject tapCount];
        if (ct == 2) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self
                selector:@selector(singleTap) object:nil];
        } 
    }
    - (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
        int ct = [(UITouch*)touches.anyObject tapCount];
        if (ct == 1)
            [self performSelector:@selector(singleTap)
                withObject:nil afterDelay:0.3];
        if (ct == 2)
            NSLog(@"double tap");
    }
    - (void) singleTap {
        NSLog(@"single tap");
    }
    

* * *

### Gesture Recognizer

UIGestureRecognizer 类实现了那四个touches ... 方法，但是它不是一个UIResponder子类，因此它并不在响应链中。

UITouch 和 UIEvent 提供了一些方法来获取触摸和手势识别的关联性。UITouch的`gestureRecognizers` 会列举出当前处理这个touch的所有手势。UIEvent的`touchesForGestureRecognizer:` 方法列举了由指定手势识别所处理的触摸。

UIGestureRecognizer 也提供了`locationInView:`方法，对于多点触摸，这个返回值是这多个点的质心位置。

下面我们实现一个当用户在视图上拖动时，这个视图也跟着移动：

    UIPanGestureRecognizer* p =
        [[UIPanGestureRecognizer alloc]
            initWithTarget:self
            action:@selector(dragging:)];
    [v addGestureRecognizer:p];
    // ...
    - (void) dragging: (UIPanGestureRecognizer*) p {
        UIView* vv = p.view;
        if (p.state == UIGestureRecognizerStateBegan)
            self->_origC = vv.center;
        CGPoint delta = [p translationInView: vv.superview];
        CGPoint c = self->_origC;
        c.x += delta.x; c.y += delta.y;
        vv.center = c;
    }
    

上面的那个触摸移动的位置增量delta，可以用`translationInView:` 方法获取，是相对于触摸的原始位置来说的。

实际上，我们不需要维护任何的触摸状态，因为我们允许重置UIPanGestureRecognizer的增量，使用`setTranslation:inView:` 方法即可，代码可以变成下面这样：

    - (void) dragging: (UIPanGestureRecognizer*) p {
        UIView* vv = p.view;
        if (p.state == UIGestureRecognizerStateBegan ||
                p.state == UIGestureRecognizerStateChanged) {
            CGPoint delta = [p translationInView: vv.superview];
            CGPoint c = vv.center;
            c.x += delta.x; c.y += delta.y;
            vv.center = c;
            [p setTranslation: CGPointZero inView: vv.superview];
        }
    }
    

一个平移手势识别还可以在受到UIDynamicAnimator影响下进行拖动。这里的策略是视图通过一个UIAttachmentBehavior来附着在一个或多个锚点上，当用户拖动时，我们移动这个锚点，然后这个视图就会跟着移动：

    - (void) dragging: (UIPanGestureRecognizer*) g {
        if (g.state == UIGestureRecognizerStateBegan) {
            self.anim =
                [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
            CGPoint loc = [g locationOfTouch:0 inView:g.view];
            CGPoint cen =
                CGPointMake(CGRectGetMidX(g.view.bounds),
                            CGRectGetMidY(g.view.bounds));
            UIOffset off = UIOffsetMake(loc.x-cen.x, loc.y-cen.y);
            CGPoint anchor = [g locationOfTouch:0 inView:self.view];
            UIAttachmentBehavior* att =
                [[UIAttachmentBehavior alloc] initWithItem:g.view
                    offsetFromCenter:off attachedToAnchor:anchor];
            [self.anim addBehavior:att];
            self.att = att;
        }
        else if (g.state == UIGestureRecognizerStateChanged) {
            self.att.anchorPoint = [g locationOfTouch:0 inView:self.view];
        }
        else {
            self.anim = nil;
        }
    }
    

* * *

### Gesture Recognizer Delegate

一个手势识别可以有一个委托，可以执行两种类型的任务：

*限制一个手势识别的操作*

`gestureRecognizerShouldBegin:` 会在手势识别处在任何可能状态之前发送给委托。返回NO迫使手势识别进入失败状态。

`gestureRecognizer:shouldReceiveTouch:` 会在一个触摸被发送到手势识别的touchesBegan:等方法之前发送。返回NO防止这个触摸发送给手势识别。

*调解手势识别冲突*

当一个手势识别识别了一个手势，如果这个手指会迫使另一个手势失败，那么 `gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:` 消息会发送给这两个手势的委托。返回YES会防止这个失败发生，同时让两个手势同时识别。例如，一个视图可以同时识别两个手指的捏和拖拽手势，一个会应用拉伸转换，一个会改变视图的center。

在一个手势生命周期的早期，当一个视图里面所有的手势识别都仍处理Possible状态，那么在iOS 7中`gestureRecognizer:shouldRequireFailureOfGestureRecognizer:` 和 `gestureRecognizer:shouldBeRequiredToFailByGestureRecognizer:` 消息会发送给这所有的手势识别的委托，来配对这个视图里的手势识别。返回YES来对这个两个传入的手势进行优先排序，就是说知道另一个手势识别失败时，这个手势识别才能成功。本质上，这些委托方法会把返回的结果作为一次和永久的决定，从而对每个手势发生时多出实时决策。

下面，我们使用委托消息来组合UILongPressGestureRecoginzer 和 UIPanGestureRecognizer手势，用户需要在视图上长按，然后我们让视图有一个拉伸扩大的动画，这时用户就可以拖动这个视图了。

    - (void) longPress: (UILongPressGestureRecognizer*) lp {
        if (lp.state == UIGestureRecognizerStateBegan) {
            CABasicAnimation* anim =
                [CABasicAnimation animationWithKeyPath: @"transform"];
            anim.toValue =
                [NSValue valueWithCATransform3D:
                    CATransform3DMakeScale(1.1, 1.1, 1)];
            anim.fromValue =
                [NSValue valueWithCATransform3D:CATransform3DIdentity];
            anim.repeatCount = HUGE_VALF;
            anim.autoreverses = YES;
            [lp.view.layer addAnimation:anim forKey:nil];
        }
        if (lp.state == UIGestureRecognizerStateEnded ||
                lp.state == UIGestureRecognizerStateCancelled) {
            [lp.view.layer removeAllAnimations];
        } 
    }
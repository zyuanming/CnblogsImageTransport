---
layout: post
title: 触摸传递 Touch Delivery
date: 2014-02-07
categories: blog
tags: [iOS]
description: 触摸传递 Touch Delivery

---

下面是一个触摸传递到视图和手势识别的完整的标准过程：

*   当有一个新的触摸，该应用程序使用hit-testing命中测试（后面会讲）来确定被触摸的视图，这个视图就会永远与这个触摸对应。这个视图称为hit-test视图。如果想忽略一个视图，不处理触摸，可以在这个阶段设置userInteractionEnabled, hidden, 和 alpha属性。

*   每次触摸状态改变，该应用程序会调用自己的sendEvent:方法，反过来又会调用window的sendEvent:方法，这个window会通过调用那几个touches...方法来传递每个事件的触摸，如下所述：
    
    *   当一个触摸第一次出现时，会考虑这个视图是否服从这个multipleTouchEnabled 和 exclusiveTouch逻辑，如果这个逻辑被允许，就会：
        
        a. 这个触摸会传递给这个hit-test视图的所有手势识别。
        
        b. 这个触摸会传递给hit-test视图本身。
    
    *   如果这个手势被一个手势识别所识别，那么对于任何与这个手势识别相关的触摸就会：
        
        a. touchesCancelled:forEvent:消息会发送给触摸的视图，这个触摸不再传递给它对应的视图。
        
        b. 如果这个触摸与任何其它的手势识别相关，这个手势识别会强制进入失败状态。
    
    *   如果一个手势识别失败，可能是因为它宣告失败，或因为它是被迫失败，它相关的触摸倒是不再传递给它，但（已经规定的情况除外），触摸会继续被传递到它们的视图。

*   如果一个触摸将要传递到一个视图，如果这个视图没有响应相应的touches...方法，响应者会从响应者链向上查找可以响应的响应者，然后传递触摸给它。

* * *

### hit-testing

hit-testing 是用来决定哪个视图被用户触摸了。通过使用视图的实例方法 hitTest:withEvent:，返回一个视图（hit-testing 视图）或者nil，目的是返回包含触摸点的最前面的视图。这个方法使用了一个优雅的递归算法，如下：

1.  一个视图的hitTest:withEvent:里面会首先调用它子视图的同样方法，查找是否有hit-testing视图，因为子视图总是在父视图的前面。然后这个子视图在hitTest:withEvent:方法里面还是以相反的顺序调用它子视图的同样方法。如果两个同级的子视图重叠了，会返回最前面的那个视图。

2.  如果一个视图hit-testing它的子视图，任何一个子视图一旦返回一个视图，那么它就会停止查询它的子视图，立刻同样返回这个视图。第一个返回的hit-test视图会沿调用链返回到顶端，这个就是最终的hit-test视图。

3.  如果，另一方面，一个视图没有子视图，或者它的所有子视图都返回nil（表明这视图和它的子视图都没有被点击），那么这个视图就会调用它自己的pointInside:withEvent:方法。如果这个调用结果显示这个触摸是在这个视图里面的，视图会返回自身，表明它本身是hit-test 视图，否则，它返回nil。

如果一个视图有一个转换，这个仍然是正常工作的，因为pointInside:withEvent:会把视图的转换考虑进去。这就是为什么一个旋转了的button仍然正常工作。

* * *

### Recognition

当一个手势识别器识别了它的手势，所有的东西都会变化。这个手势识别对应的touches 会被发送到它们的hit-test 视图的touchesCancelled:forEvent: 消息里，然后就不再到达这些视图了（除非这个手势识别的cancelsTouchesInView属性为NO）。另外，所有其它的手势识别对于这些触摸都会变成失败，同时也不再发送这些touches给这些手势识别。

**依赖顺序**

下面的方法建立了一个相关性顺序，使某个手势识别在其他的手势识别失败时才允许从Possible状态进入Began状态或者进入Ended状态：

*   UIGestureRecognizer 的 requireGestureRecognizerToFail:(发送到一个手势识别)

*   UIGestureRecognizer 的 shouldRequireFailureOfGestureRecognizer:（在子类中重写）

*   UIGestureRecognizer 的 shouldBeRequiredToFailByGestureRecognizer: （在子类中重写）

*   委托的 gestureRecognizer:shouldRequireFailureOfGestureRecognizer:

*   委托的 gestureRecognizer:shouldBeRequiredToFailByGestureRecognizer:

上面的第一个方法设置了两个手势识别的永久关系，不能撤销。其它方法就会在一个手势在视图中产生时调用，结果只适用于这个时间上的手势。

这些委托方法执行的顺序如下：对于在hit-test视图中的每对手势识别，这一对中的第一个会被发送shouldRequire消息，然后是shouldBeRequired消息，接着这一对中的第二个会被发送shouldRequire消息，然后是shouldBeRequired消息。如果任何这四种方法返回了YES，这对手势识别的关系就确定了，当前的调用序列结束，开始下一对手势识别。

**成功状态到失败状态**

当一个手势识别器将要声明它识别了一个手势时，如果下面的方法返回NO，会把这个手势识别强制从成功状态转到失败状态：

*   UIView 的 gestureRecognizerShouldBegin: （hit-test视图子类重写）

*   委托的gestureRecognizerShouldBegin:

**同时识别手势**

一个手势识别成功了，但是其它的手势识别没有强制变成失败状态，由下面的方法决定：

*   委托的gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:

*   UIGestureRecognizer 的 canPreventGestureRecognizer:（在子类中重写）

*   UIGestureRecognizer 的 canBePreventedByGestureRecognizer: （在子类中重写）

在子类中重写的方法名称中的“prevent” 表示“这个手势识别成功是建立在强制其它的手势失败的基础上”， 名称中的“be prevented” 表示“其它手势识别失败是建立在你这个手势识别成功”。调用顺序是：

1.  首先调用canPreventGestureRecognizer:方法，如果返回NO，这个手势识别结束。

2.  然后在另一个手势识别器上调用 canPreventGestureRecognizer:，如果第一次调用这个方法时返回YES，这个手势识别器会发送canBePreventedByGestureRecognizer:消息，如果这个方法也返回YES，那么这个手势识别器结束，如果返回NO，会给第二个手势识别发送 canPreventGestureRecognizer:消息，重新从1开始。

这样就解决了手势识别冲突的问题。
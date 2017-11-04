---
layout: post
title: iOS CALayer 学习（1）
date: 2014-08-01
categories: blog
tags: [iOS]
description: iOS CALayer 学习（1）

---

* * *

## 基本知识总结

1.  不像UIView 中的subviews 属性，一个layer的sublayers属性是可写的。为了移除一个layer所有的sublayers，可以设置它的sublayers的属性为nil。

2.  layer有一个 zPosition属性，是一个CGFloat类型，决定了绘制的顺序，但是默认都是0，也就是由layer中sublayers的排列顺序来绘制。

3.  一个layer自己内部的坐标系统是由它自己的bounds来描述的，跟UIView一样，它的大小是bounds的大小，它的bounds的原点是内部坐标的左上角。但是一个子layer在它的父layer中的位置不是由它的center属性确定的，跟UIView的不同。一个layer没有center属性，取而代之的，由两个组合属性来决定一个子layer在父layer中的位置：postion（位置）和anchorPoint（描点）。

*   position： 是在父layer的坐标系统的一个点位置

*   anchorPoint：是内部坐标系统的一个点位置，和position是同一个点。是一个CGPoint类型，{0,0}表示layer 的左上角，{1,1}表示layer的右下角。默认是{0.5,0.5}，就是在layer的中间。
    
    layer的position和anchorPoint是相互独立的，意味着修改任意一个不会改变另一个。

1.  当一个layer重新绘制自己时，有四个方法可能会被调用，可以选择实现其中一个方法（不要试图组合使用这四个方法，只会让你更迷惑）：
    
    *   display ： 子类layer提供 你的CALayer子类可以重写display方法。不过没有图形上下文，所以你只能设置image 到 content中。
    
    *   displayLayer ： 在委托delegate 你可以设置CALayer的delegate属性，然后在delegate中实现dispLayer：。同样，没有图形上下文，你只能设置iamge到content中。
    
    *   drawInContext： 在子类layer 你的CALayer子类可以重写drawInContext：传进来的变量是图形上下文，你可以直接绘制，但是这个图形上下文不是当前的图形上下文。
    
    *   drawLayer：inContext: 在委托中delegate 你可以设置CGLayer的delegate属性，然后在delegate中实现drawLayer：inContext：第二个参数是一个图形上下文，不过默认不是当前的图形上下文。
    
    设置一个layer的content为image和直接在layer中绘制，是相互排斥的。所以：
    
    *   如果一个layer的content设置了一个image，这个image就会立刻显示，同时取代之前所有绘制在这个layer上的内容。
    
    *   如果一个layer重新绘制自己，并调用drawInContext：或者drawLayer:inContext：绘制，那么会取代所有显示的image。
    
    *   如果一个layer重新绘制自己，但是4个方法都没有提供任何内容，这个layer就会是空白，没有内容。

2.  一个layer有一个contentsScale属性，对应layer的图形上下文中点的距离和实际设备中像素的距离。一个layer是由Cocoa管理的，如果它有内容，会自动适应它的contentsScale。如果一个UIView实现了drawRect:方法，那么在一个双倍分辨率的屏幕上，它的根Layer的contentsScale属性是2。而一个你自己创建和管理的layer，是不会自动设置contentsScale，所有的行为由你说了算。

3.  有三个layer属性会影响layer的展示，对于初学者来说可能很容易混淆：backgroundColor属性，opaque属性，opacity属性。
    
    *   想象一下backgroundColor与layer自身的绘制分离，好像在layer后面绘制。等效于一个view的backgroundColor（如果这个layer是一个view的根layer，那么这个backgroundColor就是view的backgroundColor）。
    *   这个opaque属性决定了这个layer的图形上下文是否是不透明的。一个不透明的图形上下文是黑色的，你可以在上面绘制，但是黑色仍然存在。一个透明的图形上下文是完全透明的。改变opaque属性不会立刻生效，直到下一次重绘自身。一个view的根layer的opaque属性与这个view自己的opaque属性是不同的，两者没有联系，功能不同。
    *   这个opacity不透明度属性等效于一个view的alpha属性，它同样也会影响这个layer的子layer的外观透明度。这个属性会影响layer背景颜色的外观的透明度和layer的content的外观透明度。改变这个属性会立刻生效。
    
    如果一个layer是一个实现了drawRect:的view的根layer，那么设置这个view的backgroundColor会改变layer的opaque属性：当新的背景颜色是不透明的（alpha为1），那么这个属性会被设置为YES，否则设置为NO。这个就是我们在前面说过的CGContextClearRect方法的奇怪行为的发生原因。
    
    还有，当直接在layer中绘制时，CGContextClearRect的行为与之前在一个view中绘制时的行为是不同的：在layer中使用这个方法，会在这个指定的区域绘制这个layer的背景颜色，而不是在背景颜色中挖了一个洞。

4.  不像UIView，一个layer不会自动重新绘制自己，除非layer的bounds改变，而且needsDisplayOnBoundsChange属性为YES。例如，一个view在第一次出现时会被告知重新绘制自己。当一个view收到setNeedsDisplay消息，如果这个view实现了drawRect:方法，那么这个view的根layer也会收到setNeedsDisplay消息，因为如果没有实现这个drawRect:方法，系统会认为这个view不需要重新绘制，所以也就不会给view的根layer发送setNeedsDisplay消息。因此如果你希望根layer自动绘制自己，那么哪怕drawRect:方法什么都不做，你也要实现这个方法。
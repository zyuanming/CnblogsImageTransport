---
layout: post
title: UIScrollView 技巧（2）
date: 2014-04-12
categories: blog
tags: [iOS]
description: UIScrollView 技巧（2）

---

### Zooming 缩放

* * *

为了实现一个scrollview可以缩放其内容，你可以设置scroll view的minimumZoomScale 和 maximumZoomScale属性让至少一个不为1（默认就是1）。你还需要在scroll view的委托中实现 viewForZoomingInScrollView: 方法来指定哪个是可缩放的scrollview 子视图。这个scrollview然后就会对它的子视图应用一个缩放转换。至于缩放多少是由scrollview的 zoomScale决定的。通常情况下我们需要scrollview的所有子视图都可以缩放，所以我们一般把所有的子视图放在一个content view中，再把这个content view添加到scrollview上。

    v.tag = 999;
    sv.minimumZoomScale = 1.0;
    sv.maximumZoomScale = 2.0;
    sv.delegate = self;
    

v是sv（scrollview）的一个子视图，这个子视图就是将要可以缩放的视图

    - (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
        return [scrollView viewWithTag:999];
    }
    

这样，用户就可以通过手势缩放scrollview的内容了。为了让用户缩放到临界值时不能再缩放了（默认是可以缩放超过临界值一点，当用户松开手时，scrollview会弹回临界值），我们可以设置bouncesZoom为NO。

为了让用户缩放scrollview内容时仍然可以使用scrollRectToVisible:animated:方法来滚动到指定的区域，scrollview默认会根据当前的zoomScale属性来设置它的contentSize属性。

当minimumZoomScale小于1，如果scrollview的内容缩放得比scrollview还小，那么这个缩放的视图会固定在scrollview的左上角。如果你不喜欢这样，可以通过子类化UIScrollView，重写它的layoutSubviews方法，或者通过scrollview的委托实现 scrollViewDidZoom:方法。下面是WWDC 2010视频上的一段代码演示，让缩放视图比scrollview小时，固定在scrollview的中间：

    - (void)layoutSubviews {
        [super layoutSubviews];
        UIView* v = [self.delegate viewForZoomingInScrollView:self];
        CGFloat svw = self.bounds.size.width;
        CGFloat svh = self.bounds.size.height;
        CGFloat vw = v.frame.size.width;
        CGFloat vh = v.frame.size.height;
        CGRect f = v.frame;
        if (vw < svw)
            f.origin.x = (svw - vw) / 2.0;
        else
            f.origin.x = 0;
        if (vh < svh)
            f.origin.y = (svh - vh) / 2.0;
        else
            f.origin.y = 0;
        v.frame = f;
    }
    

### 用代码进行缩放

* * *

*   setZoomScale:animated:
    
    contentOffset属性会自动适应，让当前的缩放内容始终在scrollview的中心，同时让内容全屏显示在scrollview上。

*   zoomToRect:animated:
    
    同上。

下面我们通过一个双击（UITapGestureRecognizer），让scrollview缩放到最大值，原始值，最小值：

    - (void) tapped: (UIGestureRecognizer*) tap {
        UIView* v = tap.view;
        UIScrollView* sv = (UIScrollView*)v.superview;
        if (sv.zoomScale < 1) {
            [sv setZoomScale:1 animated:YES];
            CGPoint pt =
                CGPointMake((v.bounds.size.width - sv.bounds.size.width)/2.0,0);
            [sv setContentOffset:pt animated:NO];
        }
        else if (sv.zoomScale < sv.maximumZoomScale)
            [sv setZoomScale:sv.maximumZoomScale animated:YES];
        else
            [sv setZoomScale:sv.minimumZoomScale animated:YES];
    }
    

### 缩放时，让内容更清晰

* * *

默认情况下，当一个scrollview缩放时，它仅仅是对这个缩放视图提供一个缩放转换。这个缩放视图的绘制内容是之前它的图层缓存的内容，所以当我们缩放这个视图时，原来像素的图片相当于绘制得更大，意味着内容会不清晰。

一个解决方法是使用CATiledLayer提供的功能，CATiledLayer不仅仅提供滚动，还提供缩放。我们需要用到它的另外两个属性：

*   levelsOfDetail
    
    假如这个数值是2，意味着我们又两种显示级别，可以是2x或者1x大小

*   levelsOfDetailBias
    
    有多少个显示级别是大于1x的。例如，levelsOfDetail为2，如果我们希望当放大时，大小为2x，缩小时，大小为1x，那么这个值就是1。默认是0，就是说大小从 0.5x 到 1x变化。

下面是一个小例子，scrollview 的contentview绘制了30个字：

    - (void)loadView {
        UIScrollView* sv = [[UIScrollView alloc] initWithFrame:
                            [[UIScreen mainScreen] applicationFrame]];
        self.view = sv;
        CGRect f = CGRectMake(0, 0, self.view.bounds.size.width,
                              self.view.bounds.size.height * 2);
        TiledView* content = [[TiledView alloc] initWithFrame:f];
        content.tag = 999;
        CATiledLayer* lay = (CATiledLayer*)content.layer;
        lay.tileSize = f.size;
        lay.levelsOfDetail = 2;
        lay.levelsOfDetailBias = 1;
        [self.view addSubview:content];
        [sv setContentSize: f.size];
        sv.minimumZoomScale = 1.0;
        sv.maximumZoomScale = 2.0;
        sv.delegate = self;
    }
    
    - (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
        return [scrollView viewWithTag:999];
    }
    

下面是TiledView的代码：

    + (Class) layerClass {
        return [CATiledLayer class];
    }
    -(void)drawRect:(CGRect)r {
        [[UIColor whiteColor] set];
        UIRectFill(self.bounds);
        [[UIColor blackColor] set];
        UIFont* f = [UIFont fontWithName:@"Helvetica" size:18];
        // height consists of 31 spacers with 30 texts between them
        CGFloat viewh = self.bounds.size.height;
        CGFloat spacerh = 10;
        CGFloat texth = (viewh - (31*spacerh))/30.0;
        CGFloat y = spacerh;
        for (int i = 0; i < 30; i++) {
            NSString* s = [NSString stringWithFormat:@"This is label %d", i];
            [s drawAtPoint:CGPointMake(10,y) withFont:f];
            y += texth + spacerh;
        }
        // uncomment the following to see the tiling
        /*
        UIBezierPath* bp = [UIBezierPath bezierPathWithRect:r];
        [[UIColor redColor] setStroke];
        [bp stroke];
        */
    }
    

如果不使用CATiledLayer，我们可以使用另一种方法，但是这个方法不能乱用，过度用。就是在scrollview 的委托中实现下面的方法：

    - (void)scrollViewDidEndZooming:(UIScrollView *)scrollView
                           withView:(UIView *)view
                            atScale:(float)scale {
        view.contentScaleFactor = scale * [UIScreen mainScreen].scale;
    }
    

如果这个zoomScale，屏幕分辨率，还有这个缩放视图的大小很大，你将需要一个非常大的图形上下文在内存中，可能会导致你的app内存用完。

### UIScrollView 的触摸

* * *

假如我们有一个很大的地图图片，比屏幕大，我们希望用户滚动这个地图来查看，同时还可以拖动一个标记到一个新的位置，下面是一个小例子：

    UIScrollView* sv = [UIScrollView new];
    self.sv = sv;
    [self.view addSubview:sv];
    sv.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[sv]|" 
                                                   options:0 metrics:nil views:@{@"sv":sv}]];
    [self.view addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[sv]|" 
                                                   options:0 metrics:nil views:@{@"sv":sv}]];
    UIImageView* imv = [[UIImageView alloc] initWithImage: [UIImage imageNamed:@"map.jpg"]];
    [sv addSubview:imv];
    imv.translatesAutoresizingMaskIntoConstraints = NO;
    // constraints here mean "content view is the size of the map image view"
    [self.view addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[imv]|"
                                                   options:0 metrics:nil views:@{@"imv":imv}]];
    [self.view addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[imv]|" 
                                                   options:0 metrics:nil views:@{@"imv":imv}]];
    UIImageView* flag = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"redflag.png"]];
    [sv addSubview: flag];
    UIPanGestureRecognizer* pan = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                 action:@selector(dragging:)];
    [flag addGestureRecognizer:pan];
    flag.userInteractionEnabled = YES;
    

![][1]

下面的拖动手势识别，当拖动到边缘的时候，scrollview还可以自动移动来适应新的位置，也就是用户可以在整副图片上拖动标记：

    - (void) dragging: (UIPanGestureRecognizer*) p {
        UIView* v = p.view;
        if (p.state == UIGestureRecognizerStateBegan ||
                p.state == UIGestureRecognizerStateChanged) {
            CGPoint delta = [p translationInView: v.superview];
            CGPoint c = v.center;
            c.x += delta.x; c.y += delta.y;
            v.center = c;
            [p setTranslation: CGPointZero inView: v.superview];
        } 
        // autoscroll
        if (p.state == UIGestureRecognizerStateChanged) {
            CGPoint loc = [p locationInView:self.view.superview];
            CGRect f = self.view.frame;
            UIScrollView* sv = self.sv;
            CGPoint off = sv.contentOffset;
            CGSize sz = sv.contentSize;
            CGPoint c = v.center;
            // to the right
            if (loc.x > CGRectGetMaxX(f) - 30) {
                CGFloat margin = sz.width - CGRectGetMaxX(sv.bounds);
                if (margin > 6) {
                    off.x += 5;
                    sv.contentOffset = off;
                    c.x += 5;
                    v.center = c;
                    [self keepDragging:p];
                } 
            }
            // to the left
            if (loc.x < f.origin.x + 30) {
                CGFloat margin = off.x;
                if (margin > 6) {
                    // ... omitted ...
                }
            }
            // to the bottom
            if (loc.y > CGRectGetMaxY(f) - 30) {
                CGFloat margin = sz.height - CGRectGetMaxY(sv.bounds);
                if (margin > 6) {
                    // ... omitted ...
                }
            }
            // to the top
            if (loc.y < f.origin.y + 30) {
                CGFloat margin = off.y;
                if (margin > 6) {
                    // ... omitted ...
                }
            } 
        }
    }
    
    
    - (void) keepDragging: (UIPanGestureRecognizer*) p {
        float delay = 0.1;
        dispatch_time_t popTime =
            dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self dragging: p];
        });
    }
    

下面的例子是，我想在初始化的时候，标记是在屏幕外面的，当用户向右轻扫时才让这个标记从屏幕外以动画形式移动回界面里，但是这个向右滑动的手势会被scrollview内置的手势识别，我们自定义的手势无法识别，怎么办？没关系，我们添加一个手势识别检测依赖：

    UISwipeGestureRecognizer* swipe =
        [[UISwipeGestureRecognizer alloc]
            initWithTarget:self action:@selector(swiped:)];
    [sv addGestureRecognizer:swipe];
    [sv.panGestureRecognizer requireGestureRecognizerToFail:swipe];
    

只有在我们自定义的手势识别结束后才开始识别内部的手势：

    - (void) swiped: (UISwipeGestureRecognizer*) g {
        if (g.state == UIGestureRecognizerStateEnded ||
                g.state == UIGestureRecognizerStateCancelled) {
            UIImageView* flag =
                [[UIImageView alloc] initWithImage:
                    [UIImage imageNamed:@"redflag.png"]];
            UIPanGestureRecognizer* pan = [[UIPanGestureRecognizer alloc]
                                           initWithTarget:self
                                           action:@selector(dragging:)];
            [flag addGestureRecognizer:pan];
            flag.userInteractionEnabled = YES;
            UIScrollView* sv = self.sv;
            CGPoint p = sv.contentOffset;
            CGRect f = flag.frame;
            f.origin = p;
            f.origin.x -= flag.bounds.size.width;
            flag.frame = f;
            [sv addSubview: flag];
            // thanks for the flag, now stop operating altogether
            g.enabled = NO;
            [UIView animateWithDuration:0.25 animations:^{
                CGRect f = flag.frame;
                f.origin.x = p.x;
                flag.frame = f;
            }]; 
        }
    }
    

### UIScrollView 性能优化

* * *

*   能不透明的内容，尽量不透明。

*   如果你需要绘制一个阴影，不要让系统为这个图层计算阴影的路径现状，你可以设置shadowPath，或者使用Core Graphics 来创建一个阴影来绘制。同样的，避免让视图图层的阴影与其它图层的透明度叠加在一起；例如，如果图层背景是白色的，不透明地绘制时本身会就在这个白色背景上绘制了阴影。

*   不要让绘制系统为你拉伸你的图片，你应该为当前的屏幕分辨率提供合适大小的图片。

*   在紧要关头，你可以设置图层的shouldRasterize属性为YES，来消除渲染操作的海量样本。你可以在滚动时设置这个shouldRasterize属性为YES，当滚动结束时又恢复成NO。

苹果官方也说，可以设置一个视图的clearsContextBeforeDrawing属性为NO，这样可能造成一点不同，但是具体没有验证会有什么不同或者是优化。

 [1]: http://images.cnitblog.com/blog/406864/201410/241051160279123.png
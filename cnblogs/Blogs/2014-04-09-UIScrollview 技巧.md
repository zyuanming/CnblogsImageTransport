---
layout: post
title: UIScrollview 技巧
date: 2014-04-09
categories: blog
tags: [iOS]
description: UIScrollview 技巧

---

### 设置UIScrollView的contentSize

* * *

如果使用自动布局，那么它会自动帮你基于这个scrollview的子视图的约束来计算这个内容大小。在非自动布局情况下，如果app旋转导致scrollview 的bounds改变，不会影响到scrollview的contentSize，而如果重新设置contentSize，也不会影响scrollview的子视图，这个contentSize仅仅是决定了滚动的范围。

下面我们用代码创建一个UIScrollView，UILabel在y轴上顺序排列：

![][1]

    UIScrollView* sv = [UIScrollView new];
    sv.backgroundColor = [UIColor whiteColor];
    sv.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:sv];
    [self.view addConstraints:
    [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[sv]|"
                                             options:0 metrics:nil
                                               views:@{@"sv":sv}]];
    [self.view addConstraints:
    [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[sv]|"
                                             options:0 metrics:nil
                                               views:@{@"sv":sv}]];
    UILabel* previousLab = nil;
    for (int i=0; i<30; i++) {
        UILabel* lab = [UILabel new];
        lab.translatesAutoresizingMaskIntoConstraints = NO;
        lab.text = [NSString stringWithFormat:@"This is label %d", i+1];
        [sv addSubview:lab];
        [sv addConstraints:
        [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(10)-[lab]"
                                                 options:0 metrics:nil
                                                   views:@{@"lab":lab}]];
        if (!previousLab) { // first one, pin to top
            [sv addConstraints:
            [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(10)-[lab]"
                                                     options:0 metrics:nil
                                                       views:@{@"lab":lab}]];
        } else { // all others, pin to previous
            [sv addConstraints:
            [NSLayoutConstraint
              constraintsWithVisualFormat:@"V:[prev]-(10)-[lab]"
              options:0 metrics:nil
              views:@{@"lab":lab, @"prev":previousLab}]];
        }
        previousLab = lab;
    }
    

运行代码，你会发现label 都放置在正确的位置，但是scrollView 却不能滚动。而且，即使你手动设置了contentSize也无法滚动。原因就是在页面布局时，scrollview的contentSize会自动根据它和子视图之间的约束来计算得出。解决方法就是，再添加多一个约束，告诉scroll view 它的contentSize的高度应该是多少：

    // 给底部最后一个label设置一个y轴方向的约束，这样高度就可以确定了
    [sv addConstraints:
    [NSLayoutConstraint constraintsWithVisualFormat:@"V:[lab]-(10)-|"
                                             options:0 metrics:nil
                                               views:@{@"lab":previousLab}]];
    

可以看到，我们可以在垂直方向上滚动scrollview了，在水平方向上仍然不能滚动（contentSize的宽度默认就是0，正好是我们需要的）。

*使用一个Content View*

我们一般不会把scrollview 的子视图直接添加到scrollview上，而是添加到UIView上，然后把这个视图再添加到scrollview上，这个视图就是这个Content View。这样可以更加方便的组织和使用。

在自动布局下，我们可以有两种设置scroll view的contentSize 方法：

*   设置content view 的translatesAutoresizingMaskIntoConstraints为YES，然后手动设置这个scroll view的 contentSize为这个content view的大小。

*   设置content view 的translatesAutoresizingMaskIntoConstraints为NO，然后给这个content view 设置宽度和高度约束。

设置content view的大小或者约束这种方式是与它的子视图怎么定位（设置frame，还是实用约束）无关。有四种可能的组合，这四种组合开头的代码都是一样的：

    UIScrollView* sv = [UIScrollView new];
    sv.backgroundColor = [UIColor whiteColor];
    sv.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:sv];
    [self.view addConstraints:
    [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[sv]|"
                                            options:0 metrics:nil
                                              views:@{@"sv":sv}]];
    [self.view addConstraints:
    [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[sv]|"
                                         options:0 metrics:nil
                                           views:@{@"sv":sv}]];
    UIView* v = [UIView new]; // content view
    [sv addSubview: v];
    

第一种组合不使用约束：

    CGFloat y = 10;
    for (int i=0; i<30; i++) {
        UILabel* lab = [UILabel new];
        lab.text = [NSString stringWithFormat:@"This is label %d", i+1];
        [lab sizeToFit];
        CGRect f = lab.frame;
        f.origin = CGPointMake(10,y);
        lab.frame = f;
        [v addSubview:lab]; // add to content view, not scroll view
        y += lab.bounds.size.height + 10;
    }
    // set content view frame and content size explicitly
    v.frame = CGRectMake(0,0,0,y);
    sv.contentSize = v.frame.size;
    

第二种组合，content view使用约束，但它的子视图不使用：

    CGFloat y = 10;
    for (int i=0; i<30; i++) {
        // ... same as before, create labels, keep incrementing y
    }
    // configure the content view using constraints
    v.translatesAutoresizingMaskIntoConstraints = NO;
    [sv addConstraints:
         [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[v(y)]|"
                    options:0 metrics:@{@"y":@(y)} views:@{@"v":v}]];
    [sv addConstraints:
          [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[v(0)]|"
                       options:0 metrics:nil views:@{@"v":v}]];
    

第三种组合，content view 和它的子视图都使用约束：

    UILabel* previousLab = nil;
    for (int i=0; i<30; i++) {
        UILabel* lab = [UILabel new];
        lab.translatesAutoresizingMaskIntoConstraints = NO;
        lab.text = [NSString stringWithFormat:@"This is label %d", i+1];
        [v addSubview:lab];
        [v addConstraints:
              [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(10)-[lab]"
                                                      options:0 metrics:nil
                                                        views:@{@"lab":lab}]];
        if (!previousLab) { // first one, pin to top
            [v addConstraints:
                [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(10)-[lab]"
                                                        options:0 metrics:nil
                                                          views:@{@"lab":lab}]];
        } else { // all others, pin to previous
            [v addConstraints:
                [NSLayoutConstraint
                     constraintsWithVisualFormat:@"V:[prev]-(10)-[lab]"
                                         options:0 metrics:nil
                                           views:@{@"lab":lab, @"prev":previousLab}]];
    }
        previousLab = lab;
    }
    // last one, pin to bottom, this dictates content size height
    [v addConstraints:
    [NSLayoutConstraint constraintsWithVisualFormat:@"V:[lab]-(10)-|"
                                            options:0 metrics:nil
                                              views:@{@"lab":previousLab}]];
    // configure the content view using constraints
    v.translatesAutoresizingMaskIntoConstraints = NO;
    [sv addConstraints:
        [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[v]|"
                            options:0 metrics:nil views:@{@"v":v}]];
    [sv addConstraints:
        [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[v(0)]|"
                            options:0 metrics:nil views:@{@"v":v}]];
    

第四种组合是很奇怪的组合，content view的子视图使用约束布局，但是content view 和 scrollview 不使用：

    UILabel* previousLab = nil;
    // ... same as before, add subviews and constraints to content view
    // autolayout helps us learn the consequences of those constraints
    CGSize minsz = [v systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    // set content view frame and content size explicitly
    v.frame = CGRectMake(0,0,0,minsz.height);
    sv.contentSize = v.frame.size;
    

### 滚动

* * *

在iOS 7 下，由于app都是全屏的，status bar，navigation bar 都是半透明的，所以scroll view 也会在 status bar 下面，那么有可能导致scrollview 的内容被status bar遮盖，我们可以设置：

    sv.contentInset = UIEdgeInsetsMake(20, 0, 0, 0);
    

当我们设置了contentInset，我们通常也会设置scrollIndicatorInsets，让滚动条也适应：

    sv.contentInset = UIEdgeInsetsMake(20, 0, 0, 0);
    sv.scrollIndicatorInsets = sv.contentInset;
    

这样，即可以在status bar 看到半透明的scrollview 内容，又不会滚动不下导致的显示不全，但是我们硬编码这个20的值好像不是很优雅，我们可以：

    - (void) viewWillLayoutSubviews {
        if (self.sv) {
            CGFloat top = self.topLayoutGuide.length;
            CGFloat bot = self.bottomLayoutGuide.length;
            self.sv.contentInset = UIEdgeInsetsMake(top, 0, bot, 0);
            self.sv.scrollIndicatorInsets = self.sv.contentInset;
        }
    }
    

这些如果在nib中，如果我们设置view controller的automaticallyAdjustsScrollViewInsets为YES，那么iOS 7 运行时会帮我们自动适应这个scrollview 的contentInset 和 scrollIndicatorInsets，而不需要上面的代码。这个仅仅在nib上有用，一旦我们手动创建scrollview，即使设置这个automaticallyAdjustsScrollViewInsets为YES也没有用，还是需要上面的代码。

*Tiling 平铺*

假如我们有一个非常大的内容需要显示在scroll view上，这么大的图片，用户可以滚动来查看所有的内容细节。在内存中存放整张图片是不现实的，也是不可能的。

Tiling是一个种解决方法。我们把内容分成一个个小的矩形区域，当用户滚动时，我们查找并让目标的矩形区块显示，同时我们可以释放不在显示范围内的矩形区域。

有一个内建的CALayer子类 CATiledLayer 帮我们实现了这个分块。它的tileSize属性设置区块的大小。它的drawLayer:inContext: 会在需要一个空的区块时被调用；在图形上下文中调用CGContextGetClipBoundingBox 来截取所需区块的位置。下面我们借用苹果自己提供的PhotoScroller例子来说明：

我们给scroll view添加一个子视图，一个TiledView，这个视图用来存放我们的CATiledLayer图层。TILESIZE是256：

    -(void)viewDidLoad {
        CGRect f = CGRectMake(0,0,3*TILESIZE,3*TILESIZE);
        TiledView* content = [[TiledView alloc] initWithFrame:f];
        float tsz = TILESIZE * content.layer.contentsScale;
        [(CATiledLayer*)content.layer setTileSize: CGSizeMake(tsz, tsz)];
        [self.sv addSubview:content];
        [self.sv setContentSize: f.size];
    }
    

下面是TiledView的代码，CATiledLayer是它的根图层，所以TiledView是CATiledLayer的委托。意味着当CATiledLayer的 drawLayer:inContext: 被调用时，TiledView的drawRect:方法也会被调用，而且我们必须使用imageWithContentsOfFile:方法获取图片，而不是imageNamed:，防止系统缓存这张图片：

    + (Class) layerClass {
        return [CATiledLayer class];
    }
    -(void)drawRect:(CGRect)r {
        CGRect tile = r;
        int x = tile.origin.x/TILESIZE;
        int y = tile.origin.y/TILESIZE;
        NSString *tileName =
            [NSString stringWithFormat:@"CuriousFrog_500_%d_%d", x+3, y];
        NSString *path =
            [[NSBundle mainBundle] pathForResource:tileName ofType:@"png"];
        UIImage *image = [UIImage imageWithContentsOfFile:path];
        [image drawAtPoint:CGPointMake(x*TILESIZE,y*TILESIZE)];
    }
    

上面的代码中并没有明确释放离屏区块，你可以在TiledView中调用setNeedsDisplay 或者setNeedsDisplayInRect: 方法，但是这样并不会清除离屏的区块，我们相信这个CATiledLayer会帮我们处理好。

 [1]: http://images.cnitblog.com/blog/406864/201410/240753254335316.png
---
layout: post
title: Presented View Controller
date: 2014-04-04
categories: blog
tags: [iOS]
description: Presented View Controller

---

### Presented View Animation 展示视图的动画

* * *

当一个视图展示和消失的时候可以执行动画。有几个内建的动画类型，保留了历史遗留的“modal”称号：

*UIModalTransitionStyleCoverVertical （默认）*

展示的视图会从底部向上出现来覆盖原来的视图，消失时向底部移出，显示原来的视图。“底部”这个概念会随着设备支持方向的不同而不同。

*UIModalTransitionStyleFlipHorizontal*

视图在纵轴上翻转，好像这两个视图分别为一张纸的正面和背面。 “纵轴”是设备的长轴，跟应用程序的方向无关。

*UIModalTransitionStyleCrossDissolve*

原来的视图保持静止，一个视图会消失，从而显示另一个视图。

*UIModalTransitionStylePartialCurl*

第一个视图像翻页一样，翻到第二页，而且在第二页的左上角还会显示一些第一个视图的内容。

当展示或者关闭一个视图控制器时，你可以把一个动画类型作为类型传递给这个视图控制器，但是我们一般不这么做，而是让系统使用前面的视图控制器的`modalTransitionStyle`属性作为这个动画类型，因为，你怎么展示一个视图，然后又以相反的动画关闭这个视图会显得比较合乎情理，让用户觉得我们正在返回原来的状态。

### Presentation Styles 展示类型

* * *

在 iPad 上，视图控制器的modalPresentationStyle属性可以决定一个被展示的视图控制器的视图如何覆盖屏幕，以及可以决定什么视图控制器应该被用来展示，有下面的选择：

*UIModalPresentationFullScreen（默认）*

*UIModalPresentationPageSheet*

*UIModalPresentationFormSheet*

类似UIModalPresentationPageSheet，但所呈现的视图控制器的视图更小的，让用户看到更多展示视图控制器后面的的后面。正如其名称所暗示的，这是为了让用户填写表单（苹果公司描述为“收集来自用户的结构化数据）。

*UIModalPresentationCurrentContext*

正在展示的视图控制器不一定是根视图控制器或者是一个全屏幕展示的视图控制器，它也可以是任意的视图控制器，例如是一个子视图控制器，或是一个弹出的视图控制器。将要被展示的视图控制器的视图会取代原来展示视图控制器的视图。

当将要被展示的视图控制器的modalPresentationStyle 属性是 UIModalPresentationCurrentContext时，系统会在运行时帮我们决定哪个视图控制器才是正在展示的视图控制器，这将决定哪个视图将会被要展示的视图控制器的视图所取代。系统帮我们做这个决定时，会查找要展示的视图控制器或者其他的视图控制器的definesPresentationContext属性（一个BOOL 类型），下面是系统怎么做这个决定的：

1.  从原始的展示视图控制器开始（就是发送presentViewController:animated:completion:这个消息的视图控制器），从父视图控制器链向上查找哪个视图控制器的definesPresentationContext属性为YES。如果找到一个，那这个就是要找的，这个视图控制器将是正在展示的制图控制器，它的视图会被要展示的视图控制器的视图取代。
    
    如果找不到一个，那么就按照modalPresentationStyle属性为UIModalPresentationFullScreen来处理。

2.  如果找到了一个definesPresentationContext属性为YES的视图控制器，那么还会判断这个视图控制器的providesPresentationContextTransitionStyle属性是否也为YES。如果是，那么这个视图控制器的modalTransitionStyle属性将会用来执行这个转换动画，而不是使用正在展示的视图控制器的modalTransitionStyle属性。

可以实践一下下面的代码：

    - (IBAction)doPresent:(id)sender {
        UIViewController* vc = [ExtraViewController new];
        self.definesPresentationContext = YES;
        self.providesPresentationContextTransitionStyle = YES;
        self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        vc.modalPresentationStyle = UIModalPresentationCurrentContext;
        vc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [self presentViewController:vc animated:YES completion:nil];
    }
    

结果是视图控制器执行水平翻转动画进入，而不是后面设置的UIModalTransitionStyleCoverVertical动画。

### Rotation of a Presented View 展示视图的旋转

* * *

    -(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
        return UIInterfaceOrientationPortrait;
    }
    -(NSUInteger)supportedInterfaceOrientations {
        return UIInterfaceOrientationMaskAll;
    }
    

上面的代码的意思是：当我（UIViewController）作为一个将要展示的视图控制器被初始化时，这个app应该旋转为纵向，而当我已经在展示的时候，这个app可以随着设备旋转方向而旋转。

### 手动将事件转发给子视图控制器

* * *

一个自定义的容器类视图控制器必须手动地发送willMoveToParentViewController: 和 didMoveToParentViewController:消息给它的子视图控制器，这样，子视图控制器才能自动地收到相关的视图控制器生命周期消息：viewDidAppear:，viewWillDisappear:...和设备旋转消息。但是，但是你也可以自己手动负责这些生命周期消息和旋转消息的发送，通过实现下面的方法：

*   shouldAutomaticallyForwardRotationMethods
    
    如果你重写这个方法返回NO，那么你需要负责调用下面的方法给你的子视图控制器：
    
    *   willRotateToInterfaceOrientation:duration:
    
    *   willAnimateRotationToInterfaceOrientation:duration:
    
    *   didRotateFromInterfaceOrientation:

*   shouldAutomaticallyForwardAppearanceMethods
    
    如果你重写这个方法返回YES，那么你需要负责调用下面的方法给你的子视图控制器：
    
    *   viewWillAppear:
    
    *   viewDidAppear:
    
    *   viewWillDisappear:
    
    *   viewDidDisappear:
    
    但是你iOS 6 和iOS 7中，你不会直接调用这些方法，因为你不能确定那个合适的时候去调用它们，而你可以在子视图控制器上调用下面两个方法：
    
    *   beginAppearanceTransition:animated:
        
        第一个参数是BOOL类型，YES表示这个视图控制器将要显示，NO表示将要消失
    
    *   endAppearanceTransition

下面是两个简单的使用：

对于自定义的容器类视图控制器，下面的情况，不能调用UIViewController 的 transitionFromViewController:toViewController: ，因为这个方法会自动发送那些显示周期的消息（viewWillAppear，viewWillDisappear...）给第二个参数指定的视图控制器，在下面这个情况下会不会正常发送。你应该调用 UIView 的 transitionFromView:toView: ，这里你必须调用beginAppearanceTransition: 和 endAppearanceTransition

    - (void) viewWillAppear:(BOOL)animated {
        [super viewWillAppear:animated];
        UIViewController* child = // child whose view might be in our interface;
        if (child.isViewLoaded && child.view.superview)
            [child beginAppearanceTransition:YES animated:YES];
    }
    - (void) viewDidAppear:(BOOL)animated {
        [super viewDidAppear:animated];
        UIViewController* child = // child whose view might be in our interface;
        if (child.isViewLoaded && child.view.superview)
            [child endAppearanceTransition];
    }
    

下面是一个父视图控制器和它的子视图控制器视图的交换

    [self addChildViewController:tovc];
    [fromvc willMoveToParentViewController:nil];
    [fromvc beginAppearanceTransition:NO animated:YES]; // *
    [tovc beginAppearanceTransition:YES animated:YES]; // *
    [UIView transitionFromView:fromvc.view
        toView:tovc.view
        duration:0.4
        options:UIViewAnimationOptionTransitionFlipFromLeft
        completion:^(BOOL finished) {
            [tovc endAppearanceTransition]; // *
            [fromvc endAppearanceTransition]; // *
            [tovc didMoveToParentViewController:self];
            [fromvc removeFromParentViewController];
    }];
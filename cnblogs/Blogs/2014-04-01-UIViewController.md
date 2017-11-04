---
layout: post
title: UIViewController
date: 2014-04-01
categories: blog
tags: [iOS]
description: UIViewController

---

### 通用自动视图 Generic Automatic View

UIViewController 创建时，如果没有重写 loadView方法，那么UIViewController会默认在loadView方法里为我们创建一个通用的视图，类型就是UIView，然后帮我们赋值给self.view 属性：

    - (void) loadView {
        UIView* v = [UIView new];
        self.view = v;
    }
    

在 viewDidLoad 方法里，使用这个 self.view 是保证存在的。

UIViewController 子类（下面是RootViewController）结合 nib 时，可以像下面这样创建，指定Nib 的文件名，bundle参数如果是nil表示是MainBundle，通常就是nil即可：

    RootViewController* theRVC =
        [[RootViewController alloc] initWithNibName:@"MyNib" bundle:nil];
    self.window.rootViewController = theRVC;
    

事实上，我们还可以更简便，两个常数都传nil，这样，系统会以UIViewController子类的名称来查找对应的Nib 文件，即这个对应的Nib文件名是 RootViewController.xib：

    RootViewController* theRVC = [RootViewController new];
    self.window.rootViewController = theRVC;
    

如果有一个Nib文件名是RootViewController~ipad.xib，那么这个文件将会在iPad上自动载入，而不是载入RootViewController.xib 文件，即使你在initWithNibName: bundle: 方法中明确指定了@“RootViewController”，或者传入nil。

### nib类型的视图控制器 Nib-Instantiated View Controller

一个视图控制器可以是从nib文件加载的nib类型实例化对象，我们可以像下面那样初始化一个视图控制器：

    NSArray* arr = [[UINib nibWithNibName:@"Main" bundle:nil]
                     instantiateWithOwner:nil options:nil];
    self.window.rootViewController = arr[0];
    

不过我们需要在这个nib文件的可视化编辑器上，指定对象类型是View Controller类型。我们也可以直接从Object library中拖动一个View Controller到 nib文件中。

### 旋转

在 iOS 7 和 iOS 6 中，app默认都会自动支持随设备旋转而旋转，如果默认的不符合你的需要，你可以自定义：

*   在 app 的 Info.plist 文件里，可以添加 key 为Supported interface orientations（UISupportedInterfaceOrientations） 的相应值（对于一个通用的app，还需要设置 “Supported interface orientations (iPad)”, UISupportedInterfaceOrientations~ipad），这些值可以在app 的 target 栏目的 General 标签下找到，Xcode提供了复选框的方便方式来设置。

*   可以实现app的委托方法 `application:supportedInterfaceOrientationsForWindow:` 返回一个位掩码类型的支持的app界面方向。这个方法返回的结果会覆盖在Info.plist文件中的设置，这个委托方法每次设备旋转时至少被调用一次。

*   一个视图控制器可以实现 supportedInterfaceOrientations。返回的结果是与app委托方法或者Info.plist中列举的支持方向的交集。结果不能为空，否则app会崩溃。这个方法每次设备旋转时至少被调用一次。

视图控制器还有第二种方法来控制app允许支持的方向。可以实现shouldAutorotate。这个方法返回一个BOOL类型的值，默认是YES，如果返回NO，那么这一刻，界面不会旋转，而且supportedInterfaceOrientations方法也不会被调用，这个比实现supportedInterfaceOrientations方法简单。

视图控制器可以重写下面的方法来响应方向的旋转：

*willRotateToInterfaceOrientation:duration:*

第一个参数是新的方向，self.interfaceOrientations是旧的方向。视图的bounds是旧的bounds。

*willAnimateRotationToInterfaceOrientation:duration:*

第一个参数是新的方向，self.interfaceOrientations也是新的方向，视图的bounds是新的bounds。这个方法的调用是包装在一个animation block中的，所以改变视图的可执行动画的属性会触发动画。

*didRotateFromInterfaceOrientation:*

参数是旧的方向，self.interfaceOrientations是新的方向，视图的bounds是新的bounds。

下面是旋转时完成的调用序列：

*   willRotateToInterfaceOrientation:duration:
*   updateViewConstraints (and you must call super!)
*   updateConstraints (to the view)
*   viewWillLayoutSubviews
*   layoutSubviews (to the view)
*   viewDidLayoutSubviews
*   willAnimateRotationToInterfaceOrientation:duration: • didRotateFromInterfaceOrientation:

### 初始化方向

*在iPhone上*

当app启动时，会搜索Info.plist文件中列明的支持的设备方向的数组，取数组第一个元素作为初始化界面方向。

*在iPad上*

iPad不会理会Info.plist文件中列举的支持的设备的方向的顺序，而是根据设备当前的方向来寻找最合适的启动方向。
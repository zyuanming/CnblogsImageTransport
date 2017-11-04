---
layout: post
title: iOS Animation 学习（2）
date: 2014-09-04
categories: blog
tags: [iOS]
description: iOS Animation 学习（2）

---

* * *

## UIImageView and UIImage Animation

UIImageView提供了形式很简单的动画，可能这些不值得一提，尽管如此，有时候它就是你所需要的全部。你给UIImageView 的 animationImages 或者 highlightedAnimationImages属性 一个装有UIImage 的NSArray值，这个数组代表一个简单的动画片“帧”。但你发送 startAnimating消息，图片依次显示，帧率由animationDuration属性决定，重复次数由animationRepeatCount属性决定（默认是0，意味着无限重复，或者直到收到 stopAnimating 消息）。在动画之前和之后，这个UIImageView继续显示它的图片（或者 highlightedImage）。

例如，假设我们希望一张火星图片从某个地方冒出来，并在屏幕上闪烁三次。这似乎需要某种以NSTimer为基础的解决方案，但使用UIImageView的动画就非常简单：

    UIImage* mars = [UIImage imageNamed: @"Mars"];
    UIGraphicsBeginImageContextWithOptions(mars.size, NO, 0);
    UIImage* empty = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    NSArray* arr = @[mars, empty, mars, empty, mars];
    UIImageView* iv = [[UIImageView alloc] initWithImage:empty];
    CGRect r = iv.frame;
    r.origin = CGPointMake(100,100);
    iv.frame = r;
    [self.view addSubview: iv];
    iv.animationImages = arr;
    iv.animationDuration = 2;
    iv.animationRepeatCount = 1;
    [iv startAnimating];
    

您可以将UIImageView的动画与其他类型的动画结合起来。例如，您可以一边闪烁火星图像，而在同一时间向右滑动UIImageView，使用视图的动画将在后面见解。

此外，UIImage的动画提供了并行的形式：图像本身可以是一个动画对象。就像使用的UIImageView，这真的意味着你已经形成一个多张图片的序列作为一个简单的动画片“帧”。您可以使用两个UIImage的类方法之一来指定一个图像作为动画对象：

*   animatedImageWithImages:duration:
    
    如同UIImageView的的动画图片，你提供UIImages的数组。还为整个动画提供了动画的持续时间。

*   animatedImageNamed:duration:
    
    您提供的单个图像文件的名称，就像imageNamed：，不带文件扩展名。运行时会为您提供的名称后面追加@“0”（或者，如果失败了，@“1”），使该图像文件为动画序列的第一个图像。然后它递增所附加的数字，获取相应的图像，并将它们添加到序列中（直到没有更多图片，或者我们达到@“1024”）。
    
    还有一个第三方的方法：animatedResizableImageNamed:capInsets:resizing- Mode:duration:, 把可调整大小的图片和动画图像结合起来。

你并不能告诉一个动画形象开始执行动画，也不能告诉它你想要动画重复多久。相反，只要它出现在你的界面上，动画图像就始终在执行动画，每隔1秒的时间重复这个图片序列；为了控制动画，你可以从你的界面中添加或者删除这个图像，这样可能会让动画图像转变为一个没有动画的图像。此外，动画图像可以出现在任何一个UIImage会出现的一些界面对象的属性界面上。

在这个例子中，我在代码中构建了不同大小的红色圆圈序列，并建立一个动画形象，然后我在一个UIButton显示：

    NSMutableArray* arr = [NSMutableArray array];
    float w = 18;
    for (int i = 0; i &lt; 6; i++) {
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(w,w), NO, 0);
        CGContextRef con = UIGraphicsGetCurrentContext();
        CGContextSetFillColorWithColor(con, [UIColor redColor].CGColor);
        CGContextAddEllipseInRect(con, CGRectMake(0+i,0+i,w-i*2,w-i*2));
        CGContextFillPath(con);
        UIImage* im = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [arr addObject:im];
    }
    UIImage* im = [UIImage animatedImageWithImages:arr duration:0.5];
    // assume b is a button in the interface
    [b setImage:im forState:UIControlStateNormal];
    

* * *

## View Animation

动画是最终层的动画。但是，在有限的属性范围内，你可以直接让UIView执行动画： 这些是它的 alpha， backgroundColor， bonds， center， frame 和 transform。 你也可以让UIView内容的变化执行动画。这个名单尽管很简单，但是通常已经足够了。（如果执行不了动画，你可以用更加底层的技术，直接驱动 layer 来执行动画，后面会见到。）

### Block-Based View Animation

使用UIView类方法来使一个UIView执行动画的语法，我们一般使在block中描述我们想要的动画。例如，假设我们在界面上有一个背景颜色为黄色的UIView self.v ，我们想要通过动画来改变该视图的背景颜色为红色。下面可以做到这一点：

    [UIView animateWithDuration:0.4 animations:^{
        self.v.backgroundColor = [UIColor redColor];
    }];
    

在block中所做的变化都会执行动画，所以我们可以通过动画来同时改变视图的位置和颜色：

    [UIView animateWithDuration:0.4 animations:^{
        self.v.backgroundColor = [UIColor redColor];
        CGPoint p = self.v.center;
        p.y -= 100;
        self.v.center = p;
    }];
    

但是，有时在block中的某些操作我们不想让它执行动画，在 iOS 7 中，我们可以使用 performWithoutAnimation: 方法来解决这个问题。下面的代码，视图会跳到它的新位置，然后背景颜色慢慢地变为红色：

    [UIView animateWithDuration:0.4 animations:^{
        self.v.backgroundColor = [UIColor redColor];
        [UIView performWithoutAnimation:^{
            CGPoint p = self.v.center;
            p.y -= 100;
            self.v.center = p;
        }]; 
    }];
    

在block 中的代码会要求执行动画（不是performWithoutAnimation: block 中） －－ 也就是，block中的代码给出了在重绘时刻执行什么样的动画。如果你把改变动画视图的某个属性作为动画的一部分，那么你在之后就不应该再改变它，否则结果会让人很困惑。例如，猜猜下面的代码会怎样：

    [UIView animateWithDuration:2 animations:^{
        CGPoint p = self.v.center;
        p.y = 100;
        self.v.center = p;
        CGPoint p2 = self.v.center;
        p2.y = 300;
        self.v.center = p2;
    }];
    

结果并不是两个连续的动画。我们在这里仅仅是一个动画包含相互矛盾的命令： 通过动画让视图的center 的 y 值变成 100、 通过动画让视图的center 的 y 值变成300。 第二个动画命令会导致第一个动画被取消。 所以，但执行动画时，视图会跳到 center 的 y 值 为100的位置，然后才以动画的形式下移200。

即使在block 之后改变这个值也会造成迷惑。猜猜下面的代码会怎样：

    [UIView animateWithDuration:2 animations:^{
        CGPoint p = self.v.center;
        p.y = 100;
        self.v.center = p;
    }];
    CGPoint p2 = self.v.center;
    p2.y = 300;
    self.v.center = p2;
    

这个动画从它所在的位置开始，移动到center 的 y值为300的地方！ 在block里面的代码根本没有执行。 跟在block后面的代码相当于在block中执行，它已经成为动画的一部分了，实际的效果跟下面的代码一样：

    [UIView animateWithDuration:2 animations:^{
        CGPoint p2 = self.v.center;
        p2.y = 300;
        self.v.center = p2;
    }];
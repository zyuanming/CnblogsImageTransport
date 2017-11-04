---
layout: post
title: Objective-C 宏定义的收集
date: 2014-11-06
categories: blog
tags: [iOS]
description: 写不是义务，写本身就是写的报酬。

---

> 本文翻译自：[Collection of Objective-C Macros][1]

下面你将看到一些关于Objective-C 宏定义的收集，你也可以把你收集的[回复][2]给我（谢谢你！）

    // 度数 转为 弧度
    #define degreesToRadians(x) (M_PI * x / 180.0)
    
    // 使定时器失效
    #define UA_invalidateTimer(t) [t invalidate]; t = nil;
    
    // 设备信息
    #define UA_isIPad   (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    #define UA_isIPhone (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    #define UA_isRetinaDevice ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] >= 2)
    #define UA_isMultiTaskingSupported ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)] && [[UIDevice currentDevice] isMultitaskingSupported])
    
    
    // 线程
    #define UA_runOnMainThread if (![NSThread isMainThread]) { dispatch_sync(dispatch_get_main_queue(), ^{ [self performSelector:_cmd]; }); return; };
    
    // 颜色
    #define UA_rgba(r,g,b,a) [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a]
    #define UA_rgb(r,g,b) UA_rgba(r, g, b, 1.0f)
    
    // 调试和日志
    #ifdef DEBUG<
      #define UA_log( s, ... ) NSLog( @"&lt;%@:%d&gt; %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__,  [NSString stringWithFormat:(s), ##__VA_ARGS__] )
    #else
      #define UA_log( s, ... )
    #endif
    
    #define UA_logBounds(view) UA_log(@"%@ bounds: %@", view, NSStringFromRect([view bounds]))
    #define UA_logFrame(view)  UA_log(@"%@ frame: %@", view, NSStringFromRect([view frame]))
    
    // 其它的
    #define NSStringFromBool(b) (b ? @"YES" : @"NO")
    #define UA_SHOW_VIEW_BORDERS YES
    #define UA_showDebugBorderForViewColor(view, color) if (UA_SHOW_VIEW_BORDERS) { view.layer.borderColor = color.CGColor; view.layer.borderWidth = 1.0; }
    #define UA_showDebugBorderForView(view) UA_showDebugBorderForViewColor(view, [UIColor colorWithWhite:0.0 alpha:0.25])

 [1]: http://iosdevelopertips.com/general/some-good-macros-in-ios.html
 [2]: http://iosdevelopertips.com/submit-tips
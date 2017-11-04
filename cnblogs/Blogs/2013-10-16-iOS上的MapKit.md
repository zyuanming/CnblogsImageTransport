---
layout: post
title: iOS上的MapKit
date: 2013-10-16
categories: blog
tags: [iOS]
description: iOS上的MapKit

---

> 本文翻译自：[MapKit on iOS][1]

MapKit是一个非常整洁的API，可在iPhone上很容易地显示地图，跳到指定坐标，绘制位置，甚至在顶部画出路线和其他形状。

我写这篇文章的原因是，上个月我在Baltimore参加一个叫做 Civic Hack Day的活动，我在那里使用 MapKit来显示一些公共的数据，例如一些地方的位置，犯罪率，逮捕和公交车路线。我觉得这非常有趣，我想其他人也会有兴趣想知道这是如何做到的，或者想在自己的家乡使用相同的技术！

在这篇文章中，我们将创建一个app，可以在Baltimore城市中随意缩放到一个感兴趣的地方。这个app将请求一个Baltimore 的web 服务来获取在该区域附近最近的逮捕数据，然后在地图上标识出来。

在这个过程中，你将学习如何添加一个MapKit 地图到你的app中，缩放到一个指定的地方，通过Socrata API来查询和获取有用的政府数据，创建自定义的地图标注等等！

这个项目使用ARC，Storyboard！

### 开始

首先创建一个单视图的iOS应用程序，命名为 ArrestsPlotter。确定勾选使用Storyboard和ARC。

![][2]

拖动一个Map View到视图控制器上，还有一个底部的toolbar，命名为 Refresh：

![][3]

接着选择Map View，然后在设置面板中，如下设置：

![][4]

在运行你的应用前，添加MapKit framework 和 CoreLocation framework到你的工程中：

![][5]

现在运行你的app，将看到以下的内容：

![][6]

看起来还行，但是我们不想一开始就显示整个美国，我们想指定显示某个区域：

### 设置可视区域

导航到 ViewController.h 文件，用下面的代码取代原来的：

    #import <UIKit/UIKit.h>
    #import <MapKit/MapKit.h>
    
    #define METERS_PER_MILE 1609.344
    
    @interface ViewController : UIViewController{
    }
    
    @end
    

上面只是简单地添加了一个常量，指定每英里多少米。

下面把Storyboard中的MapView 链接到ViewController.m 文件中，添加一个它的引用：

![][7]

接下来，我们在ViewController.m文件 的 viewWillAppear: 方法中，把MapView 缩放到一个初始位置：

    - (void)viewWillAppear:(BOOL)animated {
        // 1
        CLLocationCoordinate2D zoomLocation;
        zoomLocation.latitude = 39.281516;
        zoomLocation.longitude= -76.580806;
        // 2
        MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(zoomLocation, 
                                               0.5*METERS_PER_MILE, 0.5*METERS_PER_MILE);
        // 3
        MKCoordinateRegion adjustedRegion = [_mapView regionThatFits:viewRegion];
        // 4
        [_mapView setRegion:adjustedRegion animated:YES];
    }
    

这里有很多工作需要做，我一点点说明：

1.  挑选出放大的区域。这里我们选择了对于 BPD Arrests API 服务比较完善的地方， Baltimore。

2.  当你想告诉地图显示什么时，不能只提供经纬度，你还需要指定一个区域来显示。这里我们指定以用户位置为中心的，宽和长为半英里的区域。

3.  在给map view设置一个区域之前，你需要把这个区域缩放到刚好充满屏幕的大小，这个map view提供了一个帮助方法 `regionThatFits:`来实现这个功能。

4.  最后，告诉map view显示这个区域，map view会自动通过一个动画为缩放当前的视图到指定的显示区域，不需要额外的代码！

再次运行这个app，我们看到缩放到想要的区域了：

![][8]

### 获取逮捕信息

下一步就是在地图上显示有趣的逮捕信息。

在Baltimore，我们非常幸运，因为这城市正努力把所有的城市数据同步到网络上， 通过 OpenBaltimore项目。

我们将在这篇文章中使用它提供的数据集。你在阅读完这篇文章后，可以去了解一下你的城市是否也提供类似的在线服务。

总之，Baltimore 城市的数据是通过一个 Socrata公司提供的，这个公司提供了一个API让你可以访问这些数据。 这个 [Socrata API documentation][9] 可以在网上查看，这里我们就不详细介绍了，我们从一个高层次上解析我们的计划：

1.  我们感兴趣的数据集是 [BPD Arrests][10]，通过这个链接，你可以查看详细信息。

2.  为了查询这个API，你需要POST一个JSON格式的查询数据到提供的Socrata API。结果以JSON格式返回。

3.  我们需要使用的数据在稍微后面，所以我们把这个查询数据保存到一个文本中，方便以后读取和修改。

4.  为了节省时间，我们使用ASIHttRequest 网络请求库来发送数据到 web service，SBJSON 库用来解析json数据。

### 添加库

这个功能中，我们需要

1.  SBJSON

2.  ASIHTTPRequest

3.  MBProgressHUD

你需要在GitHub上下载这些开源的库，然后添加到我们的工程中。同时，还要引入 CFNetwork framework， MobileCoreServices frame，SystemConfiguration framework和 libz.1.1.3.dylib。

![][11]

注意，ASIHTTPRequest 使用非 ARC，你需要指定一个编译选项： -fno-objc-arc:

![][12]

### 获取逮捕数据

首先，从这里下载查询字符串的[样本][13]，把解压缩后的command.json 导入工程中。

接下载，我们实现Refresh 按钮的响应事件：

    // At top of file
    #import "ASIHTTPRequest.h"
    
    // Replace refreshTapped as follows
    - (IBAction)refreshTapped:(id)sender {
    
         // 1
        MKCoordinateRegion mapRegion = [_mapView region];
        CLLocationCoordinate2D centerLocation = mapRegion.center;
    
        // 2
        NSString *jsonFile = [[NSBundle mainBundle] pathForResource:@"command" ofType:@"json"];
        NSString *formatString = [NSString stringWithContentsOfFile:jsonFile encoding:NSUTF8StringEncoding error:nil];
        NSString *json = [NSString stringWithFormat:formatString,
                      centerLocation.latitude, centerLocation.longitude, 0.5*METERS_PER_MILE];
    
        // 3
        NSURL *url = [NSURL URLWithString:@"http://data.baltimorecity.gov/api/views/INLINE/rows.json?method=index"];
    
        // 4
        ASIHTTPRequest *_request = [ASIHTTPRequest requestWithURL:url];
        __weak ASIHTTPRequest *request = _request;
    
        request.requestMethod = @"POST";
        [request addRequestHeader:@"Content-Type" value:@"application/json"];
        [request appendPostData:[json dataUsingEncoding:NSUTF8StringEncoding]];
        // 5
        [request setDelegate:self];
        [request setCompletionBlock:^{
            NSString *responseString = [request responseString];
            NSLog(@"Response: %@", responseString);
        }];
        [request setFailedBlock:^{
            NSError *error = [request error];
            NSLog(@"Error: %@", error.localizedDescription);
        }];
    
        // 6
        [request startAsynchronous];
    
    }
    

下面解析：

1.  获取地图中心位置的经纬度。

2.  读取我们的查询字符串数据command.json。

3.  创建一个请求访问链接URL

4.  使用ASIHTTPRequest post我们的数据。

5.  设置ASIHTTPRequest 的两个block，完成block和失败block。

6.  开始网络请求。

运行我们的应用，点击Refresh 按钮，会在控制台看到如下的返回数据：

![][14]

### 绘制信息

为了创建和使用自定义地图标注，我们有三步：

1.  创建一个实现了MKAnnotation 协议的类，这意味着需要返回一个标题，子标题和坐标。

2.  对于每一个你想在地图上标注的地点，你可以创建一个上面类的实例，然后通过`addAnnotation`方法把这个标注添加到mapView上。

3.  把视图控制器作为map view 的委托，对于你添加的每个标注，都会调用一个委托方法：`mapView:viewForAnnotation` 。你需要在这个委托方法中返回一个MKAnnotationView的子类，用于展示标注的虚拟标志。我们这里将使用一个内建的MKPinAnnotationView。

下面是实现：

    # import <Foundation/Foundation.h>
    
    # import <MapKit/MapKit.h>
    
    @interface MyLocation : NSObject <MKAnnotation> { NSString *\_name; NSString *\_address; CLLocationCoordinate2D _coordinate; }
    
    @property (copy) NSString *name; @property (copy) NSString *address; @property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
    
    - (id)initWithName:(NSString*)name address:(NSString*)address coordinate:(CLLocationCoordinate2D)coordinate;
    
    @end
    

下面是MyLocation的实现

    #import "MyLocation.h"
    
    @implementation MyLocation
    @synthesize name = _name;
    @synthesize address = _address;
    @synthesize coordinate = _coordinate;
    
    - (id)initWithName:(NSString*)name address:(NSString*)address coordinate:(CLLocationCoordinate2D)coordinate {
        if ((self = [super init])) {
            _name = [name copy];
            _address = [address copy];
            _coordinate = coordinate;
        }
        return self;
    }
    
    - (NSString *)title {
        if ([_name isKindOfClass:[NSNull class]])
            return @"Unknown charge";
        else
            return _name;
    }
    
    - (NSString *)subtitle {
        return _address;
    }
    
    @end
    

下面是ViewController.m 中添加标注的实现：

    // Add to top of file
    #import "MyLocation.h"
    #import "SBJSON.h"
    
    // Add new method above refreshTapped
    - (void)plotCrimePositions:(NSString *)responseString {
    
        for (id<MKAnnotation> annotation in _mapView.annotations) {
            [_mapView removeAnnotation:annotation];
        }
    
        NSDictionary * root = [responseString JSONValue];
        NSArray *data = [root objectForKey:@"data"];
    
        for (NSArray * row in data) {
    
            NSNumber * latitude = [[row objectAtIndex:21]objectAtIndex:1];
            NSNumber * longitude = [[row objectAtIndex:21]objectAtIndex:2];
            NSString * crimeDescription =[row objectAtIndex:17];
            NSString * address = [row objectAtIndex:13];
    
            CLLocationCoordinate2D coordinate;
            coordinate.latitude = latitude.doubleValue;
            coordinate.longitude = longitude.doubleValue;
            MyLocation *annotation = [[MyLocation alloc] initWithName:crimeDescription address:address coordinate:coordinate] ;
            [_mapView addAnnotation:annotation];
         }
    }
    
    // Add new line inside refreshTapped, in the setCompletionBlock, right after logging the response string
    [self plotCrimePositions:responseString];
    

对于第三步，在ViewController中实现 MKMapViewDelegate 协议：

    @interface ViewController : UIViewController <MKMapViewDelegate> {
    

添加一个新的方法：

    - (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    
        static NSString *identifier = @"MyLocation";
        if ([annotation isKindOfClass:[MyLocation class]]) {
    
            MKPinAnnotationView *annotationView = (MKPinAnnotationView *) [_mapView 
                                dequeueReusableAnnotationViewWithIdentifier:identifier];
            if (annotationView == nil) {
                annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation 
                                                                 reuseIdentifier:identifier];
            } else {
                annotationView.annotation = annotation;
            }
    
            annotationView.enabled = YES;
            annotationView.canShowCallout = YES;
            annotationView.image=[UIImage imageNamed:@"arrest.png"];
            //here we use a nice image instead of the default pins
    
            return annotationView;
        }
    
        return nil;
    }
    

每次你添加一个标注，上面的方法都会被调用。

运行结果：

![][15]

### 添加一个进度指示

网络请求需要时间，我们可以在此显示一个加载进度标识：

    // Add at the top of the file
    #import "MBProgressHUD.h"
    
    // Add right after [request startAsynchronous] in refreshTapped action method
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"Loading arrests...";
    
    // Add at start of setCompletionBlock and setFailedBlock blocks
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    

### 源码

这里是一个完整的[源码项目][16]

 [1]: http://ios.biomsoft.com/2012/04/06/mapkit-on-ios/
 [2]: http://images.cnitblog.com/blog/406864/201411/061118067201875.png
 [3]: http://images.cnitblog.com/blog/406864/201411/061120117836866.png
 [4]: http://images.cnitblog.com/blog/406864/201411/061121262522283.png
 [5]: http://images.cnitblog.com/blog/406864/201411/061122537524218.png
 [6]: http://images.cnitblog.com/blog/406864/201411/061124025641096.png
 [7]: http://images.cnitblog.com/blog/406864/201411/061130259245110.png
 [8]: http://images.cnitblog.com/blog/406864/201411/061142130806869.png
 [9]: http://dev.socrata.com/querying-datasets
 [10]: https://data.baltimorecity.gov/Crime/BPD-Arrests/3i3v-ibrt
 [11]: http://images.cnitblog.com/blog/406864/201411/061156466277463.png
 [12]: http://images.cnitblog.com/blog/406864/201411/061158338456740.png
 [13]: http://www.raywenderlich.com/downloads/command2.json.zip
 [14]: http://images.cnitblog.com/blog/406864/201411/061207445642660.png
 [15]: http://images.cnitblog.com/blog/406864/201411/061334179709511.png
 [16]: http://www.raywenderlich.com/downloads/ArrestsPlotter.zip
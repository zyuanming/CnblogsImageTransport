---
layout: post
title: 有弹性，可伸展的UICollectionView 头部视图
date: 2014-12-05
categories: blog
tags: [iOS]
description: 写不是义务，写本身就是写的报酬。

---

> 本文翻译自：[Stretchy UICollectionView headers][1]

滚动视图的反弹效果可能是iOS中最具特色的效果之一。虽然最初只是华而不实，但随着时间的推移，实际上它已经发挥了一些功能用途，像下拉刷新。另一个很好地应用滚动视图的反弹效果的，就是我最近看到的弹性头部视图。

![][2]

这个效果非常好，当你向下拉动滚动视图时，可以在顶部和底部查看更多的图片内容。你可能已经在[Twitter][3]的iOS应用和[Airbnb][4]清单中看到类似的效果了。这种效果很容易实现，今天我将向您展示如何去做。

让我们开始吧。首先，创建一个\[UICollectionViewFlowLayout\]\[3\]的子类。

    #import <UIKit/UIKit.h>
    
    @interface StretchyHeaderCollectionViewLayout : UICollectionViewFlowLayout
    @end
    

如果你曾经摆弄自定义过UICollectionView的布局，那么你可能已经意识到它们非常强大的。这是我们的实现：

    #import "StretchyHeaderCollectionViewLayout.h"
    
    @implementation StretchyHeaderCollectionViewLayout
    
    - (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
        // This will schedule calls to layoutAttributesForElementsInRect: as the 
        // collectionView is scrolling. 
        return YES;
    }
    
    - (UICollectionViewScrollDirection)scrollDirection {
        // This subclass only supports vertical scrolling.
        return UICollectionViewScrollDirectionVertical;
    }
    
    - (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    
        UICollectionView *collectionView = [self collectionView];
        UIEdgeInsets insets = [collectionView contentInset];
        CGPoint offset = [collectionView contentOffset];
        CGFloat minY = -insets.top;
    
        // First get the superclass attributes.
        NSArray *attributes = [super layoutAttributesForElementsInRect:rect];
    
        // Check if we've pulled below past the lowest position
        if (offset.y < minY) {  
    
            // Figure out how much we've pulled down 
            CGFloat deltaY = fabsf(offset.y - minY);
    
            for (UICollectionViewLayoutAttributes *attrs in attributes) {
    
                // Locate the header attributes
                NSString *kind = [attrs representedElementKind];
                if (kind == UICollectionElementKindSectionHeader) {
    
                    // Adjust the header's height and y based on how much the user
                    // has pulled down.
                    CGSize headerSize = [self headerReferenceSize];
                    CGRect headerRect = [attrs frame];
                    headerRect.size.height = MAX(minY, headerSize.height + deltaY);
                    headerRect.origin.y = headerRect.origin.y - deltaY;
                    [attrs setFrame:headerRect];
                    break;
                }
            }
        }
        return attributes;
    }
    
    @end
    

这个自定义的布局会检查我们是否下拉到最低的偏移量，这意味着我们将开始拉伸头部视图。如果真的是，我们找到这个头部元素，根据拉伸的值来增加它的高度和y轴上的偏移量。

接下来，在你配置你的集合视图的地方，添加下面的代码：

    // Create a new instance of our stretchy layout and set the 
    // default size for our header (for when it's not stretched)
    StretchyHeaderCollectionViewLayout *stretchyLayout;
    stretchyLayout = [[StretchyHeaderCollectionViewLayout alloc] init];
    [stretchyLayout setHeaderReferenceSize:CGSizeMake(320.0, 160.0)];
 
    // Set our custom layout
    [collectionView setCollectionViewLayout:stretchyLayout];
    // and tell our collection view to always bounce.
    [collectionView setAlwaysBounceVertical:YES];
 
    // Then register a class to use for the header.
    [collectionView registerClass:[UICollectionReusableView class]
   forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
          withReuseIdentifier:@"ident"];

最后一件需要做的事情就是创建我们的头部视图，而且应该是[UICollectionReusableView][5]的子类。我们可以添加一个[UIImageView][6]作为它的子视图，然后使用autoresizing来让它大小合适：

    - (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView 
           viewForSupplementaryElementOfKind:(NSString *)kind 
                                 atIndexPath:(NSIndexPath *)indexPath {
        // You can make header an ivar so we only ever create one
        if (!header) {
 
            header = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                    withReuseIdentifier:@"ident"
                                                           forIndexPath:indexPath];
            CGRect bounds;
            bounds = [header bounds];
 
            UIImageView *imageView;
            imageView = [[UIImageView alloc] initWithFrame:bounds];
            [imageView setImage:[UIImage imageNamed:@"header-background"]];
 
            // Make sure the contentMode is set to scale proportionally
            [imageView setContentMode:UIViewContentModeScaleAspectFill];
            // Clip the parts of the image that are not in frame
            [imageView setClipsToBounds:YES];
            // Set the autoresizingMask to always be the same height as the header
            [imageView setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
            // Add the image to our header
            [header addSubview:imageView];
        }
        return header;
    }

这个autoresizingMask 会保持图片的高度与头部视图的一致。这个contentMode和clipsToBounds属性将居中图片以及裁切多余的内容。

你可以在[Github][7]上找到完整的代码。

 [1]: https://nrj.io/stretchy-uicollectionview-headers
 [2]:http://images.cnitblog.com/blog2015/406864/201503/161716591889553.gif
[3]:https://developer.apple.com/library/ios/documentation/uikit/reference/UICollectionViewFlowLayout_class/Reference/Reference.html
 [3]: http://twitter.com/
 [4]: http://airbnb.com/
[5]:https://developer.apple.com/library/ios/documentation/uikit/reference/UICollectionReusableView_class/Reference/Reference.html
[6]:https://developer.apple.com/library/ios/documentation/uikit/reference/UIImageView_Class/Reference/Reference.html
[7]:https://github.com/nrj/StretchyHeaderCollectionViewLayout
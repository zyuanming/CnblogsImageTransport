---
layout: post
title: 给tableview 添加一个阴影
date: 2013-10-07
categories: blog
tags: [iOS]
description: 给tableview 添加一个阴影

---

> 本文翻译自：[Adding a drop shadow to a table view][1]

最近我在实现一个tableview视图的最后一个单元格有一个阴影效果的视图。

实现的思路是在单元格的 Core Animation 图层上使用shadow属性，然后渲染出我们的阴影。

（单元格是tableview的最后一个表格）

    - (UITableViewCell *)tableView:(UITableView *)tableView
    

cellForRowAtIndexPath:(NSIndexPath *)indexPath { // ... cell.layer.shadowOffset = CGSizeMake(0, 15); cell.layer.shadowColor = [[UIColor blackColor] CGColor]; cell.layer.shadowRadius = 3; cell.layer.shadowOpacity = .75f; CGRect shadowFrame = cell.layer.bounds; CGPathRef shadowPath = [UIBezierPath bezierPathWithRect:shadowFrame].CGPath; cell.layer.shadowPath = shadowPath; // ... }

设置这个阴影路径 shadow path 是为了提供渲染速度，不需要设置表格下面的模糊图层。

你可以通过修改它的阴影属性来改变阴影的效果，例如，减少 opacity 不透明度可以实现一个更加明亮的阴影，增加radius阴影半径可以让阴影更长。

![][2]

 [1]: http://travisjeffery.com/b/2012/07/adding-a-drop-shadow-to-a-table-view/
 [2]: http://images.cnitblog.com/blog2015/406864/201503/241111548494939.png
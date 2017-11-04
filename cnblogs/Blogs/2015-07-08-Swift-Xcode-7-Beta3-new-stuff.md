---
layout: post
title: Swift:Xcode 7 Beta3 中新增的东西
date: 2015-07-08
categories: blog
tags: [iOS]
description: 写不是义务，写本身就是写的报酬。

---

> 本文翻译自[Swift: New stuff in Xcode 7 Beta 3][1]

在今天苹果推送的最新beta 版中，下面新增的内容是最让我兴奋的。

## 默认枚举命名

在最新的 beta 3 版本中，String 类型的枚举如果没有显示赋值，则默认值为该枚举对应的名字。我非常喜欢这个巨大的改进，也是beta 3 中非常大的一个功能。让我们来看一下吧：

![][2]

## Explicit Label Exclusion.

你是否曾经搞混函数中的参数和元组？现在再也不用担心这个问题了。未命名的参数现在要求显示加上 `_` 符号来区分函数`f((x: Double, y: Double))` 和 `f(x:Double, y:Double)` 。现在是这样使用 `f(_ point: (Double, Double))`

## Arruples

你现在可以添加元组类型的元素到数组中了。下面的代码是可以正常工作的，尽管在beta 3 中报错。

![][3]

## OBJC 范型

Objective-C现在支持范型子类了。我还没有时间去试用这个新功能。我也尝试了 NS_REFINED_FOR_SWIFT 这个宏，让你来创建针对Swift 的增强实现。

## 点命令

点命令现在可以无限扩展多行了。如下面的例子，点用来扩展前面一行，来解析连体方法和属性：

    let values = split("Lorem ispum eejit".characters,
        isSeparator:{$0 == Character(" ")})
        .map({String($0)})
        .map({"item \($0)"})
        .count


这种改变的副作用可能会随着发行版文档而改变。现在你不可以在一行的开头使用推断式静态成员变量了。 所以 `.staticVar = value` 已经不起作用了。因为我记不起来我有使用过这种形式了，所以我真的不关心它带来的副作用。

 [1]: http://ericasadun.com/2015/07/08/swift-new-stuff-in-xcode-7-beta-3/
 [2]: http://images0.cnblogs.com/blog2015/406864/201507/111424203934315.png
 [3]: http://images0.cnblogs.com/blog2015/406864/201507/111433235964296.png

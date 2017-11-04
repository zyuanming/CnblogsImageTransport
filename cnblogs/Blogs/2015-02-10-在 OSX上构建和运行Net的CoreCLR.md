---
layout: post
title: 在 OS X 上构建和运行 .Net 的 CoreCLR
date: 2015-02-10
categories: blog
tags: [iOS]
description: 写不是义务，写本身就是写的报酬。

---

> 本文翻译自：[Building and Running .NET’s CoreCLR on OS X][1]

没错，你没听错，[微软已经开源了.Net 核心的完整运行时实现 CLR][2]，而它不仅仅可以运行在Windows 上。他们不是随便地转储一堆ZIP文件到一个FTP服务器上，而是给我们提供了一个功能齐全，易于编译，容易托管在所有人喜欢的文件共享介质上的东西。微软甚至走得更远，在GitHub上设置了双向镜像，这样他们的内部系统会与我们看到的保持同步。这种行为给我留下了深刻的印象。

他们最初的版本适用于Windows和Ubuntu。这非常好－ 的确是一个很好的开始 － 但是我使用的是Mac系统啊。微软说他们打算在未来支持OS X平台，但只是还没有得到解决。我想当他们有机会时，我大概会在几个月后看看CLR。

当然，一旦把东西开源了，他们往往会失控。

我们看看非凡的系统程序员[Geoff Norton][3]。他了解CLR的一切。他曾经为 [Mono][4] 工作了几年 － 就是原始开源的.Net ，而且他对于把它带到OS X 有自己的切身体会。

好吧，如果你使用了一次伎俩，那么你就可以再使用一次，对吧？

> 最初的OSX 支持已经刚刚集成进CoreCLR<https://t.co/CH1BWhWdyl> [@DotNet][5]
> 
> － Geoff Norton (@geoffnorton)
> 
> [February 7, 2015][6]
> 
> 我相信我是第一个把所有的开源CLRs带到 64位OS X 上的人。非常开心。
> 
> － Geoff Norton (@geoffnorton)
> 
> [February 7, 2015][7]

一切都是从Geoff的“[有了一些时间让它可以运行在Mac上][8]”的Pull Request开始的。一些时间...我们查看他的Pull Request，可以知道过程是这样的：

*   修补构建系统，让它知道Linux并不是唯一的Unix分支

*   修补了很多汇编指令，因为Mac的指令比Ubuntu的更加严格

*   [以字节][9]（不是操作码）来重写高性能的比特组件，要不Mac不会产生期望的指令。

*   大量的unicode变化，为了适应神灵LLVM。

总之，它看起来像一个很大的高精度和繁琐的工作，我要感谢Geoff做了。

这还不是完美的支持。我与Geoff 要花费一个小时来实现打印一个Hello World。当我写这篇文章时，仍然有很多bugs。但是开源终将以胜利告终。我睡觉前有一个bug，睡醒后就已经被解决了。

但足以了！让我们开始吧：让我们构建.NET，写一些代码，然后运行它。

## 1\. 获取源码

这是很容易的一部分，这个[CoreCLR已经是托管在github上了][10]。你可以fork这个项目，或者直接获取：

    git clone git@github.com:dotnet/coreclr.git
    

你现在有超过200万行的复杂设计的代码（C＃，C++和Java），来[使编程更加容易的平台][11]。我推荐一瓶酒和一个不错的grep工具。但在此之前...

## 2\.获取构建工具

[CMake][12]是用来构建Core CLR的工具。我建议使用[Homebrew][13]来安装它。

    brew install cmake
    

很快，你将有一个很热门的小型构建工具。

## 3\.执行构建！

耶，认真的，就是这么简单：

    ./build.sh amd64 debug
    

仅仅支持 amd64（这已经足够了，苹果已经把32位像一个烫手的山芋一样扔掉了），我们选择做一个调试版本，因为这个项目还处于初期阶段。

你将在命令行下看到 **Detected OSX x86_64** ，然后是很多颜色出现。

只需要看着这些漂亮的颜色几分钟。不需要担心那些红线；不知道为什么，CMake决定用红色来表示成功。

如果你有一瓶葡萄酒，现在是一个好时机，去拿一些饼干或者蔬菜拼盘...

## 4\.佩服它吧

当CMake认为你已经准备好了，就是以下面无害的信息向你打招呼了：

    Repo successfully built.
    Product binaries are available at /Users/fak/Projects/coreclr/binaries/Product/amd64/debug
    

我们已经等了将近15年来让这个Repo 成功构建，而现在它成功了。我要向微软的CLR团队花时间来把这个构建打包得这么好脱帽致敬。（这比我下载单个C文件来编译容易多了）

不管怎样，它已经把自己放到了一个目录下。让我们一起看看我们得到了什么。

    $ cd binaries/Product/amd64/debug
    $ ls -al
    total 46032
    drwxr-xr-x  5 fak  staff       170 Feb  7 11:47 .
    drwxr-xr-x  4 fak  staff       136 Feb  7 12:25 ..
    -rwxr-xr-x  1 fak  staff     49836 Feb  7 11:47 corerun
    -rwxr-xr-x  1 fak  staff  23503712 Feb  7 11:47 libcoreclr.dylib
    -rwxr-xr-x  1 fak  staff      4176 Feb  7 11:47 libmscordaccore.dylib
    

那些神奇的颜色创建了3个文件：

### corerun

corerun是一个小的驱动程序，接受一个托管程序集，初始化CLR，然后执行该程序集。它与 mono 命令等效，只是有一个糟糕的名字而已。这个每一个你想运行在Mac上的应用的入口点。

我们将很快看到它的用处。

### libmscordaccore.dylib

一个代码库没有附件会怎样呢？有些是不属于它的，但是某些人认为包含这些会很有用。

libmscordaccore.dylib就是这样。我听说它可以“帮助调试”，但是只有4kb，我很怀疑。不，这只是一个丑陋的软件，否则会完整打包进程序中，我们最好忽略它。

### libcoreclr.dylib

这个就是它的相亲，老爹，重量级人物，超级巨星。

libcoreclr 包含三样东西：一个真他妈好的垃圾回收器；一个JIT，是一个类型和元数据系统还有一个平台抽象的容器。好了，非常多的东西，都打包进了一个超级性感的动态库里。

还记得那些100MB大的.Net 文件吗？ 还记得它们需要多长时间才能安装完吗？还记得一旦你在机器上更新了.Net，所有的应用是怎么使用的吗？

再也没有这些烦恼了。不再有安装，不再有该死的DLL文件，不再有该死的部署。你想要.Net吗？ 下面是一个单一的文件（及其附件），可以通过rsync部署。这就是.NET在一个库中的所有重要组成部分，仅仅24MB。不是由于Silverlight已经在CLR被包装得这么好（和AFAIK，这是一个比Silverlight更复杂的CLR）。

喝一小口酒。

你现在可以把 “The Book of the Runtime” 这篇文章放在你喜欢的稍后阅读服务上。当你从这些经验中醒来时，这篇文章会等着你，绝望地向你那因为太忙不能学习运行时的大脑灌输它十几年的知识。

## 5\.你将需要一个字符类...

你可能注意到上面的那些文件中缺少了一样东西：mscorlib.dll。就像在说“我的字符类在哪里了？”

你可以看到，虽然libcoreclr 知道所有的对象和类型，以及怎么管理它们，让它们开心，但是它实际上并不包含所有东西。

这个CoreCLR库包含了所有mscorelib的代码，全部都是用C#写的，而这个CoreCLR并不与C#编译器一起！因为没有编译器，这个构建系统不同编译标准的库。这很有趣，但也不是这种方式的有趣。

.Net 团队[推荐使用一个Windows机器][14]来通过命令在构建mscorlib：

    >build.cmd unixmscorlib
    

但是，嗯，是的，这个骗你的。

这一次又是 Geoff Norton。他已经构建了那个代码并发布了它。[从Geoff 的Dropbox下载这个文件即可][15]。

然后把它放到那三个文件所在的目录下：

    $ ls -al
    total 51776
    drwxr-xr-x  6 fak  staff       204 Feb  7 12:34 .
    drwxr-xr-x  4 fak  staff       136 Feb  7 12:25 ..
    -rwxr-xr-x  1 fak  staff     49836 Feb  7 11:47 corerun
    -rwxr-xr-x  1 fak  staff  23503712 Feb  7 11:47 libcoreclr.dylib
    -rwxr-xr-x  1 fak  staff      4176 Feb  7 11:47 libmscordaccore.dylib
    -rw-r--r--@ 1 fak  staff   2937856 Feb  7 12:34 mscorlib.dll
    

恭喜你，这个四个文件组成了一个OS X上完整功能的.Net 实现。

## 6\. 写一些代码

现在我们有了一个完整功能的.Net，我们需要给它一些东西来运行。如果你身边有些组建，它们会工作得非常好，不过我们还是在OS X上测试一下编译代码吧。我们可以使用Windows上的微软编译器，然后复制一些程序集到OS X上，但这是骗你的。

我们将使用[Mono的免费C#编译器][16]。简单[安装Mono][17]后，它就会在你的系统参数PATH路径里了。

好的，你知道这里要怎么做了....打开你最喜欢的编辑器，创建一个HelloWorld.cs文件：

    using System;
    
    public class HelloWorld
    {
        public static int Main (string[] args)
        {
            Console.WriteLine ("Hello, world! From CoreCLR.");
            return 0;
        }   
    }
    

现在编译它：

    $ dmcs -nostdlib -r:mscorlib.dll HelloWorld.cs
    

这个-nostdlib 选项用来告诉编译器不要自动引用它知道的任何标准库（不仅仅是mscorlib，还包括其它的）。这种情况下，我们只是通过手动明确地指定引用的组件。

然后我们通过 -r:mscorlib.dll 来引用我们的 mscorlib。这是必须的前面的选项。

事实上，我们可以看到编译器做的工作，我们也已经有了一个准备好执行的程序集：

    $ ls -al *.exe
    -rwxr-xr-x  1 fak  staff  3072 Feb  7 12:48 HelloWorld.exe
    

## 7\.运行那个小狗

    $ ./corerun -c . HelloWorld.exe
    
    Hello, world! From CoreCLR.
    

太棒了。

喝一口酒。

我们使用 corerun 来开始运行.Net 代码。这个 -c 参数用来指定要运行时的所在的目录（那两个dylibs 和 mscorlib）。因为我所有的工作都在那个目录下的，所以我只是指定 . 即可。

这就完成了！我们现在有一个完全功能的工具链来在美美的OS X上编译和运行.Net 代码。

## 8\.回馈

现在我要提醒你一下：在OS X上的.Net仍然有已知的bugs。你不能使用它来发布你的应用。

如果你是一个系统工程师，或者想了解如何才能成为一个 ， 那么深入该代码。试试运行你的应用程序，注意崩溃，然后加载LLDB。有可能到头来你会被丢失，但你会迷失在一个充满神秘和可能性的美好地方。

然后上来 <https://gitter.im/dotnet/coreclr>，我们将会讨论一切关于coreclr的东西，特别是如何让一些愚蠢的事情停止奔溃。;-)

## 展望未来

这个 CoreCLR 在我脑海里是一个怪胎 － 我不知道怎么拿走它。

我们已经对.NET中高质量的开源实现移植到OS X有多年了。我甚至用它来[创建][18]了我赖以生活的[应用程序][19]。我花了近5年来学习它：它的怪癖和权力。除了技术，还有那已经长大了，超过10年的周围成熟的一个惊人的开发者社区。

微软不能仅仅丢一堆代码到Github上，然后希望一个社区围绕着它建立起来。事实上，我不知道她们是否想要一个。管理一个社区远比管理 pull request难多了。微软更高的管理层好像太关心Azure以至于没有关心其它非500强企业正在用他们的产品做什么。不过老实说，这非常好。

短期内，微软仍会继续利用他们难以置信的编程和测试能力贡献给CLR。我们也会惊叹他们对这些复杂的C++代码做出的精细的变化。当他们在我们宝贵的平台上打破了某些东西时，开源社区仍然会站出来，或者我们决定是时候用这些小宝石做出一些新的，令人难以置信的东西出来。

也就是说，目前这仍然是微软的CLR。我很好奇它是否会变成我们的。

 [1]: http://praeclarum.org/post/110552954728/building-and-running-nets-coreclr-on-os-x
 [2]: http://blogs.msdn.com/b/dotnet/archive/2015/02/03/coreclr-is-now-open-source.aspx
 [3]: https://twitter.com/geoffnorton
 [4]: http://www.mono-project.com/
 [5]: https://twitter.com/DotNet
 [6]: https://twitter.com/geoffnorton/status/563908409380962304
 [7]: https://twitter.com/geoffnorton/status/563911442261213185
 [8]: https://github.com/dotnet/coreclr/pull/105
 [9]: https://github.com/dotnet/coreclr/pull/117#issuecomment-73343848
 [10]: https://github.com/dotnet/coreclr
 [11]: https://github.com/dotnet/coreclr/blob/master/Documentation/intro-to-clr.md
 [12]: http://www.cmake.org/
 [13]: http://brew.sh/
 [14]: https://github.com/dotnet/coreclr/wiki/Building-and-Running-CoreCLR-on-Linux
 [15]: https://www.dropbox.com/s/zvl5tsj6peh12km/mscorlib.dll?dl=0
 [16]: https://github.com/mono/mono/tree/master/mcs/mcs
 [17]: http://www.mono-project.com/download/
 [18]: http://icircuitapp.com
 [19]: http://calca.io
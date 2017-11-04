---
layout: post
title: Maven + Jetty 配置和运行
date: 2013-11-18
categories: blog
tags: [iOS]
description: Maven + Jetty 配置和运行

---

     各位，好久没有来博客园了，这段时间一直在学习编程，看各种书。虽然很辛苦，但是现在终于找到工作了，工资不是很高，但是无所谓，我会继续加油的。

进去公司几天，经理就叫我们用Maven，结合Jetty来生成一个最小的java web项目，并在Jetty下测试。遗憾的是这两样东西都不是自己熟悉的，一切从头开始学习。

今天这篇博文不是讲理论，而是如何搭建这个Java web项目（假设Maven已经配置好，Jetty也设置好了）：

1、首先在一个自己建的目录下，用命令行输入：

![](http://images.cnitblog.com/blog/406864/201212/17223730-146072372ef1409a9fc08fd270100c0a.png)

这样相当于用交互的方式来自定义创建项目

2、接着输入19，表示生成基本的Java web项目目录结构

![](http://images.cnitblog.com/blog/406864/201212/17224006-82ccbb5b096e49bba1233491b93583db.png)

3、如下图输入基本的项目坐标信息，用来唯一标识我们的项目，最后回车

![](http://images.cnitblog.com/blog/406864/201212/17224128-0bcfe03df4bf43ca88565b51376d9064.png)

4、接着我们这个项目是基于SpringMVC框架的，这个时候怎么配置呢，在如下目录先建立如下文件

![](http://images.cnitblog.com/blog/406864/201212/17224540-150b80e1b5114202b35e5abee967742a.png)

web.xml

```
 1<?xml version="1.0" encoding="UTF-8"?> 
 2 <web-app>
 3   <display-name>Archetype Created Web Application</display-name>
 4   
 5   <context-param>
 6         <param-name>contextConfigLocation</param-name>
 7         <param-value>/WEB-INF/applicationContext.xml</param-value>
 8     </context-param>
 9   
10   <servlet>
11         <servlet-name>blog</servlet-name>
12         <servlet-class>org.springframework.web.servlet.DispatcherServlet</servlet-class>
13         <init-param>
14             <param-name>contextConfigLocation</param-name>
15             <param-value>/WEB-INF/blog-servlet.xml</param-value>
16         </init-param>
17         <load-on-startup>1</load-on-startup>
18   </servlet>
19     <servlet-mapping>
20     <servlet-name>blog</servlet-name>
21     <url-pattern>*.do</url-pattern>
22     </servlet-mapping>
23 </web-app>
```
blog-servlet.xml

```
 1 <?xml version="1.0" encoding="UTF-8"?>
 2 <beans 
 3     xmlns="http://www.springframework.org/schema/beans" 
 4     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
 5     xmlns:context="http://www.springframework.org/schema/context"
 6     xsi:schemaLocation="http://www.springframework.org/schema/beans 
 7     http://www.springframework.org/schema/beans/spring-beans-2.5.xsd
 8     http://www.springframework.org/schema/context 
 9     http://www.springframework.org/schema/context/spring-context-2.5.xsd">
10      
11     <!-- ：对web包中的所有类进行扫描，以完成Bean创建和自动依赖注入的功能 -->
12     <context:component-scan base-package="org.yuanmin"/>
13 
14 
15     <!--  ：对模型视图名称的解析，即在模型视图名称添加前后缀 -->
16     <bean class="org.springframework.web.servlet.view.InternalResourceViewResolver" >
17         <property name="prefix" value="/jsp/" />
18         <property name="suffix" value=".jsp" />
19     </bean>
20 </beans>
```

applicationContext

```
 1 <beans xmlns="http://www.springframework.org/schema/beans"
 2     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
 3     xmlns:context="http://www.springframework.org/schema/context"
 4     xmlns:mvc="http://www.springframework.org/schema/mvc"
 5     xsi:schemaLocation="http://www.springframework.org/schema/beans
 6     http://www.springframework.org/schema/beans/spring-beans-3.0.xsd
 7     http://www.springframework.org/schema/context
 8     http://www.springframework.org/schema/context/spring-context-3.0.xsd
 9     http://www.springframework.org/schema/mvc
10     http://www.springframework.org/schema/mvc/spring-mvc-3.0.xsd" >
11 
12     <mvc:annotation-driven />
13 
14 </beans>
```

5、在maven的项目配置文件pom.xml中声明必要的SpringMVC框架一些需要的jar包

pom.xml

```
1 <project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
 2   xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
 3   <modelVersion>4.0.0</modelVersion>
 4   <groupId>test</groupId>
 5   <artifactId>test1</artifactId>
 6   <packaging>war</packaging>
 7   <version>1.0-SNAPSHOT</version>
 8   <name>test1 Maven Webapp</name>
 9   <url>http://maven.apache.org</url>
10   <dependencies>
11     <dependency>
12       <groupId>junit</groupId>
13       <artifactId>junit</artifactId>
14       <version>3.8.1</version>
15       <scope>test</scope>
16     </dependency>
17     <dependency>
18         <groupId>org.springframework</groupId>
19         <artifactId>spring-web</artifactId>
20         <version>3.2.0.RELEASE</version>
21         <scope>compile</scope>
22     </dependency>
23     <dependency>
24         <groupId>org.springframework</groupId>
25         <artifactId>spring-webmvc</artifactId>
26         <version>3.2.0.RELEASE</version>
27         <scope>compile</scope>
28     </dependency>
29     <dependency>
30     <groupId>org.mortbay.jetty</groupId>
31     <artifactId>jetty</artifactId>
32     <version>6.1.25</version>
33     <scope>test</scope>
34     <exclusions>
35     <exclusion>
36     <groupId>org.mortbay.jetty</groupId>
37     <artifactId>servlet-api</artifactId>
38     </exclusion>
39     </exclusions>
40     </dependency>
41     <dependency>
42     <groupId>org.mortbay.jetty</groupId>
43     <artifactId>jsp-2.1</artifactId>
44     <version>6.1.14</version>
45     <scope>test</scope>
46     </dependency>
47   </dependencies>
48   <build>
49     <finalName>jettyTes3</finalName>
50     <plugins>
51         <plugin>
52               <groupId>org.mortbay.jetty</groupId>
53               <artifactId>maven-jetty-plugin</artifactId>
54               <version>6.1.26</version>
55               <configuration>
56               <scanIntervalSeconds>10</scanIntervalSeconds>
57               <webAppConfig>
58                   <contextPath>/test</contextPath>  <!-- http://host:port/test/ -->
59               </webAppConfig>
60             <source>1.7</source>
61             <target>1.7</target>
62               </configuration>    
63           </plugin>
64     </plugins>
65   </build>
66 </project>
```

6、在项目如下目录中创建相应文件：src/main/java是必须的，maven管理下的项目都需要这个基本的目录结构（具体可以上网查查）

JettyServer.java

```
 1 package org.yuanmin;
 2 
 3 import java.io.BufferedReader;
 4 import java.io.InputStreamReader;
 5 import java.io.PrintWriter;
 6 import java.net.BindException;
 7 import java.net.InetAddress;
 8 import java.net.ServerSocket;
 9 import java.net.Socket;
10 
11 import org.mortbay.jetty.Connector;
12 import org.mortbay.jetty.Handler;
13 import org.mortbay.jetty.Server;
14 import org.mortbay.jetty.nio.SelectChannelConnector;
15 import org.mortbay.jetty.webapp.WebAppContext;
16 
17 /**
18  * 启动Jetty的辅助程序，默认端口是8080。
19  * 
20  */
21 public class JettyServer {
22     private static String parameter = "org.mortbay.jetty.servlet.Default.useFileMappedBuffer";
23     private Server server = new Server();
24 
25     public static void main(String[] args) throws Exception {
26         JettyServer jettyServer = new JettyServer();
27         try {
28             jettyServer.open();
29         } catch (BindException e) {
30             jettyServer.close();
31             Thread.sleep(1000);
32             jettyServer.open();
33         }
34     }
35 
36     public void open() throws Exception {
37         ServerSocket server = new ServerSocket(5678);
38         start();
39         Socket client = server.accept();
40         BufferedReader in = new BufferedReader(new InputStreamReader(
41                 client.getInputStream()));
42         PrintWriter out = new PrintWriter(client.getOutputStream());
43 
44         while (true) {
45             String str = in.readLine();
46             if (str.equals("stop")) {
47                 stop();
48                 out.println("stoped");
49                 out.flush();
50                 break;
51             }
52         }
53         client.close();
54         server.close();
55     }
56 
57     public void close() throws Exception {
58         Socket server = new Socket(InetAddress.getLocalHost(), 5678);
59         BufferedReader in = new BufferedReader(new InputStreamReader(
60                 server.getInputStream()));
61         PrintWriter out = new PrintWriter(server.getOutputStream());
62 
63         while (true) {
64             out.println("stop");
65             out.flush();
66             String str = in.readLine();
67             if (str.equals("stoped")) {
68                 break;
69             }
70 
71         }
72         server.close();
73     }
74 
75     @SuppressWarnings("unchecked")
76     public void start() throws Exception {
77         int port = 8080;
78         Connector connector = new SelectChannelConnector();
79         connector.setPort(port);
80 
81         WebAppContext webAppContext = new WebAppContext();
82         webAppContext.setDescriptor("src/test/resources/web.xml");
83         webAppContext.setContextPath("/");
84         webAppContext.setWar("src/main/webapp");
85         webAppContext.getInitParams().put(parameter, "false");
86         server.addConnector(connector);
87         server.setHandlers(new Handler[] { webAppContext });
88         server.setStopAtShutdown(true);
89 
90         server.start();
91     }
92 
93     public void stop() throws Exception {
94         server.stop();
95     }
96 }
```

BbtForumController.java

```
 1 package org.yuanmin;
 2 
 3 import org.springframework.stereotype.Controller;
 4 import org.springframework.web.bind.annotation.RequestMapping;
 5 
 6 @Controller
 7 public class BbtForumController {
 8 
 9     @RequestMapping("/listAllBoard.do")
10     public String listAllBoard() {
11         System.out.println("call listAllBoard method.dfsfdsdf");
12         return "index";
13     }
14 
15     @RequestMapping("/listBoardTopic.do")
16     public String listBoardTopic(int topicId) {
17         System.out.println("call listBoardTopic method.");
18         return "index2";
19     }
20 }
```

7、接下来，我们在项目目录下，用命令行输入：  mvn  eclipse:eclipse

     这时就会把我们maven项目转换为eclipse格式的项目，同时还下载相关依赖包到我们maven设置的本地仓库。

     我们应该在eclipse中设置我们这个本地仓库作为编译库，这样我们就不用倒入jar包到我们的项目中了。


![](http://images.cnitblog.com/blog/406864/201212/17234955-c71d0d62f6474ec99ee79958dbbccc0c.png)
 

         其中  E:/apache-maven-3.0.4/repository这个目录就是我设置的maven本地仓库，我们可以在maven下的


![](http://images.cnitblog.com/blog/406864/201212/17235157-79e572a770384d3d8646dbe7a876fd3a.png)
 

       中的settings.xml配置文件中设置如下：
![](http://images.cnitblog.com/blog/406864/201212/17235334-4844f588d7264e1583a0c575184225b5.png)


8、接着导入这个项目到eclipse中，这个项目我提供了两种运行方法：

     一种是在eclipse中直接运行JettyServer.java文件

     第二种是用maven的jetty插件，在命令行中定位到这个项目然后执行mvn jetty:run
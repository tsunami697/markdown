---
layout:     post   				    # 使用的布局（不需要改）
title:      Kernel: xxx_initcall	# 标题 
subtitle:   内核学习 				# 副标题
date:       2022-07-27			  	# 时间
author:     Qi						# 作者
header-img: img/post-bg-2015.jpg 	# 这篇文章标题背景图片
catalog: 	true 					# 是否归档
tags:								# 标签
    - kernel
---

# input子系统

> ​	subsys_initcall机制
> ​	从init/mian初始化subsys
> ​	内核initcall


## subsys_initcall机制

###  代码

* kernel/include/linux/init.h

```c
	...
typedef int (*initcall_t)(void);
	...
/* 1. static initcall_t: 
		声明一个函数指针变量:变量叫做__initcall_##fn##id;
   2. “##”、“#”：
   		宏定义中专门使用的，“##”意思是连接前后两个内容，拼接作用，“#”意思是把后面内容当做字符串。
        此处：#define __define_initcall(func, 4, sec) \
				 static initcall_t __initcall_##fn##id
		展开后为: static initcall_t __initcall_func4;
   3. __used、__attribute__:
   		gun c使用__used、__attribute__设置变量的属性，定义在kernel/include/linux/compiler_types.h(内核头文件)。
		used: 其作用是告诉编译器避免被链接器因为未用过而被优化掉。
		attribute((section(“name”)))：将作用的函数或数据放入指定名为"section_name"对应的段中。
 */
        
#define ___define_initcall(fn, id, __sec) \
     static initcall_t __initcall_##fn##id __used \	//
         __attribute__((__section__(#__sec ".init"))) = fn;    //有个空格，从lds文件看 会被忽略
	...
#define __define_initcall(fn, id) ___define_initcall(fn, id, .initcall##id) 
	...
#define subsys_initcall(fn)     __define_initcall(fn, 4)
//
    ...
```

* kernel/drimver/input/input.c

```c
subsys_initcall(input_init);
/*
展开：声明一个函数指针变量并初始化为input_init，链接的时候把它放到.initcall4.init的段,然后等待被调用
static initcall_t __initcall_input_init4 __uesd __attribute__((__section__(.initcall4.init))) = input_init;
*/
static initcall_t __initcall_input_init4 
    __uesd __attribute__((__section__(.initcall4.init))) = input_init;
```

### 

### 调用

* kernel/include/asm-generic/vmlinux.lds.h

* kernel/arch/arm64/kernel/vmlinux.lds

## gcc链接脚本

### gcc编译过程

```
编译：gcc -c -o main.o main.c
链接：gcc -Ttext 0 main.
```



### gcc默认的链接脚本

* 查看gcc编译使用的默认链接脚本

```c
gcc test.c -Wl,--verbose
```



### 修改gcc默认的链接脚本




## 内核链接脚本、映射文件

* kernel/System.map

系统映射文件: 内核中重要的变量（函数，全局变量等）在内核中的运行地址！

* kernel/arch/arm64/kernel/vmlinux.lds

    vmlinux.lds，是Linux内核的链接脚本文件。用来分析Linux启动流程，通过链接脚本可以找到Linux内核第一行程序是从哪里执行。

### kernel启动流程的两个阶段

* 汇编阶段（另一篇分析）

* C语言阶段

![image-20220728142339995](/home/ljq/.config/Typora/typora-user-images/image-20220728142339995.png)

kernel对input_init调用流程：

* 


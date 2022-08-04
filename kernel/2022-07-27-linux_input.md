# input子系统

> 绕不过去的 xxx_initcall 机制
>
> 链接脚本
>
> 从 init/main 初始化subsys
>
> input 子系统分析


## subsys_initcall(input_init)

### subsys_initcall介绍

* subsys_initcall是一个宏定义
* 功能：将定义的函数指针变量放在一个特定的段
* 在 kernel/include/linux/init.h 查看各个 initcall定义

###  xxx_initcall 代码解析

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
   		gun c使用__used、__attribute__设置变量的属性(gnu扩展语法)，
   		定义在kernel/include/linux/compiler_types.h(内核头文件)。
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



### 调度

kernel通过链接脚本组织initcall代码段，见 “内核链接脚本”

kernel初始化过程中，调用链接脚本的变量进行initcall的初始化，见kernel.drawio



## gcc链接脚本

### gcc编译过程

下面总结了单步编译使用的gcc命令：

```
# 1. 预处理
gcc -E hello.c -o hello.i
# 2. 编译阶段
gcc -S hello.i -o hello.s
# 3. 汇编
gcc -c hello.s -o hello.o
# 4. 链接
# 静态链接
gcc -static hello.c -o hello
# 动态链接
gcc hello.c -o hello
# 查看链接
ldd obj
# 查看elf文件段分布
size obj
# 查看elf文件
readelf -S hello
# 反汇编elf
objdump -S hello
```

​	参考链接：https://blog.csdn.net/weixin_47554309/article/details/120617975#t2

### gcc默认的链接脚本
**查看默认链接脚本**

* 前提：gcc编译过程中，使用链接脚本对.o文件进行链接。
* 可以自行指定链接脚本，内核使用vmlinux.lds指定；如果不指定，使用默认链接脚本。

* 查看gcc编译时使用的默认链接脚本
```c
gcc test.c -Wl,--verbose
```

​	参考链接：https://blog.csdn.net/Longyu_wlz/article/details/109007338#t3

​						https://blog.csdn.net/Longyu_wlz/article/details/109007373

**修改gcc默认链接脚本**

在链接阶段时，使用ld -T来指定lds文件将.o文件链接到一起

​	参考链接：https://zhidao.baidu.com/question/1738541555743407907.html

一个实例：

​	http://t.zoukankan.com/defen-p-5400492.html



## 内核映射文件

* kernel/System.map

系统映射文件，内核中重要的变量（函数，全局变量等）在内核中的运行地址。




## 内核链接脚本


* vmlinux.lds

    Linux内核最终使用的链接脚本。用来分析Linux启动流程，通过链接脚本可以找到Linux内核第一行程序是从哪里执行。

* vmlinux.lds.h、vmlinux.lds.S和vmlinux.s

    *   vmlinux.lds.S
    
        是一个汇编文件，包含vmlinux.lds.h这个头文件，该汇编文件编译后生成vmlinux.s文件。
    
*   kernel的链接脚本并不是直接提供的，⽽是提供了⼀个汇编⽂件vmlinux.lds.S，然后在编译的时候再去编译这个汇编⽂件得到真正的链接脚本vmlinux.lds。为什么linux kernel不直接提供vmlinux.lds⽽要提供⼀个vmlinux.lds.S然后在编译时才去动态⽣成vmlinux.lds呢？
    由于.lds⽂件中只能写死，不能⽤条件编译。但是在kernel中链接脚本确实有条件编译的需求（但是lds格式⼜不⽀持），于是乎kernel⼯作者找了个投机取巧的⽅法，就是把vmlinux.lds写成汇编格式，然后汇编器处理的时候顺便条件编译给处理了，得到⼀个不需要条件编译的vmlinux.lds。
    
    

### kernel启动流程的两个阶段

* 汇编阶段（另一篇分析）

* C语言阶段

    ​		内核在启动过程中需要顺序的做很多事，内核如何实现按照先后顺序去做很多初始化操作。内核的解决方案就是给内核启动时要调用的所有函数归类，执行内核某一个函数然后每个类就会按照一定的次序被调用执行。这些分类名就叫.initcallx.init。x的值从1到8。内核开发者在编写内核代码时只要将函数设置合适的级别，这些函数就会被链接的时候放入特定的段，内核启动时再按照段顺序去依次执行各个段即可（通过某一个函数，链接脚本只是规定了某一程序段在内存中的存放位置）。
    
    

## input子系统

### 核心层

* driver/input/input.c

```C
// input.c 做了三件事
1. 创建两个全局链表
    static LIST_HEAD(input_dev_list);					// 定义全局链表 : input device
    static LIST_HEAD(input_handler_list);				// 定义全局链表 : input handler
2. input_init()
    a. 创建节点/sys/class/input
    b. 创建/proc/bus/input/devices、/proc/bus/input/handlers
    c. 申请主设备号，主设备号INPUT_MAJOR == 13
3. 提供handler、device层用到的api
```

* 内核对subsys_initcall(input_init) 初始化流程见 kernel.drawio

### handler层

### 设备驱动层


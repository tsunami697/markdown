# input子系统

> subsys_initcall机制
>
> 从init/mian初始化subsys
>
> 内核initcall


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



### 调用

#### kernel链接脚本

* kernel/include/asm-generic/vmlinux.lds.h

* kernel/arch/arm64/kernel/vmlinux.lds

#### kernel初始化---initcall加载

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

* gcc编译过程中，使用链接脚本对.o文件进行链接。
* 可以我们自行指定链接脚本，内核使用vmlinux.lds指定；如果不指定，使用默认链接脚本。

* 查看gcc编译时使用的默认链接脚本
```c
gcc test.c -Wl,--verbose
```

​	参考链接：https://blog.csdn.net/Longyu_wlz/article/details/109007338#t3

​						https://blog.csdn.net/Longyu_wlz/article/details/109007373

**修改g默认链接脚本**

链接时，使用ld -T来指定lds文件将.o文件链接到一起

​	参考链接：https://zhidao.baidu.com/question/1738541555743407907.html

一个实例：

​	http://t.zoukankan.com/defen-p-5400492.html


## 内核链接脚本、映射文件

* kernel/System.map

系统映射文件: 内核中重要的变量（函数，全局变量等）在内核中的运行地址！

* kernel/arch/arm64/kernel/vmlinux.lds

    vmlinux.lds，是Linux内核的链接脚本文件。用来分析Linux启动流程，通过链接脚本可以找到Linux内核第一行程序是从哪里执行。

### kernel启动流程的两个阶段

* 汇编阶段（另一篇分析）

* C语言阶段



## kernel对input_init调用流程


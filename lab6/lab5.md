![img](file:///C:\Users\张文沁\AppData\Local\Temp\ksohtml3484\wps1.jpg)

 

 

 

# 本科生实验报告

## 实验课程:____________操作系统______________________________

## 实验名称:____________内核线程______________________________

## 专业名称:____________信息与计算科学______________________________

## 学生姓名:____________张文沁______________________________

## 学生学号:____________20337268______________________________

## 实验地点:__________________________________________

## 实验成绩:__________________________________________

## 报告时间:____________2022.4.23______________________________





### 代码全部贴在了文档中



## **1.** ***\*实验要求\****



###  实验概述

在本次实验中，我们将会学习到C语言的可变参数机制的实现方法。在此基础上，我们会揭开可变参数背后的原理，进而实现可变参数机制。实现了可变参数机制后，我们将实现一个较为简单的printf函数。此后，我们可以同时使用printf和gdb来帮助我们debug。

本次实验另外一个重点是内核线程的实现，我们首先会定义线程控制块的数据结构——PCB。然后，我们会创建PCB，在PCB中放入线程执行所需的参数。最后，我们会实现基于时钟中断的时间片轮转(RR)调度算法。在这一部分中，我们需要重点理解`asm_switch_thread`是如何实现线程切换的，体会操作系统实现并发执行的原理。

### 实验要求

> + DDL：2021.4.29 23:59
> + 提交的内容：将**4个assignment的代码**和**实验报告**放到**压缩包**中，命名为“**lab5-姓名-学号**”，并交到课程网站上[http://course.dds-sysu.tech/course/3/homework]
> + **材料的Example的代码放置在`src`目录下**。

1. 实验不限语言， C/C++/Rust都可以。
2. 实验不限平台， Windows、Linux和MacOS等都可以。
3. 实验不限CPU， ARM/Intel/Risc-V都可以。

## **2.** ***\*实验过程\****

### Assignment 1 printf的实现

> 学习可变参数机制，然后实现printf，你可以在材料中的printf上进行改进，或者从头开始实现自己的printf函数。结果截图并说说你是怎么做的。
>

```c++
print("%a %d %c",a,b,c);
```

##### 对于固定参数列表的函数，每个参数的名称、类型都是直接可见的，他们的地址也都是可以直接得到的，比如：通过函数原型声明了解到a是int类型的;b是double类型的; c是char*类型的,地址也可以通过&a直接得到。

##### 但是对于变长参数的函数，我们就没有这么顺利了。还好，按照C标准的说明，支持变长参数的函数在原型声明中，必须有至少一个最左固定参数(这一点与传统C有区别，传统C允许不带任何固定参数的纯变长参数函数)，这样我们可以得到其中固定参数的地址，但是依然无法从声明中得到其他变长参数的地址，比如：

```c
void func(const char * fmt, ... ) {
  ... ...
}
```

##### 这里我们只能得到fmt这固定参数的地址，仅从函数原型我们是无法确定"..."中有几个参数、参数都是什么类型的，自然也就无法确定其位置了。我们可以通过如下程序分析得到输出函数的传参方式，显而易见，是栈操作。

```c
#include<iostream>
using namespace std;
void Address(int a, double b, char *c) {
        printf("a = 0x%p\n", &a);
        printf("b = 0x%p\n", &b);
        printf("c = 0x%p\n", &c);
}
int main() {
    Address(1, 2.3, "hello world");
    return 0;
}
```

![image-20220423093406360](C:\Users\张文沁\AppData\Roaming\Typora\typora-user-images\image-20220423093406360.png)

##### 所以可以推导出变长参数传递和固定参数的传参过程是一样的，简单来讲都是栈操作，而栈这个东西对我们是开放的。这样一来，一旦我们知道某函数帧的栈上的一个固定参数的位置，我们完全有可能推导出其他变长参数的位置。

##### 通过这个思路，可以通过可变参数模板实现可变参数输出函数：

```c++
#include <iostream>

void FormatPrint()
{
    std::cout << std::endl;
}

template <class T, class ...Args>
void FormatPrint(T first, Args... args)
{
   std::cout << "[" << first << "]";
   FormatPrint(args...);
}

int main(void)
{
   FormatPrint(1, 2, 3, 4);
   FormatPrint("hello", 1, "world", 2, 3, 'A');
   return 0;
}
```

##### 结果如下：

### ![image-20220423092617434](C:\Users\张文沁\AppData\Roaming\Typora\typora-user-images\image-20220423092617434.png)

##### 或者有以下的有第一个参数的边长输出：

```c++
void var_args_func(const char * fmt, ... ) {
    char *ap;

    ap = ((char*)&fmt) + sizeof(fmt);
    printf("%d\n", *(int*)ap);  
        
    ap =  ap + sizeof(int);
    printf("%d\n", *(int*)ap);

    ap =  ap + sizeof(int);
    printf("%s\n", *((char**)ap));
}

int main(){
    var_args_func("%d %d %s\n", 4, 5, "hello world");
}
```

##### 至此，我们实现了变长参数在C++下的输出。有了第二个例子的输出方式，我们只需得到fmt中的%后面的字符便可以确定要输出的参数类型，下面进行printf的实现：

##### 首先为了实现进行参数`fmt`的解析，定义下面的函数作为缓冲区，如果fmt[i]不是%，则是普通字符，放入缓存区。

```c++
int printf_add_to_buffer(char *buffer, char c, int &idx, const int BUF_LEN)
{
    int counter = 0;

    buffer[idx] = c;
    ++idx;

    if (idx == BUF_LEN)
    {
        buffer[idx] = '\0';
        counter = stdio.print(buffer);
        idx = 0;
    }

    return counter;
}
```



##### 定义适用qemu的I/O函数，用于输出到屏幕、光标位置选取、换行、滚屏等操作。



```c++
STDIO::STDIO()
{
    initialize();
}

void STDIO::initialize()
{
    screen = (uint8 *)0xb8000; //初始化
}

void STDIO::print(uint x, uint y, uint8 c, uint8 color)//基本输出，给定位置
{

    if (x >= 25 || y >= 80) // 超出屏幕
    {
        return;
    }
  
    uint pos = x * 80 + y;//计算输出的位置
    screen[2 * pos] = c; 
    screen[2 * pos + 1] = color;
}

void STDIO::print(uint8 c, uint8 color)//无初始位置的输出
{
    uint cursor = getCursor();
    screen[2 * cursor] = c;
    screen[2 * cursor + 1] = color;
    cursor++;
    if (cursor == 25 * 80) //本页满，则滚动到下一行
    {
        rollUp();
        cursor = 24 * 80;
    }
    moveCursor(cursor);//屏幕的滚动实际上是指针的位置的变化
}

void STDIO::print(uint8 c)
{
    print(c, 0x07);
}

void STDIO::moveCursor(uint position)// 移动指针
{
    if (position >= 80 * 25)
    {
        return;
    }

    uint8 temp;

    // 处理高8位
    temp = (position >> 8) & 0xff;
    asm_out_port(0x3d4, 0x0e);
    asm_out_port(0x3d5, temp);

    // 处理低8位
    temp = position & 0xff;
    asm_out_port(0x3d4, 0x0f);
    asm_out_port(0x3d5, temp);
}

uint STDIO::getCursor() //得到指针位置
{
    uint pos;
    uint8 temp;

    pos = 0;
    temp = 0;
    // 处理高8位
    asm_out_port(0x3d4, 0x0e);
    asm_in_port(0x3d5, &temp);
    pos = ((uint)temp) << 8;

    // 处理低8位
    asm_out_port(0x3d4, 0x0f);
    asm_in_port(0x3d5, &temp);
    pos = pos | ((uint)temp);

    return pos;
}

void STDIO::moveCursor(uint x, uint y) //给定x,y的移动
{
    if (x >= 25 || y >= 80)
    {
        return;
    }

    moveCursor(x * 80 + y);
}

void STDIO::rollUp() //滚屏
{
    uint length;
    length = 25 * 80;
    for (uint i = 80; i < length; ++i)
    {
        screen[2 * (i - 80)] = screen[2 * i];
        screen[2 * (i - 80) + 1] = screen[2 * i + 1];
    }

    for (uint i = 24 * 80; i < length; ++i)
    {
        screen[2 * i] = ' ';
        screen[2 * i + 1] = 0x07;
    }
}

int STDIO::print(const char *const str) 
{
    int i = 0;
    for (i = 0; str[i]; ++i)
    {
        switch (str[i])
        {
        case '\n':
            uint row;
            row = getCursor() / 80;
            if (row == 24)   //row==25执行rollUp()似乎也没有什么影响
            {
                rollUp();
            }
            else
            {
                ++row;
            }
            moveCursor(row * 80);
            break;

        default:
            print(str[i]);
            break;
        }
    }

    return i;
}
```



##### printf的实现如下：



```c++
int printf(const char *const fmt, ...)
{
    const int BUF_LEN = 32;
    char buffer[BUF_LEN + 1];//定义缓冲区
    char number[33];
    int idx, counter;
    va_list ap;
    va_start(ap, fmt);
    idx = 0;
    counter = 0;

    for (int i = 0; fmt[i]; ++i)
    {
        if (fmt[i] != '%')
        {
            counter += printf_add_to_buffer(buffer, fmt[i], idx, BUF_LEN);
        }
        else
        {
            i++;
            if (fmt[i] == '\0')
            {
                break;
            }

            switch (fmt[i])//根据%后字符的不同进行相应的输出
            {
            case '%':
                counter += printf_add_to_buffer(buffer, fmt[i], idx, BUF_LEN);
                break;

            case 'c':
                counter += printf_add_to_buffer(buffer, va_arg(ap, char), idx, BUF_LEN);
                break;

            case 's':
                buffer[idx] = '\0';
                idx = 0;
                counter += stdio.print(buffer);
                counter += stdio.print(va_arg(ap, const char *));
                break;

            case 'd':
            case 'x': //本处需要进行进制转换
                int temp = va_arg(ap, int);

                if (temp < 0 && fmt[i] == 'd')
                {
                    counter += printf_add_to_buffer(buffer, '-', idx, BUF_LEN);
                    temp = -temp;
                }

                itos(number, temp, (fmt[i] == 'd' ? 10 : 16));

                for (int j = 0; number[j]; ++j)
                {
                    counter += printf_add_to_buffer(buffer, number[j], idx, BUF_LEN);
                }
                break;
            }
        }
    }

    buffer[idx] = '\0';
    counter += stdio.print(buffer);

    return counter;
}
```



##### 测试函数：



```c++
#include "asm_utils.h"
#include "interrupt.h"
#include "stdio.h"

// 屏幕IO处理器
STDIO stdio;
// 中断管理器
InterruptManager interruptManager;

extern "C" void setup_kernel()
{
    // 中断处理部件
    interruptManager.initialize();
    // 屏幕IO处理部件
    stdio.initialize();
    interruptManager.enableTimeInterrupt();
    interruptManager.setTimeInterrupt((void *)asm_time_interrupt_handler);
    //asm_enable_interrupt();
    printf("print percentage: %%\n"
           "print char \"N\": %c\n"
           "print string \"Hello World!\": %s\n"
           "print decimal: \"-1234\": %d\n"
           "print hexadecimal \"0x7abcdef0\": %x\n",
           'N', "Hello World!", -1234, 0x7abcdef0);
    //uint a = 1 / 0;
    asm_halt();
}
```



##### 最终结果如下：

![image-20220423104436580](C:\Users\张文沁\AppData\Roaming\Typora\typora-user-images\image-20220423104436580.png)

### Assignment 2 线程的实现

> 自行设计PCB，可以添加更多的属性，如优先级等，然后根据你的PCB来实现线程，演示执行结果。
>

##### 设计线程，线程最重要的部分也是线程切换的基本单位,PCB，相当于一个结构体，则第一步设计PCB：

```c++
struct PCB
{
    int *stack;                      // 栈指针，用于调度（挂起和就绪）时保存esp
    char name[MAX_PROGRAM_NAME + 1]; // 线程名
    enum ProgramStatus status;       // 线程的状态
    int priority;                    // 线程优先级
    int pid;                         // 线程pid
    int ticks;                       // 线程时间片总时间
    int ticksPassedBy;               // 线程已执行时间
    ListItem tagInGeneralList;       // 线程队列标识
    ListItem tagInAllList;           // 线程队列标识
};
```

##### 在设计完PCB内容之后，内部还需要特别设置的是状态模型，此处使用五状态模型：

```c++
enum ProgramStatus
{
    CREATED,	//创建
    RUNNING,	//运行
    READY,		//就绪
    BLOCKED,	//阻塞
    DEAD		//结束
};
```

##### ListItem是线程的队列标识符，如下定义，双向list。分为两个队列，所有进程的队列和处于就绪态的队列

```c++
struct ListItem
{
    ListItem *previous;
    ListItem *next;
};
```

##### 至此，线程的定义结束，下面实现线程的相关函数：

##### 首先为实现线程创建一个类框架：

```cpp
#ifndef PROGRAM_H
#define PROGRAM_H

class ProgramManager
{
public:
    List allPrograms;   // 所有状态的线程/进程的队列
    List readyPrograms; // 处于ready(就绪态)的线程/进程的队列
    PCB *running;       // 当前执行的线程

    ProgramManager();
    void initialize();

    // 创建一个线程并放入就绪队列
    // function：线程执行的函数
    // parameter：指向函数的参数的指
    // 成功，返回pid；失败，返回-1
    int executeThread(ThreadFunction function, void *parameter, const char *name, int priority);

    // 分配一个PCB
    PCB *allocatePCB();
    // 归还一个PCB
    void releasePCB(PCB *program);
};
#endif
```

#### PCB创建

##### 在线程创建的时候，需要申请一个PCB，一般大小为页大小（4k），PCB基本参数如下定义：

```cpp
// PCB的大小，4KB。
const int PCB_SIZE = 4096;         
// 存放PCB的数组，预留了MAX_PROGRAM_AMOUNT个PCB的大小空间。
char PCB_SET[PCB_SIZE * MAX_PROGRAM_AMOUNT]; 
// PCB的分配状态，true表示已经分配，false表示未分配。
bool PCB_SET_STATUS[MAX_PROGRAM_AMOUNT];
```

##### 分配和回收PCB：

```cpp
PCB *ProgramManager::allocatePCB()
{
    for (int i = 0; i < MAX_PROGRAM_AMOUNT; ++i)
    {
        if (!PCB_SET_STATUS[i])
        {
            PCB_SET_STATUS[i] = true;
            //返回当前程序的PCB
            return (PCB *)((int)PCB_SET + PCB_SIZE * i);
        }
    }

    return nullptr;
}

void ProgramManager::releasePCB(PCB *program)
{
    int index = ((int)program - (int)PCB_SET) / PCB_SIZE;
    //直接将状态设置为未分配即可
    PCB_SET_STATUS[index] = false;
}
```

##### 创建进程并放入就绪队列：

```cpp
int ProgramManager::executeThread(ThreadFunction function, void *parameter, const char *name, int priority)
{
    // 关中断，防止创建线程的过程被打断
    bool status = interruptManager.getInterruptStatus();
    interruptManager.disableInterrupt();

    // 分配一页作为PCB
    PCB *thread = allocatePCB();

    if (!thread)
        return -1;

    // 初始化分配的页
    memset(thread, 0, PCB_SIZE);

    for (int i = 0; i < MAX_PROGRAM_NAME && name[i]; ++i)
    {
        thread->name[i] = name[i];
    }
	//对线程进行初始化
    thread->status = ProgramStatus::READY;
    thread->priority = priority;
    thread->ticks = priority * 10;
    thread->ticksPassedBy = 0;
    thread->pid = ((int)thread - (int)PCB_SET) / PCB_SIZE;

    // 线程栈
    thread->stack = (int *)((int)thread + PCB_SIZE);
    thread->stack -= 7;
    thread->stack[0] = 0;//ebp
    thread->stack[1] = 0;//ebx
    thread->stack[2] = 0;//edi
    thread->stack[3] = 0;//esi
    thread->stack[4] = (int)function;//线程函数的起始地址
    thread->stack[5] = (int)program_exit;//线程的返回地址
    thread->stack[6] = (int)parameter;//线程的参数地址

    allPrograms.push_back(&(thread->tagInAllList));
    readyPrograms.push_back(&(thread->tagInGeneralList));

    // 恢复中断
    interruptManager.setInterruptStatus(status);

    return thread->pid;
}
```

##### 至此，线程的创建完成，下面要实现线程的调度：

```cpp
extern "C" void c_time_interrupt_handler()
{
    PCB *cur = programManager.running;

    if (cur->ticks)
    {
        --cur->ticks; //如果轮到该线程执行，则需要将当前线程的总时间减一
        ++cur->ticksPassedBy;
    }
    else
    {
        programManager.schedule();
    }
}
```

##### 线程调度函数：

```cpp
void ProgramManager::schedule()
{
    //开始关中断
    bool status = interruptManager.getInterruptStatus();
    interruptManager.disableInterrupt();
	//如果就绪态的队列为空，则无需再调度，直接返回
    if (readyPrograms.size() == 0)
    {
        interruptManager.setInterruptStatus(status);
        return;
    }
	//如果是运行态，则变为就绪态，时间片重新分配
    if (running->status == ProgramStatus::RUNNING)
    {
        running->status = ProgramStatus::READY;
        running->ticks = running->priority * 10;
        readyPrograms.push_back(&(running->tagInGeneralList));
    }
    //如果是结束，则释放该程序的PCB即可
    else if (running->status == ProgramStatus::DEAD)
    {
        releasePCB(running);
    }
	//准备将下一个就绪线程放入运行
    ListItem *item = readyPrograms.front();
    PCB *next = ListItem2PCB(item, tagInGeneralList);
    PCB *cur = running;
    next->status = ProgramStatus::RUNNING;
    running = next;
    readyPrograms.pop_front();

    asm_switch_thread(cur, next);
	//执行完之后开中断
    interruptManager.setInterruptStatus(status);
}
```



##### 结果如下：



![image-20220423213511715](C:\Users\张文沁\AppData\Roaming\Typora\typora-user-images\image-20220423213511715.png)



### Assignment 3 线程调度切换的秘密

> 操作系统的线程能够并发执行的秘密在于我们需要中断线程的执行，保存当前线程的状态，然后调度下一个线程上处理机，最后使被调度上处理机的线程从之前被中断点处恢复执行。现在，同学们可以亲手揭开这个秘密。
>
> 编写若干个线程函数，使用gdb跟踪`c_time_interrupt_handler`、`asm_switch_thread`等函数，观察线程切换前后栈、寄存器、PC等变化，结合gdb、材料中“线程的调度”的内容来跟踪并说明下面两个过程。
>
> + 一个新创建的线程是如何被调度然后开始执行的。
> + 一个正在执行的线程是如何被中断然后被换下处理器的，以及换上处理机后又是如何从被中断点开始执行的。
>
> 通过上面这个练习，同学们应该能够进一步理解操作系统是如何实现线程的并发执行的。
>

### 调度并执行

1. ##### 线程 firstThread 通过 executeThrcad 创建后进入就绪队列,firstThrcad 为第一个线程, 所以为了使它运行起来，我们手动设置它的状态为 RUNNING ，移出就绪队列，并调用函数 asm _ switch _ thread 。使得 firstThread 成功运行（该过程类似线程调度函数schcdule )。

   ##### 首先获取first_thread的相关信息：
   
   通过
   
   p/x firstThread
   
   p/x &firstThread
   
   p/x firstThread->stack
   
   p/x &firstThread->stack
   
   可以获得firstThread的内容和地址
   
   如下图所示：
   
   

2. ##### 下面进入asm_switch_thread函数，进入函数之前寄存器的数值如下

   ![image-20220426010028180](C:\Users\张文沁\AppData\Roaming\Typora\typora-user-images\image-20220426010028180.png)

3. ##### 第一步是保存ebp ebx edi esi ,为了匹配C语言的特性，否则切换之后会报错，本步对应四个push语句

   ![image-20220426010448848](C:\Users\张文沁\AppData\Roaming\Typora\typora-user-images\image-20220426010448848.png)

   ##### 四步对应寄存器如下：

   1. ![image-20220426010028180](C:\Users\张文沁\AppData\Roaming\Typora\typora-user-images\image-20220426010028180.png)
   2. ![image-20220426011118640](C:\Users\张文沁\AppData\Roaming\Typora\typora-user-images\image-20220426011118640.png)
   3. ![image-20220426011155523](C:\Users\张文沁\AppData\Roaming\Typora\typora-user-images\image-20220426011155523.png)
   4. ![image-20220426011223844](C:\Users\张文沁\AppData\Roaming\Typora\typora-user-images\image-20220426011223844.png)

4. ##### 下面保存 esp 的值，用做下次恢复使用。先将 cur -> stack 的地址放到 eax 中，第8行向[eax]中写入 csp 的值，也就是向 cur -> stack 中写入 esp 

​			![image-20220426010612088](C:\Users\张文沁\AppData\Roaming\Typora\typora-user-images\image-20220426010612088.png)

##### 		对应寄存器如下：保存esp

##### 	![image-20220426011339487](C:\Users\张文沁\AppData\Roaming\Typora\typora-user-images\image-20220426011339487.png) 

5. ##### 将 next -> stack 的值写入到 esp 中，从而完成线程栈的切换。

   由前面知道 firstThread -> stack 的值为0x22e64，地址为0x22000。首先将 firstThrcad -> stack 的地址放入 eax ，然后在把［ eax ］的值赋给 esp （即从 firstThread -> stack 的地址中取出 firstThread ->stack 的值0x22e64保存在 esp 中），这样便完成了线程栈的切换

   ![image-20220426011631657](C:\Users\张文沁\AppData\Roaming\Typora\typora-user-images\image-20220426011631657.png)

6. ##### 恢复数据：

   ![image-20220426010716631](C:\Users\张文沁\AppData\Roaming\Typora\typora-user-images\image-20220426010716631.png)

![image-20220426011715542](C:\Users\张文沁\AppData\Roaming\Typora\typora-user-images\image-20220426011715542.png)

#### 线程的切换：

#### 线程的切换依赖于PCB的切换和寄存器的恢复

1. ##### 创建断点查看在firstThread执行完之后的寄存器：

​	![image-20220426094703398](C:\Users\张文沁\AppData\Roaming\Typora\typora-user-images\image-20220426094703398.png)

2. ##### 继续往下执行，会进入运行态变就绪态时间片重新分配的函数：其中寄存器如下

   ![image-20220426095136485](C:\Users\张文沁\AppData\Roaming\Typora\typora-user-images\image-20220426095136485.png)

3. 在加载下一个进程的时候：可以查看next的内容和地址，如下p/x next

   ![image-20220426095354799](C:\Users\张文沁\AppData\Roaming\Typora\typora-user-images\image-20220426095354799.png)

4. ##### 继续向下运行，可以看到程序在（running = next）已经将下一个线程的内容写入eax：

   ![image-20220426095552002](C:\Users\张文沁\AppData\Roaming\Typora\typora-user-images\image-20220426095552002.png)

5. ##### 之后会跳转到asm_switch_thread函数，和（调度并执行）的执行过程一致



### Assignment 4 调度算法的实现

> 在材料中，我们已经学习了如何使用时间片轮转算法来实现线程调度。但线程调度算法不止一种，例如
>
> + 先来先服务。
>
> + 最短作业（进程）优先。
>
> + 响应比最高者优先算法。
>
> + 优先级调度算法。
>
> + 多级反馈队列调度算法。
>
> 此外，我们的调度算法还可以是抢占式的。
>
> 现在，同学们需要将线程调度算法修改为上面提到的算法或者是同学们自己设计的算法。然后，同学们需要自行编写测试样例来呈现你的算法实现的正确性和基本逻辑。最后，将结果截图并说说你是怎么做的。
>
> 参考资料：https://zhuanlan.zhihu.com/p/97071815
>
> Tips：
>
> + 先来先服务最简单。
> + 有些调度算法的实现**可能需要**用到中断。



##### FIFO算法，和时间片轮转算法区别在于时间片的分配与否，在FIFO中只需要判断当前线程状态进行响应，然后将就绪队列中第一个线程加入运行：

```cpp
void ProgramManager::schedule()
{
    //开始关中断
    bool status = interruptManager.getInterruptStatus();
    interruptManager.disableInterrupt();
	//如果就绪态的队列为空，则无需再调度，直接返回
    if (readyPrograms.size() == 0)
    {
        interruptManager.setInterruptStatus(status);
        return;
    }
	//如果是运行态，则变为就绪态
    if (running->status == ProgramStatus::RUNNING)
    {
        running->status = ProgramStatus::READY;
        readyPrograms.push_back(&(running->tagInGeneralList));
    }
    //如果是结束，则释放该程序的PCB即可
    else if (running->status == ProgramStatus::DEAD)
    {
        releasePCB(running);
    }
	//准备将下一个就绪线程放入运行
    //取得第一个就绪线程
    ListItem *item = readyPrograms.front();
    PCB *next = ListItem2PCB(item, tagInGeneralList);
    PCB *cur = running;
    next->status = ProgramStatus::RUNNING;
    running = next;
    readyPrograms.pop_front();

    asm_switch_thread(cur, next);
	//执行完之后开中断
    interruptManager.setInterruptStatus(status);
}
```

##### 结果如下图所示，可以正常运行：

![image-20220426102000218](C:\Users\张文沁\AppData\Roaming\Typora\typora-user-images\image-20220426102000218.png)

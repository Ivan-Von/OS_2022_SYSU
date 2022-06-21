![img](file:///C:\Users\张文沁\AppData\Local\Temp\ksohtml\wps1965.tmp.jpg)

 

 

# 						本科生实验报告



## 实验课程:	操作系统实验

## 实验名称:	第六章内存管理

## 专业名称:	信息与计算科学

## 学生姓名:	张文沁

## 学生学号:	20337268

## 实验地点:	

## 实验成绩:	

## 报告时间:	2022.6.10 

# 第七章 从内核态到用户态

> 不懂 Unix 的人注定最终还要重复发明一个蹩脚的 Unix。

# 实验概述

在本章中，我们首先会简单讨论保护模式下的特权级的相关内容。特权级保护是保护模式的特点之一，通过特权级保护，我们区分了内核态和用户态，从而限制用户态的代码对特权指令的使用或对资源的访问等。但是，用户态的代码有时不得不使用一些特权指令，如输入输出等。因此，我们介绍了系统调用的概念和如何通过中断来实现系统调用。通过系统调用，我们可以实现从用户态到内核态转移，然后在内核态下执行特权指令等，执行完成后返回到用户态。在实现了系统调用后，我们通过三步来创建了进程。这里，我们需要重点理解我们是如何通过分页机制来实现进程之间的虚拟地址空间的隔离。最后，我们介绍了fork/wait/exit的一种简洁的实现思路。

# 实验要求

> - DDL：2021年06月17号 23:59
> - 提交的内容：将**3个assignment的代码**和**实验报告**放到**压缩包**中，命名为“**lab8-姓名-学号**”，并交到课程网站上[http://course.dds-sysu.tech/course/3/homework]
> - **材料的代码放置在`src`目录下**。

1. 实验不限语言， C/C++/Rust都可以。
2. 实验不限平台， Windows、Linux和MacOS等都可以。
3. 实验不限CPU， ARM/Intel/Risc-V都可以。

## Assignment 1 系统调用

编写一个系统调用，然后在进程中调用之，根据结果回答以下问题。

- 展现系统调用执行结果的正确性，结果截图并并说说你的实现思路。
- 请根据gdb来分析执行系统调用后的栈的变化情况。
- 请根据gdb来说明TSS在系统调用执行过程中的作用。

#### 系统调用：

```cpp
void syscall_print(const char*s)
{
    printf(s);
}

void first_process()
{
    asm_system_call(1,int("hello world\n"));
    asm_halt();
}
```

#### system call:

```assembly
asm_system_call:
    push ebp
    mov ebp, esp

    push ebx
    push ecx
    push edx
    push esi
    push edi  ; 系统调用的五个参数
    push ds
    push es
    push fs
    push gs

    mov eax, [ebp + 2 * 4]
    mov ebx, [ebp + 3 * 4]
    mov ecx, [ebp + 4 * 4]
    mov edx, [ebp + 5 * 4]
    mov esi, [ebp + 6 * 4]
    mov edi, [ebp + 7 * 4]

    int 0x80 ;使用指令int 0x80调用0x80中断。0x80中断处理函数会根据保存在eax的系统调用号来调用不同的函数。

    pop gs
    pop fs
    pop es
    pop ds
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop ebp

    ret
```

#### 系统调用的实现：(在syscall.h下面)

```cpp
#ifndef SYSCALL_H
#define SYSCALL_H

#include "os_constant.h"

class SystemService
{
public:
    SystemService();
    void initialize();
    // 设置系统调用，index=系统调用号，function=处理第index个系统调用函数的地址
    bool setSystemCall(int index, int function);
};

// 第0个系统调用
int syscall_0(int first, int second, int third, int forth, int fifth);

#endif
```

#### 初始化：

```cpp
void SystemService::initialize()
{
    memset((char *)system_call_table, 0, sizeof(int) * MAX_SYSTEM_CALL);
    // 代码段的选择子默认是DPL=0的平坦模式代码段选择子，
    // 但中断描述符的DPL=3，否则用户态程序无法使用该中断描述符
    interruptManager.setInterruptDescriptor(0x80, (uint32)asm_system_call_handler, 3);
}
```

#### 加入系统调用函数：

其中function是第index个系统调用的处理函数的地址

```cpp
bool SystemService::setSystemCall(int index, int function)
{
    system_call_table[index] = function;
    return true;
}
```

#### 初始化TSS和用户段描述符：

可以参照lab3，加入存储代码段、数据段、栈段描述符的变量

```cpp
class ProgramManager
{
public:
    List allPrograms;        // 所有状态的线程/进程的队列
    List readyPrograms;      // 处于ready(就绪态)的线程/进程的队列
    PCB *running;            // 当前执行的线程
    int USER_CODE_SELECTOR;  // 用户代码段选择子
    int USER_DATA_SELECTOR;  // 用户数据段选择子
    int USER_STACK_SELECTOR; // 用户栈段选择子
    ...
}
```

初始化：

```cpp
void ProgramManager::initialize()
{
    allPrograms.initialize();
    readyPrograms.initialize();
    running = nullptr;

    for (int i = 0; i < MAX_PROGRAM_AMOUNT; ++i)
    {
        PCB_SET_STATUS[i] = false;
    }

    // 初始化用户代码段、数据段和栈段
    int selector;

    selector = asm_add_global_descriptor(USER_CODE_LOW, USER_CODE_HIGH);
    // USER_CODE_LOW  0x0000ffff    USER_CODE_HIGH 0x00cff800
    USER_CODE_SELECTOR = (selector << 3) | 0x3;

    selector = asm_add_global_descriptor(USER_DATA_LOW, USER_DATA_HIGH);
    USER_DATA_SELECTOR = (selector << 3) | 0x3;
    // USER_DATA_LOW  0x0000ffff    USER_DATA_HIGH 0x00cff200

    selector = asm_add_global_descriptor(USER_STACK_LOW, USER_STACK_HIGH);
    USER_STACK_SELECTOR = (selector << 3) | 0x3;
	// USER_STACK_LOW  0x00000000   USER_STACK_HIGH 0x0040f600
    initializeTSS();
}
```

#### 创建TSS，一个结构体：（已经规定好了内容）

```assembly
#ifndef TSS_H
#define TSS_H

struct TSS
{
public:
    int backlink;
    int esp0;
    int ss0;
    int esp1;
    int ss1;
    int esp2;
    int ss2;
    int cr3;
    int eip;
    int eflags;
    int eax;
    int ecx;
    int edx;
    int ebx;
    int esp;
    int ebp;
    int esi;
    int edi;
    int es;
    int cs;
    int ss;
    int ds;
    int fs;
    int gs;
    int ldt;
    int trace;
    int ioMap;
};
#endif
```

#### 初始化：

```assembly
void ProgramManager::initializeTSS()
{

    int size = sizeof(TSS);
    int address = (int)&tss; // 地址

    memset((char *)address, 0, size); // 赋0初始化
  
    tss.ss0 = STACK_SELECTOR; // 内核态堆栈段选择子

    int low, high, limit;

    limit = size - 1; // 段界限长度
    low = (address << 16) | (limit & 0xff);
    // DPL = 0
    high = (address & 0xff000000) | ((address & 0x00ff0000) >> 16) | ((limit & 0xff00) << 16) | 0x00008900;

    int selector = asm_add_global_descriptor(low, high); //将TSS送入GDT
    // RPL = 0
    asm_ltr(selector << 3);
    tss.ioMap = address + size;
}
```

TSS的作用仅限于提供0特权级下的栈指针和栈段选择子，因此我们关心`TSS::ss0`和`TSS::esp0`。但在这里我们只对`TSS::ss0`进行复制，`TSS::esp0`会在进程切换时更新。

其中，`STACK_SELECTOR`是特权级0下的栈段选择子，也就是我们在bootloader中放入了SS的选择子。

#### 创建进程:

> 过程：
>
> * 创建PCB
> * 初始化页目录表
> * 初始化虚拟地址

#### 和一般创建方式不一样的地方：要启动进程之前栈里面放入的内容：

```assembly
#ifndef PROCESS_H
#define PROCESS_H

struct ProcessStartStack
{
    int edi;
    int esi;
    int ebp;
    int esp_dummy;
    int ebx;
    int edx;
    int ecx;
    int eax;
    
    int gs;
    int fs;
    int es;
    int ds;

    int eip;
    int cs;
    int eflags;
    int esp;
    int ss;
};

#endif
```

#### 使用中断来启动进程：

```assembly
; void asm_start_process(int stack);
asm_start_process:
    ;jmp $
    mov eax, dword[esp+4]
    mov esp, eax
    popad
    pop gs;
    pop fs;
    pop es;
    pop ds;

    iret
```

> 用户进程和内核线程使用的是不同的代码段、数据段和栈段选择子。

#### 运行结果：

![image-20220620205743731](C:\Users\张文沁\AppData\Roaming\Typora\typora-user-images\image-20220620205743731.png)

![image-20220620205802775](C:\Users\张文沁\AppData\Roaming\Typora\typora-user-images\image-20220620205802775.png)

#### 调用结果：

![image-20220620205637213](C:\Users\张文沁\AppData\Roaming\Typora\typora-user-images\image-20220620205637213.png)

![image-20220620205655782](C:\Users\张文沁\AppData\Roaming\Typora\typora-user-images\image-20220620205655782.png)



#### gdb调试：

不明白什么问题，但是这个虚拟机从没有成功加载过符号表，多次重启无法解决连接问题...。。。借了个电脑调试了一下，如果我某天发现我的虚拟机可以使用了我就去更新提交的文件。。。（麻了）
![image-20220620211005512](C:\Users\张文沁\AppData\Roaming\Typora\typora-user-images\image-20220620211005512.png)

#### gdb进行分析：

刚开始的寄存器的值：

![image-20220620220113198](C:\Users\张文沁\AppData\Roaming\Typora\typora-user-images\image-20220620220113198.png)

> 运行时传入的参数从图中可以得到，为1,10,2,3,4。eax没有发生变化，同样按照寻参规则，ebp,esp发生变化。

![image-20220620220144735](C:\Users\张文沁\AppData\Roaming\Typora\typora-user-images\image-20220620220144735.png)

#### 简述TSS作用：

> TSS的作用是在从低特权级向高特权级转变的过程中提供0特权级栈所在段选择子和段内偏移，TSS在进程切换时起着重要的作用，通过它保存CPU中各寄存器的值，实现进程的挂起和恢复。

调用中断之前的结果：`ss=0x3b,esp=0x8048fb8,cs=0x2b` 

![image-20220620220720054](C:\Users\张文沁\AppData\Roaming\Typora\typora-user-images\image-20220620220720054.png)

之后：`ss=0x10,esp=0xc0025808,cs=0x20` 表示从用户态转入了内核态，堆栈切换到了0特权级栈![image-20220620220757155](C:\Users\张文沁\AppData\Roaming\Typora\typora-user-images\image-20220620220757155.png)



![image-20220620205512076](C:\Users\张文沁\AppData\Roaming\Typora\typora-user-images\image-20220620205512076.png)

![image-20220620205539239](C:\Users\张文沁\AppData\Roaming\Typora\typora-user-images\image-20220620205539239.png)



## Assignment 2 Fork的奥秘

实现fork函数，并回答以下问题。

- 请根据代码逻辑和执行结果来分析fork实现的基本思路。
- 从子进程第一次被调度执行时开始，逐步跟踪子进程的执行流程一直到子进程从`fork`返回，根据gdb来分析子进程的跳转地址、数据寄存器和段寄存器的变化。同时，比较上述过程和父进程执行完`ProgramManager::fork`后的返回过程的异同。
- 请根据代码逻辑和gdb来解释fork是如何保证子进程的`fork`返回值是0，而父进程的`fork`返回值是子进程的pid。

#### 实现fork:

```cpp
int ProgramManager::fork()
{
    bool status = interruptManager.getInterruptStatus();
    interruptManager.disableInterrupt();

    // 禁止内核线程调用，因为内核线程并没有设置
    PCB *parent = this->running;
    if (!parent->pageDirectoryAddress)
    {
        interruptManager.setInterruptStatus(status);
        return -1;
    }

    // 创建子进程
    int pid = executeProcess("", 0);
    if (pid == -1)
    {
        interruptManager.setInterruptStatus(status);
        return -1;
    }

    // 初始化子进程
    PCB *child = ListItem2PCB(this->allPrograms.back(), tagInAllList);
    bool flag = copyProcess(parent, child); // 复制父进程的资源到子进程中。

    if (!flag)
    {
        child->status = ProgramStatus::DEAD;
        interruptManager.setInterruptStatus(status);
        return -1;
    }

    interruptManager.setInterruptStatus(status);
    return pid;
}
```

#### 资源复制：

> 将中断瞬间保存的寄存器的内容复制到子进程0特权级栈中。

```cpp
    // 复制进程0级栈
    ProcessStartStack *childpss =
        (ProcessStartStack *)((int)child + PAGE_SIZE - sizeof(ProcessStartStack));
    ProcessStartStack *parentpss =
        (ProcessStartStack *)((int)parent + PAGE_SIZE - sizeof(ProcessStartStack));
    memcpy(parentpss, childpss, sizeof(ProcessStartStack));
    // 设置子进程的返回值为0
    childpps->eax = 0;
```

#### 初始化子进程：

```cpp
    // 准备执行asm_switch_thread的栈的内容
    child->stack = (int *)childpss - 7;
    child->stack[0] = 0;
    child->stack[1] = 0;
    child->stack[2] = 0;
    child->stack[3] = 0;
    child->stack[4] = (int)asm_start_process;
    child->stack[5] = 0;             // asm_start_process 返回地址
    child->stack[6] = (int)childpss; // asm_start_process 参数

    // 设置子进程的PCB
    child->status = ProgramStatus::READY;
    child->parentPid = parent->pid;
    child->priority = parent->priority;
    child->ticks = parent->ticks;
    child->ticksPassedBy = parent->ticksPassedBy;
    strcpy(parent->name, child->name);

    // 复制用户虚拟地址池
    int bitmapLength = parent->userVirtual.resources.length;
    int bitmapBytes = ceil(bitmapLength, 8);
    memcpy(parent->userVirtual.resources.bitmap, child->userVirtual.resources.bitmap, bitmapBytes);
```

加入`stack[5]&stack[6]` 是方便从 `asm_switch_thread` 跳转到 `asm_start_process` 处执行

实现地址隔离，使得父进程无法改变具有相同虚拟地址的子进程数据，使用中转页，进行复制操作。

```cpp
    // 从内核中分配一页作为中转页
    char *buffer = (char *)memoryManager.allocatePages(AddressPoolType::KERNEL, 1);
    if (!buffer)
    {
        child->status = ProgramStatus::DEAD;
        return false;
    }

    // 子进程页目录表物理地址
    int childPageDirPaddr = memoryManager.vaddr2paddr(child->pageDirectoryAddress);
    // 父进程页目录表物理地址
    int parentPageDirPaddr = memoryManager.vaddr2paddr(parent->pageDirectoryAddress);
    // 子进程页目录表指针(虚拟地址)
    int *childPageDir = (int *)child->pageDirectoryAddress;
    // 父进程页目录表指针(虚拟地址)
    int *parentPageDir = (int *)parent->pageDirectoryAddress;

    // 子进程页目录表初始化
    memset((void *)child->pageDirectoryAddress, 0, 768 * 4);

    // 复制页目录表
    for (int i = 0; i < 768; ++i)
    {
        // 无对应页表
        if (!(parentPageDir[i] & 0x1))
        {
            continue;
        }

        // 从用户物理地址池中分配一页，作为子进程的页目录项指向的页表
        int paddr = memoryManager.allocatePhysicalPages(AddressPoolType::USER, 1);
        if (!paddr)
        {
            child->status = ProgramStatus::DEAD;
            return false;
        }
        // 页目录项
        int pde = parentPageDir[i];
        // 构造页表的起始虚拟地址
        int *pageTableVaddr = (int *)(0xffc00000 + (i << 12));

        asm_update_cr3(childPageDirPaddr); // 进入子进程虚拟地址空间

        childPageDir[i] = (pde & 0x00000fff) | paddr; // 设置子进程页目录表的页目录项
        memset(pageTableVaddr, 0, PAGE_SIZE); // 初始化页目录项指向的页表

        asm_update_cr3(parentPageDirPaddr); // 回到父进程虚拟地址空间
    }

    // 复制页表和物理页
    for (int i = 0; i < 768; ++i)
    {
        // 无对应页表
        if (!(parentPageDir[i] & 0x1))
        {
            continue;
        }

        // 计算页表的虚拟地址
        int *pageTableVaddr = (int *)(0xffc00000 + (i << 12));

        // 复制物理页
        for (int j = 0; j < 1024; ++j)
        {
            // 无对应物理页
            if (!(pageTableVaddr[j] & 0x1))
            {
                continue;
            }

            // 从用户物理地址池中分配一页，作为子进程的页表项指向的物理页
            int paddr = memoryManager.allocatePhysicalPages(AddressPoolType::USER, 1);
            if (!paddr)
            {
                child->status = ProgramStatus::DEAD;
                return false;
            }

            // 构造物理页的起始虚拟地址
            void *pageVaddr = (void *)((i << 22) + (j << 12));
            // 页表项
            int pte = pageTableVaddr[j];
            // 复制出父进程物理页的内容到中转页
            memcpy(pageVaddr, buffer, PAGE_SIZE);

            asm_update_cr3(childPageDirPaddr); // 进入子进程虚拟地址空间

            pageTableVaddr[j] = (pte & 0x00000fff) | paddr;
            // 从中转页中复制到子进程的物理页
            memcpy(buffer, pageVaddr, PAGE_SIZE);

            asm_update_cr3(parentPageDirPaddr); // 回到父进程虚拟地址空间
        }
    }
```

#### 运行结果:

![image-20220620221139669](C:\Users\张文沁\AppData\Roaming\Typora\typora-user-images\image-20220620221139669.png)

![image-20220620221154306](C:\Users\张文沁\AppData\Roaming\Typora\typora-user-images\image-20220620221154306.png)

父进程：运行->发生中断->还原中断之前的内容->返回pid=2

子进程：由asm_start_process进入->将父进程指针赋予子进程->中断返回->子进程返回pid=0

#### 如何保证子进程一定是0父进程返回子进程的pid:

子进程的返回值是设置为0，而父进程在

## Assignment 3 哼哈二将 wait & exit

实现wait函数和exit函数，并回答以下问题。

- 请结合代码逻辑和具体的实例来分析exit的执行过程。
- 请分析进程退出后能够隐式地调用exit和此时的exit返回值是0的原因。
- 请结合代码逻辑和具体的实例来分析wait的执行过程。
- 如果一个父进程先于子进程退出，那么子进程在退出之前会被称为孤儿进程。子进程在退出后，从状态被标记为`DEAD`开始到被回收，子进程会被称为僵尸进程。请对代码做出修改，实现回收僵尸进程的有效方法。

#### wait:

> retval存放子进程的返回值，即被回收的子进程的pid，如果没有子进程就返回-1，如果存在子进程且不是DEAD状态，则阻塞即不返回。

```cpp
int ProgramManager::wait(int *retval)
{
    PCB *child;
    ListItem *item;
    bool interrupt, flag;

    while (true)
    {
        interrupt = interruptManager.getInterruptStatus();
        interruptManager.disableInterrupt();

        item = this->allPrograms.head.next;

        // 查找子进程，找到一个状态为DEAD的子进程
        flag = true;
        while (item)
        {
            child = ListItem2PCB(item, tagInAllList);
            if (child->parentPid == this->running->pid)
            {
                flag = false;
                if (child->status == ProgramStatus::DEAD)
                {
                    break;
                }
            }
            item = item->next;
        }

        if (item) // 找到一个可返回的子进程
        {
            if (retval) // 不为nullptr
            {
                *retval = child->retValue;
            }

            int pid = child->pid;
            releasePCB(child);
            interruptManager.setInterruptStatus(interrupt);
            return pid;
        }
        else 
        {
            if (flag) // 子进程已经返回
            {
                
                interruptManager.setInterruptStatus(interrupt);
                return -1; // 没有找到子进程，返回-1
            }
            else // 存在子进程，但子进程的状态不是DEAD
            {
                interruptManager.setInterruptStatus(interrupt);
                schedule();
            }
        }
    }
}
```

#### exit：

##### 实现：

> * 标记为DEAD
> * 释放物理页、页表、页表目录、虚拟内存空间

```cpp
 // 第一步，标记DEAD
    PCB *program = this->running;
    program->retValue = ret;
    program->status = ProgramStatus::DEAD;
// 第二步，释放进程所占用的物理页、页表、页目录表和虚拟地址空间
    if (program->pageDirectoryAddress)
    {
        pageDir = (int *)program->pageDirectoryAddress;
        for (int i = 0; i < 768; ++i)
        {
            if (!(pageDir[i] & 0x1))
            {
                continue;
            }

            page = (int *)(0xffc00000 + (i << 12));

            for (int j = 0; j < 1024; ++j)
            {
                if(!(page[j] & 0x1)) {
                    continue;
                }

                paddr = memoryManager.vaddr2paddr((i << 22) + (j << 12));
                memoryManager.releasePhysicalPages(AddressPoolType::USER, paddr, 1);
            }

            paddr = memoryManager.vaddr2paddr((int)page);
            memoryManager.releasePhysicalPages(AddressPoolType::USER, paddr, 1);
        }

        memoryManager.releasePages(AddressPoolType::KERNEL, (int)pageDir, 1);
        
        int bitmapBytes = ceil(program->userVirtual.resources.length, 8);
        int bitmapPages = ceil(bitmapBytes, PAGE_SIZE);

        memoryManager.releasePages(AddressPoolType::KERNEL,
                                   (int)program->userVirtual.resources.bitmap, 
                                   bitmapPages);

    }
```

#### exit执行结果：

![image-20220620215822463](C:\Users\张文沁\AppData\Roaming\Typora\typora-user-images\image-20220620215822463.png)

![image-20220620215741494](C:\Users\张文沁\AppData\Roaming\Typora\typora-user-images\image-20220620215741494.png)

![image-20220620215757865](C:\Users\张文沁\AppData\Roaming\Typora\typora-user-images\image-20220620215757865.png)

#### 解决僵尸进程的问题：

> 大概有两种方法
>
> * 父进程回收法：
>
>   wait函数阻塞调用者，直到子进程终止。所以父进程可以调用wait函数回收僵尸进程。
>
> * init进程回收法：
>
>   如果父进程先于子进程结束，让init进程回收子进程而防止僵尸进程的产生

```cpp
void first_process()
{
    int pid = fork();
    if (pid) // 父进程
    {
        asm_system_call(0, programManager.running->pid, 1);
        int pi = wait(nullptr); 
        printf("father process exit\n");
    }
    else
    {
        asm_system_call(0, programManager.running->pid, 0);
        printf("child process exit\n");
        exit(0);
    }
}
```

```cpp
void init(void *arg)
{
    printf("start process\n");
    programManager.executeProcess((const char *)first_process, 1);    
    while (1)
    {
        int pid = wait(nullptr);
        printf("test process pid: %d\n", pid);
    }   
}

//修改exit来实现上述
PCB *child;
ListItem *item = this->allPrograms.head.next;
while (item)
{
    child = ListItem2PCB(item, tagInAllList);
    // 找到子进程
    if (child->parentPid == this->running->pid)
    {
        // 修改子进程的父亲
        child->parentPid = this->running->parentPid;
    }
    item = item->next;
}
```

![image-20220620233833994](C:\Users\张文沁\AppData\Roaming\Typora\typora-user-images\image-20220620233833994.png)

![image-20220620233850298](C:\Users\张文沁\AppData\Roaming\Typora\typora-user-images\image-20220620233850298.png)

> 解释：test process 继承了子进程
#include "asm_utils.h"
#include "interrupt.h"
#include "stdio.h"
#include "program.h"
#include "thread.h"
#include "sync.h"
#include "memory.h"

// 屏幕IO处理器
STDIO stdio;
// 中断管理器
InterruptManager interruptManager;
// 程序管理器
ProgramManager programManager;
// 内存管理器
MemoryManager memoryManager;

void first_thread(void *arg)
{
    // 第1个线程不可以返回
    // stdio.moveCursor(0);
    // for (int i = 0; i < 25 * 80; ++i)
    // {
    //     stdio.print(' ');
    // }
    // stdio.moveCursor(0);

    //mycode
    printf("method: fitst-bit\n");
    //allocate the memory
    char *p1 = (char *)memoryManager.allocatePhysicalPages(AddressPoolType::KERNEL, 20);
    if(p1!=0)
    {
    	printf("the p1 of thread: %x,the number of pages: %d \n",p1,20);
    }
    char *p2 =(char *)memoryManager.allocatePhysicalPages(AddressPoolType::KERNEL, 30);
    if(p2!=0)
    {
    	printf("the p2 of thread: %x,the number of pages: %d \n",p2,30);
    }
    char *p3 =(char *)memoryManager.allocatePhysicalPages(AddressPoolType::KERNEL, 10);
    if(p3!=0)
    {
    	printf("the p3 of thread: %x,the number of pages: %d \n",p3,10);
    }
    char *p4 =(char *)memoryManager.allocatePhysicalPages(AddressPoolType::KERNEL, 30);
    if(p4!=0)
    {
    	printf("the p4 of thread: %x,the number of pages: %d \n",p4,30);
    }
    //release the memory
    memoryManager.releasePhysicalPages(AddressPoolType::KERNEL, (int)p1, 20);
    printf("ok! p1 of thread has release 20 pages.\n");
    memoryManager.releasePhysicalPages(AddressPoolType::KERNEL, (int)p3, 10);
    printf("ok! p3 of thread has release 10 pages.\n");
    //re allocate
    char *p5 =(char *)memoryManager.allocatePhysicalPages(AddressPoolType::KERNEL, 10);
    if(p5!=0)
    {
    	printf("the p5 of thread: %x,the number of pages: %d \n",p5,10);
    }   
    asm_halt();
}

extern "C" void setup_kernel()
{

    // 中断管理器
    interruptManager.initialize();
    interruptManager.enableTimeInterrupt();
    interruptManager.setTimeInterrupt((void *)asm_time_interrupt_handler);

    // 输出管理器
    stdio.initialize();

    // 进程/线程管理器
    programManager.initialize();

    // 内存管理器
    memoryManager.initialize();

    // 创建第一个线程
    int pid = programManager.executeThread(first_thread, nullptr, "first thread", 1);
    if (pid == -1)
    {
        printf("can not execute thread\n");
        asm_halt();
    }

    ListItem *item = programManager.readyPrograms.front();
    PCB *firstThread = ListItem2PCB(item, tagInGeneralList);
    firstThread->status = RUNNING;
    programManager.readyPrograms.pop_front();
    programManager.running = firstThread;
    asm_switch_thread(0, firstThread);

    asm_halt();
}

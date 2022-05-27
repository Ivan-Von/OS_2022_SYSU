#include <linux/kernel.h>
#include <sys/syscall.h>
#include <unistd.h>
#include <stdio.h>

void main()
{
        //441:long sys_mysyscall(int)
        long temp;
        temp = syscall(441,1024);
        printf("mysyscall return %ld\n",temp);
        fflush(stdout);
        /* 让程序打印完后继续维持在用户态 */
        while(1);
}
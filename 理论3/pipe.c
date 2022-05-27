#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <dirent.h>
#include <linux/input.h>
#include <signal.h>
#include <sys/wait.h>
#include <stdlib.h>
#include <pthread.h>


int main(int argc,char **argv)
{

    char buf[1024] = {0};
    memset(buf, 0, sizeof(buf));    //定义一个字符数组并且清空

    int mk = mkfifo("/tmp/tran",0777);    //创建一个有名管道（路径可以写当前路径）
        if(mk == -1)
        {
            printf("establish mk fail.\n");    //判断是否创建有名管道成功
        }

    int fifo = open("/tmp/tran", O_RDWR);    //读写方式打开管道

    int fd_src = open(argv[1],O_RDWR);    //读写方式打开需要复制的文件
        if(fd_src < 0)
        {
            printf("open %s fail.\n",argv[1]);    //判断文件是否打开成功
        }

    int fd_desc = open(argv[2],O_CREAT|O_RDWR|O_TRUNC,0777);    //创建新的文件，有就清空，并可读可写方式打开
        if(fd_desc < 0)
        {
            printf("open %s fail.\n",argv[2]);    //判断是否打开成功
        }

    while(1)    //一直循环读写文件
    {
        int dre = read(fd_src, buf, sizeof(buf));

        write(fifo, buf, dre);    //从文件中读取文件并且写入管道

        memset(buf, 0, sizeof(buf));

        int re = read(fifo, buf, sizeof(buf));    //从管道中读取文件并且写入新的文件中

        int ret = write(fd_desc, buf, re);

        memset(buf , 0, sizeof(buf));

        if(ret < 1024)    //判断文件是否写入完成，完成则退出。
            break;
    }

    printf("copy succes.\n");

close(fd_src);
close(fd_desc);    //关闭文件

return 0;
}
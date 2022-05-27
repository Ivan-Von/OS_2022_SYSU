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
    memset(buf, 0, sizeof(buf));    //����һ���ַ����鲢�����

    int mk = mkfifo("/tmp/tran",0777);    //����һ�������ܵ���·������д��ǰ·����
        if(mk == -1)
        {
            printf("establish mk fail.\n");    //�ж��Ƿ񴴽������ܵ��ɹ�
        }

    int fifo = open("/tmp/tran", O_RDWR);    //��д��ʽ�򿪹ܵ�

    int fd_src = open(argv[1],O_RDWR);    //��д��ʽ����Ҫ���Ƶ��ļ�
        if(fd_src < 0)
        {
            printf("open %s fail.\n",argv[1]);    //�ж��ļ��Ƿ�򿪳ɹ�
        }

    int fd_desc = open(argv[2],O_CREAT|O_RDWR|O_TRUNC,0777);    //�����µ��ļ����о���գ����ɶ���д��ʽ��
        if(fd_desc < 0)
        {
            printf("open %s fail.\n",argv[2]);    //�ж��Ƿ�򿪳ɹ�
        }

    while(1)    //һֱѭ����д�ļ�
    {
        int dre = read(fd_src, buf, sizeof(buf));

        write(fifo, buf, dre);    //���ļ��ж�ȡ�ļ�����д��ܵ�

        memset(buf, 0, sizeof(buf));

        int re = read(fifo, buf, sizeof(buf));    //�ӹܵ��ж�ȡ�ļ�����д���µ��ļ���

        int ret = write(fd_desc, buf, re);

        memset(buf , 0, sizeof(buf));

        if(ret < 1024)    //�ж��ļ��Ƿ�д����ɣ�������˳���
            break;
    }

    printf("copy succes.\n");

close(fd_src);
close(fd_desc);    //�ر��ļ�

return 0;
}
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <pthread.h>
#include <semaphore.h>
#include <time.h>
 
#define BUFF_MAX 10    //假设缓冲区buff最大存储数据为10
#define SC_NUM 2       //假设两个生产者
#define XF_NUM 3       //假设两个消费者
 
sem_t empty;           //信号量empty
sem_t full;            //信号量full
pthread_mutex_t mutex; //互斥锁的定义
 
int buff[BUFF_MAX];    //缓冲区存储10十个数据
int in = 0; //初始写入下标为0
int out = 0; //初始读取下标为0
 
void * sc_thread(void * arg)    //生产者线程函数 sc的意思就是生产的缩写
{
    int index = (int)arg;
    for(int i = 0 ; i < 30 ; i++)
    {
        sem_wait(&empty);   //对初始值为10的信号量进行减一的操作
        pthread_mutex_lock(&mutex);  //上锁
        buff[in] = rand() % 100;   //在缓冲区中存储的数据是多少我们不关心，只需要知道那玩意存进去就好了
        printf("生产者%d，在%d位置上,产生了%d数据\n",index,in,buff[in]); //打印做个标记
        in = (in + 1) % BUFF_MAX;  //假设写满之后，重头开始覆盖前面的数据，不会产生越界
        pthread_mutex_unlock(&mutex);   //解锁
        sem_post(&full);   //对full为0的初始值信号量进行加一，告诉消费者函数，可以进行读取了
        int n = rand() % 3; 
        sleep(n);    //随机进行睡眠一到三秒
    }
}
 
void * xf_thread(void * arg)  //xf是消费者的缩写
{
    int index = (int)arg;  
    for(int i = 0 ; i < 20 ; i++)      //因为生产者有两个，各自写入30次总共就是60次
    {                                  //然后消费者有三个，各自读取20次，刚好可以读完
        sem_wait(&full);
        pthread_mutex_lock(&mutex);
        printf("消费者%d，在%d位置上，读取了%d数据\n",index,out,buff[out]);
        out = (out + 1) % BUFF_MAX;
        pthread_mutex_unlock(&mutex);
        sem_post(&empty);
 
        int n = rand() % 10;
        sleep(n);
   }        
}
 
int main()
{
    sem_init(&empty,0,BUFF_MAX);
    sem_init(&full,0,0);
    pthread_mutex_init(&mutex,NULL);
 
    srand(time(NULL));
    pthread_t sc_id[SC_NUM];
    pthread_t xf_id[XF_NUM];
    for(int i = 0 ; i < SC_NUM ; i++)
    {
        pthread_create(&sc_id[i],NULL,sc_thread,(void*)i);
    }
 
    for(int i = 0 ; i < XF_NUM ; i++)
    {
        pthread_create(&xf_id[i],NULL,xf_thread,(void*)i);
    }
 
    for(int i = 0 ; i < SC_NUM ; i++)
    {
         pthread_join(sc_id[i],NULL);
    }
 
    for(int i = 0 ; i < XF_NUM ; i++)
    {
        pthread_join(xf_id[i],NULL);
    }
 
    sem_destroy(&empty);
    sem_destroy(&full);
    pthread_mutex_destroy(&mutex);
 
    printf("main run over\n");
    exit(0);
}
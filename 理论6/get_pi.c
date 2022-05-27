#include<stdio.h>
#include<stdlib.h>
#include<pthread.h>
#include<time.h>
#define TOTAL_NUM 10000000                          //设置点的总数
#define THREAD_NUM 5                                //线程总数

pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;   //定义互斥锁
int circle_num = 0;                                 //统计圆内点数
int num = 0;										//计数用，防止程序出错

void* monte_carlo(void* tid)                        //统计函数，每个子线程算200遍
{
    srand((unsigned)time(NULL));
    int i = 0;
    while(i<TOTAL_NUM/THREAD_NUM)
    {
        pthread_mutex_lock(&lock);                  //申请互斥锁
        
        /*产生随机的x、y坐标值*/
        double pointX = (double)rand()/(double)RAND_MAX;
        double pointY = (double)rand()/(double)RAND_MAX;
        double l = pointX*pointX+pointY*pointY;

        /*判断是否位于圆内*/
        if(l<=1.0)
            ++circle_num;
        ++num;
        ++i;
        
        pthread_mutex_unlock(&lock);                //释放互斥锁
        
    }
    return 0;
}

int main()
{
    pthread_t thread[THREAD_NUM];                   //线程定义
    int i, state;

    for(i = 0;i<THREAD_NUM;i++)                     //线程创建
    {
        printf("create thread%d\n", i);
        state = pthread_create(&thread[i], NULL, monte_carlo, NULL);
        if(state)
        {
            printf("error!\n");
            exit(-1);
        }
    }

    for(i = 0;i<THREAD_NUM;i++)                     //等待子线程完成
    {
        pthread_join(thread[i],NULL);
    }

    pthread_mutex_destroy(&lock);                   //销毁互斥锁

    /*将pi的结果打印*/
    printf("num = %d, circle_num = %d, pi = %.5lf\n", num, circle_num, 4.0*circle_num/TOTAL_NUM);

    return 0;
}

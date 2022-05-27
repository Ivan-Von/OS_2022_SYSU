#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>

//静态加载pthreadVC2.lib库文件
#pragma comment(lib, "pthreadVC2.lib")


//声明互斥信号量,五根筷子互斥使用
pthread_mutex_t chopstick[5] = { PTHREAD_MUTEX_INITIALIZER ,PTHREAD_MUTEX_INITIALIZER ,PTHREAD_MUTEX_INITIALIZER
,PTHREAD_MUTEX_INITIALIZER, PTHREAD_MUTEX_INITIALIZER };

//函数声明
void getChop(int i);
void layChop(int i);
void *philosophe(void *i);

//全局变量声明
//用来表示有多少个哲学家在拿筷子
int count = 0;

int main()
{
	//声明进程变量thread1
	pthread_t t1, t2, t3, t4, t5;
	//创建五个进程

	pthread_create(&t1, NULL, philosophe, (void*)1);
	pthread_create(&t2, NULL, philosophe, (void*)2);
	pthread_create(&t3, NULL, philosophe, (void*)3);
	pthread_create(&t4, NULL, philosophe, (void*)4);
	pthread_create(&t5, NULL, philosophe, (void*)5);
	pthread_join(t1, NULL);
	pthread_join(t2, NULL);
	pthread_join(t3, NULL);
	pthread_join(t4, NULL);
	pthread_join(t5, NULL);
	system("pause");
	return 0;
}

/*
哲学家方法，用于线程的创建
*/
void *philosophe(void *i) {
	int index = (int)i;
	if (index % 2) {
		getChop(index - 1);
		getChop(index % 5);
	}
	else {
		getChop(index % 5);
		getChop(index - 1);
	}
	printf("哲学家%d开始进餐！\n", index);
	layChop(index);
	return NULL;
}
/*
哲学家拿起筷子的方法
*/
void getChop(int i) {

	while (true) {
		int ret_trylock = pthread_mutex_trylock(&chopstick[i]);
		if (!ret_trylock) {
			break;
		}
	}
}

//哲学家放筷子开始思考
void layChop(int i)
{
	//把打印语句放在上面是考虑到当把锁释放后，会立即有线程对资源进行加锁，以为是程序逻辑有问题
	printf("哲学家%d已经进餐完毕，开始思考\n", i);
	pthread_mutex_unlock(&chopstick[i - 1]);
	pthread_mutex_unlock(&chopstick[i % 5]);
}





#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>

//静态加载pthreadVC2.lib库文件
#pragma comment(lib, "pthreadVC2.lib")

//声明互斥信号量,五根筷子互斥使用
pthread_mutex_t chopstick[5] = { PTHREAD_MUTEX_INITIALIZER ,PTHREAD_MUTEX_INITIALIZER ,PTHREAD_MUTEX_INITIALIZER 
                                 ,PTHREAD_MUTEX_INITIALIZER, PTHREAD_MUTEX_INITIALIZER };

//函数声明
void eat(int i);
void think(int i);
void *philosophe(void *i);

int main()
{
	//声明进程变量thread1
	pthread_t t1,t2,t3,t4,t5;
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
	//哲学家开始吃饭
	eat(index);
	//吃完饭后开始思考
	think(index);
	
	return NULL;
}

/*
哲学家拿起筷子的方法
*/
void eat(int i) {
	//当得到两个筷子的时候，对两只筷子进行加锁，如果对一个筷子加锁了，要进行解锁，否则其余的也吃不了饭
    while (true) {
		//这里好像不能用阻塞式做，当取得两个资源后，对其进行加锁，然后循环所以会造成线程阻塞
		int ret_trylock1 = pthread_mutex_trylock(&chopstick[i - 1]);
		int ret_trylock2 = pthread_mutex_trylock(&chopstick[i % 5]);
		if (!ret_trylock1&&!ret_trylock2) {
			break;
		}
		else if (ret_trylock1 && !ret_trylock2) {
			pthread_mutex_unlock(&chopstick[i % 5]);
		}
		else if (!ret_trylock1 && ret_trylock2) {
			pthread_mutex_unlock(&chopstick[i - 1]);
		}
	}
	printf("哲学家%d开始进餐！\n", i);
}

//哲学家放筷子开始思考
void think(int i)
{
	//把打印语句放在上面是考虑到当把锁释放后，会立即有线程对资源进行加锁，导致输出语句顺序出现异常
	printf("哲学家%d已经进餐完毕，开始思考\n", i);
	pthread_mutex_unlock(&chopstick[i-1]);
	pthread_mutex_unlock(&chopstick[i%5]);
	//释放对筷子资源的控制
}




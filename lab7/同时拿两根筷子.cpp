#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>

//��̬����pthreadVC2.lib���ļ�
#pragma comment(lib, "pthreadVC2.lib")

//���������ź���,������ӻ���ʹ��
pthread_mutex_t chopstick[5] = { PTHREAD_MUTEX_INITIALIZER ,PTHREAD_MUTEX_INITIALIZER ,PTHREAD_MUTEX_INITIALIZER 
                                 ,PTHREAD_MUTEX_INITIALIZER, PTHREAD_MUTEX_INITIALIZER };

//��������
void eat(int i);
void think(int i);
void *philosophe(void *i);

int main()
{
	//�������̱���thread1
	pthread_t t1,t2,t3,t4,t5;
	//�����������
	
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
��ѧ�ҷ����������̵߳Ĵ���
*/
void *philosophe(void *i) {
	int index = (int)i;
	//��ѧ�ҿ�ʼ�Է�
	eat(index);
	//���극��ʼ˼��
	think(index);
	
	return NULL;
}

/*
��ѧ��������ӵķ���
*/
void eat(int i) {
	//���õ��������ӵ�ʱ�򣬶���ֻ���ӽ��м����������һ�����Ӽ����ˣ�Ҫ���н��������������Ҳ�Բ��˷�
    while (true) {
		//���������������ʽ������ȡ��������Դ�󣬶�����м�����Ȼ��ѭ�����Ի�����߳�����
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
	printf("��ѧ��%d��ʼ���ͣ�\n", i);
}

//��ѧ�ҷſ��ӿ�ʼ˼��
void think(int i)
{
	//�Ѵ�ӡ�����������ǿ��ǵ��������ͷź󣬻��������̶߳���Դ���м���������������˳������쳣
	printf("��ѧ��%d�Ѿ�������ϣ���ʼ˼��\n", i);
	pthread_mutex_unlock(&chopstick[i-1]);
	pthread_mutex_unlock(&chopstick[i%5]);
	//�ͷŶԿ�����Դ�Ŀ���
}




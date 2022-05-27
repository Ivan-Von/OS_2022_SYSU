#include <iostream>
#include <thread>
#include <mutex>
#include <condition_variable>
#include <memory>

using namespace std;

const int arr_size = 2048;

struct CircleQueue
{
	int arr[arr_size];//数组做循环队列
	int read_pos;
	int write_pos;

	condition_variable cond_not_full;//表示非满的条件变量，队列满时阻塞。
	condition_variable cond_not_empty;//表示非空的条件变量，队列空时阻塞。
	mutex mtx;//保护数组的互斥量

	CircleQueue() : read_pos(0), write_pos(0) {}
} g_circleQueue;

void produceItem(CircleQueue &qu, int item)
{
	unique_lock<mutex> lock(qu.mtx); 
	while ((qu.write_pos + 1) % arr_size == qu.read_pos)
	{
		cout << "队列满..." << endl;
		qu.cond_not_full.wait(lock); //队列满时，条件变量阻塞，等待消费者线程消费数据。
	}
	//队列不满，执行生产操作。
	qu.arr[qu.write_pos] = item;
	qu.write_pos = (qu.write_pos + 1) % arr_size;
	//通知因队列空而阻塞的消费者线程。
	qu.cond_not_empty.notify_all();
	lock.unlock();
}

void consumItem(CircleQueue &qu, int& item)
{
	unique_lock<mutex> lock(qu.mtx);
	while (qu.write_pos == qu.read_pos)
	{
		cout << "队列空..." << endl;
		qu.cond_not_empty.wait(lock); //队列空时，条件变量阻塞，等待生产者线程。
	}
	//队列不空，执行消费操作
	item = qu.arr[qu.read_pos];
	qu.read_pos = (qu.read_pos + 1) % arr_size;

	qu.cond_not_full.notify_all();
	lock.unlock();
}
//每个生产线程生产3个产品
void produceTask()
{
	for (int i = 0; i < 3; i++)
	{
		this_thread::sleep_for(chrono::seconds(1));
		produceItem(g_circleQueue, i + 1);
		
		cout  << " produce " << i + 1 << endl;
	}
}

void consumTask()
{
	while (1)
	{
		int item = 0;
		consumItem(g_circleQueue, item);
		this_thread::sleep_for(chrono::seconds(1));
		cout  << " consume " << item << endl;
	}
}
int main()
{
	unique_lock<mutex> lock();
		//4生产线程
	thread producer1(produceTask);
	thread producer2(produceTask);
	thread producer3(produceTask);
	thread producer4(produceTask);
	//2消费线程
	thread consumer1(consumTask);
	thread consumer2(consumTask);

	producer1.join();
	producer2.join();
	producer3.join();
	producer4.join();
	consumer1.join();
	consumer2.join();
	return 0;
}

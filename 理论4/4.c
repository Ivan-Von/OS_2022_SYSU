#include <thread>
#include <stdio.h>
#include <pthread.h>
int minValue = 0;
int maxValue = 0;
int averageValue = 0;

void mmax(int a[], int size)
{
    for (int i = 0; i < size; ++i)
    {
        if (a[i] > maxValue)
        {
            maxValue = a[i];
        }
    }
}
void mmin(int a[], int size)
{
    minValue = 9999;
    for (int i = 0; i < size; ++i)
    {
        if (a[i] < minValue)
        {
            minValue = a[i];
        }
    }
}
void average(int a[], int size)
{
    int sum = 0;
    for (int i = 0; i < size; ++i)
    {
        sum += a[i];

    }
    if (size > 0)
    {
        averageValue = sum / size;
    }
}

int main()
{
    int a[8];
	for (int i = 0;i < 7;++i){
		int sum = 0;
		scanf("%d",&sum);
		a[i] = sum;
	}
    std::thread calcMinWorkThead(mmin, a, 7);
    std::thread calcMaxWorkThead(mmax, a, 7);
    std::thread calcAverageWorkThead(average, a, 7);
    calcMinWorkThead.join();
    calcMaxWorkThead.join();
    calcAverageWorkThead.join();
    printf("Minimum:%d\nMaximum:%d\nAverage:%d\n", minValue, maxValue, averageValue);
    return 0;
}
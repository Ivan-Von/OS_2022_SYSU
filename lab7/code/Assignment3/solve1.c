
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <semaphore.h>
#include <unistd.h>

#define N 5 // five philosopher
#define T_EAT 5
#define T_THINK 5
#define N_ROOM  4  //同一时间只允许４人用餐
#define left(phi_id) (phi_id+N-1)%N
#define right(phi_id) (phi_id+1)%N

enum { think , hungry , eat  }phi_state[N];
sem_t chopstick[N];
sem_t room;

void thinking(int id){
    sleep(T_THINK);
    printf("philosopher[%d] is thinking...\n", id);
}

void eating(int id){
    sleep(T_EAT);
    printf("philosopher[%d] is eating...\n", id);
}

void take_forks(int id){
    //获取左右两边的筷子
    //printf("Pil[%d], left[%d], right[%d]\n", id, left(id), right(id));
    sem_wait(&chopstick[left(id)]);
    sem_wait(&chopstick[right(id)]);
    //printf("philosopher[%d]  take_forks...\n", id);
}

void put_down_forks(int id){
    printf("philosopher[%d] is put_down_forks...\n", id);
    sem_post(&chopstick[left(id)]);
    sem_post(&chopstick[right(id)]);
}

void* philosopher_work(void *arg){
    int id = *(int*)arg;
    printf("philosopher init [%d] \n", id);
    while(1){
        thinking(id);
        sem_wait(&room);
        take_forks(id);
        sem_post(&room);
        eating(id);
        put_down_forks(id);
    }
}

int main(){
    pthread_t phiTid[N];
    int i;
    int err;
    int *id=(int *)malloc(sizeof(int)*N);

    //initilize semaphore
    for (i = 0; i < N; i++)
    {
        if(sem_init(&chopstick[i], 0, 1) != 0)
        {
            printf("init forks error\n");
        }
    }

    sem_init(&room, 0, N_ROOM);

    for(i=0; i < N; ++i){
        id[i] = i;
        err = pthread_create(&phiTid[i], NULL, philosopher_work, (void*)(&id[i])); //thread id是0,1,2,3,4
        if (err != 0)
            printf("can't create process for reader\n");
    }

    while(1);

    // delete the source of semaphore
    for (i = 0; i < N; i++)
    {
        err = sem_destroy(&chopstick[i]);
        if (err != 0)
        {
            printf("can't destory semaphore\n");
        }
    }
    exit(0);
    return 0;
}
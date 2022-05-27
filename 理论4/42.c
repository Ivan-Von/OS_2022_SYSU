#include<stdio.h>
#include<pthread.h>
#include<unistd.h>

#define ARRAY_COUNT 10
int need_sort_array[10]={7,12,19,3,18,4,2,6,15,8};
int sorted[10];

void *worker(void *arg){
    int i,j;
    int tmp;
    int Min;
    for(i=0;i<ARRAY_COUNT/2;i++){
            Min=i;
        for(j=i+1;j<ARRAY_COUNT/2;j++){
            if(need_sort_array[Min]>need_sort_array[j])
                    Min=j;
        }
        tmp=need_sort_array[i];
        need_sort_array[i]=need_sort_array[Min];
        need_sort_array[Min]=tmp;
    }
}


void master(){
    int i,j;
    int tmp;
    int Min;
    for(i=ARRAY_COUNT/2;i<ARRAY_COUNT;i++){
            Min=i;
        for(j=i+1;j<ARRAY_COUNT;j++){
            if(need_sort_array[Min]>need_sort_array[j])
                    Min=j;
        }
        tmp=need_sort_array[i];
        need_sort_array[i]=need_sort_array[Min];
        need_sort_array[Min]=tmp;
    }
}

void Merge_Array(){
        int i=0,j=ARRAY_COUNT/2,k=0;
        while(i<ARRAY_COUNT/2&&j<ARRAY_COUNT){
            if(need_sort_array[i]<need_sort_array[j])
                    sorted[k++]=need_sort_array[i++];
            else
                    sorted[k++]=need_sort_array[j++];
        }
        while(i<ARRAY_COUNT/2)
                sorted[k++]=need_sort_array[i++];
        while(j<ARRAY_COUNT)
                sorted[k++]=need_sort_array[j++];
}


void print(int *array){
        int i;
        for(i=0;i<ARRAY_COUNT;i++)
                printf("%d ",array[i]);
        printf("\n");
}


int main(){
    pthread_t pid;
    printf("Before sort,need_sort_array: ");
    print(need_sort_array);
    pthread_create(&pid,NULL,&worker,NULL);
    master();
    pthread_join(pid,NULL);
    printf("After sorted,need_sort_array: ");
    print(need_sort_array);
    Merge_Array();
    printf("sorted array: ");
    print(sorted);
    return 0;
}
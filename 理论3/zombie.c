//������ʬ����
#include<stdio.h>
#include<sys/types.h>
#include<unistd.h>

int main(void)
{
    pid_t pid;
    if ((pid = fork()) < 0)
	{
		printf("Fork Failed");
	}
    else if (pid == 0)
	{
	        printf("Child process\n");
    	}
    else
    {
        printf("Parent Process\n");
        sleep(30);  //����������30s��֤�ӽ������˳�����Ϊ��ʬ����
        printf("Weak up and quit\n");
    }
    return 0;
}
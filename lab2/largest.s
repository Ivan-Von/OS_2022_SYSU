extern printf
extern exit
section .data
array dd 1,2,3,4,5,6,7,8,9,10
format db "%d"
section .text
global _start
_start:
	mov eax,0 ����¼���ֵ
	mov ebx,array ������һ�����ִ���ebx
	mov ecx,10 ��ecx��¼���鳤�ȣ���ѭ������
Loop:
	cmp [ebx],eax 
	jl next �����ھ���ת
	mov eax,[ebx] �������������
next:
	add ebx,4 ������һ�����֣�ƫ��Ѱַ
	loop Loop ������ѭ��
push eax
push format
call printf
push 0
call exit
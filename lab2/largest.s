extern printf
extern exit
section .data
array dd 1,2,3,4,5,6,7,8,9,10
format db "%d"
section .text
global _start
_start:
	mov eax,0 ；记录最大值
	mov ebx,array ；将第一个数字传入ebx
	mov ecx,10 ；ecx记录数组长度，即循环次数
Loop:
	cmp [ebx],eax 
	jl next ；大于就跳转
	mov eax,[ebx] ；否则更新数字
next:
	add ebx,4 ；到下一个数字，偏移寻址
	loop Loop ；继续循环
push eax
push format
call printf
push 0
call exit
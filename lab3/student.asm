%include "head.include"

your_if:
mov edx,[a1]
cmp edx,12
jl case1
cmp edx,24
jl case2
jl case3

case1:
mov eax,[a1]
mov ebx,2
idiv ebx
inc eax
mov [if_flag],eax
jmp end

case2:
mov eax,24
sub eax,[a1]
imul eax,edx
mov [if_flag],eax
jmp end

case3:
mov eax,[a1]
shl eax,4
mov [if_flag],eax
jmp end

end:
your_while:
loop1:
mov edx,[a2]
cmp edx,12
jl end_loop
call my_random
mov ebx,[while_flag]
mov edx,[a2]
mov byte[ebx+(edx-12)],a1
dec edx
mov [a2],edx
jmp loop1

end_loop:
%include "end.include"

your_function:
xor eax,eax
xor ecx,ecx
mov ebx,[your_string]
loop2:
mov cl,byte[eax+ebx] ;×Ö½Ú¼Ä´æÆ÷
inc eax
cmp ecx,0
je end_for
pushad
push ecx
call print_a_char
pop ecx
popad
jmp loop2
	
end_for:
ret
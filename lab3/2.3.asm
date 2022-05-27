mov gs,ax
mov sp,0x7c00
mov ax,0xb800
mov gs,ax

start:
;清屏
mov ah,6
mov al,0
mov ch,0
mov cl,0
mov dh,25
mov dl,80
int 10h
mov ah,0;调用16号中断的0号功能
int 16h
mov ah,0xcf
mov [gs:2*0],ax
;死循环
jmp $
times 510 - ($ - $$) db 0
db 0x55,0xaa
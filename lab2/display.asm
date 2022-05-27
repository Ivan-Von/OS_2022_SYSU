org 0x7c00
[bits 16]
xor ax, ax ; eax = 0
; 初始化段寄存器, 段地址全部设为0
mov ds, ax
mov ss, ax
mov es, ax
mov fs, ax
mov gs, ax

; 初始化栈指针
mov sp, 0x7c00
mov ax, 0xb800
mov gs, ax


mov ah, 0x01 ;蓝色
mov al, 'H'
mov [gs:2 * 0], ax

mov ah, 0x02
mov al, 'e'
mov [gs:2 * 1], ax

mov ah, 0x03
mov al, 'l'
mov [gs:2 * 2], ax

mov ah, 0x04
mov al, 'l'
mov [gs:2 * 3], ax

mov ah, 0x05
mov al, 'o'
mov [gs:2 * 4], ax

mov ah, 0x06
mov al, ' '
mov [gs:2 * 5], ax

mov ah, 0x07
mov al, 'W'
mov [gs:2 * 6], ax

mov ah, 0x08
mov al, 'o'
mov [gs:2 * 7], ax

mov ah, 0x00
mov al, 'r'
mov [gs:2 * 8], ax

mov ah, 0x01
mov al, 'l'
mov [gs:2 * 9], ax

mov al, 'd'
mov [gs:2 * 10], ax

jmp $ ; 死循环

times 510 - ($ - $$) db 0
db 0x55, 0xaa
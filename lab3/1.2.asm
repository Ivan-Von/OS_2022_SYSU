org 0x7c00
[bits 16]
xor ax, ax ; eax = 0
; ��ʼ���μĴ���, �ε�ַȫ����Ϊ0
mov ds, ax
mov ss, ax
mov es, ax
mov fs, ax
mov gs, ax

; ��ʼ��ջָ��
mov sp, 0x7c00
mov ax, 0xb8ac
mov gs, ax


mov ah, 0x07 ;��ɫ
mov al, '2'
mov [gs:2 * 0], ax

mov al, '0'
mov [gs:2 * 1], ax

mov al, '3'
mov [gs:2 * 2], ax

mov al, '3'
mov [gs:2 * 3], ax

mov al, '7'
mov [gs:2 * 4], ax

mov al, '2'
mov [gs:2 * 5], ax

mov al, '6'
mov [gs:2 * 6], ax

mov al, '8'
mov [gs:2 * 7], ax

mov al, 'Z'
mov [gs:2 * 8], ax

mov al, 'W'
mov [gs:2 * 9], ax

mov al, 'Q'
mov [gs:2 * 10], ax

jmp $ ; ��ѭ��

times 510 - ($ - $$) db 0
db 0x55, 0xaa
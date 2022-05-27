%include "boot.inc"
;org 0x7e00
[bits 16]
mov ax, 0xb800
mov gs, ax
xor ebx, ebx

;��������
mov dword [GDT_START_ADDRESS+0x00],0x00 ;0x7e24
mov dword [GDT_START_ADDRESS+0x04],0x00  

;����������������һ�����ݶΣ���Ӧ0~4GB�����Ե�ַ�ռ�
mov dword [GDT_START_ADDRESS+0x08],0x0000ffff    ; ����ַΪ0���ν���Ϊ0xFFFFF
mov dword [GDT_START_ADDRESS+0x0c],0x00cf9200    ; ����Ϊ4KB���洢���������� 

;��������ģʽ�µĶ�ջ��������      
mov dword [GDT_START_ADDRESS+0x10],0x00000000    ; ����ַΪ0x00000000������0x0 
mov dword [GDT_START_ADDRESS+0x14],0x00409600    ; ����Ϊ1���ֽ�

;��������ģʽ�µ��Դ�������   
mov dword [GDT_START_ADDRESS+0x18],0x80007fff    ; ����ַΪ0x000B8000������0x07FFF 
mov dword [GDT_START_ADDRESS+0x1c],0x0040920b    ; ����Ϊ�ֽ�

;��������ģʽ��ƽ̹ģʽ�����������
mov dword [GDT_START_ADDRESS+0x20],0x0000ffff    ; ����ַΪ0���ν���Ϊ0xFFFFF
mov dword [GDT_START_ADDRESS+0x24],0x00cf9800    ; ����Ϊ4kb������������� 

;��ʼ����������Ĵ���GDTR
mov word [pgdt], 39      ;��������Ľ���   0x7e7e
lgdt [pgdt]                        ;0x7e84
      
in al,0x92                         ;����оƬ�ڵĶ˿�  0x7e89
or al,0000_0010B                   ;0x7e8b
out 0x92,al                        ;��A20 0x7e8d

cli                                ;�жϻ�����δ���� 0x7e8f
mov eax,cr0                        ;0x7e90
or eax,1                           ;0x7e93
mov cr0,eax                        ;����PEλ  0x7e97
      
;���½��뱣��ģʽ
jmp dword CODE_SELECTOR:protect_mode_begin        ;0x7e9a

;16λ��������ѡ���ӣ�32λƫ��
;����ˮ�߲����л�������
[bits 32]           
protect_mode_begin:                              

mov eax, DATA_SELECTOR                     ;�������ݶ�(0..4GB)ѡ����
mov ds, eax
mov es, eax
mov eax, STACK_SELECTOR
mov ss, eax
mov eax, VIDEO_SELECTOR
mov gs, eax
;����Ϊ�ַ��������Ĵ���

;�ѱ������ȫ��
pushad
mov bx,0
mov cx,4000 ;4000=2*25*80
loop0:
    cmp bx,cx
    jz loop0end
    mov ah,0x00 ;��ɫ
    mov al,'0'
    mov [gs:bx],ax
    add bx,2
    jmp loop0
loop0end:
popad

;��ʼ�����ù��λ��Ϊ(2,0)
    mov ebx,160

loop1: ;ѭ�����
    mov al,[num] 
    mov ah,[color]
    add al,'0'
    mov [gs:ebx],ax

;�������ж���һ���Ƿ�Ҫ�ķ���
pushad
judge_dh_0:
    mov ax,160
    cmp bx,ax
    jg judge_dh_24 ; ���ڵ�0��
    mov al,1
    mov [down],al ;������Ϊ0��������
judge_dh_24:
    mov ax,3840 ;3840 = 24*160
    cmp bx,ax
    jl judge_dl_0 ; bx<24*160,���ڵ�24��
    mov al,0
    mov [down],al ;������Ϊ24��������
judge_dl_0:
    mov ax,bx
    mov cl,160
    div cl  ;bx/160,������ah��
    mov dx,0
    cmp ah,dh
    jne judge_dl_79 ; ���ڵ�0��
    mov al,1
    mov [right],al ;����Ϊ0��������
judge_dl_79:
    mov dx,158 ;158=2*79
    cmp ah,dl
    jne judge_end ; ���ڵ�79��
    mov al,0
    mov [right],al ;����Ϊ79��������
judge_end: 
popad

;������һ��������
push ax
push cx
if_right:
    mov al,1
    mov cl,[right]
    cmp cl,al
    jne else1 ;right=0,��ȥelse1
    add bx,2
    jmp if_down
else1:
    sub bx,2
if_down:
    mov al,1
    mov cl,[down]
    cmp cl,al
    jne else2 ;down=0,��ȥelse2
    add bx,160
    jmp set_xy_end
else2:
    sub bx,160
set_xy_end:
pop cx
pop ax

;����һ�������ֺ���ɫ
pushad
    mov al,[num]
    inc al
    mov bl,10
    cmp al,bl
    jne not_need_set_0 ;num!=10,����Ҫ����
    mov al,0
not_need_set_0:
    mov [num],al

    mov al,[color]
    inc al
    mov bl,255
    cmp al,bl
    jne not_need_set_1 ;num!=255,����Ҫ����
    mov al,0
not_need_set_1:
    mov [color],al
popad

;ÿ��ʾһ�������ӳ�һ��ʱ��
pushad
    mov ecx,1000000
for_wait:
    mov eax,1
    and eax,1
    loop for_wait
popad

jmp loop1
myinfo db '                         zwq20337268                         '
    infolen dw $-myinfo
    curcolor db 80h      
    curcolor2 db 09h      
    times 510-($-$$) db 0 
    db 55h, 0AAh        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
jmp $ ; ��ѭ��

pgdt dw 0
     dd GDT_START_ADDRESS

bootloader_tag db 'run bootloader'
bootloader_tag_end:
protect_mode_tag db 'enter protect mode'
protect_mode_tag_end:
num db 0 ;��ʾ�����ֺ���ɫ
color db 8 
right db 1 ;��ʶ����
down db 1
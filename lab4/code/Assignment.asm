%include "boot.inc"
;org 0x7e00
[bits 16]
mov ax, 0xb800
mov gs, ax
xor ebx, ebx

;空描述符
mov dword [GDT_START_ADDRESS+0x00],0x00 ;0x7e24
mov dword [GDT_START_ADDRESS+0x04],0x00  

;创建描述符，这是一个数据段，对应0~4GB的线性地址空间
mov dword [GDT_START_ADDRESS+0x08],0x0000ffff    ; 基地址为0，段界限为0xFFFFF
mov dword [GDT_START_ADDRESS+0x0c],0x00cf9200    ; 粒度为4KB，存储器段描述符 

;建立保护模式下的堆栈段描述符      
mov dword [GDT_START_ADDRESS+0x10],0x00000000    ; 基地址为0x00000000，界限0x0 
mov dword [GDT_START_ADDRESS+0x14],0x00409600    ; 粒度为1个字节

;建立保护模式下的显存描述符   
mov dword [GDT_START_ADDRESS+0x18],0x80007fff    ; 基地址为0x000B8000，界限0x07FFF 
mov dword [GDT_START_ADDRESS+0x1c],0x0040920b    ; 粒度为字节

;创建保护模式下平坦模式代码段描述符
mov dword [GDT_START_ADDRESS+0x20],0x0000ffff    ; 基地址为0，段界限为0xFFFFF
mov dword [GDT_START_ADDRESS+0x24],0x00cf9800    ; 粒度为4kb，代码段描述符 

;初始化描述符表寄存器GDTR
mov word [pgdt], 39      ;描述符表的界限   0x7e7e
lgdt [pgdt]                        ;0x7e84
      
in al,0x92                         ;南桥芯片内的端口  0x7e89
or al,0000_0010B                   ;0x7e8b
out 0x92,al                        ;打开A20 0x7e8d

cli                                ;中断机制尚未工作 0x7e8f
mov eax,cr0                        ;0x7e90
or eax,1                           ;0x7e93
mov cr0,eax                        ;设置PE位  0x7e97
      
;以下进入保护模式
jmp dword CODE_SELECTOR:protect_mode_begin        ;0x7e9a

;16位的描述符选择子：32位偏移
;清流水线并串行化处理器
[bits 32]           
protect_mode_begin:                              

mov eax, DATA_SELECTOR                     ;加载数据段(0..4GB)选择子
mov ds, eax
mov es, eax
mov eax, STACK_SELECTOR
mov ss, eax
mov eax, VIDEO_SELECTOR
mov gs, eax
;以下为字符弹射程序的代码

;把背景变成全黑
pushad
mov bx,0
mov cx,4000 ;4000=2*25*80
loop0:
    cmp bx,cx
    jz loop0end
    mov ah,0x00 ;黑色
    mov al,'0'
    mov [gs:bx],ax
    add bx,2
    jmp loop0
loop0end:
popad

;起始：设置光标位置为(2,0)
    mov ebx,160

loop1: ;循环输出
    mov al,[num] 
    mov ah,[color]
    add al,'0'
    mov [gs:ebx],ax

;输出完后判断下一步是否要改方向
pushad
judge_dh_0:
    mov ax,160
    cmp bx,ax
    jg judge_dh_24 ; 不在第0行
    mov al,1
    mov [down],al ;若行数为0则往下走
judge_dh_24:
    mov ax,3840 ;3840 = 24*160
    cmp bx,ax
    jl judge_dl_0 ; bx<24*160,不在第24行
    mov al,0
    mov [down],al ;若行数为24则往上走
judge_dl_0:
    mov ax,bx
    mov cl,160
    div cl  ;bx/160,余数在ah中
    mov dx,0
    cmp ah,dh
    jne judge_dl_79 ; 不在第0列
    mov al,1
    mov [right],al ;若列为0则往右走
judge_dl_79:
    mov dx,158 ;158=2*79
    cmp ah,dl
    jne judge_end ; 不在第79列
    mov al,0
    mov [right],al ;若列为79则往左走
judge_end: 
popad

;设置下一步的坐标
push ax
push cx
if_right:
    mov al,1
    mov cl,[right]
    cmp cl,al
    jne else1 ;right=0,跳去else1
    add bx,2
    jmp if_down
else1:
    sub bx,2
if_down:
    mov al,1
    mov cl,[down]
    cmp cl,al
    jne else2 ;down=0,跳去else2
    add bx,160
    jmp set_xy_end
else2:
    sub bx,160
set_xy_end:
pop cx
pop ax

;改下一步的数字和颜色
pushad
    mov al,[num]
    inc al
    mov bl,10
    cmp al,bl
    jne not_need_set_0 ;num!=10,不需要置零
    mov al,0
not_need_set_0:
    mov [num],al

    mov al,[color]
    inc al
    mov bl,255
    cmp al,bl
    jne not_need_set_1 ;num!=255,不需要置零
    mov al,0
not_need_set_1:
    mov [color],al
popad

;每显示一个数字延迟一段时间
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
jmp $ ; 死循环

pgdt dw 0
     dd GDT_START_ADDRESS

bootloader_tag db 'run bootloader'
bootloader_tag_end:
protect_mode_tag db 'enter protect mode'
protect_mode_tag_end:
num db 0 ;显示的数字和颜色
color db 8 
right db 1 ;标识方向
down db 1
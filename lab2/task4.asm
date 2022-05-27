;Rats OS
;Tab=4
[bits 16]

    org     0x7c00 				;ָ�������ƫ�ƵĻ���ַ

;----------- loader const ------------------
LOADER_SECTOR_LBA  		equ 0x1		;��2���߼�������ʼ
LOADER_SECTOR_COUNT		equ 9		;��ȡ9������
LOADER_BASE_ADDR 		equ 0x9000  ;�ڴ��ַ0x9000
;-------------------------------------------

;������������ 
    jmp     Entry
    db      0x90
    db      "RATSBOOT"     		;�����������ƿ�����������ַ�����8�ֽڣ�    

;�����������
Entry:

    ;------------------
    ;��ʼ���Ĵ���
    mov ax,0				
    mov ss,ax
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov fs,ax
    mov gs,ax
    mov sp,0x7c00

    ;------------------
    ;����
    mov ah,0x06				;�����Ļ					
    mov al,0
    mov cx,0   
    mov dx,0xffff  
    mov bh,0x17				;����Ϊ���װ���
    int 0x10
    

    mov ah,0x02				;���λ�ó�ʼ��
    mov dx,0
    mov bh,0
    mov dh,0x0
    mov dl,0x0
    int 0x10

    ;------------------
    ;��ȡӲ��1-10����
    mov ebx,LOADER_SECTOR_LBA 		;LBA������
    mov cx,LOADER_SECTOR_COUNT		;��ȡ������
    mov di,LOADER_BASE_ADDR			;д���ڴ��ַ
    call Func_ReadLBA16
    
    jmp LOADER_BASE_ADDR

; ------------------------------------------------------------------------
; ��ȡ����:Func_ReadLBA16
; ����:
; ebx �����߼���
; cx �����������,8λ
; di ��ȡ���д���ڴ��ַ
; ------------------------------------------------------------------------	
Func_ReadLBA16:
    ;���ö�ȡ��������
    mov al,cl
    mov dx,0x1F2
    out dx,al
    
    ;����lba��ַ
    ;���õ�8λ
    mov al,bl
    mov dx,0x1F3
    out dx,al
    
    ;������8λ
    shr ebx,8
    mov al,bl
    mov dx,0x1F4
    out dx,al
    
    ;���ø�8λ
    shr ebx,8
    mov al,bl
    mov dx,0x1F5
    out dx,al
    
    ;���ø�4λ��device
    shr ebx,8
    and bl,0x0F
    or bl,0xE0
    mov al,bl
    mov dx,0x1F6
    out dx,al
        
    ;����commond
    mov al,0x20
    mov dx,0x1F7
    out dx,al

.check_status:;������״̬
    nop
    in al,dx
    and al,0x88			;��4λΪ1��ʾӲ��׼�������ݴ��䣬��7λΪ1��ʾӲ��æ
    cmp al,0x08
    jnz .check_status   ;��������û׼���ã�����ѭ�����
    

        
    ;����ѭ��������cx
    mov ax,cx 			;�˷�ax���Ŀ�������
    mov dx,256
    mul dx
    mov cx,ax			;ѭ������ = ������ x 512 / 2 
    mov bx,di
    mov dx,0x1F0
    
.read_data: 				
    in ax,dx			;��ȡ����
    mov [bx],ax			;�������ݵ��ڴ�
    add bx,2    		;��ȡ��ɣ��ڴ��ַ����2���ֽ�
    
    loop .read_data
    ret


FillSector:
    resb    510-($-$$)       	;����ǰ��$������(1FE)�����
    db      0x55, 0xaa
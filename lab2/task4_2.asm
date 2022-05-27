;Rats OS
;Tab=4
[bits 16]

section loader vstart=LOADER_BASE_ADDR ;ָ�������ƫ�ƵĻ���ַ

;----------- loader const ------------------
LOADER_BASE_ADDR 		equ 0x9000  ;�ڴ��ַ0x9000
;---------------------------------------	
	jmp Entry
	
;�����������
Entry:
	

	;---------------------------
    ;����ַ���
    mov si,HelloMsg			;��HelloMsg�ĵ�ַ����si
    mov dh,0				;������ʾ��
	mov dl,0				;������ʾ��
    call Func_Sprint			;���ú���

	
	jmp $			;��CPU���𣬵ȴ�ָ��


		
; ------------------------------------------------------------------------
; ��ʾ�ַ�������:Func_Sprint
; ����:
; si = �ַ�����ʼ��ַ,
; dh = ��N�У�0��ʼ
; dl = ��N�У�0��ʼ
; ------------------------------------------------------------------------
Func_Sprint:
            mov cx,0			;BIOS�жϲ�������ʾ�ַ�������
            mov bx,si
    .len:;��ȡ�ַ�������
            mov al,[bx]			;��ȡ1���ֽڵ�al
            inc bx				;��ȡ�¸��ֽ�
            cmp al,0			;�Ƿ���0����
            je .sprint
            inc	cx				;������
            jmp .len
    .sprint:;��ʾ�ַ���
            mov bx,si
            mov bp,bx
            mov bx,ds
            mov es,bx			;BIOS�жϲ���������[ES:BP]Ϊ��ʾ�ַ�����ʼ��ַ

            mov ah,0x13			;BIOS�жϲ������ж�ģʽ
            mov al,0x01			;BIOS�жϲ����������ʽ
            mov bh,0x0			;BIOS�жϲ�����ָ����ҳΪ0
            mov bl,0x1F			;BIOS�жϲ�������ʾ���ԣ�ָ����ɫ����			
            int 0x10			;����BIOS�жϲ����Կ�������ַ���
            ret
; ------------------------------------------------------------------------
;׼����ʾ�ַ���
HelloMsg: db "hello world!",0
	times	512-($-$$) db  0 ; ����ǰ��$������(1FE)�����	
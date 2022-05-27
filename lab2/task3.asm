[bits 16]

    org     0x7c00 			;ָ�������ƫ�ƵĻ���ַ
    
    jmp     Entry			;��ת���������
    db 		0x90
    db      "RATSBOOT"              
;�������
Entry:

Clear_Screen: 				;�����Ļ	    
    mov ah,0x06				
    mov bh,0x07					
    mov al,0
    mov cx,0   
    mov dx,0xffff  
    mov bh,0x17				;����Ϊ���װ���
    int 0x10
    
Clear_Cursor: 				; ���λ�ó�ʼ��
    mov ah,0x02				
    mov bh,0
    mov dx,0
    int 0x10

Fin:
	hlt
    jmp Fin				;������ѭ������������ִ�С�

Fill_Sector:
	resb    510-($-$$)       	;����ǰ��$������(1FE)�����
	db      0x55, 0xaa
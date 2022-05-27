	;RATSBOOT
	;TAB=4
	
	;���峣��
	DISC_ADDR 		EQU 0x8000		;���̵�һ��������ʼ�����ص��ڴ滺��ĵ�ַ
	SECTOR_NUM 		EQU 18		;��ȡ������
	CYLINDER_NUM	EQU	10			;��ȡ������
	
			ORG	0x7c00	;ָ�������ƫ�ƵĻ���ַ
	
	;��������Ǳ�׼FAT32	��ʽ����ר�õĴ���
	
			JMP		Entry
	
			DB      0x90                ;nop,0x02
			DB      "RATSBOOT"          ;��8�ֽڣ������������ƿ�����������ַ���
			DW      512                 ;ÿ��������sector���Ĵ�С������Ϊ512 �ֽڣ�
			DB      8                   ;�أ�cluster ���Ĵ�С��ÿ����Ϊ8��������
			DW      584                 ;����������,������������
			DB      2                   ;FAT�ĸ���������Ϊ2��
			DW      0                   ;����Ŀ¼��Ŀ����
			DW      0                   ;���������������0����ʹ��ƫ��0x20����4�ֽ�ֵ��
			DB      0x00f8              ;���̽�������
			DW      0                   ;��FAT16��ÿ���ļ�����������
			DW      63                  ;ÿ���ŵ�������
			dw      255                 ;��ͷ��
			dd      63                  ;��������
			dd      3902913             ;���̴�С���ܹ����������������65535���μ�ƫ��0x13��
			dd      3804                ;ÿ���ļ�������������3804������
	
			dw      0                   ;Flagss
			dw      0                   ;�汾��
			dd      2                   ;��Ŀ¼��ʼ��
	
			dw      1                   ;FSInfo����
			dw      6                   ;������������
			times 12 db 0               ;����δʹ��
	
			DW      0                   ;����ϵͳ����������
			db      0x80                ;BIOS�豸����
			db      0                   ;δʹ��
			db      0x29                ;���
			DD      0xffffffff          ;���к�
			DB      "HELLO-OS   "       ;(11�ֽ�)�������ƣ���ꡣ�ַ������ȹ̶�
			DB      "FAT32   "          ;(8�ֽ�)FAT�ļ�ϵͳ���͡� 0x52
	
			times 12 db 0
	
	;�����������
	Entry:
			MOV	AX,0				;��ʼ���Ĵ���
			MOV	SS,AX
			MOV	SP,0x7c00
			MOV	DS,AX
	
			MOV DI,StartMessage	;��Message1�εĵ�ַ����SI
			CALL DisplayStr		;���ú���
			MOV DI,BootMessage	;��Message1�εĵ�ַ����SI
			ADD DH,1
			CALL DisplayStr		;���ú���


	;��ȡ���̳�ʼ��
			MOV	AX,DISC_ADDR/0x10	;���ô��̶�ȡ�Ļ�����������ַΪES=0x820��[ES:BX]=ES*0x10+BX
			MOV	ES,AX				;BIOS�жϲ�����ES:BX���������ĵ�ַ
	
			MOV	CH,0				;��������Ϊ0
			MOV	DH,0				;���ô�ͷΪ0
			MOV	CL,1				;��������Ϊ2
	
	ReadSectorLoop:
			CALL ReadDisk0;			;��ȡһ������
	
	;׼����һ������
	ReadNextSector:
			MOV	AX,ES
			ADD	AX,0x0020			
			MOV	ES,AX				;�ڴ浥Ԫ��ַ����0x20(512�ֽ�)��[ES+0x20:]
			ADD	CL,1				;��ȡ����������+1
			CMP	CL,SECTOR_NUM		;�ж��Ƿ��ȡ��18����
			JBE	ReadSectorLoop		;����cmp�ж�(<=)���Ϊtrue����ת��DisplayError
	
	;��ȡ��һ���ͷ��ѭ����ȡ����
			MOV	CL,1				;��������Ϊ0
			ADD	DH,1				;���ô�ͷ����+1:��ȡ��һ����ͷ
			CMP	DH,2				;�жϴ�ͷ�Ƿ��ȡ���
			JB	ReadSectorLoop		;����cmp�ж�(<)���Ϊtrue����ת��DisplayError
	
			MOV	DH,0				;���ô�ͷΪ0
			ADD	CH,1				;�����������+1;��ȡ��һ����
			CMP	CH,CYLINDER_NUM		;�ж��Ƿ��Ѿ���ȡ10������
			JB	ReadSectorLoop		;����cmp�ж�(<)���Ϊtrue����ת��DisplayError
	
	;LoadSuccess:
	    MOV DI,Succmsg
	    MOV DH,3
	    CALL DisplayStr            ;�˴�����ע�͵������ܵ���INT��ԭ������
	
	;����ִ��boot�ļ�:
			;MOV	[0x0ff0],CH			;���ܹ���ȡ���������洢���ڴ浥Ԫ��
			;JMP 0xc200				;��תִ�����ڴ浥Ԫ0xc200�Ĵ���


	GoLoader:
			MOV	[0x0ff0],CH			;���ܹ���ȡ���������洢���ڴ浥Ԫ��
			JMP	0xc200				;��תִ�����ڴ浥Ԫ0xc200�Ĵ���:DISC_ADDR-0x200+0x4200
									;(����������ʼ��ַ0x8000+���̴���:boot�ļ���ʼ0x4200)
	
	LoadError:
			MOV DI,Errormsg
			MOV DH,3
			CALL DisplayStr	;�������ʧ����ʾ���ش���
	
	;�������
	Fin:
		HLT						;��CPU���𣬵ȴ�ָ�
		JMP	Fin


	; ------------------------------------------------------------------------
	; ��ȡһ����������:ReadDisk0
	; ------------------------------------------------------------------------
	; ����:ES:BS ��������ַ��CH���棬DH��ͷ��CL������AL������=1,DL������=0x
	; ------------------------------------------------------------------------
	ReadDisk0:
	
			MOV	SI,0				;��ʼ����ȡʧ�ܴ���������ѭ������
	
	;Ϊ�˷�ֹ��ȡ����ѭ����ȡ5��
	;����BIOS��ȡһ������
	ReadFiveLoop:
	
			MOV	AH,0x02				;BIOS�жϲ�����������
			MOV	AL,1				;BIOS�жϲ�������ȡ������
			MOV	BX,0
			MOV	DL,0x00				;BIOS�жϲ��������ö�ȡ������Ϊ����
			INT	0x13				;����BIOS�жϲ������̣���ȡ����
			JNC	ReadEnd				;������ת�������ɹ���λ��־=0������תִ��ReadNextSector
	
			ADD	SI,1				;ѭ����ȡ��������+1
			CMP	SI,5				;�ж��Ƿ��Ѿ���ȡ����5��
			JAE	LoadError			;����cmp�ж�(>=)���Ϊtrue����ת��DisplayError
	
			MOV	AH,0x00				;BIOS�жϲ���������ϵͳ��λ
			MOV	DL,0x00				;BIOS�жϲ��������ö�ȡ������Ϊ����
			INT	0x13				;����BIOS�жϲ������̣�����ϵͳ��λ
			JMP	ReadFiveLoop
	;������ȡ���
	ReadEnd:
			RET
	
	; ------------------------------------------------------------------------
	; ��ʾ�ַ�������:DisplayStr
	; ------------------------------------------------------------------------
	; ����:SI:�ַ�����ʼ��ַ, DHΪ��N��
	; ------------------------------------------------------------------------
	DisplayStr:
		MOV CX,0			;BIOS�жϲ�������ʾ�ַ�������
		MOV BX,DI
	.1:;��ȡ�ַ�������
		MOV AL,[BX]			;��ȡ1���ֽڡ��������ΪAL
		ADD BX,1			;��ȡ�¸��ֽ�
		CMP AL,0			;�Ƿ���0����
		JE .2
		ADD	CX,1			;������
		JMP .1
	.2:;��ʾ�ַ���
		MOV BX,DI
		MOV BP,BX
		MOV AX,DS
		MOV ES,AX				;BIOS�жϲ���������[ES:BP]Ϊ��ʾ�ַ�����ʼ��ַ
	
		MOV AH,0x13				;BIOS�жϲ�������ʾ���ִ�
		MOV AL,0x01				;BIOS�жϲ������ı������ʽ(40��25 16ɫ �ı�)
		MOV BH,0x0				;BIOS�жϲ�����ָ����ҳΪ0
		MOV BL,0x0c				;BIOS�жϲ�����ָ����ɫ����07			
		MOV DL,0				;�к�Ϊ0
		INT 0x10				;����BIOS�жϲ����Կ�������ַ�
		RET
	
	;���ݳ�ʼ��
	StartMessage: 	DB "hello,Adria's CHS call",0
	BootMessage: 	DB "booting............",0
	Errormsg: 		DB "  ",0
	Succmsg:  		DB " ",0
	
	FillSector:
		RESB	510-($-$$)		;����ǰ��$������(1FE)�����
		DB		0x55, 0xaa
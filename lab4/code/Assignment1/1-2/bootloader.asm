	;RATSBOOT
	;TAB=4
	
	;定义常量
	DISC_ADDR 		EQU 0x8000		;磁盘第一个扇区开始，加载到内存缓冲的地址
	SECTOR_NUM 		EQU 18		;读取扇区数
	CYLINDER_NUM	EQU	10			;读取柱面数
	
			ORG	0x7c00	;指明程序的偏移的基地址
	
	;以下这段是标准FAT32	格式软盘专用的代码
	
			JMP		Entry
	
			DB      0x90                ;nop,0x02
			DB      "RATSBOOT"          ;（8字节）启动区的名称可以是任意的字符串
			DW      512                 ;每个扇区（sector）的大小（必须为512 字节）
			DB      8                   ;簇（cluster ）的大小（每个簇为8个扇区）
			DW      584                 ;保留扇区数,包括启动扇区
			DB      2                   ;FAT的个数（必须为2）
			DW      0                   ;最大根目录条目个数
			DW      0                   ;总扇区数（如果是0，就使用偏移0x20处的4字节值）
			DB      0x00f8              ;磁盘介质描述
			DW      0                   ;（FAT16）每个文件分配表的扇区
			DW      63                  ;每个磁道扇区数
			dw      255                 ;磁头数
			dd      63                  ;隐藏扇区
			dd      3902913             ;磁盘大小，总共扇区数（如果超过65535，参见偏移0x13）
			dd      3804                ;每个文件分配表的扇区，3804个扇区
	
			dw      0                   ;Flagss
			dw      0                   ;版本号
			dd      2                   ;根目录启始簇
	
			dw      1                   ;FSInfo扇区
			dw      6                   ;启动扇区备份
			times 12 db 0               ;保留未使用
	
			DW      0                   ;操作系统自引导代码
			db      0x80                ;BIOS设备代号
			db      0                   ;未使用
			db      0x29                ;标记
			DD      0xffffffff          ;序列号
			DB      "HELLO-OS   "       ;(11字节)磁盘名称，卷标。字符串长度固定
			DB      "FAT32   "          ;(8字节)FAT文件系统类型。 0x52
	
			times 12 db 0
	
	;程序核心内容
	Entry:
			MOV	AX,0				;初始化寄存器
			MOV	SS,AX
			MOV	SP,0x7c00
			MOV	DS,AX
	
			MOV DI,StartMessage	;将Message1段的地址放入SI
			CALL DisplayStr		;调用函数
			MOV DI,BootMessage	;将Message1段的地址放入SI
			ADD DH,1
			CALL DisplayStr		;调用函数


	;读取磁盘初始化
			MOV	AX,DISC_ADDR/0x10	;设置磁盘读取的缓冲区基本地址为ES=0x820。[ES:BX]=ES*0x10+BX
			MOV	ES,AX				;BIOS中断参数：ES:BX＝缓冲区的地址
	
			MOV	CH,0				;设置柱面为0
			MOV	DH,0				;设置磁头为0
			MOV	CL,1				;设置扇区为2
	
	ReadSectorLoop:
			CALL ReadDisk0;			;读取一个扇区
	
	;准备下一个扇区
	ReadNextSector:
			MOV	AX,ES
			ADD	AX,0x0020			
			MOV	ES,AX				;内存单元基址后移0x20(512字节)。[ES+0x20:]
			ADD	CL,1				;读取扇区数递增+1
			CMP	CL,SECTOR_NUM		;判断是否读取到18扇区
			JBE	ReadSectorLoop		;上面cmp判断(<=)结果为true则跳转到DisplayError
	
	;读取另一面磁头。循环读取柱面
			MOV	CL,1				;设置柱面为0
			ADD	DH,1				;设置磁头递增+1:读取下一个磁头
			CMP	DH,2				;判断磁头是否读取完毕
			JB	ReadSectorLoop		;上面cmp判断(<)结果为true则跳转到DisplayError
	
			MOV	DH,0				;设置磁头为0
			ADD	CH,1				;设置柱面递增+1;读取下一柱面
			CMP	CH,CYLINDER_NUM		;判断是否已经读取10个柱面
			JB	ReadSectorLoop		;上面cmp判断(<)结果为true则跳转到DisplayError
	
	;LoadSuccess:
	    MOV DI,Succmsg
	    MOV DH,3
	    CALL DisplayStr            ;此处必须注释掉，不能调用INT。原因不明。
	
	;加载执行boot文件:
			;MOV	[0x0ff0],CH			;将总共读取的柱面数存储在内存单元中
			;JMP 0xc200				;跳转执行在内存单元0xc200的代码


	GoLoader:
			MOV	[0x0ff0],CH			;将总共读取的柱面数存储在内存单元中
			JMP	0xc200				;跳转执行在内存单元0xc200的代码:DISC_ADDR-0x200+0x4200
									;(启动扇区开始地址0x8000+软盘代码:boot文件开始0x4200)
	
	LoadError:
			MOV DI,Errormsg
			MOV DH,3
			CALL DisplayStr	;如果加载失败显示加载错误
	
	;程序挂起
	Fin:
		HLT						;让CPU挂起，等待指令。
		JMP	Fin


	; ------------------------------------------------------------------------
	; 读取一个扇区函数:ReadDisk0
	; ------------------------------------------------------------------------
	; 参数:ES:BS 缓冲区地址，CH柱面，DH磁头，CL扇区，AL扇区数=1,DL驱动器=0x
	; ------------------------------------------------------------------------
	ReadDisk0:
	
			MOV	SI,0				;初始化读取失败次数，用于循环计数
	
	;为了防止读取错误，循环读取5次
	;调用BIOS读取一个扇区
	ReadFiveLoop:
	
			MOV	AH,0x02				;BIOS中断参数：读扇区
			MOV	AL,1				;BIOS中断参数：读取扇区数
			MOV	BX,0
			MOV	DL,0x00				;BIOS中断参数：设置读取驱动器为软盘
			INT	0x13				;调用BIOS中断操作磁盘：读取扇区
			JNC	ReadEnd				;条件跳转，操作成功进位标志=0。则跳转执行ReadNextSector
	
			ADD	SI,1				;循环读取次数递增+1
			CMP	SI,5				;判断是否已经读取超过5次
			JAE	LoadError			;上面cmp判断(>=)结果为true则跳转到DisplayError
	
			MOV	AH,0x00				;BIOS中断参数：磁盘系统复位
			MOV	DL,0x00				;BIOS中断参数：设置读取驱动器为软盘
			INT	0x13				;调用BIOS中断操作磁盘：磁盘系统复位
			JMP	ReadFiveLoop
	;扇区读取完成
	ReadEnd:
			RET
	
	; ------------------------------------------------------------------------
	; 显示字符串函数:DisplayStr
	; ------------------------------------------------------------------------
	; 参数:SI:字符串开始地址, DH为第N行
	; ------------------------------------------------------------------------
	DisplayStr:
		MOV CX,0			;BIOS中断参数：显示字符串长度
		MOV BX,DI
	.1:;获取字符串长度
		MOV AL,[BX]			;读取1个字节。这里必须为AL
		ADD BX,1			;读取下个字节
		CMP AL,0			;是否以0结束
		JE .2
		ADD	CX,1			;计数器
		JMP .1
	.2:;显示字符串
		MOV BX,DI
		MOV BP,BX
		MOV AX,DS
		MOV ES,AX				;BIOS中断参数：计算[ES:BP]为显示字符串开始地址
	
		MOV AH,0x13				;BIOS中断参数：显示文字串
		MOV AL,0x01				;BIOS中断参数：文本输出方式(40×25 16色 文本)
		MOV BH,0x0				;BIOS中断参数：指定分页为0
		MOV BL,0x0c				;BIOS中断参数：指定白色字体07			
		MOV DL,0				;列号为0
		INT 0x10				;调用BIOS中断操作显卡。输出字符
		RET
	
	;数据初始化
	StartMessage: 	DB "hello,Adria's CHS call",0
	BootMessage: 	DB "booting............",0
	Errormsg: 		DB "  ",0
	Succmsg:  		DB " ",0
	
	FillSector:
		RESB	510-($-$$)		;处理当前行$至结束(1FE)的填充
		DB		0x55, 0xaa
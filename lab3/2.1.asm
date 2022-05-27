SECTION MBR vstart=0x7c00    
;表示将起始地址设置为0x7c00——因为BIOS会将MBR程序加载到0x7c00处

    mov    sp, 0x7c00    
;根据已知，至少0x500-0x7DFF为可用区域，则将其当用作栈即可


;清空屏幕，使用BIOS提供的中断
    mov    ax, 0x600    
    mov    bx, 0x700    
    mov    cx, 0x0        
    mov    dx, 0x184f    
    int    0x10
;下面获取当前的光标位置
;    INT 0x10;    功能号:0x03    功能描述:获取当前光标位置
;    输入:
;        AH--功能号:    0x03
;        BH--带获取光标的页码号
;    输出:
;        CH--光标开始行
;        CL--光标结束行
;        DH--光标所在行号
;        DL--光标所在列号

;调用功能号为0x3的BIOS中断，获取当前光标位置的相关信息，并将相关信息保存在对应的寄存器中

    mov    ah, 0x03    
    mov    bx, 0        
    int    0x10

;    下面进行打印字符串
;    INT 0x10;    功能号:0x13    功能描述:打印出字符串
;    输入:
;        ES:BP--字符串地址
;        AH--功能号    0x13
;        AL--设置写字符串方式 1表示光标跟随移动
;        CX--字符串长度(不包括最后的0)
;        BH--设置要显示的页号
;        BL--设置字符属性 0x2表示黑底绿字

    mov    ax, cs
    mov    es, ax        
    mov    ax, String
    mov    bp, ax           
    mov    ax, 0x1301    
    mov    bx, 0x2        
    mov    cx, 0x12    
    int    0x10
;调用了能号为0x13的BIOS中断，将0:String地址处，长度为0x12（后期随长度进行修改）的字符串进行了输出，并且光标跟随移动
    jmp    $
    String db "Cursor behind me."
    times 510 - ($ - $$) db 0
    db    0x55, 0xaa
    Dn_Rt equ 1             ; D-Down,U-Up,R-right,L-Left
    Up_Rt equ 2
    Up_Lt equ 3
    Dn_Lt equ 4
    delay equ 1000        ; ��ʱ���ӳټ���,���ڿ��ƻ�����ٶ�
    ddelay equ 100          ; ��ʱ���ӳټ���,���ڿ��ƻ�����ٶ�

    org 7C00h               ; ����װ�ص�7C00h�������ŵ�����������¼
    
    mov ah,15              ;����
    int 10h
    mov ah,0
    int 10h

start:
    mov ax,cs               ; ��ʼ��
    mov es,ax               ; ES = CS
    mov ds,ax               ; DS = CS
    mov es,ax               ; ES = CS
    mov ax,0B800h
    mov gs,ax               ; GS = B800h��ָ���ı�ģʽ����ʾ������
    mov byte[char],'w'

loop1:
    dec word[count]         ; �ݼ���������
    jnz loop1               ; >0����ת;
    mov word[count],delay
    dec word[dcount]        ; �ݼ���������
    jnz loop1
    mov word[count],delay  ;��ʱ
    mov word[dcount],ddelay

    mov al,1
    cmp al,byte[rdul]
    jz  DnRt
    mov al,2
    cmp al,byte[rdul]
    jz  UpRt
    mov al,3
    cmp al,byte[rdul]
    jz  UpLt
    mov al,4
    cmp al,byte[rdul]
    jz  DnLt
 

DnRt:
    inc word[x]
    inc word[y]
    mov bx,word[x]
    mov ax,screenh
    sub ax,bx
    jz  dr2ur
    mov bx,word[y]
    mov ax,screenw
    sub ax,bx
    jz  dr2dl
    jmp show

dr2ur:
    mov word[x],paddingh
    mov byte[rdul],Up_Rt
    jmp show

dr2dl:
    mov word[y],paddingw
    mov byte[rdul],Dn_Lt
    jmp show


UpRt:
    dec word[x]
    inc word[y]
    mov bx,word[y]
    mov ax,screenw
    sub ax,bx
    jz  ur2ul
    mov bx,word[x]
    mov ax,-1
    sub ax,bx
    jz  ur2dr
    jmp show

ur2ul:
    mov word[y],paddingw
    mov byte[rdul],Up_Lt
    jmp show

ur2dr:
    mov word[x],1
    mov byte[rdul],Dn_Rt
    jmp show


UpLt:
    dec word[x]
    dec word[y]
    mov bx,word[x]
    mov ax,-1
    sub ax,bx
    jz  ul2dl
    mov bx,word[y]
    mov ax,-1
    sub ax,bx
    jz  ul2ur
    jmp show

ul2dl:
    mov word[x],1
    mov byte[rdul],Dn_Lt
    jmp show
ul2ur:
    mov word[y],1
    mov byte[rdul],Up_Rt
    jmp show

DnLt:
    inc word[x]
    dec word[y]
    mov bx,word[y]
    mov ax,-1
    sub ax,bx
    jz  dl2dr
    mov bx,word[x]
    mov ax,screenh
    sub ax,bx
    jz  dl2ul
    jmp show

dl2dr:
    mov word[y],1
    mov byte[rdul],Dn_Rt
    jmp show

dl2ul:
    mov word[x],paddingh
    mov byte[rdul],Up_Lt
    jmp show

show:
    xor ax,ax               ; �����Դ��ַ
    mov ax,word[x]
    mov bx,80
    mul bx
    add ax,word[y]
    mov bx,2
    mul bx
    mov bp,ax
    mov ah,[curcolor2]      ; ���ַ��ı���ɫ��ǰ��ɫ��Ĭ��ֵΪ07h������ĵ���
    inc byte[curcolor2]
    cmp byte[curcolor2], 0fh
    jnz skip
 
skip:
    mov al,byte[char]       ; AL = ��ʾ�ַ�ֵ��Ĭ��ֵΪ20h=�ո����
    mov word[gs:bp],ax      ; ��ʾ�ַ���ASCII��ֵ

    mov si, myinfo          ; ��ʾ������ѧ��
    mov di, 2
    mov cx, word[infolen]
loop2:                      ; ��ʾmyinfo�е�ÿ���ַ�
    mov al, byte[ds:si]
    inc si
    mov ah, [curcolor]      ; ����ɫ��ǰ��ɫ
    add byte[curcolor], 12h ; ��ɫ�������ֿ���������Դﵽ�����Ч��
    mov word [gs:di],ax
    add di,2
    loop loop2
    jmp loop1

end:
    jmp $                   ; ֹͣ��������ѭ��
    DataArea:
    count dw delay
    dcount dw ddelay
    rdul db Dn_Rt           ; �������˶�
    char db 0

    screenw equ 80          ; ��Ļ����ַ���
    screenh equ 25          ; ��Ļ�߶��ַ���
    x dw 2                  ; ��ʼ����
    y dw 0                  ; ��ʼ����
    paddingw equ screenw-2
    paddingh equ screenh-2

    myinfo db '                             zwq20337268                            '
    infolen dw $-myinfo     ; myinfo�ַ����ĳ���
    curcolor db 80h         ; ���浱ǰ�ַ���ɫ���ԣ�����myinfo
    curcolor2 db 09h        ; ���浱ǰ�ַ���ɫ���ԣ������ƶ����ַ�

    times 510-($-$$) db 0   ; ���0��һֱ����510�ֽ�
    db 55h, 0AAh            ; ����ĩβ�����ֽ�Ϊ0x55��0xAA
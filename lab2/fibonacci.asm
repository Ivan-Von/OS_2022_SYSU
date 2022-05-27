%include 'functions.s'  
  
section.text  
global _start  
_start:  
  
     mov ecx, 20          
     mov eax, 1             
     mov ebx, 1  
  
fibonacci:   
     call iprintLF   
     add ebx, eax  
     mov edx, eax  
     mov eax, ebx  
     mov ebx, edx  
     dec ecx  
     jnz fibonacci  
     call quit       
section.data  
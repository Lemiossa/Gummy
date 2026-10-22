;; io.asm
;; Criado por Matheus Leme da Silva

;; void io_wait(void);
global io_wait
io_wait:
    push ax
    mov al, 0
    out 0x80, al
    pop ax
    ret

;; Envia um byte para a porta de IO
;; void outb(unsigned short port, unsigned char value);
global outb
outb:
    push ebp
    mov ebp, esp
    push eax
    push edx
    mov dx, word[ebp+8]
    mov al, byte[ebp+12]
    out dx, al
    pop edx
    pop eax
    pop ebp
    ret

;; Envia uma word para a porta de IO
;; void outw(unsigned short port, unsigned short value);
global outw
outw:
    push ebp
    mov ebp, esp
    push eax
    push edx
    mov dx, word[ebp+8]
    mov ax, word[ebp+12]
    out dx, ax
    pop edx
    pop eax
    pop ebp
    ret

;; Envia um dword para a porta de IO
;; void outl(unsigned short port, unsigned int value);
global outl
outl:
    push ebp
    mov ebp, esp
    push eax
    push edx
    mov dx, word[ebp+8]
    mov eax, dword[ebp+12]
    out dx, eax
    pop edx
    pop eax
    pop ebp
    ret

;; Le um byte da porta de IO
;; unsigned char inb(unsigned short port);
global inb
inb:
    push ebp
    mov ebp, esp
    push edx
    mov dx, word[ebp+8]
    in al, dx
    pop edx
    pop ebp
    ret

;; Le uma word da porta de IO
;; unsigned short inw(unsigned short port);
global inw
inw:
    push ebp
    mov ebp, esp
    push edx
    mov dx, word[ebp+8]
    in ax, dx
    pop edx
    pop ebp
    ret

;; Le um dword da porta de IO
;; unsigned int inl(unsigned short port);
global inl
inl:
    push ebp
    mov ebp, esp
    push edx
    mov dx, word[ebp+8]
    in eax, dx
    pop edx
    pop ebp
    ret

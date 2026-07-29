;; io.asm
;; Created by Matheus Leme da Silva
bits 32

;; Out byte to IO port
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

;; Out word to IO port
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

;; Out dword to IO port
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

;; In byte to IO port
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

;; In word to IO port
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

;; In dword to IO port
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

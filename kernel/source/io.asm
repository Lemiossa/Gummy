;; io.asm
;; Created by Matheus Leme da Silva
BITS 32

;; Out byte to IO port
;; void outb(unsigned short port, unsigned char value);
GLOBAL outb
outb:
    PUSH EBP
    MOV EBP, ESP
    PUSH EAX
    PUSH EDX
    MOV DX, WORD[EBP+8]
    MOV AL, BYTE[EBP+12]
    OUT DX, AL
    POP EDX
    POP EAX
    POP EBP
    RET

;; Out word to IO port
;; void outw(unsigned short port, unsigned short value);
GLOBAL outw
outw:
    PUSH EBP
    MOV EBP, ESP
    PUSH EAX
    PUSH EDX
    MOV DX, WORD[EBP+8]
    MOV AX, WORD[EBP+12]
    OUT DX, AX
    POP EDX
    POP EAX
    POP EBP
    RET

;; Out dword to IO port
;; void outl(unsigned short port, unsigned int value);
GLOBAL outl
outl:
    PUSH EBP
    MOV EBP, ESP
    PUSH EAX
    PUSH EDX
    MOV DX, WORD[EBP+8]
    MOV EAX, DWORD[EBP+12]
    OUT DX, EAX
    POP EDX
    POP EAX
    POP EBP
    RET

;; In byte to IO port
;; unsigned char inb(unsigned short port);
GLOBAL inb
inb:
    PUSH EBP
    MOV EBP, ESP
    PUSH EDX
    MOV DX, WORD[EBP+8]
    IN AL, DX
    POP EDX
    POP EBP
    RET

;; In word to IO port
;; unsigned short inw(unsigned short port);
GLOBAL inw
inw:
    PUSH EBP
    MOV EBP, ESP
    PUSH EDX
    MOV DX, WORD[EBP+8]
    IN AX, DX
    POP EDX
    POP EBP
    RET

;; In dword to IO port
;; unsigned int inl(unsigned short port);
GLOBAL inl
inl:
    PUSH EBP
    MOV EBP, ESP
    PUSH EDX
    MOV DX, WORD[EBP+8]
    IN EAX, DX
    POP EDX
    POP EBP
    RET

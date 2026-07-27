;; gdt.asm
;; Created by Matheus Leme da Silva
BITS 32

;; void gdt_flush(GdtR *);
GLOBAL gdt_flush
gdt_flush:
    MOV EAX, [ESP+4]
    LGDT [EAX]
    JMP 0x08:flush
flush:
    MOV AX, 0x10
    MOV DS, AX
    MOV ES, AX
    MOV FS, AX
    MOV GS, AX
    MOV SS, AX
    RET

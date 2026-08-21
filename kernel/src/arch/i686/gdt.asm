;; gdt.asm
;; Created by Matheus Leme da Silva
bits 32

;; void gdt_flush(GDTR *);
global gdt_flush
gdt_flush:
    mov eax, [esp+4]
    lgdt [eax]
    jmp 0x08:flush
flush:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    ret

;; entry.asm
;; Created by Matheus Leme da Silva
bits 32

section .text
global _start
extern kmain
extern __bss_start, __bss_end

_start:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x7c00

    ;; Zero BSS
    cld
    xor al, al
    mov edi, __bss_start
    mov ecx, __bss_end
    sub ecx, edi
    rep stosb

    call kmain

.hang:
    cli
    hlt
    jmp .hang

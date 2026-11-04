;; entry.asm
;; Criado por Matheus Leme da Silva
bits 32
section .text

extern main
global _start
_start:
    call main
    ;; Executa o exit
    mov ebx, eax
    mov eax, 0
    int 0x80
    jmp $

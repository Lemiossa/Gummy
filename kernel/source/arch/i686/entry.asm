;; entry.asm
;; Created by Matheus Leme da Silva
BITS 32

SECTION .text
GLOBAL _start
EXTERN kmain
EXTERN __bss_start, __bss_end

_start:
    MOV AX, 0x10
    MOV DS, AX
    MOV ES, AX
    MOV FS, AX
    MOV GS, AX
    MOV SS, AX
    MOV ESP, 0x7C00

    ;; Zero BSS
    CLD
    XOR AL, AL
    MOV EDI, __bss_start
    MOV ECX, __bss_end
    SUB ECX, EDI
    REP STOSB

    CALL kmain

.hang:
    CLI
    HLT
    JMP .hang

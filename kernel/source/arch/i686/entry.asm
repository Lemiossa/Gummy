;; entry.asm
;; Created by Matheus Leme da Silva
BITS 32

SECTION .text
GLOBAL _start
EXTERN kmain

_start:
    MOV AX, 0x10
    MOV DS, AX
    MOV ES, AX
    MOV FS, AX
    MOV GS, AX
    MOV SS, AX
    MOV ESP, 0x7C00

    CALL kmain

.hang:
    CLI
    HLT
    JMP .hang

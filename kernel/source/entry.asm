;; entry.asm
;; 32-bit protected mode entry point for Bitix kernel
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

    MOV ESP, stack_top

    CALL kmain

.hang:
    CLI
    HLT
    JMP .hang

SECTION .bss
ALIGN 16
stack_bottom:
    RESB 16384
stack_top:

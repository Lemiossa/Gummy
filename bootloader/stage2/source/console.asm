;; console.asm
;; Created by Matheus Leme da Silva
%IFNDEF CONSOLE_ASM
%DEFINE CONSOLE_ASM

BITS 16

;; Prints a string on the screen
;; DS:SI: String pointer
;; Returns: None
print_string:
    PUSH AX
    PUSH SI
    MOV AH, 0x0E
.loop:
    LODSB
    TEST AL, AL
    JZ .end
    INT 0x10
    JMP .loop
.end:
    POP SI
    POP AX
    RET

%ENDIF ;; CONSOLE_ASM

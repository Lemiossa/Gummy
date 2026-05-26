;; console.asm
;; Created by Matheus Leme da Silva
%IFNDEF CONSOLE_ASM
%DEFINE CONSOLE_ASM

BITS 16

;; Prints a string on the screen
;; DS:SI: String pointer
;; Returns: None
console_print_string:
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

;; Prints a nibble(4-bit)
;; AL: Nibble
;; Returns: None
console_print_nibble:
    PUSH AX
    AND AL, 0x0F
    ;; If AL < 10: print AL + '0'
    ;; else: print AL + 'A' - 10
    MOV AH, 0x0E
    CMP AL, 10
    JAE .else
    ADD AL, '0'
    JMP .end
.else:
    ADD AL, 'A' - 10
.end:
    INT 0x10
    MOV DX, 0x00
    MOV AH, 0x01
    INT 0x14
    POP AX
    RET

;; Prints a byte(8-bit)
;; AL: Byte
;; Returns: None
console_print_byte:
    PUSH AX
    SHR AL, 4
    CALL console_print_nibble
    POP AX
    CALL console_print_nibble
    RET

%ENDIF ;; CONSOLE_ASM

;; console.asm
;; Created by Matheus Leme da Silva
%ifndef console_asm
%define console_asm

bits 16

;; Prints a string on the screen
;; DS:SI: String pointer
;; Returns: None
console_print_string:
    push ax
    push si
    mov ah, 0x0e
.loop:
    lodsb
    test al, al
    jz .end
    int 0x10
    jmp .loop
.end:
    pop si
    pop ax
    ret

;; Prints a nibble(4-bit)
;; AL: Nibble
;; Returns: None
console_print_nibble:
    push ax
    and al, 0x0f
    ;; If AL < 10: print AL + '0'
    ;; else: print AL + 'A' - 10
    mov ah, 0x0e
    cmp al, 10
    jae .else
    add al, '0'
    jmp .end
.else:
    add al, 'A' - 10
.end:
    int 0x10
    mov dx, 0x00
    mov ah, 0x01
    int 0x14
    pop ax
    ret

;; Prints a byte(8-bit)
;; AL: Byte
;; Returns: None
console_print_byte:
    push ax
    shr al, 4
    call console_print_nibble
    pop ax
    call console_print_nibble
    ret

%endif ;; CONSOLE_ASM

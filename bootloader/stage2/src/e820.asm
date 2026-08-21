;; e820.asm
;; Created by Matheus Leme da Silva
%ifndef E820_ASM
%define E820_ASM
bits 16

;; Reads de E820 table to 0x500
;; Structure:
;; word: Num of entries
;; ...: entries
;; Returns:
;; CF=1 if an error occours
;; Entries are stored using 24 bytes each.
;; In this code, I assume there won't be enough entries to exceed at least 0x5000 (a reasonable distance from 0x7C00, where the stack is located).
e820_init:
    push ax
    push bx
    push cx
    push dx
    push di
    push es
    xor ax, ax
    mov es, ax
    mov di, 0x502
    mov word[es:0x500], 0
    xor ebx, ebx
.loop:
    mov eax, 0xE820
    mov edx, 0x534D4150
    mov ecx, 24
    int 0x15
    ;; Error
    jc .error
    cmp eax, 0x534D4150
    jne .error
    inc word[es:0x500]
    ;; End
    test ebx, ebx
    jz .end
    add di, 24
    jmp .loop
.end:
    clc
    jmp .ret
.error:
    stc
.ret:
    pop es
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

%endif ;; E820_ASM

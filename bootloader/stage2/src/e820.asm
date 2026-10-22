;; e820.asm
;; Criado por Matheus Leme da Silva
%ifndef E820_ASM
%define E820_ASM
bits 16

;; Le a tabela E820 para 0x500
;; Estrutura:
;; word: Numero de entradas
;; ...: entradas
;; Retorna:
;; CF=1 se ocorrer um erro
;; Cada entrada e armazenada usando 24 bytes.
;; Neste codigo, assumo que nao havera entradas suficientes para passar de 0x5000 (uma distancia razoavel de 0x7C00, onde a pilha fica).
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
    ;; Erro
    jc .error
    cmp eax, 0x534D4150
    jne .error
    inc word[es:0x500]
    ;; Fim
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

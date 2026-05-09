;; console.asm
;; Criado por Matheus Leme Da Silva
%ifndef _CONSOLE_ASM_
%define _CONSOLE_ASM_

;; %define T80x50                          ;; Descomente para modo 80x50

;; Inicializa o console
section .text
console_init:
	;; Define modo texto 80x25 (3) ou 80x50 (83)
	mov ax, 3
	int 0x10

	;; Define modo 80x50 se configurado
	%ifdef T80x50
	mov ax, 0x1112
	int 0x10
	%endif ;; T80x50
	ret

;; Exibe um caractere na tela com os atributos atuais e posição do cursor
;; AL: caractere
section .text
print_char:
	push ax

	;; DEBUG: Exibe na serial se DEBUG estiver definido
%ifdef DEBUG
	push dx
	xor dx, dx
	mov ah, 0x01
	int 0x14
	pop dx
%endif ;; DEBUG

	mov ah, 0x0E
	int 0x10

	pop ax
	ret

;; Exibe uma string terminada em zero na tela
;; DS:SI: ponteiro para a string
section .text
print_string:
	push ax
	push si
.loop:
	lodsb  ;; AL = DS:SI++
	test al, al
	jz .end
	call print_char
	jmp .loop
.end:
	pop si
	pop ax
	ret

;; Macro para exibir strings inline
%macro print 1+
section .data
%%string: db %1, 0
section .text
	push si
	mov si, %%string
	call print_string
	pop si
%endmacro

;; Macro para nova linha
%macro newline 0
section .text
	push ax
	mov al, 0x0D
	call print_char
	mov al, 0x0A
	call print_char
	pop ax
%endmacro

;; Converte um nibble para caractere hexadecimal
;; AL: nibble (0x0-0xF)
;; Retorna: AL: caractere hexadecimal
section .text
nibble_to_hex:
	push cx
	mov cl, al
	and cl, 0x0F
	cmp cl, 9
	jbe .digit
	sub cl, 10
	add cl, 'A'
	jmp .end
.digit:
	add cl, '0'
.end:
	mov al, cl
	pop cx
	ret

;; Exibe um valor de 4 bits em hexadecimal
;; AL: nibble
section .text
print_nibble:
	push ax
	and al, 0x0F
	cmp al, 9
	jbe .digit
	sub al, 10
	add al, 'A'
	jmp .end
.digit:
	add al, '0'
.end:
	call print_char
	pop ax
	ret

;; Exibe um valor de 8 bits em hexadecimal
;; 1: r8
%macro print_hex_byte 1
section .text
	push ax
	mov al, %1
	shr al, 4
	call print_nibble
	pop ax
	push ax
	mov al, %1
	call print_nibble
	pop ax
%endmacro

;; Exibe um valor de 16 bits em hexadecimal
;; 1: r16
%macro print_hex_word 1
section .text
	push bx
	mov bx, %1
	print_hex_byte bh
	print_hex_byte bl
	pop bx
%endmacro

;; Exibe um valor de 32 bits em hexadecimal
;; 1: r16 alto
;; 2: r16 baixo
%macro print_hex_dword 2
section .text
	push cx
	mov cx, %1
	print_hex_word cx
	mov cx, %2
	print_hex_word cx
	pop cx
%endmacro

%endif ;; _CONSOLE_ASM_

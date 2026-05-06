;; console.asm
;; Created by Matheus Leme Da Silva
%ifndef _CONSOLE_ASM_
%define _CONSOLE_ASM_

;; %define T80x50                          ;; Uncomment for 80x50 mode

;; Initializes console
section .text
console_init:
	;; Set text mode 80x25 (3) or 80x50 (83)
	mov ax, 3
	int 0x10

	;; Set 80x50 mode if configured
	%ifdef T80x50
	mov ax, 0x1112
	int 0x10
	%endif ;; T80x50
	ret

;; Prints a character on the screen with current attributes and cursor position
;; AL: character
section .text
print_char:
	push ax

	;; DEBUG: Print on serial if DEBUG is defined
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

;; Prints a string ending with zero on the screen
;; DS:SI: pointer to string
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

;; Macro for printing inline strings
%macro print 1+
section .data
%%string: db %1, 0
section .text
	push si
	mov si, %%string
	call print_string
	pop si
%endmacro

;; Macro for new line
%macro newline 0
section .text
	push ax
	mov al, 0x0D
	call print_char
	mov al, 0x0A
	call print_char
	pop ax
%endmacro

;; Converts a nibble to hex character
;; AL: nibble (0x0-0xF)
;; Returns: AL: hex character
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

;; Prints a 4-bit value in hex
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

;; Prints an 8-bit value in hex
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

;; Prints a 16-bit value in hex
;; 1: r16
%macro print_hex_word 1
section .text
	push bx
	mov bx, %1
	print_hex_byte bh
	print_hex_byte bl
	pop bx
%endmacro

;; Prints a 32-bit value in hex
;; 1: high r16
;; 2: low r16
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

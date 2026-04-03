;; console.asm
;; Created by Matheus Leme Da Silva
%ifndef _CONSOLE_ASM_
%define _CONSOLE_ASM_
section .text

;; Prints a character on the screen
print_char:
	push ax
	
	;; Print on VGA
	mov ah, 0x0E
	int 0x10

	;; DEBUG: Print on serial
	%ifdef DEBUG
	push dx
	xor dx, dx
	mov ah, 0x01
	int 0x14
	pop dx
	%endif ;; DEBUG

	pop ax
	ret

;; Prints a string ending with zero on the screen
;; DS:SI: pointer to string
print_string:
	push ax
	push si
.loop:
	lodsb ;; al = ds:si++
	test al, al
	jz .end
	call print_char
	jmp .loop
.end:
	pop si
	pop ax
	ret

%macro print 1+
section .data
%%string: db %1, 0
section .text
	push si
	mov si, %%string
	call print_string
	pop si
%endmacro

%macro newline 0
	push ax
	mov al, 0x0D
	call print_char
	mov al, 0x0A
	call print_char
	pop ax
%endmacro

;; Prints a HEX 4-bit value in AL
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

;; Prints a HEX 8-bit value
;; 1: r8
%macro print_hex_byte 1
	push ax
	mov al, %1

	push ax
	;; Nibble 1
	shr al, 4
	call print_nibble
	pop ax

	;; Nibble 0
	call print_nibble

	pop ax
%endmacro

;; Prints a HEX 16-bit value
;; 1: r16
%macro print_hex_word 1
	push bx
	mov bx, %1
	print_hex_byte bh
	print_hex_byte bl
	pop bx
%endmacro

;; Prints a HEX 32-bit value
;; 1: high r16
;; 2: low r16
%macro print_hex_dword 2
	push cx
	mov cx, %1
	print_hex_word cx
	mov cx, %2
	print_hex_word cx
	pop cx
%endmacro

%endif ;; _CONSOLE_ASM_

;; console.asm
;; Created by Matheus Leme Da Silva
%ifndef _CONSOLE_ASM_
%define _CONSOLE_ASM_
section .text

;; Prints a string ending with zero on the screen
;; DS:SI: pointer to string
print_string:
	push ax
	push si
	mov ah, 0x0E
.loop:
	lodsb ;; al = ds:si++
	test al, al
	jz .end
	int 0x10
	jmp .loop
.end:
	pop si
	pop ax
	ret

%macro print 1+
	jmp %%print_the_string
section .data
%%string: db %1, 0
section .text
%%print_the_string:
	push si
	mov si, %%string
	call print_string
	pop si
%endmacro

%macro newline 0
	push ax
	mov ah, 0x0E
	mov al, 0x0D
	int 0x10
	mov al, 0x0A
	int 0x10
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
	mov ah, 0x0E
	int 0x10
	pop ax
	ret

;; Prints a HEX 8-bit value 
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
	ret
%endmacro

%endif ;; _CONSOLE_ASM_

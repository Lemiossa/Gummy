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
	jmp %%print
section .data
%%string:
	db %1, 0
section .text
%%print:
	push si
	mov si, %%string
	call print_string
	pop si
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

;; Prints a HEX 8-bit value in AL
;; AL: Byte
print_hex_byte:
	push ax
	;; Nibble 1
	shr al, 4
	call print_nibble
	pop ax
	;; Nibble 0
	call print_nibble
	
	ret

%endif ;; _CONSOLE_ASM_

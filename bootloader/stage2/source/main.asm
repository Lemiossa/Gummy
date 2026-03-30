;; main.asm
;; Created by Matheus Leme Da Silva 
section .text
org 0x7E00
bits 16

;; Bootloader main function
main:
	cli
	xor ax, ax
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, 0x7C00
	sti
	
	mov [drive], dl

	;; Set text mode
	mov ax, 0x0003
	int 0x10
	
	;; Set 8x8 font
	mov ax, 0x1112
	int 0x10
	
	call enable_a20_line

	mov al, 0
	mov cx, 0xFF
print_hex:
	call print_hex_byte
	inc al

	push ax
	mov ah, 0x0E
	mov al, ' '
	int 0x10
	pop ax
	
	loop print_hex

	cli
	hlt

%include "include/console.asm"
%include "include/a20.asm"

section .data
drive: db 0

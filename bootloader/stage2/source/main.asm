;; main.asm
;; Created by Matheus Leme Da Silva 
section .text
org 0x7E00
bits 16

;; Jmp to main before includes
jmp main

;; Begin includes
%include "console.asm"
%include "a20.asm"
%include "disk.asm"
;; End includes

;; Bootloader main function
main:
	cli
	xor ax, ax
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, 0x7C00
	sti
	newline

	mov [drive], dl
	
	;; Set font 8x8
	print "Setting font 8x8..."
	mov ax, 0x1112
	int 0x10
	print " Ok", 0x0D, 0x0A

	call set_drive
	call enable_a20_line
	cli
	hlt

section .data
drive: db 0

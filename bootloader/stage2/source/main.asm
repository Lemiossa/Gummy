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
	
	mov [drive], dl
	call enable_a20_line

	print "Hello World"
	cli
	hlt

section .data
drive: db 0

;; main.asm
;; Created by Matheus Leme Da Silva 
section .text
org 0x7E00
bits 16

%define DEBUG

;; Jmp to main before includes
jmp main

;; Begin includes
%include "console.asm"
%include "a20.asm"
%include "disk.asm"
%include "fat.asm"
;; End includes

section .text

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
	call console_init
	print "Booting..."
	newline

	;; Initially, only floppies
	xor dx, dx
	xor ax, ax
	mov bl, [drive]
	call fat_init
	jnc is_valid_fat
	panic "Is not valid FAT partition"
is_valid_fat:

	call enable_a20_line

	cli
	hlt

section .bss
drive: resb 0

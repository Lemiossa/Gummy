;; main.asm
;; Created by Matheus Leme Da Silva 
org 0x7E00
bits 16
section .text

;; %define DEBUG

;; Jmp to main before includes
jmp main

;; Begin includes
%include "console.asm"
%include "a20.asm"
%include "disk.asm"
%include "fat.asm"
;; End includes

;; Bootloader main function
section .text
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
	
	mov si, .fat_transfer_struct
	call fat_read
	jnc .ok
	print "Error!"
	jmp .halt
.ok: 
	print "Readed!"

.halt:
	cli
	hlt
section .data
.fat_transfer_struct:
	dw 0x0000, .path  ;; Seg is 0
	dw 0x1000, 0x0000 ;; 0x1000:0x0000
	dd 0 
	dd 100

.path: db "/subdir/text.txt", 0

section .bss
drive: resb 1

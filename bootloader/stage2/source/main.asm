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
	
	mov si, .text_path
	mov di, .entry
	call fat_find
	jnc .found
	print "NOT FOUND!"
	jmp .halt
.found:
	print "FOUND '"

	mov si, .entry+fat_entry.name

	mov cx, 11
.print_name:
	lodsb
	call print_char
	loop .print_name
	print "'", 0x0A
.halt:
	cli
	hlt
.text_path: db "/subdir/text.txt/", 0
section .bss
.entry: resb fat_entry_size

section .bss
drive: resb 1

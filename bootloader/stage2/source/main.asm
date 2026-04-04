;; main.asm
;; Created by Matheus Leme Da Silva 
section .text
org 0x7E00
bits 16

;; %define DEBUG

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

	print "Listing /:"
	newline
	xor bx, bx
	mov cx, 1
	call fat_list_tree

	print "Finding '"
	mov si, .name
	call print_string
	print "'..."
	mov di, .entry
	xor bx, bx
	call fat_find_in_dir
	jnc .found
	panic "Failed to find!"
.found:
	print " Found!"
	newline

	print "clus_low=0x"
	print_hex_word word [.entry+fat_entry.clus_low]

	cli
	hlt
.name: db "SUBDIR     "
section .bss
.entry: resb fat_entry_size

section .data
drive: db 0

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

;; List a directory tree in FAT
;; BX: Start cluster
;; CX: Depth
list_dir:
	push ax
	push bx
	push cx
	push dx

	xor ax, ax
	xor dx, dx
	mov di, .entry

.list_loop:
	call fat_read_dir
	jc .end
	
	test byte [.entry+fat_entry.attr], 0x08
	jnz .skip

	cmp byte [.entry+fat_entry.name], '.'
	je .no_print_dir
.print_name:
	push si
	push ax
	push cx
	
	test cx, cx
	jz .print_spaces.end

.print_spaces:
	mov al, ' '
	call print_char
	loop .print_spaces
.print_spaces.end:

	mov si, .entry+fat_entry.name
	mov cx, 11
.print_loop:
	lodsb
	call print_char
	loop .print_loop

	newline
	pop cx
	pop ax
	pop si

	test byte [.entry+fat_entry.attr], 0x10
	jz .no_print_dir
	push bx
	push cx
	inc cx
	mov bx, word [.entry+fat_entry.clus_low]
	call list_dir
	pop cx
	pop bx
.no_print_dir:

.skip:
	add ax, 1
	adc dx, 0
	jmp .list_loop

.end:
	pop dx
	pop cx
	pop bx
	pop ax
	ret
section .bss
.entry: resb fat_entry_size
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
	call list_dir

	cli
	hlt

section .data
drive: db 0

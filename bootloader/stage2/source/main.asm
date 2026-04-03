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

;; lists root dir using the FAT driver
list_root_dir:
	push ax
	push dx
	push bx
	xor ax, ax
	xor dx, dx
	mov bx, 0
	mov di, .entry
.loop:
	call fat_read_dir
	jc .end

	push ax
	push si
	push cx
	mov si, .entry+fat_entry.name
	mov cx, 0
.print_loop:
	cmp cx, 11
	jae .print_loop.end
	mov al, byte [si]
	call print_char
	inc si
	inc cx
	jmp .print_loop
.print_loop.end:
	newline
	
	pop cx
	pop si
	pop ax

	inc ax
	jmp .loop
.end:
	clc
	pop bx
	pop dx
	pop ax
	ret
.entry: times fat_entry_size db 0

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

	;; Initially, only floppies
	xor dx, dx
	xor ax, ax
	mov bl, [drive]
	call fat_init
	jnc is_valid_fat
	panic "Is not valid FAT partition"
is_valid_fat:

	call list_root_dir

	call enable_a20_line
	cli
	hlt

section .data
drive: db 0

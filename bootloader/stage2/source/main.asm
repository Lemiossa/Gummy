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

section .text
;; Finds a FAT entry
;; DS:SI: path
;; ES:DI: Out
;; Return nothing
;; Automatically handles error 
find:
	print "Finding "
	call print_string
	print "..."
	newline
	call fat_find
	jnc .normal
	print "Error!"
	jmp halt
.normal:
	mov si, di+fat_entry.name
	mov cx, 11
.print:
	lodsb 
	mov ah, 0x0E
	call print_char
	loop .print
	newline
	ret

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
	print "Bitix Bootloader"
	newline
	print "Build: ", __DATE__, " ", __TIME__
	newline
	newline

	print "Initializing..."
	newline

	;; Initialize FAT filesystem
	xor dx, dx
	xor ax, ax
	mov bl, [drive]
	call fat_init
	jnc .fat_ok
	print "Invalid FAT partition!"
	newline
	jmp halt
.fat_ok:

	;; Enable A20 line
	call enable_a20_line
	jnc .a20_ok
	print "Failed to enable A20 line!"
	newline
	jmp halt
.a20_ok:
	mov si, .path0
	mov di, .entry
	call find

	mov si, .path1
	call find

	jmp halt
.path0: db '/subdir', 0
.path1: db '/subdir/text.txt', 0
.entry: times fat_entry_size db 0

halt:
	print "System halted! Press any key to reboot.", 0x0D, 0x0A
	mov ah, 0x00
	int 0x16
	jmp 0xFFFF:0x0000


section .bss
drive: resb 1

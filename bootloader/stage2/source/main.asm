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
	print_title "Bitix"
	newline
	print "================"
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
	print_error "Invalid FAT partition!"
	jmp halt
.fat_ok:
	print_success "FAT OK"
	newline

;; Enable A20 line
	call enable_a20_line
	jnc .a20_ok
	jmp halt
.a20_ok:
	print_success "A20 OK"
	newline

halt:
	print "System halted! Press any key to reboot.", 0x0D, 0x0A
	cli
	hlt

section .bss
drive: resb 1

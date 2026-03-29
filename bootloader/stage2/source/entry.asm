section .entry
bits 16

global _start
_start:
	cli
	xor ax, ax
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, 0x7C00
	sti

	mov ah, 0x0E
	mov al, 'X'
	int 0x10

	cli
	hlt

;; disk.asm
;; Created by Matheus Leme Da Silva
%ifndef _DISK_ASM_
%define _DISK_ASM_
section .text
%include "console.asm"

sector_size:      equ 0x200

;; Sets drive to disk operations
;; DL: Drive number
set_drive:
	pusha
	mov [current_drive_number], dl
	call get_drive_parameters
	mov [current_sectors_per_track], cl
	mov [current_heads], dh
%ifdef DEBUG
	print "Number of heads: 0x"
	print_hex_word word [current_heads]
	newline
	
	print "Sectors per track: 0x"
	print_hex_word word [current_sectors_per_track]
	newline
%endif ;; DEBUG
	popa

	ret

;; Return drive parameters of a disk
;; Uses current_drive
;; Returns:
;; CL: Sectors per track
;; DH: Number of heads
;; CF if an error occurred
get_drive_parameters:
	push ax
	push di
	push es

	xor ax, ax
	mov es, ax

	clc
	mov ah, 0x08
	mov dl, [current_drive_number]
	xor di, di
	int 0x13
	jc .err

	;; CL[bits 0-5] = sectors per track
	;; DH = heads - 1
	and cl, 0x3F
	inc dh

	clc
	pop es
	pop di
	pop ax
	ret
.err:
	stc
	pop es
	pop di
	pop ax
	ret

;; Resets a disk
disk_reset:
	push ax
	push dx
	mov dl, [current_drive_number]
	mov ah, 0x00
	int 0x13
	pop dx
	pop ax
	ret

;; Reads a sector(DX:AX) from disk to memory(ES:BX)
;; DX:AX: LBA
;; ES:BX: Addr
read_sector:
	push ax
	push cx
	push dx

%ifdef DEBUG
	print "Reading sector: 0x"
	print_hex_dword dx, ax
	newline
%endif ;; DEBUG

	;; LBA -> CHS
	;; C = (LBA / sectors_per_track) / heads
	;; H = (LBA / sectors_per_track) % heads
	;; S = (LBA % sectors_per_track) + 1
	
	div word [current_sectors_per_track]
	;; AX = LBA / sectors_per_track
	;; DX = LBA % sectors_per_track
	inc dx
	xor dh, dh
	push dx
	
	xor dx, dx
	div word [current_heads]
	;; AX = (LBA / sectors_per_track) / heads
	;; DX = (LBA / sectors_per_track) % heads
	
	mov ch, al
	shl ah, 6
	mov cl, ah
	
	pop ax
	or cl, al

	shl dx, 8

	;; int13h ah=2 func
	;; Params:
	;; al = sector count
	;; ch = cylinder & 0xFF
	;; cl = (sector & 0x3F) | ((cylinder & 0xC000) >> 13)
	;; dh = head
	;; dl = drive
	;; es:bx = ptr

	mov si, 3
	jmp .try
.retry:
	call disk_reset
.try:
	clc
	mov ax, 0x0201 ;; read function, 1 sector
	mov dl, [current_drive_number]
	int 0x13
	jnc .no_err
	test si, si
	jz .err
	dec si
	jmp .retry
.no_err:

	clc
	pop dx
	pop cx
	pop ax
	ret
.err:
	stc
	pop dx
	pop cx
	pop ax
	ret

current_drive_number: db 0
current_sectors_per_track: dw 0
current_heads: dw 0

%endif ;; _DISK_ASM_


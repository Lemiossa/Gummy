;; disk.asm
;; Created by Matheus Leme Da Silva
%ifndef _DISK_ASM_
%define _DISK_ASM_
section .text
%include "console.asm"

;; Sets drive to disk operations
;; DL: Drive number
set_drive:
	print "Setting drive number to 0x"
	print_hex_byte dl
	newline

	mov [current_drive_number], dl
	call get_drive_parameters
	mov [current_sectors_per_track], cl
	mov [current_heads], dh
	ret

;; Return drive parameters of a disk
;; Return sectors per track in CL and number of heads in DH
;; Uses current_drive
get_drive_parameters:
	push ax
	push di
	push es

	xor ax, ax
	mov es, ax

	mov ah, 0x08
	mov dl, [current_drive_number]
	xor di, di
	int 0x13
	jc int13_failed

	;; CL[bits 0-5] = sectors per track
	;; DH = heads - 1
	and cl, 0x3F
	inc dh

	pop es
	pop di
	pop ax
	ret

;; Reads a sector(DX:AX) from disk to memory(ES:BX)
;; DX: LBA high
;; AX: LBA low
;; ES: Segment to load
;; BX: Offset to load
read_sector:
	push ax
	push cx
	push dx
	
	;; LBA -> CHS
	;; C = (LBA / sectors_per_track) / heads
	;; H = (LBA / sectors_per_track) % heads
	;; S = (LBA % sectors_per_track) + 1
	
	div word [current_sectors_per_track]
	;; AX = LBA / sectors_per_track
	;; DX = LBA % sectors_per_track
	inc dx
	mov dh, dl
	push dx
	
	xor dx, dx
	div word [current_heads]
	;; AX = (LBA / sectors_per_track) / heads
	;; DX = (LBA % sectors_per_track) % heads
	
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

	mov ax, 0x0201 ;; read function, 1 sector
	mov dl, [current_drive_number]
	int 0x13

	jc int13_failed
	
	pop dx
	pop cx
	pop ax
	ret

;; Prints int13 error message and halt the computer
int13_failed:
	print "int13 failed!"

	;; Get status of last operation
	mov ah, 0x01
	int 0x13
	jc .end
	print " code=0x"
	print_hex_byte ah
	newline
.end:
	cli
	hlt

current_drive_number: db 0
current_sectors_per_track: dw 0
current_heads: dw 0

%endif ;; _DISK_ASM_


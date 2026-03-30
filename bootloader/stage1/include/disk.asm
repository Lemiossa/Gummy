;; disk.asm
;; Created by Matheus Leme Da Silva
%ifndef _DISK_ASM_
%define _DISK_ASM_

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
	
	div word [sectors_per_track]
	;; AX = LBA / sectors_per_track
	;; DX = LBA % sectors_per_track
	inc dx
	mov dh, dl
	push dx
	
	xor dx, dx
	div word [heads]
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
	mov dl, [drive]
	int 0x13

	jc int13_failed
	
	pop dx
	pop cx
	pop ax
	ret

;; Prints int13 error message and halt the computer
int13_failed:
	mov si, int13_failed_message
	call print_string

int13_failed_message: db "Int13 failed!", 0x0D, 0x0A, 0

%endif ;; _DISK_ASM_

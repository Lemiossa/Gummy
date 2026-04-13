;; disk.asm
;; Created by Matheus Leme Da Silva
%ifndef _DISK_ASM_
%define _DISK_ASM_
%include "console.asm"

sector_size:      equ 0x200

;; Sets drive to disk operations
;; DL: Drive number
section .text
set_drive:
	pusha
	mov byte [current_drive_number], dl
	call get_drive_parameters
	mov byte [current_sectors_per_track], cl
	mov byte [current_heads], dh
	popa

	ret

;; Return drive parameters of a disk
;; Uses current_drive
;; Returns:
;; CL: Sectors per track
;; DH: Number of heads
;; CF if an error occurred
section .text
get_drive_parameters:
	push ax
	push di
	push es

	xor ax, ax
	mov es, ax

	clc
	mov ah, 0x08
	mov dl, byte [current_drive_number]
	xor di, di
	int 0x13
	jc .error

	;; CL[bits 0-5] = sectors per track
	;; DH = heads - 1
	and cl, 0x3F
	inc dh

	clc
	jmp .ret
.error:
	stc
.ret:
	pop es
	pop di
	pop ax
	ret

;; Resets a disk
section .text
disk_reset:
	push ax
	push dx
	clc
	mov dl, byte [current_drive_number]
	mov ah, 0x00
	int 0x13
	jc .error
	;; Carry is already clear
	jmp .ret
.error:
	stc
.ret:
	pop dx
	pop ax
	ret

;; Converts LBA to CHS
;; DX:AX: LBA
;; Returns:
;; int13h format:
;;    ch = cylinder low
;;    cl = sector | cylinder high
;;    dh = head
lba_to_chs:
	push bx
	;; LBA -> CHS
	;; C = (LBA / sectors_per_track) / heads
	;; H = (LBA / sectors_per_track) % heads
	;; S = (LBA % sectors_per_track) + 1

	xor bx, bx
	mov bl, byte [current_sectors_per_track]
	div bx
	;; AX = LBA / sectors_per_track
	;; DX = LBA % sectors_per_track
	xor dh, dh
	inc dx
	mov byte [.sector], dl
	
	xor dx, dx
	mov bl, byte [current_heads]
	div bx
	;; AX = (LBA / sectors_per_track) / heads
	;; DX = (LBA / sectors_per_track) % heads
	mov word [.cylinder], ax
	mov byte [.head], dl

	;; CH = Cylinder & 0xFF
	;; CL = Sector | ((Cylinder >> 2) & 0xC0)
	;; DH = Head
	mov ch, byte [.cylinder]
	mov bx, word [.cylinder]
	shr bx, 2
	and bx, 0xC0
	mov cl, byte [.sector]
	and cl, 0x3F ;; Sector uses five bits
	or cl, bl
	mov dh, [.head]

	pop bx
	ret
section .bss
.cylinder: resw 1
.head:     resb 1
.sector:   resb 1

;; Reads a sector(DX:AX) from disk to memory(ES:BX)
;; DX:AX: LBA
;; ES:BX: Addr
section .text
read_sector:
	push ax
	push cx
	push dx
	push si

%ifdef DEBUG
	print "Reading sector: 0x"
	print_hex_dword dx, ax
	print ", spt=0x"
	print_hex_byte byte [current_sectors_per_track]
	print ", heads=0x"
	print_hex_byte byte [current_heads]
	newline
%endif ;; DEBUG
	
	call lba_to_chs

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
	jc .error
.try:
	clc
	mov ax, 0x0201 ;; read function, 1 sector
	mov dl, [current_drive_number]
	int 0x13
	jnc .end
	test si, si
	jz .error
	dec si
	jmp .retry
.end:
	clc
	jmp .ret
.error:
	stc
.ret:
	pop si
	pop dx
	pop cx
	pop ax
	ret

section .bss
current_drive_number:      resb 1
current_sectors_per_track: resb 1
current_heads:             resb 1

%endif ;; _DISK_ASM_


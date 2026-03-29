;; stage1.asm
;; Created by Matheus Leme Da Silva 
bits 16
org 0x7C00

start_addr: equ 0x7E00
start_sector: equ 1
sector_count: equ 1

;; Main function
_start:
	cli
	xor ax, ax
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, 0x7C00
	sti

	mov [drive], dl

	;; Get sectors per track and heads of disk
	mov ah, 0x08
	xor di, di
	int 0x13
	jc int13_failed

	;; AH = status
	;; CL[bits 0-5] = sectors per track
	;; DH = heads - 1
	and cl, 0x3F
	inc dh
	mov [sectors_per_track], cl
	mov [heads], dh

	mov si, start_message
	call print_string

	;; Setup
	;; Set ES:BX to start_addr
	;; Set DX:AX to start_sector
	;; Set CX to count
	;; loop:
	;; If CX == 0: far jump
	;; If BX >= 0x8000:
	;;     BX -= 0x8000
	;;     ES += 0x800
	;; read
	;; BX += 512
	;; increment DX:AX
	;; goto loop

	;; Address
	mov bx, (start_addr >> 4)
	mov es, bx
	mov bx, (start_addr & 0x0F)

	;; Sector
	mov ax, (start_sector & 0xFFFF)
	mov dx, ((start_sector >> 8) & 0xFFFF)
	
	mov cx, sector_count
.loop:
	test cx, cx
	jz .end
	
	cmp bx, 0x8000
	jb .no_increment_segment

	sub bx, 0x8000

	push ax
	mov ax, es
	add ax, 0x800
	mov es, ax
	pop ax

.no_increment_segment:
	call read_sector
	
	add bx, 512
	
	add ax, 1
	adc dx, 0
	
	dec cx
	jmp .loop
.end:
	jmp (start_addr >> 4):(start_addr & 0x0F) ;; Far jump

	jmp halt

;; Prints a string ending with zero on the screen
;; DS:SI: pointer to string
print_string:
	push ax
	push si
	mov ah, 0x0E
.loop:
	lodsb ;; al = ds:si++
	test al, al
	jz .end
	int 0x10
	jmp .loop
.end:
	pop si
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

;; Prints halt message and halt the computer
halt:
	mov si, halted_message
	call print_string

	cli
	hlt

halted_message: db "System is halted. Please, reboot.", 0x0D, 0x0A, 0
int13_failed_message: db "Int13 failed!", 0x0D, 0x0A, 0
start_message: db "Starting...", 0x0D, 0x0A, 0

drive: db 0
sectors_per_track: dw 0
heads: dw 0

times 510 - ($ - $$) db 0
dw 0xAA55

;; This code is loaded by stage1 
main:
	mov al, 'X'
	mov ah, 0x0E
	int 0x10

	cli
	hlt

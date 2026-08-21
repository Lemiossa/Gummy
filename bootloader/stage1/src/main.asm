;; main.asm
;; Created by Matheus Leme Da Silva
bits 16
org 0x7c00

start_addr:   equ 0x7e00
start_sector: equ 1
sector_count: equ 62

jmp short main
nop

;; Space for BPB
times 62 - ($ - $$) db 0

;; Main function
main:
	cli
	xor ax, ax
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, 0x7c00
	sti

	mov [drive], dl

	;; Get sectors per track AND heads from disk
	mov ah, 0x08
	xor di, di
	int 0x13
	jc int13_failed

	;; AH = status
	;; CL[BITS 0-5] = sectors per track
	;; DH = heads - 1
	and cl, 0x3f
	inc dh
	mov [sectors_per_track], cl
	mov [heads], dh

	;; Setup
	;; Set ES:BX to start_addr
	;; Set DX:AX to start_sector
	;; Set CX to count
	;; LOOP:
	;; If CX == 0: far jump
	;; If BX >= 0x8000:
	;;     BX -= 0x8000
	;;     ES += 0x800
	;; read
	;; BX += 512
	;; increment DX:AX
	;; back to LOOP

	;; Address
	mov bx, (start_addr >> 4)
	mov es, bx
	mov bx, (start_addr & 0x0f)

	;; Sector
	mov ax, (start_sector & 0xffff)
	mov dx, ((start_sector >> 8) & 0xffff)
	
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

	push ax
	mov ah, 0x0e
	mov al, '.'
	int 0x10
	pop ax

	add bx, 512
	
	add ax, 1
	adc dx, 0
	
	dec cx
	jmp .loop
.end:
	mov dl, [drive]

	;; Far jump
	push word (start_addr >> 4)   ;; SEGMENT
	push word (start_addr & 0x0f) ;; offset
	retf

	jmp halt

%include "console.asm"
%include "disk.asm"

;; Display halt message AND halt the computer
halt:
	mov si, halted_message
	call print_string

	cli
	hlt

halted_message: db "System halted. Please restart.", 0x0d, 0x0a, 0

drive: db 0
sectors_per_track: dw 0
heads: dw 0

times 440 - ($ - $$) db 0
;; Boot signature
dd __TIME__

times 510 - ($ - $$) db 0
dw 0xaa55

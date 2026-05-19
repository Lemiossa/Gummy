;; disk.asm
;; Created by Matheus Leme Da Silva
%IFNDEF _DISK_ASM_
%DEFINE _DISK_ASM_

;; Read a sector (DX:AX) from disk to memory (ES:BX)
;; DX: High LBA
;; AX: Low LBA
;; ES: SEGMENT to load
;; BX: Offset to load
read_sector:
	PUSH AX
	PUSH CX
	PUSH DX

	;; LBA -> CHS
	;; C = (LBA / sectors_per_track) / heads
	;; H = (LBA / sectors_per_track) % heads
	;; S = (LBA % sectors_per_track) + 1
	
	DIV word [sectors_per_track]
	;; AX = LBA / sectors_per_track
	;; DX = LBA % sectors_per_track
	INC DX
	MOV DH, DL
	PUSH DX
	
	XOR DX, DX
	DIV word [heads]
	;; AX = (LBA / sectors_per_track) / heads
	;; DX = (LBA % sectors_per_track) % heads
	
	MOV CH, AL
	SHL AH, 6
	MOV CL, AH
	
	POP AX
	OR CL, AL

	SHL DX, 8

	;; int13h AH=2 func
	;; Parameters:
	;; AL = sector count
	;; CH = cylinder & 0xFF 
	;; CL = (sector & 0x3F) | ((cylinder & 0xC000) >> 13)
	;; DH = head
	;; DL = drive
	;; ES:BX = pointer

	MOV AX, 0x0201 ;; read function, 1 sector
	MOV DL, [drive]
	INT 0x13

	JC int13_failed
	
	POP DX
	POP CX
	POP AX
	RET

;; Display int13 error message AND halt the computer
int13_failed:
	MOV SI, int13_failed_message
	CALL print_string
	JMP halt

int13_failed_message: DB "Int13 failed!", 0x0D, 0x0A, 0

%ENDIF ;; _DISK_ASM_

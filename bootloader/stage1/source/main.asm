;; main.asm
;; Created by Matheus Leme Da Silva
BITS 16
ORG 0x7C00

start_addr:   EQU 0x7E00
start_sector: EQU 1
sector_count: EQU 62

JMP short main
NOP

;; Space for BPB
TIMES 62 - ($ - $$) DB 0

;; Main function
main:
	CLI
	XOR AX, AX
	MOV DS, AX
	MOV ES, AX
	MOV SS, AX
	MOV SP, 0x7C00
	STI

	MOV [drive], DL

	;; Get sectors per track AND heads from disk
	MOV AH, 0x08
	XOR DI, DI
	INT 0x13
	JC int13_failed

	;; AH = status
	;; CL[BITS 0-5] = sectors per track
	;; DH = heads - 1
	AND CL, 0x3F
	INC DH
	MOV [sectors_per_track], CL
	MOV [heads], DH

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
	MOV BX, (start_addr >> 4)
	MOV ES, BX
	MOV BX, (start_addr & 0x0F)

	;; Sector
	MOV AX, (start_sector & 0xFFFF)
	MOV DX, ((start_sector >> 8) & 0xFFFF)
	
	MOV CX, sector_count
.loop:
	TEST CX, CX
	JZ .end
	
	CMP BX, 0x8000
	JB .no_increment_segment

	SUB BX, 0x8000

	PUSH AX
	MOV AX, ES
	ADD AX, 0x800
	MOV ES, AX
	POP AX

.no_increment_segment:
	CALL read_sector

	PUSH AX
	MOV AH, 0x0E
	MOV AL, '.'
	INT 0x10
	POP AX

	ADD BX, 512
	
	ADD AX, 1
	ADC DX, 0
	
	DEC CX
	JMP .loop
.end:
	MOV DL, [drive]

	;; Far jump
	PUSH word (start_addr >> 4)   ;; SEGMENT
	PUSH word (start_addr & 0x0F) ;; offset
	RETF

	JMP halt

%INCLUDE "console.asm"
%INCLUDE "disk.asm"

;; Display halt message AND halt the computer
halt:
	MOV SI, halted_message
	CALL print_string

	CLI
	HLT

halted_message: DB "System halted. Please restart.", 0x0D, 0x0A, 0

drive: DB 0
sectors_per_track: DW 0
heads: DW 0

TIMES 440 - ($ - $$) DB 0
;; Boot signature
DD __TIME__

TIMES 510 - ($ - $$) DB 0
DW 0xAA55

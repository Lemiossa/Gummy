;; disk.asm
;; Created by Matheus Leme da Silva
%IFNDEF DISK_ASM
%DEFINE DISK_ASM
BITS 16

;; Initialize disk system
;; DL: Disk Drive
;; Returns:
;; CF=1 if an error occours
disk_init:
    PUSH CX
    PUSH DX
    MOV BYTE [drive], DL
    CALL disk_get_parameters
    JC .error
    MOV BYTE [sectors_per_track], CL
    MOV BYTE [heads], DH
    MOV BYTE [sectors_per_track+1], 0
    MOV BYTE [heads+1], 0
.end:
    CLC
    JMP .ret
.error:
    STC
.ret:
    POP DX
    POP CX
    RET

;; Gets disk paramenters
;; DL: Disk drive
;; Returns:
;; CL: Sectors per track
;; DH: Heads
;; CF=1 if an error occours
disk_get_parameters:
    PUSH AX
    MOV AH, 0x08
    INT 0x13
    INC DH
    AND CL, 0x3F
    POP AX
    RET

;; Converts LBA to CHS
;; DX:AX: LBA
;; Returns:
;; int13h ah=02h format:
;;  CX = Cylinder and Sector
;;  DH = Head
disk_lba_to_chs:
    PUSH BP
    PUSH AX
    ;; https://wiki.osdev.org/Disk_access_using_the_BIOS_(INT_13h)
    ;; Temp = LBA / (Sectors per Track)
    ;; Sector = (LBA % (Sectors per Track)) + 1
    ;; Head = Temp % (Number of Heads)
    ;; Cylinder = Temp / (Number of Heads)

    ;; Temp
    DIV WORD [sectors_per_track]
    ;; AX = Temp
    ;; DX = Sector - 1
    INC DX
    MOV BP, DX

    XOR DX, DX
    DIV WORD [heads]
    ;; AX = Cylinder
    ;; DX = Head
    MOV DH, DL
    XOR DL, DL

    MOV CX, BP
    MOV CH, AL
    SHR AX, 2
    AND AX, 0xC0
    OR CL, AL

    POP AX
    POP BP
    RET

;; Reads disk sector
;; DX:AX: Sector
;; ES:BX: Buffer
;; Returns:
;; CF=1 if an error occours
disk_read_sector:
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH ES
    CALL disk_lba_to_chs
    MOV AX, 0x0201
    MOV DL, [drive]
    INT 0x13
    JC .error
.end:
    CLC
    JMP .ret
.error:
    STC
.ret:
    POP ES
    POP DX
    POP CX
    POP BX
    POP AX
    RET

drive:             DB 0
sectors_per_track: DW 0
heads:             DW 0

%ENDIF ;; DISK_ASM

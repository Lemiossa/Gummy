;; fat.asm
;; Created by Matheus Leme da Silva
%IFNDEF FAT_ASM
%DEFINE FAT_ASM

BITS 16

STRUC fat_bpb
    .jump:                RESB 3
    .oem:                 RESB 8
    .bytes_per_sector:    RESW 1
    .sectors_per_cluster: RESB 1
    .reserved_sectors:    RESW 1
    .num_fat_tables:      RESB 1
    .root_dir_entries:    RESW 1
    .total_sectors16:     RESW 1
    .media_descriptor:    RESB 1
    .sectors_per_fat:     RESW 1
    .sectors_per_track:   RESW 1
    .heads:               RESW 1
    .hidden_sectors:      RESD 1
    .total_sectors32:     RESD 1
ENDSTRUC

;; Get next cluster in FAT12
fat_next_cluster:
    RET


;; Initializes FAT system
;; DX:AX: First sector of part
;; Returns: 
;; CF=1 if an error occours
fat_init:
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH ES

    MOV WORD[fat_first_sector], AX
    MOV WORD[fat_first_sector+2], DX

    XOR BX, BX
    MOV ES, BX
    MOV BX, 0x500
    CALL disk_read_sector

    ;; Verify if is FAT32
    CMP WORD[ES:0x500+fat_bpb.sectors_per_fat], 0
    JE .error

    ;; Verify if bytes per sector is 512
    MOV AX, WORD[ES:0x500+fat_bpb.bytes_per_sector]
    CMP AX, 512
    JNE .error

    ;; All informations in: https://wiki.osdev.org/FAT#Programming_Guide
    ;; root_dir_sectors = ((fat_bpb.root_dir_entries * 32) + 511) / 512;
    MOV AX, WORD[ES:0x500+fat_bpb.root_dir_entries]
    MOV BX, 32
    MUL BX
    ;; DX:AX = fat_bpb.root_dir_entries * 32
    ADD AX, 511
    ADC DX, 0
    ;; DX:AX = (fat_bpb.root_dir_entries * 32) + 511
    MOV BX, 512
    DIV BX 
    ;; AX = ((fat_bpb.root_dir_entries * 32) + 511) / 512
    MOV WORD[fat_root_dir_sectors], AX
    ;; first_data_sector = fat_bpb.reserved_sectors + (fat_bpb.num_fat_tables * fat_bpb.sectors_per_fat) + root_dir_sectors
    ADD AX, WORD[ES:0x500+fat_bpb.reserved_sectors]
    ;; AX = fat_bpb.reserved_sectors + root_dir_sectors
    MOV AX, CX
    XOR AX, AX
    MOV AL, BYTE[ES:0x500+fat_bpb.num_fat_tables]
    MUL WORD[ES:0x500+fat_bpb.sectors_per_fat]
    ADD AX, WORD[fat_first_sector]
    ADC DX, WORD[fat_first_sector+2]
    ;; DX:AX = fat_bpb.reserved_sectors + root_dir_sectors + (fat_bpb.num_fat_tables * fat_bpb.sectors_per_fat)
    MOV WORD[fat_first_data_sector], AX
    MOV WORD[fat_first_data_sector+2], DX

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

fat_type:             DB 0
fat_root_dir_sectors: DW 0
fat_first_data_sector:DD 0
fat_first_sector:     DD 0

%ENDIF ;; FAT_ASM

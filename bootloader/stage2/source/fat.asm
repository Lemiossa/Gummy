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
;; AX: Cluster
;; Return:
;; AX: Cluster
;; CF=1 if an error occours
fat12_next_cluster:
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH DI
    ;; fat_offset = cluster + (cluster / 2)
    ;; fat_sector = fat_first_fat_sector + (fat_offset / 512)
    ;; ent_offset = fat_offset % 512
    MOV BX, AX
    MOV DI, AX
    SHR AX, 1 ;; Divide by 2
    ;; AX = cluster / 2
    ADD AX, BX
    ;; AX = fat_offset
    XOR DX, DX
    MOV BX, 512
    DIV BX
    ;; AX = fat_offset / 512
    ;; DX = ent_offset
    ADD AX, WORD[fat_first_fat_sector]
    ;; AX = fat_sector
    ;; DX = ent_offset
    MOV CX, DX
    XOR DX, DX
    MOV BX, temp_sector_buffer
    CALL disk_read_sector
    ADD AX, 1
    ADC DX, 0
    ADD BX, 512
    CALL disk_read_sector
    SUB BX, 512
    JC .error
    ADD BX, CX
    MOV AX, WORD[ES:BX]
    TEST DI, 1
    JZ .zero
    SHR AX, 4
    JMP .end
.zero:
    AND AX, 0xFFF
.end:
    CLC
    JMP .ret
.error:
    STC
.ret:
    POP DI
    POP DX
    POP CX
    POP BX
    RET

;; Initializes FAT system
;; AX: First sector of part
;; Returns: 
;; CF=1 if an error occours
fat_init:
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH ES
    MOV WORD[fat_first_sector], AX
    XOR DX, DX
    XOR BX, BX
    MOV ES, BX
    MOV BX, 0x500
    CALL disk_read_sector
    CMP WORD[ES:0x500+510], 0xAA55
    JNE .error
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
    ;; first_data_sector = first_part_sector + fat_bpb.reserved_sectors + (fat_bpb.num_fat_tables * fat_bpb.sectors_per_fat) + root_dir_sectors
    ADD AX, WORD[ES:0x500+fat_bpb.reserved_sectors]
    ;; AX = fat_bpb.reserved_sectors + root_dir_sectors
    MOV CX, AX
    XOR AX, AX
    MOV AL, BYTE[ES:0x500+fat_bpb.num_fat_tables]
    MUL WORD[ES:0x500+fat_bpb.sectors_per_fat]
    ADD AX, WORD[fat_first_sector]
    ADD AX, CX
    ;; DX:AX = first_part_sector + fat_bpb.reserved_sectors + root_dir_sectors + (fat_bpb.num_fat_tables * fat_bpb.sectors_per_fat)
    MOV WORD[fat_first_data_sector], AX
    ;; fisrt_fat_sector = fat_bpb.reserved_sectors
    MOV AX, WORD[fat_first_sector]
    ADD AX, WORD[ES:0x500+fat_bpb.reserved_sectors]
    ;; data_sectors = fat_bpb.total_sectors - (fat_bpb.reserved_sectors + (fat_bpb.num_fat_tables * fat_bpb.sectors_per_fat) + root_dir_sectors)
    XOR AH, AH
    MOV AL, BYTE[ES:0x500+fat_bpb.num_fat_tables]
    MOV BX, WORD[ES:0x500+fat_bpb.sectors_per_fat]
    MUL BX
    ;; DX:AX = fat_bpb.num_fat_tables * fat_bpb.sectors_per_fat
    ADD AX, WORD[ES:0x500+fat_bpb.reserved_sectors]
    ;; AX = fat_bpb.reserved_sectors + (fat_bpb.num_fat_tables * fat_bpb.sectors_per_fat)
    ADD AX, WORD[fat_root_dir_sectors]
    ;; AX = (fat_bpb.reserved_sectors + (fat_bpb.num_fat_tables * fat_bpb.sectors_per_fat)) + root_dir_sectors
    MOV BX, WORD[ES:0x500+fat_bpb.total_sectors16]
    SUB BX, AX
    MOV AX, BX
    ;; AX = fat_bpb.total_sectors - (fat_bpb.reserved_secotrs + ((fat_bpb.num_fat_tables * fat_bpb.sectors_per_fat) + root_dir_sectors))
    ;; AX = data_sectors
    MOV WORD[fat_data_sectors], AX
    ;; total_clusters = data_sectors / fat_bpb.sectors_per_cluster
    XOR DX, DX
    MOV BX, WORD[ES:0x500+fat_bpb.sectors_per_cluster]
    DIV BX
    ;; AX = total_clusters
    ;; If total_clusters < 4085: FAT12
    ;; If total_clusters < 65525: FAT16
    CMP AX, 4085
    JB .fat12
    MOV BYTE[fat_type], 16
    JMP .end
.fat12:
    MOV BYTE[fat_type], 12
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

fat_type:                 DB 0
fat_root_dir_sectors:     DW 0
fat_data_sectors:         DW 0
fat_first_data_sector:    DW 0
fat_first_fat_sector:     DW 0
fat_first_root_dir_sector:DW 0
fat_first_sector:         DW 0

temp_sector_buffer: TIMES 512 * 2 DB 0

%ENDIF ;; FAT_ASM

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

STRUC fat_entry
    .name:                RESB 11
    .attr:                RESB 1
    .res0:                RESB 1
    .time_hundredths:     RESB 1
    .ctime:               RESW 1
    .cdate:               RESW 1
    .adate:               RESW 1
    .cluster_hi:          RESW 1
    .mtime:               RESW 1
    .mdate:               RESW 1
    .cluster_lo:          RESW 1
    .file_size_lo:        RESW 1
    .file_size_hi:        RESW 1
ENDSTRUC

;; Initializes FAT system
;; Returns: 
;; CF=1 if an error occours
fat_init:
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH ES
    XOR AX, AX
    XOR DX, DX
    XOR BX, BX
    MOV ES, BX
    MOV BX, 0x500
    CALL disk_read_sector
    CMP WORD[ES:0x500+510], 0xAA55
    JNE .error
    ;; Reject FAT32
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
    MOV CX, AX
    XOR AX, AX
    MOV AL, BYTE[ES:0x500+fat_bpb.num_fat_tables]
    MUL WORD[ES:0x500+fat_bpb.sectors_per_fat]
    ADD AX, CX
    ;; DX:AX = first_part_sector + fat_bpb.reserved_sectors + root_dir_sectors + (fat_bpb.num_fat_tables * fat_bpb.sectors_per_fat)
    MOV WORD[fat_first_data_sector], AX
    ;; fat_first_root_dir_sector = fat_first_data_sector - fat_root_dir_sectors
    SUB AX, WORD[fat_root_dir_sectors]
    MOV WORD[fat_first_root_dir_sector], AX
    ;; first_fat_sector = fat_bpb.reserved_sectors
    MOV AX, WORD[ES:0x500+fat_bpb.reserved_sectors]
    MOV WORD[fat_first_fat_sector], AX
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
    JC .error
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

;; Get next cluster in FAT16
;; AX: Cluster
;; Return:
;; AX: Cluster
;; CF=1 if an error occours
fat16_next_cluster:
    PUSH BX
    PUSH CX
    PUSH DX
    ;; fat_offset = cluster * 2
    ;; fat_sector = fat_first_fat_sector + (fat_offset / 512)
    ;; ent_offset = fat_offset % 512
    SHL AX, 1 ;; Multiply by 2
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
    JC .error
    ADD BX, CX
    MOV AX, WORD[ES:BX]
.end:
    CLC
    JMP .ret
.error:
    STC
.ret:
    POP DX
    POP CX
    POP BX
    RET

;; Get next cluster
;; AX: Cluster
;; Return:
;; AX: Cluster
;; CF=1 if an error occours
fat_next_cluster:
    CMP BYTE[fat_type], 12
    JE .fat12
    CMP BYTE[fat_type], 16
    JNE .error
    CALL fat16_next_cluster
.fat12:
    CALL fat12_next_cluster
.end:
    CLC
    JMP .ret
.error:
    STC
.ret:
    RET

;; Read an root dir entry
;; AX: entry index
;; ES:DI: Pointer to data
;; Returns:
;; CF=1 If an error occours
fat_read_root_dir:
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH DI
    PUSH SI
    PUSH DS
    PUSH ES
    ;; byte_pos = index * 32
    ;; sector = root_dir_sector + (byte_pos / 512)
    ;; offset = byte_pos % 512
    MOV BX, 32
    MUL BX
    ;; DX:AX = index * 32
    MOV BX, 512
    DIV BX
    ;; AX = byte_pos / 512
    ;; DX = offset
    ADD AX, WORD[fat_first_root_dir_sector]
    ;; AX = sector
    ;; DX = offset
    MOV SI, DX
    XOR DX, DX
    MOV DS, DX
    ADD SI, temp_sector_buffer
    MOV BX, temp_sector_buffer
    CALL disk_read_sector
    ;; Copy the entry
    MOV CX, 32
    CLD
    REP MOVSB
.end:
    CLC 
    JMP .ret
.error:
    STC
.ret:
    POP ES
    POP DS
    POP SI
    POP DI
    POP DX
    POP CX
    POP BX
    POP AX
    RET

;; Converts Cluster to LBA
;; AX: Cluster
;; Returns:
;; DX:AX: LBA
fat_cluster_to_lba:
    PUSH BX
    PUSH ES
    ;; LBA = ((cluster - 2) * fat_bpb.sectors_per_cluster) + fat_first_data_sector
    SUB AX, 2
    ;; AX = cluster - 2
    XOR BX, BX
    MOV ES, BX
    MOV BL, BYTE [ES:0x500+fat_bpb.sectors_per_cluster]
    MUL BX
    ;; DX:AX = (cluster - 2) * fat_bpb.sectors_per_cluster
    ADD AX, WORD [fat_first_data_sector]
    ADC DX, 0
    ;; DX:AX = LBA
    POP ES
    POP BX
    RET


;; Read fat file
;; DS:SI: Entry
;; ES:DI: Output
fat_read_file:
    
    RET

fat_type:                 DB 0
fat_root_dir_sectors:     DW 0
fat_data_sectors:         DW 0
fat_first_data_sector:    DW 0
fat_first_fat_sector:     DW 0
fat_first_root_dir_sector:DW 0

temp_sector_buffer: TIMES 512 * 2 DB 0

%ENDIF ;; FAT_ASM

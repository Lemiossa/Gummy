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

    

.end:
    CLC
    JMP .ret
.error:
    STC
.ret:
    POP DX
    POP CX
    POP BX
    POP AX
    RET

fat_type: DB 0 

%ENDIF ;; FAT_ASM

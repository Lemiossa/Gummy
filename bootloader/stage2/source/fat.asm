;; fat.asm
;; Created by Matheus Leme da Silva
%ifndef fat_asm
%define fat_asm

bits 16

temp_sector_buffer: equ 0x500

struc fat_bpb
    .jump:                resb 3
    .oem:                 resb 8
    .bytes_per_sector:    resw 1
    .sectors_per_cluster: resb 1
    .reserved_sectors:    resw 1
    .num_fat_tables:      resb 1
    .root_dir_entries:    resw 1
    .total_sectors16:     resw 1
    .media_descriptor:    resb 1
    .sectors_per_fat:     resw 1
    .sectors_per_track:   resw 1
    .heads:               resw 1
    .hidden_sectors:      resd 1
    .total_sectors32:     resd 1
endstruc

struc fat_entry
    .name:                resb 11
    .attr:                resb 1
    .res0:                resb 1
    .time_hundredths:     resb 1
    .ctime:               resw 1
    .cdate:               resw 1
    .adate:               resw 1
    .cluster_hi:          resw 1
    .mtime:               resw 1
    .mdate:               resw 1
    .cluster_lo:          resw 1
    .file_size_lo:        resw 1
    .file_size_hi:        resw 1
endstruc

;; Initializes FAT system
;; Returns: 
;; CF=1 if an error occours
fat_init:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    xor ax, ax
    xor dx, dx
    push es
    mov bx, (temp_sector_buffer >> 4)
    mov es, bx
    mov bx, (temp_sector_buffer & 0x0f)
    call disk_read_sector
    pop es
    jc .error
    push ds
    cld
    mov si, (temp_sector_buffer >> 4)
    mov ds, si
    mov si, (temp_sector_buffer & 0x0f)
    mov di, fat_bpb_data
    mov cx, fat_bpb_size
    rep movsb
    pop ds
    ;; Reject FAT32
    cmp word[fat_bpb_data+fat_bpb.sectors_per_fat], 0
    je .error
    ;; Verify if bytes per sector is 512
    mov ax, word[fat_bpb_data+fat_bpb.bytes_per_sector]
    cmp ax, 512
    jne .error
    ;; All informations in: https://wiki.osdev.org/FAT#Programming_Guide
    ;; root_dir_sectors = ((fat_bpb.root_dir_entries * 32) + 511) / 512;
    mov ax, word[fat_bpb_data+fat_bpb.root_dir_entries]
    mov bx, 32
    mul bx
    ;; DX:AX = fat_bpb.root_dir_entries * 32
    add ax, 511
    adc dx, 0
    ;; DX:AX = (fat_bpb.root_dir_entries * 32) + 511
    mov bx, 512
    div bx 
    ;; AX = ((fat_bpb.root_dir_entries * 32) + 511) / 512
    mov word[fat_root_dir_sectors], ax
    ;; first_data_sector = fat_bpb.reserved_sectors + (fat_bpb.num_fat_tables * fat_bpb.sectors_per_fat) + root_dir_sectors
    add ax, word[fat_bpb_data+fat_bpb.reserved_sectors]
    ;; AX = fat_bpb.reserved_sectors + root_dir_sectors
    mov cx, ax
    xor ax, ax
    mov al, byte[fat_bpb_data+fat_bpb.num_fat_tables]
    mul word[fat_bpb_data+fat_bpb.sectors_per_fat]
    add ax, cx
    ;; DX:AX = first_part_sector + fat_bpb.reserved_sectors + root_dir_sectors + (fat_bpb.num_fat_tables * fat_bpb.sectors_per_fat)
    mov word[fat_first_data_sector], ax
    ;; fat_first_root_dir_sector = fat_first_data_sector - fat_root_dir_sectors
    sub ax, word[fat_root_dir_sectors]
    mov word[fat_first_root_dir_sector], ax
    ;; first_fat_sector = fat_bpb.reserved_sectors
    mov ax, word[fat_bpb_data+fat_bpb.reserved_sectors]
    mov word[fat_first_fat_sector], ax
    ;; data_sectors = fat_bpb.total_sectors - (fat_bpb.reserved_sectors + (fat_bpb.num_fat_tables * fat_bpb.sectors_per_fat) + root_dir_sectors)
    xor ah, ah
    mov al, byte[fat_bpb_data+fat_bpb.num_fat_tables]
    mov bx, word[fat_bpb_data+fat_bpb.sectors_per_fat]
    mul bx
    ;; DX:AX = fat_bpb.num_fat_tables * fat_bpb.sectors_per_fat
    add ax, word[fat_bpb_data+fat_bpb.reserved_sectors]
    ;; AX = fat_bpb.reserved_sectors + (fat_bpb.num_fat_tables * fat_bpb.sectors_per_fat)
    add ax, word[fat_root_dir_sectors]
    ;; AX = (fat_bpb.reserved_sectors + (fat_bpb.num_fat_tables * fat_bpb.sectors_per_fat)) + root_dir_sectors
    mov bx, word[fat_bpb_data+fat_bpb.total_sectors16]
    sub bx, ax
    mov ax, bx
    ;; AX = fat_bpb.total_sectors - (fat_bpb.reserved_secotrs + ((fat_bpb.num_fat_tables * fat_bpb.sectors_per_fat) + root_dir_sectors))
    ;; AX = data_sectors
    mov word[fat_data_sectors], ax
    ;; total_clusters = data_sectors / fat_bpb.sectors_per_cluster
    xor dx, dx
    mov bl, byte[fat_bpb_data+fat_bpb.sectors_per_cluster]
    xor bh, bh
    div bx
    ;; AX = total_clusters
    ;; If total_clusters < 4085: FAT12
    ;; If total_clusters < 65525: FAT16
    cmp ax, 4085
    jb .fat12
    mov byte[fat_type], 16
    jmp .end
.fat12:
    mov byte[fat_type], 12
.end:
    clc
    jmp .ret
.error:
    stc
.ret:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

;; Get next cluster in FAT12
;; AX: Cluster
;; Return:
;; AX: Cluster
;; CF=1 if an error occours
fat12_next_cluster:
    push bx
    push cx
    push dx
    push di
    push es
    ;; fat_offset = cluster + (cluster / 2)
    ;; fat_sector = fat_first_fat_sector + (fat_offset / 512)
    ;; ent_offset = fat_offset % 512
    mov bx, ax
    mov di, ax
    shr ax, 1 ;; Divide by 2
    ;; AX = cluster / 2
    add ax, bx
    ;; AX = fat_offset
    xor dx, dx
    mov bx, 512
    div bx
    ;; AX = fat_offset / 512
    ;; DX = ent_offset
    add ax, word[fat_first_fat_sector]
    ;; AX = fat_sector
    ;; DX = ent_offset
    mov cx, dx
    xor dx, dx
    mov bx, (temp_sector_buffer >> 4)
    mov es, bx
    mov bx, (temp_sector_buffer & 0x0f)
    call disk_read_sector
    jc .error
    add ax, 1
    adc dx, 0
    add bx, 512
    call disk_read_sector
    sub bx, 512
    jc .error
    add bx, cx
    mov ax, word[es:bx]
    test di, 1
    jz .zero
    shr ax, 4
    jmp .end
.zero:
    and ax, 0xfff
.end:
    clc
    jmp .ret
.error:
    stc
.ret:
    pop es
    pop di
    pop dx
    pop cx
    pop bx
    ret

;; Get next cluster in FAT16
;; AX: Cluster
;; Return:
;; AX: Cluster
;; CF=1 if an error occours
fat16_next_cluster:
    push bx
    push cx
    push dx
    push es
    ;; fat_offset = cluster * 2
    ;; fat_sector = fat_first_fat_sector + (fat_offset / 512)
    ;; ent_offset = fat_offset % 512
    mov bx, 2
    mul bx
    ;; DX:AX = fat_offset
    mov bx, 512
    div bx
    ;; AX = fat_offset / 512
    ;; DX = ent_offset
    add ax, word[fat_first_fat_sector]
    ;; AX = fat_sector
    ;; DX = ent_offset
    mov cx, dx
    xor dx, dx
    mov bx, (temp_sector_buffer >> 4)
    mov es, bx
    mov bx, (temp_sector_buffer & 0x0f)
    call disk_read_sector
    jc .error
    add bx, cx
    mov ax, word[es:bx]
.end:
    clc
    jmp .ret
.error:
    stc
.ret:
    pop es
    pop dx
    pop cx
    pop bx
    ret

;; Get next cluster
;; AX: Cluster
;; Return:
;; AX: Cluster
;; CF=1 if an error occours
fat_next_cluster:
    cmp byte[fat_type], 12
    je .fat12
    cmp byte[fat_type], 16
    je .fat16
    jmp .error
.fat12:
    call fat12_next_cluster
    jc .error
    jmp .end
.fat16:
    call fat16_next_cluster 
    jc .error
.end:
    clc
    jmp .ret
.error:
    stc
.ret:
    ret

;; Read an root dir entry
;; AX: entry index
;; ES:DI: Pointer to data
;; Returns:
;; CF=1 If an error occours
fat_read_root_dir:
    push ax
    push bx
    push cx
    push dx
    push di
    push si
    push ds
    push es
    ;; byte_pos = index * 32
    ;; sector = root_dir_sector + (byte_pos / 512)
    ;; offset = byte_pos % 512
    mov bx, 32
    mul bx
    ;; DX:AX = index * 32
    mov bx, 512
    div bx
    ;; AX = byte_pos / 512
    ;; DX = offset
    add ax, word[fat_first_root_dir_sector]
    ;; AX = sector
    ;; DX = offset
    mov si, dx
    ;; DX:AX LBA
    push es
    mov bx, (temp_sector_buffer >> 4)
    mov es, bx
    mov bx, (temp_sector_buffer & 0x0f)
    xor dx, dx
    call disk_read_sector
    pop es
    jc .error
    add si, bx
    ;; SI = offset
    mov bx, (temp_sector_buffer >> 4)
    mov ds, bx
    ;; DS:SI = source
    ;; ES:DI = output
    cld
    mov cx, 32
    rep movsb
.end:
    clc 
    jmp .ret
.error:
    stc
.ret:
    pop es
    pop ds
    pop si
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

;; Finds a fat file in a root directory
;; DS:SI: Filename
;; Returns:
;; AX: Index
;; CF=1 if an error occours
fat_find_in_root_dir:
    push bx
    push cx
    push dx
    push di
    push si
    push ds
    push es
    push cs
    pop es
    xor ax, ax
    mov dx, si
    mov bx, word[fat_bpb_data+fat_bpb.root_dir_entries]
.find_loop:
    mov di, .entry
    call fat_read_root_dir
    jc .error
    cmp byte[es:di], 0
    je .error
    cmp byte[es:di], 0xe5
    je .next
    cld
    mov cx, 11
    mov si, dx
    repe cmpsb
    je .end
.next:
    inc ax
    dec bx
    jnz .find_loop
.end:
    clc
    jmp .ret
.error:
    stc
.ret:
    pop es
    pop ds
    pop si
    pop di
    pop dx
    pop cx
    pop bx
    ret
.entry: times 32 db 0

;; Converts Cluster to LBA
;; AX: Cluster
;; Returns:
;; DX:AX: LBA
fat_cluster_to_lba:
    push bx
    ;; LBA = ((cluster - 2) * fat_bpb.sectors_per_cluster) + fat_first_data_sector
    sub ax, 2
    ;; AX = cluster - 2
    mov bl, byte[fat_bpb_data+fat_bpb.sectors_per_cluster]
    xor bh, bh
    mul bx
    ;; DX:AX = (cluster - 2) * fat_bpb.sectors_per_cluster
    add ax, word[fat_first_data_sector]
    adc dx, 0
    ;; DX:AX = LBA
    pop bx
    ret

;; Return CF=1 if cluster is EOF
;; AX: Cluster
fat_cluster_is_eof: 
    cmp byte[fat_type], 12
    je .fat12
    cmp byte[fat_type], 16
    jne .eof
    cmp ax, 0xfff8
    jae .eof
    jmp .neof
.fat12:
    cmp ax, 0x0ff8
    jae .eof
.neof:
    clc
    jmp .ret
.eof:
    stc
.ret:
    ret

;; Reads a fat file
;; DS:SI: Entry
;; ES:BX: Output
;; Returns:
;; CF=1 if an error occours
fat_read_file:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    mov ax, word[si+fat_entry.cluster_lo]
    cmp ax, 2
    jb .error
.loop:
    call fat_cluster_is_eof
    jc .end
    ;; AX = cluster
    mov di, ax
    call fat_cluster_to_lba 
    mov cl, byte[fat_bpb_data+fat_bpb.sectors_per_cluster]
    xor ch, ch
.read:
    cmp bx, 0x8000
    jb .no_inc_seg
    ;; If (bx >= 0x8000) 
    ;; {
    ;;   bx -= 0x8000;
    ;;   es += 0x800;
    ;; }
    sub bx, 0x8000
    push ax
    mov ax, es
    add ax, 0x800
    mov es, ax
    pop ax
.no_inc_seg:
    call disk_read_sector
    jc .error
    add bx, 512
    add ax, 1
    adc dx, 0
    loop .read
    mov ax, di
    call fat_next_cluster
    jc .error
    jmp .loop
.end:
    clc
    jmp .ret
.error:
    stc
.ret:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

fat_type:                 db 0
fat_root_dir_sectors:     dw 0
fat_data_sectors:         dw 0
fat_first_data_sector:    dw 0
fat_first_fat_sector:     dw 0
fat_first_root_dir_sector:dw 0
fat_bpb_data:             times fat_bpb_size db 0

%endif ;; FAT_ASM

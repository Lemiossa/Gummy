;; fat.asm
;; Criado por Matheus Leme Da Silva
%ifndef fat_asm
%define fat_asm

bits 16
cpu 386

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
    .file_size:           resd 1
endstruc

;; Inicializa o sistema FAT
;; Retorna:
;; CF=1 se ocorrer um erro
fat_init:
    push eax
    push ebx
    push ecx
    push edx
    push si
    push di

    ;; Ler setor do FAT(0)
    xor eax, eax
    ;; Ler em temp_sector_buffer
    push es
    mov bx, (temp_sector_buffer >> 4) ;; segmento
    mov es, bx
    mov bx, (temp_sector_buffer & 0x0F) ;; offset
    call disk_read_sector
    pop es
    jc .error

    push ds
    cld
    mov si, (temp_sector_buffer >> 4)
    mov ds, si
    mov si, (temp_sector_buffer & 0x0F)
    ;; Bootloader ja deixa o es no lugar certo, isso significa que es ja contem o segmento correto para acessar fat_bpb_data
    mov di, fat_bpb_data
    mov cx, fat_bpb_size
    rep movsb
    pop ds

    ;; Calculos daqui em diante ============================

    ;; Rejeita FAT32
    cmp word[fat_bpb_data+fat_bpb.sectors_per_fat], 0
    je .error
    ;; Verifica se bytes por setor e 512
    mov ax, word[fat_bpb_data+fat_bpb.bytes_per_sector]
    cmp ax, 512
    jne .error
    ;; Todas as informacoes em: https://wiki.osdev.org/FAT#Programming_Guide

    ;; =====================================================
    ;; Total sectors
    movzx eax, word[fat_bpb_data+fat_bpb.total_sectors16]
    test eax, eax
    jnz .sectorsdefined
    mov eax, dword[fat_bpb_data+fat_bpb.total_sectors32]
.sectorsdefined:
    mov dword[fat_total_sectors], eax
    test eax, eax
    jz .error

    ;; =====================================================
    ;; root_dir_sectors = ((fat_bpb.root_dir_entries * 32) + 511) / 512;
    xor eax, eax
    mov ax, word[fat_bpb_data+fat_bpb.root_dir_entries]
    shl eax, 5
    ;; EAX = fat_bpb.root_dir_entries * 32
    add eax, 511
    ;; EAX = (fat_bpb.root_dir_entries * 32) + 511
    shr eax, 9
    ;; EAX = ((fat_bpb.root_dir_entries * 32) + 511) / 512
    mov dword[fat_root_dir_sectors], eax
    
    ;; =====================================================
    ;; first_data_sector = fat_bpb.reserved_sectors + (fat_bpb.num_fat_tables * fat_bpb.sectors_per_fat) + root_dir_sectors
    movzx ecx, word[fat_bpb_data+fat_bpb.reserved_sectors]
    add eax, ecx
    ;; AX = fat_bpb.reserved_sectors + root_dir_sectors
    movzx ecx, byte[fat_bpb_data+fat_bpb.num_fat_tables]
    movzx ebx, word[fat_bpb_data+fat_bpb.sectors_per_fat]
    imul ecx, ebx
    add eax, ecx
    ;; EAX = fat_bpb.reserved_sectors + root_dir_sectors + (fat_bpb.num_fat_tables * fat_bpb.sectors_per_fat)
    mov dword[fat_first_data_sector], eax

    ;; =====================================================
    ;; fat_first_root_dir_sector = fat_first_data_sector - fat_root_dir_sectors
    sub eax, dword[fat_root_dir_sectors]
    mov dword[fat_first_root_dir_sector], eax

    ;; =====================================================
    ;; first_fat_sector = fat_bpb.reserved_sectors
    movzx eax, word[fat_bpb_data+fat_bpb.reserved_sectors]
    mov dword[fat_first_fat_sector], eax

    ;; =====================================================
    ;; data_sectors = total_sectors - (fat_bpb.reserved_sectors + (fat_bpb.num_fat_tables * fat_bpb.sectors_per_fat) + root_dir_sectors)
    movzx eax, byte[fat_bpb_data+fat_bpb.num_fat_tables]
    movzx ebx, word[fat_bpb_data+fat_bpb.sectors_per_fat]
    imul eax, ebx
    ;; EAX = fat_bpb.num_fat_tables * fat_bpb.sectors_per_fat
    movzx ebx, word[fat_bpb_data+fat_bpb.reserved_sectors]
    add eax, ebx
    ;; EAX = fat_bpb.reserved_sectors + (fat_bpb.num_fat_tables * fat_bpb.sectors_per_fat)
    movzx ebx, word[fat_root_dir_sectors]
    add eax, ebx
    ;; EAX = (fat_bpb.reserved_sectors + (fat_bpb.num_fat_tables * fat_bpb.sectors_per_fat)) + root_dir_sectors
    mov ebx, dword[fat_total_sectors]
    sub ebx, eax
    mov eax, ebx
    ;; EAX = fat_bpb.total_sectors - (fat_bpb.reserved_secotrs + ((fat_bpb.num_fat_tables * fat_bpb.sectors_per_fat) + root_dir_sectors))
    ;; EAX = data_sectors
    mov dword[fat_data_sectors], eax

    ;; =====================================================
    ;; total_clusters = data_sectors / fat_bpb.sectors_per_cluster
    xor edx, edx
    movzx ebx, byte[fat_bpb_data+fat_bpb.sectors_per_cluster]
    test ebx, ebx
    jz .error
    div ebx
    ;; AX = total_clusters
    ;; If total_clusters < 4085: FAT12
    ;; If total_clusters < 65525: FAT16
    cmp eax, 4085
    jb .fat12

    cmp eax, 65525
    jae .error

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
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

;; Obtem o proximo cluster na FAT12
;; AX: Cluster
;; Retorna:
;; AX: Cluster
;; CF=1 se ocorrer um erro
fat12_next_cluster:
    push ebx
    push ecx
    push edx
    push di
    push es

    ;; Calcular:
    ;; fat_offset = cluster + (cluster / 2)
    ;; fat_sector = fat_first_fat_sector + (fat_offset / 512)
    ;; ent_offset = fat_offset % 512
    movzx ebx, ax
    mov di, ax
    shr eax, 1 ;; Divide por 2
    ;; EAX = cluster / 2
    add eax, ebx
    ;; EAX = fat_offset
    xor edx, edx
    mov ebx, 512
    div ebx
    ;; EAX = fat_offset / 512
    ;; EDX = ent_offset
    add eax, dword[fat_first_fat_sector]

    ;; EAX = fat_sector
    ;; EDX = ent_offset

    ;; Ler primeiro setor em EAX
    mov bx, (temp_sector_buffer >> 4)
    mov es, bx
    mov bx, (temp_sector_buffer & 0x0f)
    call disk_read_sector
    jc .error

    ;; Ler segundo setor
    add eax, 1
    add bx, 512
    call disk_read_sector
    jc .error

    sub bx, 512
    add bx, dx
    mov ax, word[es:bx]
    test di, 1
    jz .zero
    shr ax, 4
    jmp .end
.zero:
    and ax, 0xFFF
.end:
    clc
    jmp .ret
.error:
    stc
.ret:
    pop es
    pop di
    pop edx
    pop ecx
    pop ebx
    ret

;; Obtem o proximo cluster na FAT16
;; AX: Cluster
;; Retorna:
;; AX: Cluster
;; CF=1 se ocorrer um erro
fat16_next_cluster:
    push ebx
    push ecx
    push edx
    push es

    ;; Calcular:
    ;; fat_offset = cluster * 2
    ;; fat_sector = fat_first_fat_sector + (fat_offset / 512)
    ;; ent_offset = fat_offset % 512
    movzx ebx, ax
    mov eax, ebx
    shl eax, 1
    ;; EAX = fat_offset
    xor edx, edx
    mov ebx, 512
    div ebx
    ;; EAX = fat_offset / 512
    ;; EDX = ent_offset
    add eax, dword[fat_first_fat_sector]

    ;; EAX = fat_sector
    ;; EDX = ent_offset

    ;; Ler setor
    mov bx, (temp_sector_buffer >> 4)
    mov es, bx
    mov bx, (temp_sector_buffer & 0x0f)
    call disk_read_sector
    jc .error

    add bx, dx
    mov ax, word[es:bx]
.end:
    clc
    jmp .ret
.error:
    stc
.ret:
    pop es
    pop edx
    pop ecx
    pop ebx
    ret

;; Obtem o proximo cluster
;; AX: Cluster
;; Retorna:
;; AX: Cluster
;; CF=1 se ocorrer um erro
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

;; Le uma entrada do diretorio raiz
;; EAX: indice da entrada
;; ES:DI: Ponteiro para os dados
;; Retorna:
;; CF=1 se ocorrer um erro
fat_read_root_dir:
    push eax
    push ebx
    push ecx
    push edx
    push di
    push si
    push ds
    push es

    ;; Calcular:
    ;; byte_pos = index * 32
    ;; setor = root_dir_sector + (byte_pos / 512)
    ;; offset = byte_pos % 512
    shl eax, 5
    ;; EAX = index * 32
    xor edx, edx
    mov ebx, 512
    div ebx
    ;; EAX = byte_pos / 512
    ;; EDX = offset
    add eax, dword[fat_first_root_dir_sector]
    ;; EAX = setor
    ;; EDX = offset

    ;; Ler setor
    ;; EAX = LBA
    mov si, dx
    push es
    mov bx, (temp_sector_buffer >> 4)
    mov es, bx
    mov bx, (temp_sector_buffer & 0x0f)
    call disk_read_sector
    pop es
    jc .error

    add si, bx
    ;; SI = offset

    mov bx, (temp_sector_buffer >> 4)
    mov ds, bx
    ;; DS:SI = origem
    ;; ES:DI = destino
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
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

;; Encontra um arquivo FAT no diretorio raiz
;; DS:SI: Nome do arquivo
;; Retorna:
;; EAX: Indice
;; CF=1 se ocorrer um erro
fat_find_in_root_dir:
    push ebx
    push ecx
    push edx
    push di
    push si
    push ds
    push es

    xor eax, eax
    mov es, ax
    movzx edx, si
    movzx ebx, word[fat_bpb_data+fat_bpb.root_dir_entries]
.find_loop:
    mov di, .entry
    call fat_read_root_dir
    jc .error
    cmp byte[es:di], 0 ;; invalido
    je .error
    cmp byte[es:di], 0xE5 ;; deletado
    je .next
    cld
    mov cx, 11
    mov si, dx
    repe cmpsb
    je .end
.next:
    inc eax
    dec ebx
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
    pop edx
    pop ecx
    pop ebx
    ret
.entry: times 32 db 0

;; Converte cluster para LBA
;; EAX: Cluster
;; Retorna:
;; EAX: LBA
fat_cluster_to_lba:
    push ebx
    ;; LBA = ((cluster - 2) * fat_bpb.sectors_per_cluster) + fat_first_data_sector
    sub eax, 2
    ;; EAX = cluster - 2
    movzx ebx, byte[fat_bpb_data+fat_bpb.sectors_per_cluster]
    imul eax, ebx
    ;; EAX = (cluster - 2) * fat_bpb.sectors_per_cluster
    add eax, dword[fat_first_data_sector]
    ;; EAX = LBA
    pop ebx
    ret

;; Retorna CF=1 se o cluster for EOF
;; EAX: Cluster
fat_cluster_is_eof:
    cmp byte[fat_type], 12
    je .fat12
    cmp byte[fat_type], 16
    jne .eof
    cmp eax, 0xFFF8
    jae .eof
    jmp .neof
.fat12:
    cmp ax, 0x0FF8
    jae .eof
.neof:
    clc
    jmp .ret
.eof:
    stc
.ret:
    ret

;; Le um arquivo FAT
;; DS:SI: Entrada
;; ES:BX: Destino
;; Retorna:
;; CF=1 se ocorrer um erro
fat_read_file:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi

    ;; Verificar se file_size == 0
    mov eax, dword[si+fat_entry.file_size]
    test eax, eax
    jz .error

    ;; Verificar se destino + file_size >= 0x90000, se sim, erro
    movzx ebx, bx
    mov edi, es
    shl edi, 4
    add edi, ebx
    add edi, eax
    cmp edi, 0x90000
    jae .error

    movzx eax, word[si+fat_entry.cluster_lo]
    cmp eax, 2
    jb .error
.loop:
    call fat_cluster_is_eof
    movzx eax, ax
    jc .end

    ;; EAX = cluster
    mov edi, eax
    call fat_cluster_to_lba
    ;; EAX = LBA
    movzx cx, byte[fat_bpb_data+fat_bpb.sectors_per_cluster]
.read:
    cmp bx, 0x8000
    jb .no_inc_seg
    ;; Se (bx >= 0x8000)
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
    inc eax
    loop .read

    mov eax, edi
    call fat_next_cluster
    jc .error
    jmp .loop
.end:
    clc
    jmp .ret
.error:
    stc
.ret:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

fat_type:                 db 0
fat_root_dir_sectors:     dd 0
fat_data_sectors:         dd 0
fat_first_data_sector:    dd 0
fat_first_fat_sector:     dd 0
fat_first_root_dir_sector:dd 0
fat_total_sectors:        dd 0
fat_bpb_data:             times fat_bpb_size db 0

%endif ;; FAT_ASM

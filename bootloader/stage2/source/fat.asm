;; fat.asm
;; Created by Matheus Leme Da Silva
%ifndef _FAT_ASM_
%define _FAT_ASM_
%include "disk.asm"
section .text

first_sector:     equ 0x500
sector_buffer:    equ first_sector + sector_size

struc fat_bpb
	.jump:             resb 3
	.oem_id:           resb 8
	.bytes_per_sector: resw 1
	.sectors_per_clus: resb 1
	.reserved_sectors: resw 1
	.num_fats:         resb 1
	.root_dir_entries: resw 1
	.total_sectors16:  resw 1 ;; If is zero, uses .fat_total_sectors32
	.media_desc_type:  resb 1
	.sectors_per_fat:  resw 1
	.sectors_per_track:resw 1
	.number_of_heads:  resw 1
	.hidden_sectors:   resd 1
	.total_sectors32:  resd 1
endstruc

struc fat_entry
	.name:         resb 8
	.ext:          resb 3
	.attr:         resb 1
	.res0:         resb 2 ;; Windows NT Reserved and Creation time in hundredths
	.created_time: resw 1 ;; HHHHHMMMMMMSSSSS; Multiply seconds by 2
	.created_date: resw 1 ;; YYYYYYYMMMMDDDDD;
	.accessed_date:resw 1 ;; YYYYYYYMMMMDDDDD;
	.clus_high:    resw 1
	.modified_time:resw 1 ;; HHHHHMMMMMMSSSSS;
	.modified_date:resw 1 ;; YYYYYYYMMMMDDDDD;
	.clus_low:     resw 1
	.file_size:    resd 1
endstruc

;; Converts cluster to LBA
;; AX: Cluster
;; Return
;; DX:AX: LBA
;; CF if an error occour
fat_clus_to_lba:
	push cx
	push si
	cmp byte [fat_initialized], 0
	je .error

	;; LBA = ((clus - 2) * fat_bpb->sectors_per_clus) + first_fat_data_lba
	sub ax, 2
	xor dx, dx

	push dx
	xor cx, cx
	mov cl, [first_sector+fat_bpb.sectors_per_clus]
	mul cx

	pop si          ;; Old DX
	imul si, cx     ;; Old DX = Old DX * CX
	add dx, si      ;; DX += Old DX

	;; DX:AX = (clus - 2) * fat_bpb->sectors_per_clus
	add ax, word [fat_data_lba]
	adc dx, word [fat_data_lba+2]

	clc
	pop si
	pop cx
	ret
.error:
	stc
	pop si
	pop cx
	ret

;; Verify if cluster is EOF
;; AX: cluster
;; Returns:
;; CF If is EOF
clus_is_eof:
	cmp byte [fat_type], 12
	je .fat12

	cmp byte [fat_type], 16
	je .fat16
	stc
	ret
.fat12:
	cmp ax, 0x0FF8
	jae .fat12.EOF
	clc
	ret
.fat12.EOF:
	stc
	ret
.fat16:
	cmp ax, 0xFFF8
	jae .fat16.EOF
	clc
	ret
.fat16.EOF:
	stc
	ret

;; Reads the FAT 
;; AX: Cluster
;; Returns:
;; CF on fail
;; BX: Value
read_fat:
	push ax
	push cx
	push dx
	cmp byte [fat_type], 12
	je .fat12

	cmp byte [fat_type], 16
	je .fat16
.error:
	stc
	pop dx
	pop cx
	pop ax
	ret
.fat12:
	push ax
	;; fat_offset = cluster + (cluster << 1)
	mov bx, ax
	shl bx, 1
	add ax, bx
	mov bx, ax
	;; BX = cluster + (cluster <<  1)
	
	;; NOTE: In this code, I assume that fat_sector will not exceed 16 bits

	;; fat_sector = fat_lba + (fat_offset / sector_size)
	;; ent_offset = fat_offset % sector_size
	xor dx, dx
	mov cx, sector_size
	div cx
	;; AX = fat_offset / sector_size
	;; DX = fat_offset % sector_size

	add ax, word [fat_lba]
	;; AX = fat_lba + (fat_offset / sector_size)

	;; AX = fat_sector
	;; DX = ent_offset

	;; Read fat sectors
	push ax
	push dx
	;; Sector +0
	mov bx, sector_buffer
	xor dx, dx
	call read_sector

	;; Sector +1 
	add ax, 1
	adc dx, 0
	add bx, sector_size
	call read_sector
	pop dx
	pop ax

	;; table_val = *(uint16_t *)&fat[ent_offset]
	mov bx, sector_buffer
	add bx, dx
	mov cx, [bx]
	mov bx, cx
	pop ax
	;; BX = table_val
	;; AX = cluster

	;; If cluster is even, use last 12 bits, else use first 12 bits
	test ax, 1
	jz .is_even
	shr bx, 4
	jmp .fat12.end
.is_even:
	and bx, 0x0FFF
.fat12.end:
	clc
	pop dx
	pop cx
	pop ax
	ret
.fat16:
	push ax
	;; fat_offset = cluster << 1
	mov bx, ax
	shl bx, 1
	;; BX = cluster << 1
	
	;; NOTE: In this code, I assume that fat_sector will not exceed 16 bits

	;; fat_sector = fat_lba + (fat_offset / sector_size)
	;; ent_offset = fat_offset % sector_size
	xor dx, dx
	mov cx, sector_size
	div cx
	;; AX = fat_offset / sector_size
	;; DX = fat_offset % sector_size

	add ax, word [fat_lba]
	;; AX = fat_lba + (fat_offset / sector_size)

	;; AX = fat_sector
	;; DX = ent_offset

	;; Read fat sectors
	push ax
	push dx
	;; Sector +0
	mov bx, sector_buffer
	xor dx, dx
	call read_sector
	pop dx
	pop ax

	;; table_val = *(uint16_t *)&fat[ent_offset]
	mov bx, sector_buffer
	add bx, dx
	mov cx, [bx]
	mov bx, cx
	pop ax
	;; BX = table_val
	;; AX = cluster
	
	clc
	pop dx
	pop cx
	pop ax
	ret

;; Initialize FAT system
;; BL: Disk to read
;; DX:AX: Start LBA of partition
;; Return:
;; CF: If is not valid FAT partition
fat_init:
	pusha
	push dx
	mov dl, bl
	call set_drive
	pop dx
	
	mov bx, first_sector
	call read_sector
	jc .error

	;; Only supports 512 bytes per sector
	cmp word [first_sector+fat_bpb.bytes_per_sector], sector_size
	jne .error

	mov word [fat_start_sector], ax
	mov word [fat_start_sector+2], dx

	mov word [fat_sector_size], sector_size

	;; Total Sectors
	push ax
	mov ax, [first_sector+fat_bpb.total_sectors16]
	mov word [fat_total_sectors], ax
	mov word [fat_total_sectors+2], 0
	cmp word [fat_total_sectors], 0
	pop ax
	jne .use_fat_total_sectors16

	push ax
	mov ax, [first_sector+fat_bpb.total_sectors32]
	mov word [fat_total_sectors], ax
	mov ax, [first_sector+fat_bpb.total_sectors32+2]
	mov word [fat_total_sectors+2], ax
	pop ax
.use_fat_total_sectors16:

	;; Fat size
	push ax
	mov ax, [first_sector+fat_bpb.sectors_per_fat]
	mov word [fat_size], ax
	pop ax
	cmp word [fat_size], 0
	je .error

	;; fat_root_dir_sectors = ((root_dir_entries * 32) + (bytes_per_sector - 1)) / bytes_per_sector
	push ax
	push cx
	push dx
	mov ax, [first_sector+fat_bpb.root_dir_entries]
	mov cx, 32
	mul cx
	;; DX:AX = root_dir_entries * 32
	
	add ax, (sector_size-1)
	adc dx, 0
	;; DX:AX = (root_dir_entries * 32) + (bytes_per_sector - 1)

	div word [fat_sector_size]
	;; AX = ((root_dir_entries * 32) + (bytes_per_sector - 1)) / bytes_per_sector

	mov word [fat_root_dir_sectors], ax
	pop dx
	pop cx
	pop ax

	;; fat_data_lba = (num_fats * fat_size) + fat_root_dir_sectors + reserved_sectors + fat_start_sector
	push ax
	push cx
	push dx
	
	mov cx, [fat_size]
	xor ax, ax
	mov al, [first_sector+fat_bpb.num_fats]
	mul cx
	;; DX:AX = num_fats * fat_size

	add ax, [fat_root_dir_sectors]
	adc dx, 0
	;; DX:AX = (num_fats * fat_size) + fat_root_dir_sectors

	add ax, [first_sector+fat_bpb.reserved_sectors]
	adc dx, 0
	;; DX:AX = (num_fats * fat_size) + fat_root_dir_sectors + reserved_sectors

	add ax, [fat_start_sector]
	adc dx, [fat_start_sector+2]

	mov word [fat_data_lba], ax
	mov word [fat_data_lba+2], dx
	pop dx
	pop cx
	pop ax
	
	;; fat_lba = fat_start_sector + reserved_sectors
	push ax
	push dx
	mov ax, [first_sector+fat_bpb.reserved_sectors]
	xor dx, dx
	;; DX:AX = reserved_sectors
	
	add ax, [fat_start_sector]
	adc dx, [fat_start_sector+2]
	;; DX:AX = fat_start_sector + reserved_sectors

	mov word [fat_lba], ax
	mov word [fat_lba+2], dx
	pop dx
	pop ax

	;; fat_data_sectors = fat_total_sectors - ((num_fats * fat_size) + reserved_sectors + fat_root_dir_sectors)
	push ax
	push bx
	push cx
	push dx

	mov cx, [fat_size]
	xor ax, ax
	mov al, [first_sector+fat_bpb.num_fats]
	mul cx
	;; DX:AX = num_fats * fat_size

	add ax, [first_sector+fat_bpb.reserved_sectors]
	adc dx, 0
	;; DX:AX = (num_fats * fat_size) + reserved_sectors

	add ax, [fat_root_dir_sectors]
	adc dx, 0
	;; DX:AX = (num_fats * fat_size) + reserved_sectors + fat_root_dir_sectors
	
	mov bx, ax
	mov cx, dx

	mov ax, [fat_total_sectors]
	mov dx, [fat_total_sectors+2]

	sub ax, bx
	sbb dx, cx
	;; DX:AX = fat_total_sectors - ((num_fats * fat_size) + reserved_sectors + fat_root_dir_sectors)

	mov word [fat_data_sectors], ax
	mov word [fat_data_sectors+2], dx
	pop dx
	pop cx
	pop bx
	pop ax
	
	;; fat_total_clusters = fat_data_sectors / sectors_per_cluster
	push ax
	push cx
	push dx
	mov ax, word [fat_data_sectors]
	mov dx, word [fat_data_sectors+2]
	xor cx, cx
	mov cl, byte [first_sector+fat_bpb.sectors_per_clus]
	div cx
	;; AX = fat_data_sectors / sectors_per_cluster

	mov word [fat_total_clusters], ax
	pop dx
	pop cx
	pop ax

	;; root_lba = data_lba - root_dir_sectors
	push ax
	push dx
	mov ax, word [fat_data_lba]
	mov dx, word [fat_data_lba+2]
	sub ax, word [fat_root_dir_sectors]
	sbb dx, 0
	;; DX:AX = data_lba - root_dir_sectors

	mov word [fat_root_lba], ax
	mov word [fat_root_lba+2], dx
	pop dx
	pop ax

%ifdef DEBUG
	print "=== Fat information ==="
	newline
	print "start_sector:      0x"
	print_hex_dword word [fat_start_sector+2], word [fat_start_sector]
	newline
	print "total_sectors:     0x"
	print_hex_dword word [fat_total_sectors+2], word [fat_total_sectors]
	newline
	print "data_lba:          0x"
	print_hex_dword word [fat_data_lba+2], word [fat_data_lba]
	newline 
	print "data_sectors:      0x"
	print_hex_dword word [fat_data_sectors+2], word [fat_data_sectors]
	newline
	print "lba:               0x"
	print_hex_dword word [fat_lba+2], word [fat_lba]
	newline
	print "root_lba:          0x"
	print_hex_dword word [fat_root_lba+2], word [fat_root_lba]
	newline
	print "total_clusters:    0x"
	print_hex_word word [fat_total_clusters]
	newline
	print "root_dir_sectors:  0x"
	print_hex_word word [fat_root_dir_sectors]
	newline
	
	newline
	print "=== BPB ==="
	newline

	print "OEM ID: "
	mov si, first_sector + fat_bpb.oem_id
	mov cx, 8
	.print_oem:
		lodsb
		call print_char
		loop .print_oem
	newline

	print "Bytes per sector:       0x"
	print_hex_word word [first_sector+fat_bpb.bytes_per_sector]
	newline

	print "Sectors per cluster:    0x"
	print_hex_byte byte [first_sector+fat_bpb.sectors_per_clus]
	newline

	print "Reserved sectors:       0x"
	print_hex_word word [first_sector+fat_bpb.reserved_sectors]
	newline

	print "Number of FATs:         0x"
	print_hex_byte byte [first_sector+fat_bpb.num_fats]
	newline

	print "Root dir entries:       0x"
	print_hex_word word [first_sector+fat_bpb.root_dir_entries]
	newline

	print "Total sectors (16):     0x"
	print_hex_word word [first_sector+fat_bpb.total_sectors16]
	newline

	print "Media descriptor:       0x"
	print_hex_byte byte [first_sector+fat_bpb.media_desc_type]
	newline

	print "Sectors per FAT:        0x"
	print_hex_word word [first_sector+fat_bpb.sectors_per_fat]
	newline

	print "Sectors per track:      0x"
	print_hex_word word [first_sector+fat_bpb.sectors_per_track]
	newline

	print "Number of heads:        0x"
	print_hex_word word [first_sector+fat_bpb.number_of_heads]
	newline

	print "Hidden sectors:         0x"
	print_hex_dword word [first_sector+fat_bpb.hidden_sectors+2], \
					 word [first_sector+fat_bpb.hidden_sectors]
	newline

	print "Total sectors (32):     0x"
	print_hex_dword word [first_sector+fat_bpb.total_sectors32+2], \
					 word [first_sector+fat_bpb.total_sectors32]
	newline
%endif ;; DEBUG

	cmp word [fat_total_clusters], 4085

	jae .fat16
	mov byte [fat_type], 12
	jmp .initialized
.fat16: 
	mov byte [fat_type], 16
.initialized:
	mov byte [fat_initialized], 1
	clc
	popa
	ret
.error:
	stc
	popa
	ret

;; Reads a FAT directory from a cluster
;; BX: Starting directory cluster
;; DX:AX: Directory index
;; ES:DI: Pointer for entry
;; Returns:
;; CF is set if an error occurred or end of directory is reached
;; NOTE: If the Starting directory cluster is zero, read the root direcotry
fat_read_dir:
	pusha
	cmp byte [fat_initialized], 1
	jne .error

	mov word [.current_clus], bx
	mov word [.index], ax
	mov word [.index+2], dx

	cmp bx, 2
	jb .read_dir

	;; ents_per_clus = (sectors_per_clus * 512) / 32
	;; ents_per_clus = Total entries in a cluster
	;; faster: ents_per_clus = sectors_per_clus << 4
	;; because: 512 / 32 = 16; ents_per_clus = sectors_per_clus * 16 => ents_per_clus: << 4

	push ax
	mov ax, [first_sector+fat_bpb.sectors_per_clus]
	shl ax, 4
	;; AX = sectors_per_clus << 4
	mov word [.ents_per_clus], ax
	pop ax

	;; skip_clus = index / ents_per_clus
	;; skip_clus = Number of clusters to skip

	;; ent_clus = index % ents_per_clus
	;; ent_clus = Entry index inside the cluster
	push ax
	push dx
	div word [.ents_per_clus]
	;; AX = index / ents_per_clus 
	;; DX = index % ents_per_clus 

	mov word [.skip_clus], ax
	mov word [.ent_clus], dx
	pop dx
	pop ax

	;; sector = ent_clus / 16
	;; sector = Sector inside the cluster
	
	;; ent_sector = ent_clus % 16
	;; ent_sector = Entry index inside the sector
	push ax
	push dx
	mov ax, word [.ent_clus]
	xor dx, dx
	mov cx, 16
	div cx
	;; AX = ent_clus / 16
	;; DX = ent_clus % 16
	mov word [.sector], ax
	mov word [.ent_sector], dx
	pop dx
	pop ax

	;; Skip clusters
	xor cx, cx
.skip_cluster_loop:
	cmp cx, word [.skip_clus]
	jae .skip_cluster_loop.end

	push ax
	mov ax, word [.current_clus]
	call read_fat
	mov ax, bx
	call clus_is_eof
	pop ax
	jc .error

	mov word [.current_clus], bx
	inc cx
	jmp .skip_cluster_loop
.skip_cluster_loop.end:
	mov ax, word [.current_clus]
	call fat_clus_to_lba
	jc .error
.read_dir:
	cmp word [.current_clus], 2
	jae .skip_root_dir_sector

	;; This code executes if is root dir
	cmp word [.index+2], 0
	jne .error

	mov ax, word [first_sector+fat_bpb.root_dir_entries]
	cmp word [.index], ax
	jae .error

	;; sector = index / 16
	;; ent_sector = index % 16
	mov ax, word [.index]
	mov dx, word [.index+2]
	mov cx, 16
	div cx

	mov word [.ent_sector], dx

	xor dx, dx

	add ax, word [fat_root_lba]
	adc dx, word [fat_root_lba+2]

	mov word [.sector], ax
	mov word [.sector+2], dx
	xor ax, ax
	xor dx, dx
.skip_root_dir_sector:
	;; Read sector
	;; If is cluster: add. If is root dir: .sector is LBA
	mov bx, sector_buffer
	add ax, word [.sector]
	adc dx, word [.sector+2]
	call read_sector
	jc .error
	
	mov si, word [.ent_sector] 
	shl si, 5 ;; * 32
	add si, sector_buffer
	
	cmp byte [si+fat_entry.name], 0
	je .error ;; Reached end

	;; DS:SI = source
	;; ES:DI = dest

	mov cx, 32
	cld
	rep movsb ;; Copy

.end:
	clc
	popa
	ret
.error:
	stc
	popa
	ret
.index:         dd 0
.sector:        dd 0
.ents_per_clus: dw 0
.skip_clus:     dw 0
.ent_clus:      dw 0
.ent_sector:    dw 0
.current_clus:  dw 0

;; Finds an entry in a dir
;; BX: Start cluster
;; DS:SI: String to 8.3 name
;; ES:DI: Pointer to out entry
;; Returns:
;; CF if an error occurs
fat_find_in_dir:
	push ax
	push bx
	push cx
	push dx
	push di

	mov word [.out.seg], es
	mov word [.out.off], di

	xor ax, ax
	xor dx, dx
	mov di, .entry

.find_loop:
	call fat_read_dir
	jc .end
	
	test byte [.entry+fat_entry.attr], 0x08
	jnz .skip
	
	;; Compares name
	push di
	push si
	push ax
	push cx
	
	;; DS:SI Already points to string
	mov di, .entry+fat_entry.name
	mov cx, 11
.compare_loop:
	cmpsb
	jne .not_equal
	loop .compare_loop
.equal:
	mov cx, 32
	mov si, .entry
	mov di, word [.out.seg]
	mov es, di
	mov di, word [.out.off]
	cld
	rep movsb
	stc
.not_equal:
	pop cx
	pop ax
	pop si
	pop di

	jc .end
.skip:
	add ax, 1
	adc dx, 0
	jmp .find_loop
.end:
	clc
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret
.error:
	stc
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret
.out.seg: dw 0
.out.off: dw 0
section .bss
.entry:   resb fat_entry_size
section .text

;; List a directory tree in FAT
;; BX: Start cluster
;; CX: Depth
fat_list_tree:
	push ax
	push bx
	push cx
	push dx

	xor ax, ax
	xor dx, dx
	mov di, .entry

.list_loop:
	call fat_read_dir
	jc .end
	
	test byte [.entry+fat_entry.attr], 0x08
	jnz .skip

.print_name:
	push si
	push ax
	push cx
	
	test cx, cx
	jz .print_spaces.end

.print_spaces:
	mov al, ' '
	call print_char
	loop .print_spaces
.print_spaces.end:

	mov si, .entry+fat_entry.name
	mov cx, 11
.print_loop:
	lodsb
	call print_char
	loop .print_loop

	newline
	pop cx
	pop ax
	pop si

	cmp byte [.entry+fat_entry.name], '.'
	je .no_print_dir

	test byte [.entry+fat_entry.attr], 0x10
	jz .no_print_dir
	push bx
	push cx
	inc cx
	mov bx, word [.entry+fat_entry.clus_low]
	call fat_list_tree
	pop cx
	pop bx
.no_print_dir:

.skip:
	add ax, 1
	adc dx, 0
	jmp .list_loop

.end:
	pop dx
	pop cx
	pop bx
	pop ax
	ret
section .bss
.entry: resb fat_entry_size
section .text

;; List a directory in FAT
;; BX: Start cluster
;; CX: Depth
fat_list_dir:
	push ax
	push bx
	push cx
	push dx

	xor ax, ax
	xor dx, dx
	mov di, .entry

.list_loop:
	call fat_read_dir
	jc .end
	
	test byte [.entry+fat_entry.attr], 0x08
	jnz .skip

	cmp byte [.entry+fat_entry.name], '.'
	je .no_print_dir
.print_name:
	push si
	push ax
	push cx
	
	test cx, cx
	jz .print_spaces.end

.print_spaces:
	mov al, ' '
	call print_char
	loop .print_spaces
.print_spaces.end:

	mov si, .entry+fat_entry.name
	mov cx, 11
.print_loop:
	lodsb
	call print_char
	loop .print_loop

	newline
	pop cx
	pop ax
	pop si
.no_print_dir:

.skip:
	add ax, 1
	adc dx, 0
	jmp .list_loop

.end:
	pop dx
	pop cx
	pop bx
	pop ax
	ret
section .bss
.entry: resb fat_entry_size
section .text
section .data
fat_start_sector:     dd 0
fat_total_sectors:    dd 0
fat_data_lba:         dd 0
fat_data_sectors:     dd 0
fat_lba:              dd 0
fat_root_lba:         dd 0
fat_total_clusters:   dw 0
fat_root_dir_sectors: dw 0
fat_sector_size:      dw 0
fat_size:             dw 0
fat_type:             db 0
fat_initialized:      db 0

%endif ;; _FAT_ASM_


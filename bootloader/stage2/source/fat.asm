;; fat.asm
;; Created by Matheus Leme Da Silva
%ifndef _FAT_ASM_
%define _FAT_ASM_
%include "disk.asm"
section .text

;; WARNING: This driver only supports FAT12 and FAT16

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

;; Converts character in AL to UPPERCASE
;; AL: Char
;; Returns:
;; AL: Char UPPERCASE
section .text
to_upper:
	cmp al, 'a'
	jb .end
	cmp al, 'z'
	ja .end
	;; This code executes if AL >= 'a' && AL <= 'z'

	sub al, ('a' - 'A')
.end:
	ret

;; Converts normal filename to FAT filename
;; DS:SI: Filename
;; ES:DI: Out FAT filename
section .text
fat_filename_to_fatname:
	push ax
	push bx
	push cx
	push si
	push di

	push di
	;; Fill out FAT name with 11 ' '
	mov cx, 11
	mov al, ' '
	rep stosb
	pop di

	mov bx, di ;; Save out PTR on BX

	mov cx, 8
.name_loop:
	lodsb

	test al, al
	jz .end
	cmp al, '/'
	jz .end
	cmp al, '.'
	je .dot

	call to_upper

	mov byte [es:di], al
	inc di
	loop .name_loop
	jmp .end ;; Do not add extension if no encountered '.'
.dot:
	mov cx, 3
	mov di, bx
	add di, 8 ;; EXT
.ext_loop:
	lodsb
	test al, al
	jz .end

	call to_upper

	mov byte [es:di], al
	inc di

	loop .ext_loop
.end:
	pop di
	pop si
	pop cx
	pop bx
	pop ax
	ret

;; Converts cluster to LBA
;; AX: Cluster
;; Return
;; DX:AX: LBA
;; CF if an error occour
section .text
fat_clus_to_lba:
	push cx
	push si
	cmp byte [fat_initialized], 0
	je .error

	cmp ax, 2
	jb .error

	;; LBA = ((clus - 2) * fat_bpb->sectors_per_clus) + first_fat_data_lba
	sub ax, 2
	xor dx, dx

	xor cx, cx
	mov cl, [first_sector+fat_bpb.sectors_per_clus]
	mul cx

	;; DX:AX = (clus - 2) * fat_bpb->sectors_per_clus
	add ax, word [fat_data_lba]
	adc dx, word [fat_data_lba+2]

.end:
	jmp .ret
	clc
.error:
	stc
.ret:
	pop si
	pop cx
	ret

;; Verify if cluster is EOF
;; AX: cluster
;; Returns:
;; CF If is EOF
section .text
clus_is_eof:
	cmp byte [fat_type], 12
	je .fat12

	cmp byte [fat_type], 16
	je .fat16
	jmp .error
.fat12:
	cmp ax, 0x0FF8
	jae .error
.fat16:
	cmp ax, 0xFFF8
	jae .error
.end:
	clc
	jmp .ret
.error:
	stc
.ret:
	ret

;; Reads the FAT 
;; AX: Cluster
;; Returns:
;; CF if an error occours
;; BX: Value
section .text
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
	;; BX = cluster + (cluster << 1)
	
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

;; Skips n clusters 
;; AX: Start cluster
;; CX: Number of clusters to skip
;; Returns:
;; AX: The last cluster
;; CF If an error occours
skip_clusters:
	push bx
	push cx
	test cx, cx
	jz .end
.loop:
	call read_fat
	jc .error
	mov ax, bx
	call clus_is_eof
	jc .error
	loop .loop
	mov ax, bx
.end:
	clc
	jmp .ret
.error:
	stc
.ret:
	pop cx
	pop bx
	ret

;; Initialize FAT system
;; BL: Disk to read
;; DX:AX: Start LBA of partition
;; Return:
;; CF: If is not valid FAT partition
section .text
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

	;; ents_per_clus = (sectors_per_clus * 512) / 32
	;; ents_per_clus = Total entries in a cluster
	;; faster: ents_per_clus = sectors_per_clus << 4
	;; because: 512 / 32 = 16; ents_per_clus = sectors_per_clus * 16 => ents_per_clus: << 4

	push ax
	mov ax, [first_sector+fat_bpb.sectors_per_clus]
	shl ax, 4
	;; AX = sectors_per_clus << 4
	mov word [fat_ents_per_clus], ax
	pop ax

	;; bytes per clus = sectors_per_clus * sector_size
	push ax
	mov ax, word [first_sector+fat_bpb.sectors_per_clus]
	shl ax, 9
	mov word [fat_bytes_per_clus], ax
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
.end:
	clc
	jmp .ret
.error:
	stc
.ret:
	popa
	ret

;; Reads a FAT directory from a cluster
;; BX: Starting directory cluster
;; AX: Directory index
;; ES:DI: Pointer for entry
;; Returns:
;; CF is set if an error occurred or end of directory is reached
;; NOTE: If the Starting directory cluster is zero, read the root direcotry
section .text
fat_read_dir:
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	cmp byte [fat_initialized], 1
	jne .error

	cmp bx, 2
	jb .root_dir

	;; skip_clus = index / ents_per_clus
	;; skip_clus = Number of clusters to skip

	;; ent_clus = index % ents_per_clus
	;; ent_clus = Entry index inside the cluster
	xor dx, dx
	div word [fat_ents_per_clus]
	;; AX = index / ents_per_clus
	;; DX = index % ents_per_clus

	mov cx, ax
	mov ax, bx
	call skip_clusters
	jc .error
	mov cx, ax

	;; sector = ent_clus / 16
	;; sector = Sector inside the cluster
	
	;; ent_sector = ent_clus % 16
	;; ent_sector = Entry index inside the sector
	mov ax, dx
	xor dx, dx
	mov bx, 16
	div bx
	
	;; AX = sector
	;; DX = ent_sector
	mov bx, ax
	mov si, dx

	mov ax, cx
	call fat_clus_to_lba
	jc .error
	
	;; Read sector
	add ax, bx
	adc dx, 0
	mov bx, sector_buffer
	call read_sector
	jc .error
	
	shl si, 5 ;; * 32
	add si, sector_buffer
	
	cmp byte [si+fat_entry.name], 0
	je .error ;; Reached end
	jmp .copy

.root_dir:
	xor dx, dx
	mov cx, 16
	;; sector = ent_clus / 16
	;; sector = Sector inside the cluster
	
	;; ent_sector = ent_clus % 16
	;; ent_sector = Entry index inside the sector
	div cx
	;; AX = sector
	;; DX = entry

	cmp ax, word [fat_root_dir_sectors]
	jae .error

	mov si, dx ;; Save entry 
	mov bx, ax ;; Save sector
	mov ax, word [fat_root_lba]
	mov dx, word [fat_root_lba+2]
	add ax, bx
	adc dx, 0

	mov bx, sector_buffer
	call read_sector
	jc .error 

	shl si, 5 ;; * 32
	add si, sector_buffer

	cmp byte [si+fat_entry.name], 0
	je .error

.copy:
	;; DS:SI = source
	;; ES:DI = dest
	mov cx, 32
	cld
	rep movsb ;; Copy

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

;; Finds an entry in a dir
;; BX: Start cluster
;; DS:SI: String to 8.3 name
;; ES:DI: Pointer to out entry
;; Returns:
;; CF if an error occurs
section .text
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
	jc .error
	
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
	cld
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
	pop cx
	pop ax
	pop si
	pop di
	jmp .end
.not_equal:
	pop cx
	pop ax
	pop si
	pop di
.skip:
	add ax, 1
	adc dx, 0
	jmp .find_loop
.end:
	clc
	jmp .ret
.error:
	stc
.ret:
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret
section .data
.out.seg:  dw 0
.out.off:  dw 0
section .bss
.entry:    resb fat_entry_size

;; Finds file using absolute PATH
;; DS:SI: Path
;; ES:DI: Out
;; Returns:
;; CF if an error occour
section .text
fat_find:
	push ax
	push bx
	push cx
	push si
	push di

	mov word [.out.seg], es
	mov word [.out.off], di

	cmp byte [si], '/'
	jne .error ;; Is not absolute PATH
	
	xor bx, bx ;; Start on root dir
.find_loop:
	mov al, byte [si]

	test al, al
	jz .end

	cmp al, '/'
	je .loop_end

	;; SI already points to filename
	push di
	mov di, .fat_name
	call fat_filename_to_fatname
	pop di
	
	;; Find in dir
	push si
	push di
	push es
	mov si, .fat_name
	mov di, word [.out.seg]
	mov es, di
	mov di, word [.out.off]
	call fat_find_in_dir
	pop es
	pop di
	pop si
	jc .error

	test byte [es:di+fat_entry.attr], 0x10
	jz .end ;; Is FILE

	;; Is DIR, Set current clus(BX) to clus_low of the entry
	mov bx, word [es:di+fat_entry.clus_low]

;; Jump to next '/'
.next_slash:
	cmp byte [si], '/'
	je .loop_end
	inc si
	jmp .next_slash

.loop_end:
	inc si
	jmp .find_loop

.end:
	clc
	jmp .ret
.error:
	stc
.ret:
	pop di
	pop si
	pop cx
	pop bx
	pop ax
	ret
section .bss
.out.seg:  resw 1
.out.off:  resw 1
.fat_name: resb 12

;; Reads FAT data
;; CX: Cluster
;; BX: Bytes to read
;; DX:AX: Offset
;; Returns:
;; CF if an error occours
section .text
fat_read:
	push ax
	push bx
	push cx
	push dx

	cmp byte [fat_initialized], 0
	je .error

	;; skip clusters = offset / bytes_per_clus
	;; cluster offset = offset % bytes_per_clus
	div word [fat_bytes_per_clus]
	;; AX = skip clusters
	;; DX = cluster offset
	push cx
	xchg ax, cx
	call skip_clusters
	pop cx
	;; AX = start_clus
	push ax
	;; sector in cluster = offset / sector_size
	;; offset in sector = offset % sector_size
	mov ax, dx
	xor dx, dx
	div word [sector_size]
	;; AX = sector in cluster
	;; DX = offset in sector
	push bx
	mov bx, dx
	xor dx, dx
	pop ax
	
.root_dir:
	

.end:
	clc
	jmp .ret
.error:
	stc
.ret:
	pop dx
	pop cx
	pop bx
	pop ax
	ret

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
fat_bytes_per_clus:   dw 0
fat_ents_per_clus:    dw 0
fat_type:             db 0
fat_initialized:      db 0

%endif ;; _FAT_ASM_


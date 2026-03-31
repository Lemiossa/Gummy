;; fat.asm
;; Created by Matheus Leme Da Silva
%ifndef _FAT_ASM_
%define _FAT_ASM_
%include "disk.asm"
section .text

first_sector:     equ 0x500
sector_buffer:    equ first_sector + sector_size

struc bpb
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

;; Converts cluster to LBA
;; DX:AX: Cluster
;; Return
;; DX:AX: LBA
;; CF if an error occour
cluster_to_lba:
	push cx
	push si
	cmp byte [fat_initialized], 0
	je .error

	;; LBA = ((clus - 2) * bpb->sectors_per_clus) + first_fat_data_lba
	sub ax, 2
	sbb dx, 0
	
	push dx
	xor cx, cx
	mov cl, [first_sector+bpb.sectors_per_clus]
	mul cx

	pop si          ;; Old DX
	imul si, cx     ;; Old DX = Old DX * CX
	add dx, si      ;; DX += Old DX

	;; DX:AX = (clus - 2) * bpb->sectors_per_clus
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
	cmp word [first_sector+bpb.bytes_per_sector], sector_size
	jne .error

	mov word [fat_start_sector], ax
	mov word [fat_start_sector+2], dx

	mov word [fat_sector_size], sector_size

	;; Total Sectors
	push ax
	mov ax, [first_sector+bpb.total_sectors16]
	mov word [fat_total_sectors], ax
	mov word [fat_total_sectors+2], 0
	cmp word [fat_total_sectors], 0
	pop ax
	jne .use_fat_total_sectors16

	push ax
	mov ax, [first_sector+bpb.total_sectors32]
	mov word [fat_total_sectors], ax
	mov ax, [first_sector+bpb.total_sectors32+2]
	mov word [fat_total_sectors+2], ax
	pop ax
.use_fat_total_sectors16:

	;; Fat size
	push ax
	mov ax, [first_sector+bpb.sectors_per_fat]
	mov word [fat_size], ax
	pop ax
	cmp word [fat_size], 0
	je .error

	;; fat_root_dir_sectors = ((root_dir_entries * 32) + (bytes_per_sector - 1)) / bytes_per_sector
	push ax
	push cx
	push dx
	mov ax, [first_sector+bpb.root_dir_entries]
	mov cx, 32
	mul cx
	;; DX:AX = root_dir_entries * 32
	
	add ax, (sector_size-1)
	adc dx, 0
	;; DX:AX = (root_dir_entries * 32) + (bytes_per_sector - 1)

	div word [fat_sector_size]
	;; DX:AX = ((root_dir_entries * 32) + (bytes_per_sector - 1)) / bytes_per_sector

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
	mov al, [first_sector+bpb.num_fats]
	mul cx
	;; DX:AX = num_fats * fat_size

	add ax, [fat_root_dir_sectors]
	adc dx, 0
	;; DX:AX = (num_fats * fat_size) + fat_root_dir_sectors

	add ax, [first_sector+bpb.reserved_sectors]
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
	mov ax, [first_sector+bpb.reserved_sectors]
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
	mov al, [first_sector+bpb.num_fats]
	mul cx
	;; DX:AX = num_fats * fat_size

	add ax, [first_sector+bpb.reserved_sectors]
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
	mov cl, byte [first_sector+bpb.sectors_per_clus]
	div cx
	;; AX = fat_data_sectors / sectors_per_cluster

	mov word [fat_total_clusters], ax
	pop dx
	pop cx
	pop ax

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

section .data
fat_start_sector:     dd 0
fat_total_sectors:    dd 0
fat_data_lba:         dd 0
fat_data_sectors:     dd 0
fat_lba:              dd 0
fat_total_clusters:   dw 0
fat_root_dir_sectors: dw 0
fat_sector_size:      dw 0
fat_size:             dw 0
fat_type:             db 0
fat_initialized:      db 0

%endif ;; _FAT_ASM_


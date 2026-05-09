;; fat.asm
;; Criado por Matheus Leme Da Silva
%ifndef _FAT_ASM_
%define _FAT_ASM_
%include "disk.asm"
section .text

;; ATENÇÃO: Este driver só suporta FAT12 e FAT16

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
	.total_sectors16:  resw 1 ;; Se for zero, usa .fat_total_sectors32
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
	.res0:         resb 2 ;; Reservado Windows NT e tempo de criação em centésimos
	.created_time: resw 1 ;; HHHHHMMMMMMSSSSS; Multiplicar segundos por 2
	.created_date: resw 1 ;; YYYYYYYMMMMDDDDD;
	.accessed_date:resw 1 ;; YYYYYYYMMMMDDDDD;
	.clus_high:    resw 1
	.modified_time:resw 1 ;; HHHHHMMMMMMSSSSS;
	.modified_date:resw 1 ;; YYYYYYYMMMMDDDDD;
	.clus_low:     resw 1
	.file_size:    resd 1
endstruc

;; Converte caractere em AL para MAIÚSCULO
;; AL: Caractere
;; Retorna:
;; AL: Caractere MAIÚSCULO
section .text
to_upper:
	cmp al, 'a'
	jb .end
	cmp al, 'z'
	ja .end
	;; Este código executa se AL >= 'a' && AL <= 'z'

	sub al, ('a' - 'A')
.end:
	ret

;; Converte nome de arquivo normal para nome de arquivo FAT
;; DS:SI: Nome do arquivo
;; ES:DI: Saída com nome FAT
section .text
fat_filename_to_fatname:
	push ax
	push bx
	push cx
	push si
	push di

	push di
	;; Preenche nome FAT com 11 espaços
	mov cx, 11
	mov al, ' '
	rep stosb
	pop di

	mov bx, di ;; Salva ponteiro de saída em BX

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
	jmp .end ;; Não adiciona extensão se não encontrar '.'
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

;; Converte cluster para LBA
;; AX: Cluster
;; Retorna
;; DX:AX: LBA
;; CF se ocorrer um erro
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

;; Verifica se cluster é EOF
;; AX: cluster
;; Retorna:
;; CF Se for EOF
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

;; Lê a FAT
;; AX: Cluster
;; Retorna:
;; CF se ocorrer um erro
;; BX: Valor
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
	
	;; NOTA: Neste código, assumo que fat_sector não excederá 16 bits

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

	;; Lê setores da FAT
	push ax
	push dx
	;; Setor +0
	mov bx, sector_buffer
	xor dx, dx
	call read_sector

	;; Setor +1 
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

	;; Se cluster for par, usa últimos 12 bits, senão usa primeiros 12 bits
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
	
	;; NOTA: Neste código, assumo que fat_sector não excederá 16 bits

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

	;; Lê setores da FAT
	push ax
	push dx
	;; Setor +0
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

;; Pula n clusters
;; AX: Cluster inicial
;; CX: Número de clusters para pular
;; Retorna:
;; AX: O último cluster
;; CF Se ocorrer um erro
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

;; Inicializa o sistema FAT
;; BL: Disco para ler
;; DX:AX: LBA inicial da partição
;; Retorna:
;; CF: Se não for uma partição FAT válida
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

	;; Suporta apenas 512 bytes por setor
	cmp word [first_sector+fat_bpb.bytes_per_sector], sector_size
	jne .error

	mov word [fat_start_sector], ax
	mov word [fat_start_sector+2], dx

	mov word [fat_sector_size], sector_size

	;; Total de setores
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
	;; Tamanho da FAT
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
	;; ents_per_clus = Total de entradas em um cluster
	;; mais rápido: ents_per_clus = sectors_per_clus << 4
	;; porque: 512 / 32 = 16; ents_per_clus = sectors_per_clus * 16 => ents_per_clus: << 4

	push ax
	mov ax, [first_sector+fat_bpb.sectors_per_clus]
	shl ax, 4
	;; AX = sectors_per_clus << 4
	mov word [fat_ents_per_clus], ax
	pop ax

	;; bytes por cluster = sectors_per_clus * sector_size
	push ax
	mov ax, word [first_sector+fat_bpb.sectors_per_clus]
	shl ax, 9
	mov word [fat_bytes_per_clus], ax
	pop ax
%ifdef DEBUG
	print "=== Informacoes FAT ==="
	newline
	print "setor_inicial:      0x"
	print_hex_dword word [fat_start_sector+2], word [fat_start_sector]
	newline
	print "total_setores:     0x"
	print_hex_dword word [fat_total_sectors+2], word [fat_total_sectors]
	newline
	print "data_lba:          0x"
	print_hex_dword word [fat_data_lba+2], word [fat_data_lba]
	newline 
	print "data_setores:      0x"
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
	print "root_dir_setores:  0x"
	print_hex_word word [fat_root_dir_sectors]
	newline
	
	newline
	print "=== BPB ==="
	newline

	print "ID OEM: "
	mov si, first_sector + fat_bpb.oem_id
	mov cx, 8
	.print_oem:
		lodsb
		call print_char
		loop .print_oem
	newline

	print "Bytes por setor:        0x"
	print_hex_word word [first_sector+fat_bpb.bytes_per_sector]
	newline

	print "Setores por cluster:    0x"
	print_hex_byte byte [first_sector+fat_bpb.sectors_per_clus]
	newline

	print "Setores reservados:     0x"
	print_hex_word word [first_sector+fat_bpb.reserved_sectors]
	newline

	print "Numero de FATs:         0x"
	print_hex_byte byte [first_sector+fat_bpb.num_fats]
	newline

	print "Entradas dir raiz:      0x"
	print_hex_word word [first_sector+fat_bpb.root_dir_entries]
	newline

	print "Total setores (16):     0x"
	print_hex_word word [first_sector+fat_bpb.total_sectors16]
	newline

	print "Descritor de midia:     0x"
	print_hex_byte byte [first_sector+fat_bpb.media_desc_type]
	newline

	print "Setores por FAT:        0x"
	print_hex_word word [first_sector+fat_bpb.sectors_per_fat]
	newline

	print "Setores por trilha:     0x"
	print_hex_word word [first_sector+fat_bpb.sectors_per_track]
	newline

	print "Numero de cabecas:      0x"
	print_hex_word word [first_sector+fat_bpb.number_of_heads]
	newline

	print "Setores ocultos:        0x"
	print_hex_dword word [first_sector+fat_bpb.hidden_sectors+2], \
					 word [first_sector+fat_bpb.hidden_sectors]
	newline

	print "Total setores (32):     0x"
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

;; Lê um diretório FAT a partir de um cluster
;; BX: Cluster inicial do diretório
;; AX: Índice do diretório
;; ES:DI: Ponteiro para a entrada
;; Retorna:
;; CF é definido se ocorrer um erro ou fim do diretório for atingido
;; NOTA: Se o cluster inicial for zero, lê o diretório raiz
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

	;; skip_clus = indice / ents_per_clus
	;; skip_clus = Número de clusters para pular

	;; ent_clus = indice % ents_per_clus
	;; ent_clus = Índice da entrada dentro do cluster
	xor dx, dx
	div word [fat_ents_per_clus]
	;; AX = indice / ents_per_clus
	;; DX = indice % ents_per_clus

	mov cx, ax
	mov ax, bx
	call skip_clusters
	jc .error
	mov cx, ax

	;; sector = ent_clus / 16
	;; sector = Setor dentro do cluster
	
	;; ent_sector = ent_clus % 16
	;; ent_sector = Índice da entrada dentro do setor
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
	
	;; Lê setor
	add ax, bx
	adc dx, 0
	mov bx, sector_buffer
	call read_sector
	jc .error
	
	shl si, 5 ;; * 32
	add si, sector_buffer
	
	cmp byte [si+fat_entry.name], 0
	je .error ;; Fim do diretório
	jmp .copy

.root_dir:
	xor dx, dx
	mov cx, 16
	;; sector = ent_clus / 16
	;; sector = Setor dentro do cluster
	
	;; ent_sector = ent_clus % 16
	;; ent_sector = Índice da entrada dentro do setor
	div cx
	;; AX = setor
	;; DX = entrada

	cmp ax, word [fat_root_dir_sectors]
	jae .error

	mov si, dx ;; Salva entrada
	mov bx, ax ;; Salva setor
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
	;; DS:SI = origem
	;; ES:DI = destino
	mov cx, 32
	cld
	rep movsb ;; Copia

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

;; Encontra uma entrada em um diretório
;; BX: Cluster inicial
;; DS:SI: String para nome 8.3
;; ES:DI: Ponteiro para entrada de saída
;; Retorna:
;; CF se ocorrer um erro
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
	
	;; Compara nome
	push di
	push si
	push ax
	push cx
	
	;; DS:SI já aponta para a string
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

;; Encontra arquivo usando CAMINHO absoluto
;; DS:SI: Caminho
;; ES:DI: Saída
;; Retorna:
;; CF se ocorrer um erro
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
	jne .error ;; Não é caminho absoluto
	
	xor bx, bx ;; Começa no diretório raiz
.find_loop:
	mov al, byte [si]

	test al, al
	jz .end

	cmp al, '/'
	je .loop_end

	;; SI já aponta para o nome do arquivo
	push di
	mov di, .fat_name
	call fat_filename_to_fatname
	pop di
	
	;; Procura no diretório
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
	jz .end ;; É arquivo

	;; É DIR, Define clus atual(BX) para clus_low da entrada
	mov bx, word [es:di+fat_entry.clus_low]

	;; Pula para o próximo componente
	;; Ex: si aponta para subdir/text.txt
	;; Depois, si aponta para text.txt
.next:
	mov al, byte [si]
	test al, al
	jz .end

	inc si
	cmp byte [si-1], '/'
	jne .next

	jmp .find_loop
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

;; Lê arquivo
;; DS:SI: Entrada
;; ES:BX: Saída
;; DX:AX: Deslocamento
;; CX: Bytes para ler
section .text
fat_read_file:
	push ax
	push bx
	push cx
	push dx
	push di
	push si
	push bp
	
	test cx, cx
	jz .end ;; Bytes para ler == 0

	test byte [si+fat_entry.attr], 0x10
	jnz .error ;; É diretório
	
	cmp byte [si+fat_entry.clus_low], 2
	jb .error

	;; Pula clusters = deslocamento / tamanho do cluster
	;; Setor no cluster = deslocamento % tamanho do cluster
	div word [fat_bytes_per_clus]
	;; AX = Pula clusters
	;; DX = Setor no cluster

	push ax
	push cx
	push dx
	mov cx, ax
	mov ax, word [si+fat_entry.clus_low]
	call skip_clusters
	mov bp, ax
	pop dx
	pop cx
	pop ax
	

.end:
	clc
	jmp .ret
.error:
	stc
.ret:
	pop bp
	pop si
	pop di
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


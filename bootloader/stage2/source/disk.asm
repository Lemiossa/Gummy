;; disk.asm
;; Criado por Matheus Leme Da Silva
%ifndef _DISK_ASM_
%define _DISK_ASM_
%include "console.asm"

sector_size:      equ 0x200

;; Define a unidade para operações de disco
;; DL: Número da unidade
section .text
set_drive:
	pusha
	mov byte [current_drive_number], dl
	call get_drive_parameters
	mov byte [current_sectors_per_track], cl
	mov byte [current_heads], dh
	popa

	ret

;; Retorna parâmetros da unidade de disco
;; Usa current_drive
;; Retorna:
;; CL: Setores por trilha
;; DH: Número de cabeças
;; CF se ocorreu um erro
section .text
get_drive_parameters:
	push ax
	push di
	push es

	xor ax, ax
	mov es, ax

	clc
	mov ah, 0x08
	mov dl, byte [current_drive_number]
	xor di, di
	int 0x13
	jc .error

	;; CL[bits 0-5] = setores por trilha
	;; DH = cabeças - 1
	and cl, 0x3F
	inc dh

	clc
	jmp .ret
.error:
	stc
.ret:
	pop es
	pop di
	pop ax
	ret

;; Reinicia um disco
section .text
disk_reset:
	push ax
	push dx
	clc
	mov dl, byte [current_drive_number]
	mov ah, 0x00
	int 0x13
	jc .error
	;; Carry já está limpo
	jmp .ret
.error:
	stc
.ret:
	pop dx
	pop ax
	ret

;; Converte LBA para CHS
;; DX:AX: LBA
;; Retorna:
;; formato int13h:
;;    ch = cilindro baixo
;;    cl = setor | cilindro alto
;;    dh = cabeça
lba_to_chs:
	push bx
	;; LBA -> CHS
	;; C = (LBA / setores_por_trilha) / cabeças
	;; H = (LBA / setores_por_trilha) % cabeças
	;; S = (LBA % setores_por_trilha) + 1

	xor bx, bx
	mov bl, byte [current_sectors_per_track]
	div bx
	;; AX = LBA / setores_por_trilha
	;; DX = LBA % setores_por_trilha
	xor dh, dh
	inc dx
	mov byte [.sector], dl
	
	xor dx, dx
	mov bl, byte [current_heads]
	div bx
	;; AX = (LBA / setores_por_trilha) / cabeças
	;; DX = (LBA / setores_por_trilha) % cabeças
	mov word [.cylinder], ax
	mov byte [.head], dl

	;; CH = Cilindro & 0xFF
	;; CL = Setor | ((Cilindro >> 2) & 0xC0)
	;; DH = Cabeça
	mov ch, byte [.cylinder]
	mov bx, word [.cylinder]
	shr bx, 2
	and bx, 0xC0
	mov cl, byte [.sector]
	and cl, 0x3F ;; Setor usa cinco bits
	or cl, bl
	mov dh, [.head]

	pop bx
	ret
section .bss
.cylinder: resw 1
.head:     resb 1
.sector:   resb 1

;; Lê um setor (DX:AX) do disco para a memória (ES:BX)
;; DX:AX: LBA
;; ES:BX: Endereço
section .text
read_sector:
	push ax
	push cx
	push dx
	push si

%ifdef DEBUG
	print "Lendo setor: 0x"
	print_hex_dword dx, ax
	print ", spt=0x"
	print_hex_byte byte [current_sectors_per_track]
	print ", cabecas=0x"
	print_hex_byte byte [current_heads]
	newline
%endif ;; DEBUG
	
	call lba_to_chs

	;; int13h ah=2 func
	;; Parâmetros:
	;; al = contagem de setores
	;; ch = cilindro & 0xFF
	;; cl = (setor & 0x3F) | ((cilindro & 0xC000) >> 13)
	;; dh = cabeça
	;; dl = unidade
	;; es:bx = ponteiro

	mov si, 3
	jmp .try
.retry:
	call disk_reset
	jc .error
.try:
	clc
	mov ax, 0x0201 ;; função leitura, 1 setor
	mov dl, [current_drive_number]
	int 0x13
	jnc .end
	test si, si
	jz .error
	dec si
	jmp .retry
.end:
	clc
	jmp .ret
.error:
	stc
.ret:
	pop si
	pop dx
	pop cx
	pop ax
	ret

section .bss
current_drive_number:      resb 1
current_sectors_per_track: resb 1
current_heads:             resb 1

%endif ;; _DISK_ASM_


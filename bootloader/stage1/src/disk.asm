;; disk.asm
;; Criado por Matheus Leme Da Silva
%ifndef _disk_asm_
%define _disk_asm_

;; Le um setor (DX:AX) do disco para a memoria (ES:BX)
;; DX: LBA alto
;; AX: LBA baixo
;; ES: SEGMENTO onde carregar
;; BX: Offset onde carregar
read_sector:
	push ax
	push cx
	push dx

	;; LBA -> CHS
	;; C = (LBA / sectors_per_track) / heads
	;; H = (LBA / sectors_per_track) % heads
	;; S = (LBA % sectors_per_track) + 1

	div word [sectors_per_track]
	;; AX = LBA / sectors_per_track
	;; DX = LBA % sectors_per_track
	inc dx
	mov dh, dl
	push dx

	xor dx, dx
	div word [heads]
	;; AX = (LBA / sectors_per_track) / heads
	;; DX = (LBA % sectors_per_track) % heads

	mov ch, al
	shl ah, 6
	mov cl, ah

	pop ax
	or cl, al

	shl dx, 8

	;; funcao int13h AH=2
	;; Parametros:
	;; AL = quantidade de setores
	;; CH = cilindro & 0xFF
	;; CL = (setor & 0x3F) | ((cilindro & 0xC000) >> 13)
	;; DH = cabeca
	;; DL = unidade
	;; ES:BX = ponteiro

	mov ax, 0x0201 ;; funcao de leitura, 1 setor
	mov dl, [drive]
	int 0x13

	jc int13_failed

	pop dx
	pop cx
	pop ax
	ret

;; Exibe a mensagem de erro do int13 E para o computador
int13_failed:
	mov si, int13_failed_message
	call print_string
	jmp halt

int13_failed_message: db "Falha no Int13!", 0x0d, 0x0a, 0

%endif ;; _DISK_ASM_

;; disk.asm
;; Criado por Matheus Leme Da Silva
%ifndef _DISK_ASM_
%define _DISK_ASM_

;; Lê um setor (DX:AX) do disco para a memória (ES:BX)
;; DX: LBA alta
;; AX: LBA baixa
;; ES: Segmento para carregar
;; BX: Deslocamento para carregar
read_sector:
	push ax
	push cx
	push dx

	;; LBA -> CHS
	;; C = (LBA / setores_por_trilha) / cabeças
	;; H = (LBA / setores_por_trilha) % cabeças
	;; S = (LBA % setores_por_trilha) + 1
	
	div word [sectors_per_track]
	;; AX = LBA / setores_por_trilha
	;; DX = LBA % setores_por_trilha
	inc dx
	mov dh, dl
	push dx
	
	xor dx, dx
	div word [heads]
	;; AX = (LBA / setores_por_trilha) / cabeças
	;; DX = (LBA % setores_por_trilha) % cabeças
	
	mov ch, al
	shl ah, 6
	mov cl, ah
	
	pop ax
	or cl, al

	shl dx, 8

	;; int13h ah=2 func
	;; Parâmetros:
	;; al = contagem de setores
	;; ch = cilindro & 0xFF 
	;; cl = (setor & 0x3F) | ((cilindro & 0xC000) >> 13)
	;; dh = cabeça
	;; dl = unidade
	;; es:bx = ponteiro

	mov ax, 0x0201 ;; função leitura, 1 setor
	mov dl, [drive]
	int 0x13

	jc int13_failed
	
	pop dx
	pop cx
	pop ax
	ret

;; Exibe mensagem de erro int13 e interrompe o computador
int13_failed:
	mov si, int13_failed_message
	call print_string
	jmp halt

int13_failed_message: db "Int13 falhou!", 0x0D, 0x0A, 0

%endif ;; _DISK_ASM_

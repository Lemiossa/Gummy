;; main.asm
;; Criado por Matheus Leme Da Silva
bits 16
org 0x7C00

start_addr:   equ 0x7E00
start_sector: equ 1
sector_count: equ 62

jmp short main
nop

;; Espaço para BPB
times 62 - ($ - $$) db 0

;; Função principal
main:
	cli
	xor ax, ax
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, 0x7C00
	sti

	mov [drive], dl

	;; Obtém setores por trilha e cabeças do disco
	mov ah, 0x08
	xor di, di
	int 0x13
	jc int13_failed

	;; AH = status
	;; CL[bits 0-5] = setores por trilha
	;; DH = cabeças - 1
	and cl, 0x3F
	inc dh
	mov [sectors_per_track], cl
	mov [heads], dh

	;; Configuração
	;; Define ES:BX para start_addr
	;; Define DX:AX para start_sector
	;; Define CX para contagem
	;; loop:
	;; Se CX == 0: salto distante
	;; Se BX >= 0x8000:
	;;     BX -= 0x8000
	;;     ES += 0x800
	;; ler
	;; BX += 512
	;; incrementar DX:AX
	;; voltar ao loop

	;; Endereço
	mov bx, (start_addr >> 4)
	mov es, bx
	mov bx, (start_addr & 0x0F)

	;; Setor
	mov ax, (start_sector & 0xFFFF)
	mov dx, ((start_sector >> 8) & 0xFFFF)
	
	mov cx, sector_count
.loop:
	test cx, cx
	jz .end
	
	cmp bx, 0x8000
	jb .no_increment_segment

	sub bx, 0x8000

	push ax
	mov ax, es
	add ax, 0x800
	mov es, ax
	pop ax

.no_increment_segment:
	call read_sector

	push ax
	mov ah, 0x0E
	mov al, '.'
	int 0x10
	pop ax

	add bx, 512
	
	add ax, 1
	adc dx, 0
	
	dec cx
	jmp .loop
.end:
	mov dl, [drive]

	;; Salto distante
	push word (start_addr >> 4)   ;; segmento
	push word (start_addr & 0x0F) ;; deslocamento
	retf

	jmp halt

%include "console.asm"
%include "disk.asm"

;; Exibe mensagem de parada e interrompe o computador
halt:
	mov si, halted_message
	call print_string

	cli
	hlt

halted_message: db "Sistema interrompido. Por favor, reinicie.", 0x0D, 0x0A, 0

drive: db 0
sectors_per_track: dw 0
heads: dw 0

times 440 - ($ - $$) db 0
;; Assinatura de boot
dd __TIME__

times 510 - ($ - $$) db 0
dw 0xAA55

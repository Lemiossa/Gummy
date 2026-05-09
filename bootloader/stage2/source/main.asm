;; main.asm
;; Criado por Matheus Leme Da Silva
org 0x7E00
bits 16
section .text

;; %define DEBUG

;; Jmp para main antes dos includes
jmp main

;; Início dos includes
%include "console.asm"
%include "a20.asm"
%include "disk.asm"
%include "fat.asm"
;; Fim dos includes

section .text
;; Encontra uma entrada FAT
;; DS:SI: caminho
;; ES:DI: Saída
;; Não retorna nada
;; Lida com erro automaticamente
find:
	print "Procurando "
	call print_string
	print "..."
	newline
	call fat_find
	jnc .normal
	print "Erro!"
	jmp halt
.normal:
	mov si, di+fat_entry.name
	mov cx, 11
.print:
	lodsb 
	mov ah, 0x0E
	call print_char
	loop .print
	newline
	ret

;; Função principal do bootloader
section .text
main:
	cli
	xor ax, ax
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, 0x7C00
	sti

	mov [drive], dl

	call console_init
	print "Bitix Bootloader"
	newline
	print "Build: ", __DATE__, " ", __TIME__
	newline
	newline

	print "Inicializando..."
	newline

	;; Inicializa sistema de arquivos FAT
	xor dx, dx
	xor ax, ax
	mov bl, [drive]
	call fat_init
	jnc .fat_ok
	print "Particao FAT invalida!"
	newline
	jmp halt
.fat_ok:

	;; Habilita linha A20
	call enable_a20_line
	jnc .a20_ok
	print "Falha ao habilitar linha A20!"
	newline
	jmp halt
.a20_ok:
	mov si, .path0
	mov di, .entry
	call find

	mov si, .path1
	call find

	print "Lendo..."
	newline
	mov si, .entry
	mov di, 0x1000
	mov es, di
	xor di, di
	xor ax, ax
	xor dx, dx
	mov cx, 32
	call fat_read_file

	jmp halt
.path0: db '/subdir', 0
.path1: db '/subdir/text.txt', 0
.entry: times fat_entry_size db 0

halt:
	print "Sistema interrompido! Pressione qualquer tecla para reiniciar.", 0x0D, 0x0A
	mov ah, 0x00
	int 0x16
	jmp 0xFFFF:0x0000


section .bss
drive: resb 1

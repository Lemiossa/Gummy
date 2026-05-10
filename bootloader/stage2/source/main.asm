;; main.asm
;; Criado por Matheus Leme Da Silva
org 0x7E00
bits 16
section .text

;; %define DEBUG

;; Jmp para main antes dos includes
jmp main

%include "console.asm"
%include "a20.asm"
%include "disk.asm"
%include "fat.asm"

section .text
halt16:
	print "Sistema interrompido! Pressione qualquer tecla para reiniciar.", 0x0D, 0x0A
	mov ah, 0x00
	int 0x16
	jmp 0xFFFF:0x0000

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
	jmp halt16
.fat_ok:
	mov si, kernel_path
	mov di, .entry
	call fat_find
	jnc .found
	print "Falha ao procurar: "
	mov si, kernel_path
	call print_string
	newline
	jmp halt16
.found:
	mov si, .entry
	mov bx, 0x1000
	mov es, bx
	xor bx, bx
	call fat_read_file
	jnc .readed
	print "Erro na leitura!"
	newline
	jmp halt16
.readed:
	;; Habilita linha A20
	call enable_a20_line
	jnc .a20_ok
	print "Falha ao habilitar linha A20!"
	newline
	jmp halt16
.a20_ok:
	cli
	lgdt [gdtr]
	mov eax, cr0
	or al, 1
	mov cr0, eax
	jmp 0x08:.protected
bits 32
.protected:
	;; Pular para o kernel
	jmp 0x10000

	jmp halt32
.entry: times fat_entry_size db 0

halt32:
	cli
	hlt
	jmp halt32

section .data
kernel_path: db '/system/kernel.sys'

%macro gdt_entry 4
	;; 1 = Limit, 2 = base, 3 = access, 4 = flags
	dw (%1 & 0xFFFF)
	dw (%2 & 0xFFFF)
	db ((%2 >> 16) & 0xFF)
	db (%3 & 0xFF)
	db (((%1 >> 16) & 0xF) | ((%4 & 0xF) << 4))
	db ((%2 >> 24) & 0xFF)
%endmacro

gdt:
	gdt_entry 0, 0, 0, 0
	gdt_entry 0xFFFFF, 0x0, 0x9A, 0xC
	gdt_entry 0xFFFFF, 0x0, 0x92, 0xC
gdt_end:

gdtr:
	dw gdt_end-gdt-1
	dd gdt

section .bss
drive: resb 1


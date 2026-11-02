;; main.asm
;; Criado por Matheus Leme Da Silva
org 0x7e00
bits 16
cpu 8086

%define CONFIG_LOC 0x1000

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00
    sti

;; Checar se a CPU é 286+
;; No 186 os bits 12-15 das flags SEMPRE são 1 depois de um popf
;; No 286+ eles podem ser zerados
check_286:
    pushf
    ;; flags antigas
    xor ax, ax
    push ax
    ;; ax, flags antigas
    popf
    ;; flags antigas
    pushf
    ;; novas flags, flags antigas
    pop ax
    ;; flags antigas
    popf
    ;; nada, flags antigas foram resturadas, e as flags zeradas estão em ax
    and ax, 0xF000
    cmp ax, 0xF000
    jne check_386 ;; é 286
    ;; 8086/186
    mov si, inccpu_error_message 
    call console_print_string
;; Para o sistema
halt:
    mov si, halted_message
    call console_print_string
    cli
    hlt
cpu 286
;; Checar se a CPU é 386+
;; Na 286 em real mode, os bits 12-14 não podem ser setados
;; Na 386+, podem
check_386:
    pushf
    mov ax, 0x7000
    push ax
    popf                ;; tenta setar bits 12-14
    pushf
    pop ax
    popf
    and ax, 0x7000
    jnz main ;; é 386+
    ;; 286
    mov si, inccpu_error_message 
    call console_print_string
    jmp halt
cpu 386
main:
    call disk_init
    jnc .disk_ok
    jmp halt
.disk_ok:
    mov si, start_message
    call console_print_string
    call fat_init
    jc fat_error

    ;; Carregar kernel
    mov si, kernel_file
    mov edx, 0x10000
    call read_file

    ;; Carregar init
    ;; mov si, init_file
    ;; mov edx, 0x30000
    ;; call read_file

    jmp exit_real_mode

.entry: times 32 db 0

exit_real_mode:
    call e820_init
    jc mem_error

    jmp _to32bit
    jmp halt

fat_error:
    mov si, fat_error_message
    call console_print_string
    jmp halt

mem_error:
    mov si, mem_error_message
    call console_print_string
    jmp halt

;; Zera a entry
zero_entry:
    ;; Zerar a entrada
    push di
    push ax
    push cx
    push es
    push ds
    pop es
    cld
    mov di, entry
    mov cx, 16
    xor ax, ax
    rep stosw
    pop es
    pop cx
    pop ax
    pop di
    ret

;; Carrega um arquivo do diretorio raiz
;;  ds:si: Filename, no formato FAT
;;  edx:   Endereco fisico de onde carregar
;; PARA O SISTEMA SE NÃO CONSEGUIR CARREGAR
read_file:
    push eax
    push ebx
    push edx
    push esi
    push edi
    push es

    call zero_entry

    ;; Encontra o arquivo
    call fat_find_in_root_dir
    jc .fail
    ;; EAX = indice do diretorio raiz
    ;; Le a entrada
    mov di, entry
    call fat_read_root_dir
    jc .fail

    ;; Le o arquivo do kernel
    mov si, entry
    mov ebx, edx
    shr edx, 4
    mov es, dx
    and ebx, 0xF
    call fat_read_file
    jnc .ret

    ;; Erro daqui em diante
.fail:
    mov si, fat_failed_to_load_error_message
    call console_print_string
    pop es
    pop edi
    pop esi
    pop edx
    pop ebx
    pop eax
    mov ah, 0x0E
    mov cx, 11
.print_name:
    lodsb
    int 0x10
    loop .print_name
    mov al, `\r`
    int 0x10
    mov al, `\n`
    int 0x10
    jmp halt
.ret:
    pop es
    pop edi
    pop esi
    pop edx
    pop ebx
    pop eax
    ret
entry: times 32 db 0

fat_failed_to_load_error_message: db `Falha ao ler arquivo: `, 0

%include "console.asm"
%include "disk.asm"
%include "fat.asm"
%include "e820.asm"

start_message:              db `\r\n`, NAME, ` bootloader v`, VERSION, `\r\n`, 0
mem_error_message:          db `Erro de memoria!\r\n`, 0
inccpu_error_message:       db `Erro: a CPU precisa ser 386+\r\n`, 0
halted_message:             db `Sistema parado! Reinicie.\r\n`, 0
config_invalid_size_message:db `Arquivo de config com tamanho errado, deve ser >0 e <=512\r\n`, 0
fat_error_message:          db `Erro de FAT!\r\n`, 0
kernel_file:                db `KERNEL  SYS`
init_file:                  db `INIT    SYS`

%include "32bit.asm"

;; disk.asm
;; Criado por Matheus Leme da Silva
%ifndef disk_asm
%define disk_asm
bits 16
cpu 386

struc disk_address_packet
    .size:     resb 1
    .reserved: resb 1
    .sectors:  resw 1
    .offset:   resw 1
    .segment:  resw 1
    .lba_low:  resd 1
    .lba_high: resd 1
endstruc

;; Inicializa o sistema de disco
;; DL: Unidade de disco
;; Faz a verificação do int13h extensions, caso contrário, para o sistema
disk_init:
    push bx
    push cx
    push dx
    mov byte [drive], dl
    mov ah, 0x41
    mov bx, 0x55AA
    int 0x13
    jc .error 

    cmp bx, 0xAA55
    jne .error

    test cx, 1
    jz .error
.end:
    clc
    jmp .ret
.error:
    mov si, extdisk_error_message
    call console_print_string
    jmp halt
.ret:
    pop dx
    pop cx
    pop bx
    ret


;; Le um setor do disco
;; EAX: Setor
;; ES:BX: Buffer
;; Retorna:
;; CF=1 se ocorrer um erro
disk_read_sector:
    push ax
    push cx
    push dx
    push si
    push es
    mov si, DAP
    mov word [si+disk_address_packet.offset], bx
    mov cx, es
    mov word [si+disk_address_packet.segment], es
    mov dword [si+disk_address_packet.lba_low], eax
    mov cx, 3
.read_loop:
    mov dl, byte [drive]
    mov ah, 0x42
    int 0x13
    jnc .end
    loop .read_loop
    jc .error
.end:
    clc
    jmp .ret
.error:
    mov si, failed_to_read_message
    call console_print_string
    jmp halt
.ret:
    pop es
    pop si
    pop dx
    pop cx
    pop ax
    ret

DAP:
    db 0x10, 0 ;; Size, reserved
    dw 1 ;; sectors
    dw 0, 0 ;; offset, segment
    dd 0, 0 ;; lba_low, lba_high

extdisk_error_message:      db `Erro: int13h extensions nao suportado\r\n`, 0
failed_to_read_message:     db `Erro: falha ao ler setor!\r\n`, 0

drive:             db 0

%endif ;; DISK_ASM

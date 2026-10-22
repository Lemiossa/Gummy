;; disk.asm
;; Criado por Matheus Leme da Silva
%ifndef disk_asm
%define disk_asm
bits 16

;; Inicializa o sistema de disco
;; DL: Unidade de disco
;; Retorna:
;; CF=1 se ocorrer um erro
disk_init:
    push cx
    push dx
    mov byte [drive], dl
    call disk_get_parameters
    jc .error
    mov byte [sectors_per_track], cl
    mov byte [heads], dh
    test cl, cl
    jz .error
    test dh, dh
    jz .error
.end:
    clc
    jmp .ret
.error:
    stc
.ret:
    pop dx
    pop cx
    ret

;; Obtem os parametros do disco
;; DL: Unidade de disco
;; Retorna:
;; CL: Setores por trilha
;; DH: Cabecas
;; CF=1 se ocorrer um erro
disk_get_parameters:
    push ax
    mov ah, 0x08
    int 0x13
    jc .error
    inc dh
    and cl, 0x3f
.end:
    clc
    jmp .ret
.error:
    stc
.ret:
    pop ax
    ret

;; Converte LBA para CHS
;; DX:AX: LBA
;; Retorna:
;; formato int13h ah=02h:
;;  CX = Cilindro e setor
;;  DH = Cabeca
disk_lba_to_chs:
    push bp
    push ax
    ;; https://wiki.osdev.org/Disk_access_using_the_BIOS_(INT_13h)
    ;; Temp = LBA / (Setores por trilha)
    ;; Setor = (LBA % (Setores por trilha)) + 1
    ;; Cabeca = Temp % (Numero de cabecas)
    ;; Cilindro = Temp / (Numero de cabecas)

    ;; Temp
    div word [sectors_per_track]
    ;; AX = Temp
    ;; DX = Setor - 1
    inc dx
    mov bp, dx

    xor dx, dx
    div word [heads]
    ;; AX = Cilindro
    ;; DX = Cabeca
    mov dh, dl
    xor dl, dl

    mov cx, bp
    mov ch, al
    shr ax, 2
    and ax, 0xc0
    or cl, al

    pop ax
    pop bp
    ret

;; Le um setor do disco
;; DX:AX: Setor
;; ES:BX: Buffer
;; Retorna:
;; CF=1 se ocorrer um erro
disk_read_sector:
    push ax
    push bx
    push cx
    push dx
    push si
    push es
    call disk_lba_to_chs
    mov si, 3
.read_loop:
    mov dl, [drive]
    mov ax, 0x0201
    int 0x13
    jnc .end
    mov dl, [drive]
    xor ah, ah
    int 0x13
    dec si
    jnz .read_loop
    jc .error
.end:
    clc
    jmp .ret
.error:
    stc
.ret:
    pop es
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

drive:             db 0
sectors_per_track: dw 0
heads:             dw 0

%endif ;; DISK_ASM

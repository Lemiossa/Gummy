;; disk.asm
;; Created by Matheus Leme da Silva
%ifndef disk_asm
%define disk_asm
bits 16

;; Initialize disk system
;; DL: Disk Drive
;; Returns:
;; CF=1 if an error occours
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

;; Gets disk paramenters
;; DL: Disk drive
;; Returns:
;; CL: Sectors per track
;; DH: Heads
;; CF=1 if an error occours
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

;; Converts LBA to CHS
;; DX:AX: LBA
;; Returns:
;; int13h ah=02h format:
;;  CX = Cylinder and Sector
;;  DH = Head
disk_lba_to_chs:
    push bp
    push ax
    ;; https://wiki.osdev.org/Disk_access_using_the_BIOS_(INT_13h)
    ;; Temp = LBA / (Sectors per Track)
    ;; Sector = (LBA % (Sectors per Track)) + 1
    ;; Head = Temp % (Number of Heads)
    ;; Cylinder = Temp / (Number of Heads)

    ;; Temp
    div word [sectors_per_track]
    ;; AX = Temp
    ;; DX = Sector - 1
    inc dx
    mov bp, dx

    xor dx, dx
    div word [heads]
    ;; AX = Cylinder
    ;; DX = Head
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

;; Reads disk sector
;; DX:AX: Sector
;; ES:BX: Buffer
;; Returns:
;; CF=1 if an error occours
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

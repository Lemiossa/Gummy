;; main.asm
;; Created by Matheus Leme Da Silva
org 0x7e00
bits 16

main:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00
    sti
    call disk_init
    jnc .disk_ok
    mov si, disk_error_message 
    call console_print_string
    jmp halt
.disk_ok:
    mov si, start_message
    call console_print_string
    call fat_init
    jc fat_error

    ;; Find file
    mov si, kernel_file
    call fat_find_in_root_dir
    jc fat_error
    ;; AX = root directory index
    ;; Peek entry
    mov di, .entry
    call fat_read_root_dir
    jc fat_error
    ;; Read kernel file
    mov si, .entry
    mov bx, 0x1000
    mov es, bx
    xor bx, bx
    call fat_read_file
    jc fat_error
    call e820_init
    jc mem_error
    jmp jump_to_kernel
    jmp halt
.entry: times 32 db 0

;; Halts the system
halt:
    mov si, halted_message
    call console_print_string
    cli
    hlt

fat_error:
    mov si, fat_error_message
    call console_print_string
    jmp halt

mem_error:
    mov si, mem_error_message
    call console_print_string
    jmp halt

%include "console.asm"
%include "disk.asm"
%include "fat.asm"
%include "e820.asm"

start_message:      db `\r\n`, NAME, ` bootloader v`, VERSION, `\r\n`, 0
disk_error_message: db `Disk error!\r\n`, 0
fat_error_message:  db `FAT error!\r\n`, 0
mem_error_message:  db `Mem error!\r\n`, 0
halted_message:     db `System is halted! Please, reboot.\r\n`, 0
kernel_file:        db `KERNEL  SYS`

%macro gdt_entry 4
    ;; base limit access flags
    dw (%2 & 0xffff)
    dw (%1 & 0xffff)
    db ((%1 >> 16) & 0xff)
    db (%3 & 0xff)
    db (((%4 & 0x0f) << 4) | ((%2 >> 16) & 0x0f))
    db ((%1 >> 24) & 0xff)
%endmacro

gdt:
    .null:   gdt_entry 0x00000000, 0x00000, 0b00000000, 0b0000
    .code32: gdt_entry 0x00000000, 0xfffff, 0b10011010, 0b1100
    .data32: gdt_entry 0x00000000, 0xfffff, 0b10010010, 0b1100
gdt_end:

gdtr:
    dw gdt_end - gdt - 1
    dd gdt

jump_to_kernel:
    cli
    in al, 0x92
    or al, 2
    out 0x92, al
    lgdt [gdtr]
    mov eax, cr0
    or al, 1
    mov cr0, eax
    jmp 0x08:pmode
bits 32
pmode:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov gs, ax
    mov fs, ax
    mov ss, ax
    mov esp, 0x7c00
    jmp 0x08:0x10000
    cli
    hlt

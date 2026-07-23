;; main.asm
;; Created by Matheus Leme Da Silva
ORG 0x7E00
BITS 16

main:
    CLI
    XOR AX, AX
    MOV DS, AX
    MOV ES, AX
    MOV SS, AX
    MOV SP, 0x7C00
    STI
    CALL disk_init
    JNC .disk_ok
    MOV SI, disk_error_message 
    CALL console_print_string
    JMP halt
.disk_ok:
    MOV SI, start_message
    CALL console_print_string
    CALL fat_init
    JC fat_error

    ;; Find file
    MOV SI, kernel_file
    CALL fat_find_in_root_dir
    JC fat_error
    ;; AX = root directory index
    ;; Peek entry
    MOV DI, .entry
    CALL fat_read_root_dir
    JC fat_error
    ;; Read kernel file
    MOV SI, .entry
    MOV BX, 0x1000
    MOV ES, BX
    XOR BX, BX
    CALL fat_read_file
    JC fat_error
    JMP jump_to_kernel
    JMP halt
.entry: TIMES 32 DB 0

;; Halts the system
halt:
    MOV SI, halted_message
    CALL console_print_string
    CLI
    HLT

fat_error:
    MOV SI, fat_error_message
    CALL console_print_string
    JMP halt

%INCLUDE "console.asm"
%INCLUDE "disk.asm"
%INCLUDE "fat.asm"

start_message:      DB `\r\nGummy Bootloader\r\n`, 0
disk_error_message: DB `Disk error!\r\n`, 0
fat_error_message:  DB `FAT error!\r\n`, 0
halted_message:     DB `System is halted! Please, reboot.\r\n`, 0
kernel_file:        DB `KERNEL  SYS`

%macro gdt_entry 4
    ;; base limit access flags
    DW (%2 & 0xFFFF)
    DW (%1 & 0xFFFF)
    DB ((%1 >> 16) & 0xFF)
    DB (%3 & 0xFF)
    DB (((%4 & 0x0F) << 4) | ((%2 >> 16) & 0x0F))
    DB ((%1 >> 24) & 0xFF)
%endmacro

gdt:
    .NULL:   gdt_entry 0x00000000, 0x00000, 0b00000000, 0b0000
    .CODE32: gdt_entry 0x00000000, 0xFFFFF, 0b10011010, 0b1100
    .DATA32: gdt_entry 0x00000000, 0xFFFFF, 0b10010010, 0b1100
gdt_end

gdtr:
    DW gdt_end - gdt - 1
    DD gdt

jump_to_kernel:
    CLI
    IN AL, 0x92
    OR AL, 2
    OUT 0x92, AL
    LGDT [gdtr]
    MOV EAX, CR0
    OR AL, 1
    MOV CR0, EAX
    JMP 0x08:pmode
BITS 32
pmode:
    MOV AX, 0x10
    MOV DS, AX
    MOV ES, AX
    MOV GS, AX
    MOV FS, AX
    MOV SS, AX
    MOV ESP, 0x7C00
    JMP 0x08:0x10000
    CLI
    HLT

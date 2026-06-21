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

    XOR AX, AX
    MOV DX, AX
    CALL fat_init
    JNC .fat_ok
    MOV SI, fat_error_message
    CALL console_print_string
    JMP halt
.fat_ok:

;; Halts the system
halt:
    MOV SI, halted_message
    CALL console_print_string
    CLI
    HLT

%INCLUDE "console.asm"
%INCLUDE "disk.asm"
%INCLUDE "fat.asm"

start_message:      DB `\r\nGummy Bootloader\r\n`, 0
disk_error_message: DB `Disk error!\r\n`, 0
fat_error_message:  DB `FAT error!\r\n`, 0
halted_message:     DB `System is halted! Please, reboot.\r\n`, 0


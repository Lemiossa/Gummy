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

    MOV SI, start_message
    CALL console_print_string

;; Halts the system
halt:
    MOV SI, halted_message
    CALL console_print_string
    CLI
    HLT

%INCLUDE "console.asm"
%INCLUDE "disk.asm"

start_message:      DB `\r\nBitix Bootloader\r\n`, 0
disk_error_message: DB `Disk error!\r\n`, 0
halted_message:     DB `System is halted! Please, reboot.\r\n`, 0


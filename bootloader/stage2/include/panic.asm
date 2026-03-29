;; a20.asm
;; Created by Matheus Leme Da Silva
%ifndef _PANIC_ASM_
%define _PANIC_ASM_
%include "include/console.asm"

panic_base_message: db "Panic: ", 0
halted_message: db 0x0D, 0x0A, "System is halted! Please, reboot.", 0x0D, 0x0A, 0

;; Prints a panic message and halts the system
;; DS:SI: Message
panic:
	;; Panic base message
	push si
	mov si, panic_base_message
	call print_string
	pop si

	;; Message
	call print_string

	;; Halted message
	mov si, halted_message
	call print_string
	cli
	hlt


%endif ;; _PANIC_ASM_


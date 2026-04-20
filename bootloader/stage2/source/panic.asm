;; panic.asm
;; Created by Matheus Leme Da Silva
%ifndef _PANIC_ASM_
%define _PANIC_ASM_
%include "console.asm"

;; Prints a panic message in red and halts the system
;; Usage: panic "Error message"
%macro panic 1+
	print "[ERROR] ", %1, 0x0D, 0x0A, 0x0

	jmp halt
%endmacro

%endif ;; _PANIC_ASM_

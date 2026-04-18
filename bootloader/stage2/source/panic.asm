;; a20.asm
;; Created by Matheus Leme Da Silva
%ifndef _PANIC_ASM_
%define _PANIC_ASM_
%include "console.asm"

;; Prints a panic message and halts the system
%macro panic 1+
	mov byte [current_attributes], 0x4F
	print "Panic: ", %1, 0x0D, 0x0A, 0x0
	jmp halt
%endmacro

%endif ;; _PANIC_ASM_


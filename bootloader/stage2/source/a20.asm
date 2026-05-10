;; a20.asm
;; Created by Matheus Leme Da Silva
%ifndef _A20_ASM_
%define _A20_ASM_
%include "console.asm"
%include "panic.asm"

;; Enable A20 line
;; BIOS method
section .text
enable_a20_line:
	push ax
	push si

	;; Get status
	mov ax, 0x2402
	int 0x15
	;; This function sets AH != 0 or CF if an error occurs
	;; If AH == 0, AL is the A20 line status; 0 = disabled, 1 = enabled

	jc a20_line_error
	test ah, ah
	jnz a20_line_error
	test al, al
	jnz .end

	;; Enable
	mov ax, 0x2401
	int 0x15
	;; This function sets AH != 0 or CF if an error occurs

	jc a20_line_error
	test ah, ah
	jnz a20_line_error
.end:

	pop si
	pop ax
	ret

;; Display A20 line error message and halt the system
a20_line_error:
	panic "Failed to enable A20 line", 0x0A

%endif ;; _A20_ASM_

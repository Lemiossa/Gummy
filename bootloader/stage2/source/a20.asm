;; a20.asm
;; Created by Matheus Leme Da Silva
%ifndef _A20_ASM_
%define _A20_ASM_
%include "console.asm"
%include "panic.asm"
section .text

;; Enable A20 line
;; BIOS Method
enable_a20_line:
	push ax
	push si

	;; Get status
	mov ax, 0x2402
	int 0x15
	;; This fn sets AH != 0 or CF if an error occurs
	;; If AH == 0, AL is A20 line state; 0 = disabled, 1 = enabled

	jc a20_line_error
	test ah, ah
	jnz a20_line_error
	test al, al
	jnz .end

	;; Enable 
	mov ax, 0x2401
	int 0x15
	;; This fn sets AH != 0 or CF if an error occurs

	jc a20_line_error
	test ah, ah
	jnz a20_line_error
.end:

	pop si
	pop ax
	ret

;; Prints an a20 line error message and halts the system
a20_line_error:
	panic "Failed to enabled A20 line"

%endif ;; _A20_ASM_

;; a20.asm
;; Created by Matheus Leme Da Silva
%ifndef _A20_ASM_
%define _A20_ASM_
%include "include/console.asm"
%include "include/panic.asm"

a20_line_error_message: db "Failed to enable A20 line!", 0
a20_line_enabling_message: db "Enabling A20 line...", 0
a20_line_enabled_message: db " Enabled.", 0x0D, 0x0A, 0

;; Enable A20 line
;; BIOS Method
enable_a20_line:
	push ax
	push si
	mov si, a20_line_enabling_message
	call print_string

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
	mov si, a20_line_enabled_message
	call print_string

	pop si
	pop ax
	ret


;; Prints an a20 line error message and halts the system
a20_line_error:
	mov si, a20_line_error_message
	call panic
	;; This code never executes, but just as a precaution
	cli
	hlt

%endif ;; _A20_ASM_

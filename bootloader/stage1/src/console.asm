;; console.asm
;; Created by Matheus Leme Da Silva
%ifndef _console_asm_
%define _console_asm_

;; Prints a string ending with zero on the screen
;; DS:SI: pointer to string
print_string:
	push ax
	push si
	mov ah, 0x0e
.loop:
	lodsb ;; AL = DS:SI++
	test al, al
	jz .end
	int 0x10
	jmp .loop
.end:
	pop si
	pop ax
	ret

%endif ;; _CONSOLE_ASM_


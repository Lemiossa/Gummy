;; console.asm
;; Created by Matheus Leme Da Silva
%ifndef _CONSOLE_ASM_
%define _CONSOLE_ASM_

;; Prints a string ending with zero on the screen
;; DS:SI: pointer to string
print_string:
	push ax
	push si
	mov ah, 0x0E
.loop:
	lodsb ;; al = ds:si++
	test al, al
	jz .end
	int 0x10
	jmp .loop
.end:
	pop si
	pop ax
	ret

%endif ;; _CONSOLE_ASM_

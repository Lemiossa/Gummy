;; console.asm
;; Criado por Matheus Leme Da Silva
%ifndef _console_asm_
%define _console_asm_

;; Imprime uma string terminada em zero na tela
;; DS:SI: ponteiro para a string
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


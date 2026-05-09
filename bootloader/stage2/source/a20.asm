;; a20.asm
;; Criado por Matheus Leme Da Silva
%ifndef _A20_ASM_
%define _A20_ASM_
%include "console.asm"
%include "panic.asm"

;; Habilita a linha A20
;; Método BIOS
section .text
enable_a20_line:
	push ax
	push si

	;; Obtém status
	mov ax, 0x2402
	int 0x15
	;; Esta função define AH != 0 ou CF se ocorrer um erro
	;; Se AH == 0, AL é o estado da linha A20; 0 = desabilitada, 1 = habilitada

	jc a20_line_error
	test ah, ah
	jnz a20_line_error
	test al, al
	jnz .end

	;; Habilita
	mov ax, 0x2401
	int 0x15
	;; Esta função define AH != 0 ou CF se ocorrer um erro

	jc a20_line_error
	test ah, ah
	jnz a20_line_error
.end:

	pop si
	pop ax
	ret

;; Exibe mensagem de erro da linha A20 e interrompe o sistema
a20_line_error:
	panic "Falha ao habilitar linha A20", 0x0A

%endif ;; _A20_ASM_

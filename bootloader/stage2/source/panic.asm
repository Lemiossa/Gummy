;; panic.asm
;; Criado por Matheus Leme Da Silva
%ifndef _PANIC_ASM_
%define _PANIC_ASM_
%include "console.asm"

;; Exibe uma mensagem de pânico em vermelho e interrompe o sistema
;; Uso: panic "Mensagem de erro"
%macro panic 1+
	print "[ERRO] ", %1, 0x0D, 0x0A, 0x0

	jmp halt16
%endmacro

%endif ;; _PANIC_ASM_

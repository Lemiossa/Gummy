;; tss.asm
;; Criado por Matheus Leme da Silva
bits 32
section .text

;; Carrega a TSS no registrador de tarefas
;; void tss_flush(uintptr_t sel);
global tss_flush
tss_flush:
    mov ax, [esp+4]
    ltr ax
    ret

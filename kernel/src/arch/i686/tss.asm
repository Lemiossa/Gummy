;; tss.asm
;; Created by Matheus Leme da Silva
bits 32
section .text

;; Loads the TSS into the task register
;; void tss_flush(uintptr_t sel);
global tss_flush
tss_flush:
    mov ax, [esp+4]
    ltr ax
    ret

;; tss.asm
;; Created by Matheus Leme da Silva
bits 32
section .text

;; Loads the TSS into the task register
;; void tss_flush(void);
global tss_flush
tss_flush:
    mov ax, 0x28
    ltr ax
    ret

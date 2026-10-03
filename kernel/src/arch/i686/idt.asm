;; idt.asm
;; Created by Matheus Leme da Silva
bits 32

;; Loads the idt
;; void load_idt(idtr_t *);
global load_idt
load_idt:
    cli
    mov eax, [esp+4]
    lidt [eax]
    ret

extern interrupt_handler

;; Restores the CPU context
;; void restore_context(uintptr_t esp0);
global restore_context
restore_context:
    mov eax, [esp+4]
    mov esp, eax
    jmp _restore_context

isr_common:
    push eax
    push ebx
    push ecx
    push edx
    push ebp
    push edi
    push esi

    push ds
    push es
    push fs
    push gs

    push esp ;; *ctx
    call interrupt_handler
    add esp, 4 ;; esp -= sizeof(interrupt_context_t *)

_restore_context:
    pop gs
    pop fs
    pop es
    pop ds

    pop esi
    pop edi
    pop ebp
    pop edx
    pop ecx
    pop ebx
    pop eax
    add esp, 8 ;; error_code + int_num
    iret

%macro isr_stub_no_error 1
global isr_stub_%1
isr_stub_%1:
    push dword 0
    push dword %1
    jmp isr_common
%endmacro

%macro isr_stub_error 1
global isr_stub_%1
isr_stub_%1:
    push dword %1
    jmp isr_common
%endmacro

%assign i 0
%rep 256
    %if i = 8 || i = 10 || i = 11 || i = 12 || i = 13 || i = 14 || i = 17
        isr_stub_error i
    %else
        isr_stub_no_error i
    %endif

    %assign i i + 1
%endrep

global isr_table

section .data
isr_table:
%assign i 0
%rep 256
    dd isr_stub_%+i
    %assign i i + 1
%endrep

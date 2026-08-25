;; idt.asm
;; Created by Matheus Leme da Silva
bits 32

;; Loads the idt
;; void load_idt(IDTR *);
global load_idt
load_idt:
    cli
    mov eax, [esp+4]
    lidt [eax]
    ret

extern interrupt_handler

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

    push esp
    call interrupt_handler
    add esp, 4

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

isr_stub_no_error 0   ;; Division by zero
isr_stub_no_error 1   ;; Debug
isr_stub_no_error 2   ;; Non-maskable interrupt
isr_stub_no_error 3   ;; Breakpoint
isr_stub_no_error 4   ;; Overflow
isr_stub_no_error 5   ;; Bound range exceeded
isr_stub_no_error 6   ;; Invalid opcode
isr_stub_no_error 7   ;; Device not available
isr_stub_error 8
isr_stub_no_error 9
isr_stub_error 10     ;; Invalid TSS
isr_stub_error 11     ;; Segment not present
isr_stub_error 12     ;; Stack segment fault
isr_stub_error 13     ;; General protection fault
isr_stub_error 14     ;; Page fault
isr_stub_no_error 15
isr_stub_no_error 16
isr_stub_error 17
isr_stub_no_error 18
isr_stub_no_error 19
isr_stub_no_error 20
isr_stub_no_error 21
isr_stub_no_error 22
isr_stub_no_error 23
isr_stub_no_error 24
isr_stub_no_error 25
isr_stub_no_error 26
isr_stub_no_error 27
isr_stub_no_error 28
isr_stub_no_error 29
isr_stub_no_error 30
isr_stub_no_error 31


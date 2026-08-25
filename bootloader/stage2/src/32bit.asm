%ifndef _32BIT_ASM
%define _32BIT_ASM

%include "config.asm"

_to32bit:
    cli
    in al, 0x92
    or al, 2
    out 0x92, al
    lgdt [gdtr]
    mov eax, cr0
    or al, 1
    mov cr0, eax
    jmp GDT_CODE32:_32bit_entry
bits 32
_32bit_entry:
    mov ax, GDT_DATA32
    mov ds, ax
    mov es, ax
    mov gs, ax
    mov fs, ax
    mov ss, ax
    mov esp, 0x7C00

    mov eax, pt
    or eax, 0x003
    mov esi, pd
    mov [esi], eax ;; PD[0] = PT | 0x003
    add esi, 768 * 4
    mov [esi], eax ;; PD[768] = PT | 0x003
    mov eax, pd
    or eax, 0x003
    add esi, 255 * 4
    mov [esi], eax ;; PD[1023] = PD | 0x003

    ;; Enable Paging
    mov eax, pd
    mov cr3, eax

    mov eax, cr0
    or eax, 0x80000001
    mov cr0, eax


    jmp GDT_CODE32:KERNEL_LOAD_ADDRESS
    cli
    hlt

align 4096
pd:
    times 1024 dd 0

pt:
    ;; 256 * 4KiB = 1MiB
%assign i 0
%rep 256
    dd (i * 0x1000) | 3
%assign i i + 1
%endrep
    times 768 dd 0

%endif ;; _32BIT_ASM

%ifndef CONFIG_ASM
%define CONFIG_ASM

%macro gdt_entry 4
    ;; base limit access flags
    dw (%2 & 0xffff)
    dw (%1 & 0xffff)
    db ((%1 >> 16) & 0xff)
    db (%3 & 0xff)
    db (((%4 & 0x0f) << 4) | ((%2 >> 16) & 0x0f))
    db ((%1 >> 24) & 0xff)
%endmacro

gdt:
    .null:   gdt_entry 0x00000000, 0x00000, 0b00000000, 0b0000
    .code32: gdt_entry 0x00000000, 0xfffff, 0b10011010, 0b1100
    .data32: gdt_entry 0x00000000, 0xfffff, 0b10010010, 0b1100
gdt_end:

gdtr:
    dw gdt_end - gdt - 1
    dd gdt

%define GDT_NULL            0x00
%define GDT_CODE32          0x08
%define GDT_DATA32          0x10
%define KERNEL_LOAD_ADDRESS 0x10000

%endif ;; CONFIG_ASM

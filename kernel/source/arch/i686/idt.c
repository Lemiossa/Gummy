/*
 * idt.c
 * Created by Matheus Leme da Silva
 * */
#include "terminal.h"
#include <idt.h>
#include <types.h>

IDTR idtr = {0};
IDTEntry idt[IDT_ENTRIES] = {0};

extern void load_idt(IDTR *);
extern void isr_stub_0(void);   
extern void isr_stub_1(void);   
extern void isr_stub_2(void);   
extern void isr_stub_3(void);   
extern void isr_stub_4(void);   
extern void isr_stub_5(void);   
extern void isr_stub_6(void);   
extern void isr_stub_7(void);   
extern void isr_stub_8(void);   
extern void isr_stub_9(void);   
extern void isr_stub_10(void);  
extern void isr_stub_11(void);  
extern void isr_stub_12(void);  
extern void isr_stub_13(void);  
extern void isr_stub_14(void);  
extern void isr_stub_15(void);
extern void isr_stub_16(void);  
extern void isr_stub_17(void);  
extern void isr_stub_18(void);  
extern void isr_stub_19(void);  
extern void isr_stub_20(void);
extern void isr_stub_21(void);
extern void isr_stub_22(void);
extern void isr_stub_23(void);
extern void isr_stub_24(void);
extern void isr_stub_25(void);
extern void isr_stub_26(void);
extern void isr_stub_27(void);
extern void isr_stub_28(void);
extern void isr_stub_29(void);
extern void isr_stub_30(void);
extern void isr_stub_31(void);


// Sets a IDT entry
void idt_set_entry(uint16_t index, uint32_t offset, uint16_t selector, uint8_t attr)
{
    if (index >= IDT_ENTRIES)
        return;

    idt[index].offset_low = offset & 0xFFFF;
    idt[index].selector = selector;
    idt[index].reserved = 0;
    idt[index].attributes = attr;
    idt[index].offset_high = (offset >> 16) & 0xFFFF;
}


// Interrupt handler
void interrupt_handler(interrupt_context *ctx)
{
    if (ctx->int_num < 32)
        terminal_print_string("Exception\r\n");
}

// Initializes IDT
void idt_init(void)
{
    idtr.offset = (uint32_t)idt;
    idtr.size = IDT_ENTRIES * sizeof (IDTEntry) - 1;

    idt_set_entry(0, (uint32_t)isr_stub_0, 0x08, IDT_INTERRUPT_GATE);
    idt_set_entry(1, (uint32_t)isr_stub_1, 0x08, IDT_INTERRUPT_GATE);
    idt_set_entry(2, (uint32_t)isr_stub_2, 0x08, IDT_INTERRUPT_GATE);
    idt_set_entry(3, (uint32_t)isr_stub_3, 0x08, IDT_TRAP_GATE);
    idt_set_entry(4, (uint32_t)isr_stub_4, 0x08, IDT_TRAP_GATE);
    idt_set_entry(5, (uint32_t)isr_stub_5, 0x08, IDT_INTERRUPT_GATE);
    idt_set_entry(6, (uint32_t)isr_stub_6, 0x08, IDT_INTERRUPT_GATE);
    idt_set_entry(7, (uint32_t)isr_stub_7, 0x08, IDT_INTERRUPT_GATE);
    idt_set_entry(8, (uint32_t)isr_stub_8, 0x08, IDT_INTERRUPT_GATE);
    idt_set_entry(9, (uint32_t)isr_stub_9, 0x08, IDT_INTERRUPT_GATE);
    idt_set_entry(10, (uint32_t)isr_stub_10, 0x08, IDT_INTERRUPT_GATE);
    idt_set_entry(11, (uint32_t)isr_stub_11, 0x08, IDT_INTERRUPT_GATE);
    idt_set_entry(12, (uint32_t)isr_stub_12, 0x08, IDT_INTERRUPT_GATE);
    idt_set_entry(13, (uint32_t)isr_stub_13, 0x08, IDT_INTERRUPT_GATE);
    idt_set_entry(14, (uint32_t)isr_stub_14, 0x08, IDT_INTERRUPT_GATE);
    idt_set_entry(15, (uint32_t)isr_stub_15, 0x08, IDT_INTERRUPT_GATE);
    idt_set_entry(16, (uint32_t)isr_stub_16, 0x08, IDT_INTERRUPT_GATE);
    idt_set_entry(17, (uint32_t)isr_stub_17, 0x08, IDT_INTERRUPT_GATE);
    idt_set_entry(18, (uint32_t)isr_stub_18, 0x08, IDT_INTERRUPT_GATE);
    idt_set_entry(19, (uint32_t)isr_stub_19, 0x08, IDT_INTERRUPT_GATE);
    idt_set_entry(20, (uint32_t)isr_stub_20, 0x08, IDT_INTERRUPT_GATE);
    idt_set_entry(21, (uint32_t)isr_stub_21, 0x08, IDT_INTERRUPT_GATE);
    idt_set_entry(22, (uint32_t)isr_stub_22, 0x08, IDT_INTERRUPT_GATE);
    idt_set_entry(23, (uint32_t)isr_stub_23, 0x08, IDT_INTERRUPT_GATE);
    idt_set_entry(24, (uint32_t)isr_stub_24, 0x08, IDT_INTERRUPT_GATE);
    idt_set_entry(25, (uint32_t)isr_stub_25, 0x08, IDT_INTERRUPT_GATE);
    idt_set_entry(26, (uint32_t)isr_stub_26, 0x08, IDT_INTERRUPT_GATE);
    idt_set_entry(27, (uint32_t)isr_stub_27, 0x08, IDT_INTERRUPT_GATE);
    idt_set_entry(28, (uint32_t)isr_stub_28, 0x08, IDT_INTERRUPT_GATE);
    idt_set_entry(29, (uint32_t)isr_stub_29, 0x08, IDT_INTERRUPT_GATE);
    idt_set_entry(30, (uint32_t)isr_stub_30, 0x08, IDT_INTERRUPT_GATE);
    idt_set_entry(31, (uint32_t)isr_stub_31, 0x08, IDT_INTERRUPT_GATE);

    load_idt(&idtr);
}

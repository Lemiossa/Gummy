/*
 * idt.c
 * Created by Matheus Leme da Silva
 * */
#include <io.h>
#include <terminal.h>
#include <idt.h>
#include <types.h>

IDTR idtr = {0};
IDTEntry idt[IDT_ENTRIES] = {0};
IntHandler handlers[IDT_ENTRIES] = {0};

extern void load_idt(IDTR *);
extern uint32_t isr_table[IDT_ENTRIES];

// Sets a IDT entry
static void idt_set_entry(uint16_t index, uint32_t offset, uint16_t selector, uint8_t attr)
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
void interrupt_handler(IntCtx *ctx)
{
    if (ctx->int_num >= IDT_ENTRIES)
        return;

    IntHandler handler = handlers[ctx->int_num];

    if (handler)
        handler(ctx);
}

// set a idt handler
void idt_set_handler(uint16_t index, IntHandler handler)
{
    if (index > IDT_ENTRIES)
        return;

    handlers[index] = handler;
}

// Initializes IDT
void idt_init(void)
{
    idtr.offset = (uint32_t)idt;
    idtr.size = IDT_ENTRIES * sizeof (IDTEntry) - 1;

    for (int i = 0; i < IDT_ENTRIES; i++)
        idt_set_entry(i, isr_table[i], 0x08, IDT_INTERRUPT_GATE);

    idt_set_entry(3, isr_table[3], 0x08, IDT_TRAP_GATE);
    idt_set_entry(4, isr_table[4], 0x08, IDT_TRAP_GATE);

    load_idt(&idtr);
}

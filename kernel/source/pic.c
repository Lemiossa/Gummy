/*
 * pic.c
 * Created by Matheus Leme da Silva
 * https://wiki.osdev.org/8259_PIC
 * */
#include <types.h>
#include <io.h>
#include <pic.h>

#define PIC1_CMD     0x20
#define PIC2_CMD     0xA0
#define PIC1_DATA    0x21
#define PIC2_DATA    0xA1
#define PIC_EOI      0x20

#define ICW1         0x10
#define ICW1_ICW4    0x01
#define ICW4_8086    0x01

// Remaps de PIC
void pic_remap(void)
{
    outb(PIC1_CMD, ICW1 | ICW1_ICW4);
    io_wait();
    outb(PIC2_CMD, ICW1 | ICW1_ICW4);
    io_wait();
    outb(PIC1_DATA, PIC_VECTOR_START);
    io_wait();
    outb(PIC2_DATA, PIC_VECTOR_START+8);
    io_wait();
    outb(PIC1_DATA, 1 << 2);
    io_wait();
    outb(PIC2_DATA, 2);
    io_wait();

    outb(PIC1_DATA, ICW4_8086);
    io_wait();
    outb(PIC2_DATA, ICW4_8086);
    io_wait();

    outb(PIC1_DATA, 0xFF);
    outb(PIC2_DATA, 0xFF);
}

// Send End Of Interrupt to PIC
void pic_send_eoi(uint8_t irq)
{
    if (irq >= 8)
        outb(PIC2_CMD, PIC_EOI);
    outb(PIC1_CMD, PIC_EOI);
}

// Set IRQ mask
void pic_irq_set_mask(uint8_t irq)
{
    if (irq < 8)
        outb(PIC1_DATA, inb(PIC1_DATA) | (1 << irq));
    else  
        outb(PIC2_DATA, inb(PIC2_DATA) | (1 << (irq - 8)));
}

// Clear IRQ mask
void pic_irq_clear_mask(uint8_t irq)
{
    if (irq < 8)
        outb(PIC1_DATA, inb(PIC1_DATA) & ~(1 << irq));
    else  
        outb(PIC2_DATA, inb(PIC2_DATA) & ~(1 << (irq - 8)));
}

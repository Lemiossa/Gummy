/*
 * gdt.c
 * Created by Matheus Leme da Silva
 * */
#include <types.h>
#include <gdt.h>

extern void gdt_flush(GdtR *);

GdtEntry gdt[GDT_ENTRIES] = {0};
GdtR gdtr = {0};

// Sets a GDT entry
void gdt_set_entry(uint16_t index, uint32_t base, uint32_t limit, uint8_t access, uint8_t flags)
{
    if (index >= GDT_ENTRIES)
        return;

    gdt[index].base_low = base & 0xFFFF;
    gdt[index].limit_low = limit & 0xFFFF;
    gdt[index].base_mid = (base >> 16) & 0xFF;
    gdt[index].access = access;
    gdt[index].flags_and_limit_high = ((flags << 4) & 0xF0) | ((limit >> 16) & 0x0F);
    gdt[index].base_high = (base >> 24) & 0xFF;
}

// Initializes the basic GDT
void gdt_init(void)
{
    gdtr.size = GDT_ENTRIES * sizeof(GdtEntry) - 1;
    gdtr.loc = (uint32_t)gdt;
    for (int i = 0; i < GDT_ENTRIES; i++)
        gdt_set_entry(i, 0x00000000, 0x00000, 0b00000000, 0b0000); //NULL 
    gdt_set_entry(1, 0x00000000, 0xFFFFF, 0b10011010, 0b1100); //CODE32
    gdt_set_entry(2, 0x00000000, 0xFFFFF, 0b10010010, 0b1100); //DATA32
    gdt_flush(&gdtr);
}

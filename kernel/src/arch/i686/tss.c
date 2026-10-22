/*
 * tss.c
 * Created by Matheus Leme da Silva
 * */
#include <tss.h>
#include <string.h>
#include <gdt.h>

static struct tss_entry tss;

// Initializes the TSS
void tss_init(void)
{
    memset(&tss, 0, sizeof(struct tss_entry));

    tss.ss0 = 0x10; // Kernel Data Segment Selector

    tss.iomap_base = sizeof(struct tss_entry);

    gdt_set_entry(
        5,
        (uint32_t)&tss,
        sizeof(tss) - 1,
        0b10001001,
        0b0000
    );

    tss_flush(0x28);
}

void tss_set_sp0(uintptr_t sp0, uintptr_t ss0)
{
    tss.esp0 = sp0;
    tss.ss0 = ss0;
}

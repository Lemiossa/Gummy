/*
 * kmain.c
 * Criado por Matheus Leme Da Silva
 */
#include <io.h>
#include <types.h>
#include <terminal.h>
#include <gdt.h>
#include <idt.h>
#include <pic.h>
#include <exception.h>
#include <e820.h>
#include <pmm.h>
#include <vmm.h>
#include <sched.h>
#include <heap.h>
#include <debug.h>
#include <tss.h>

void kmain(void)
{
    disable_interrupts();
    debug_init();

    debug_log_string("KMAIN", "Inicializando GDT...\r\n");
    gdt_init();
    debug_log_string("KMAIN", "GDT inicializado!\r\n");

    debug_log_string("KMAIN", "Inicializando TSS...\r\n");
    tss_init();
    debug_log_string("KMAIN", "TSS inicializado!\r\n");


    debug_log_string("KMAIN", "Inicializando terminal...\r\n");
    terminal_init();
    debug_log_string("KMAIN", "Terminal inicializado!\r\n");

    debug_log_string("KMAIN", "Inicializando IDT...\r\n");
    idt_init();
    debug_log_string("KMAIN", "IDT inicializado!\r\n");

    debug_log_string("KMAIN", "Remapeando PIC...\r\n");
    pic_remap();
    debug_log_string("KMAIN", "PIC remapeado!\r\n");

    debug_log_string("KMAIN", "Inicializando excecoes...\r\n");
    exception_init();
    debug_log_string("KMAIN", "Excecoes inicializadas!\r\n");

    debug_log_string("KMAIN", "Inicializando E820...\r\n");
    E820_init();
    debug_log_string("KMAIN", "E820 inicializado!\r\n");

    debug_log_string("KMAIN", "Inicializando PMM...\r\n");
    pmm_init();
    debug_log_string("KMAIN", "PMM inicializado!\r\n");

    debug_log_string("KMAIN", "Inicializando VMM...\r\n");
    vmm_init();
    debug_log_string("KMAIN", "VMM inicializado!\r\n");

    debug_log_string("KMAIN", "Inicializando heap...\r\n");
    heap_init();
    debug_log_string("KMAIN", "Heap inicializado!\r\n");

    debug_log_string("KMAIN", "Inicializando escalonador...\r\n");
    if (sched_init(100))
    {
        debug_log_string("KMAIN", "Falha ao inicializar o escalonador!\r\n");
        goto halt;
    }
    debug_log_string("KMAIN", "Escalonador inicializado!\r\n");
    enable_interrupts();

    terminal_print_string(NAME);
    terminal_print_string(" v");
    terminal_print_string(VERSION);
    terminal_print_string("\r\n");

halt:
    debug_log_string("KMAIN", "Sistema parado\r\n");
    disable_interrupts();
    halt_cpu();
}

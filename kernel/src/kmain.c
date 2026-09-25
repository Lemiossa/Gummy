/*
 * kmain.c
 * Created by Matheus Leme Da Silva
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

void kmain(void)
{
    disable_interrupts();
    debug_init();

    debug_log_string("KMAIN", "Initializing GDT...\r\n");
    gdt_init();
    debug_log_string("KMAIN", "GDT Initialized!\r\n");

    debug_log_string("KMAIN", "Initializing terminal...\r\n");
    terminal_init();
    debug_log_string("KMAIN", "Terminal initialized!\r\n");

    debug_log_string("KMAIN", "Initializing IDT...\r\n");
    idt_init();
    debug_log_string("KMAIN", "IDT initialized!\r\n");

    debug_log_string("KMAIN", "Remapping PIC...\r\n");
    pic_remap();
    debug_log_string("KMAIN", "PIC remapped!\r\n");

    debug_log_string("KMAIN", "Initializing exceptions...\r\n");
    exception_init();
    debug_log_string("KMAIN", "Exceptions initialized!\r\n");

    debug_log_string("KMAIN", "Initializing E820...\r\n");
    E820_init();
    debug_log_string("KMAIN", "E820 initialized!\r\n");

    debug_log_string("KMAIN", "Initializing PMM...\r\n");
    pmm_init();
    debug_log_string("KMAIN", "PMM initialized!\r\n");

    debug_log_string("KMAIN", "Initializing VMM...\r\n");
    vmm_init();
    debug_log_string("KMAIN", "VMM initialized!\r\n");

    debug_log_string("KMAIN", "Initializing heap...\r\n");
    heap_init();
    debug_log_string("KMAIN", "Heap initialized!\r\n");

    sched_init(100);
    enable_interrupts();

    terminal_print_string(NAME);
    terminal_print_string(" v");
    terminal_print_string(VERSION);
    terminal_print_string("\r\n");

    disable_interrupts();
    halt_cpu();
}

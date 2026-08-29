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
#include <timer.h>

void kmain()
{
    disable_interrupts();
    gdt_init();
    terminal_init();
    idt_init();
    pic_remap();
    exception_init();
    E820_init();
    pmm_init();
    vmm_init();
    timer_init(100);
    enable_interrupts();

    terminal_print_string(NAME);
    terminal_print_string(" v");
    terminal_print_string(VERSION);
    terminal_print_string("\r\n");
    terminal_print_string("Hello World\r\n");

    while (1);
}

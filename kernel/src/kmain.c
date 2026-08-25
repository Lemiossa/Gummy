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
#include <e820.h>
#include <pmm.h>

void kmain()
{
    disable_interrupts();
    gdt_init();
    terminal_init();
    idt_init();
    pic_remap();
    E820_init();
    pmm_init();

    terminal_print_string(NAME);
    terminal_print_string(" v");
    terminal_print_string(VERSION);
    terminal_print_string("\r\n");
    terminal_print_string("Hello World\r\n");

    while (1);
}

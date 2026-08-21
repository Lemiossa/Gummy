/*
 * kmain.c
 * Created by Matheus Leme Da Silva
 */
#include <types.h>
#include <terminal.h>
#include <gdt.h>
#include <idt.h>
#include <pic.h>
#include <e820.h>

void kmain()
{
    gdt_init();
    terminal_init();
    terminal_print_string(NAME);
    terminal_print_string(" v");
    terminal_print_string(VERSION);
    terminal_print_string("\r\n");
    pic_remap();
    idt_init();
    E820_init();
    terminal_print_string("Total memory: 0x");
    terminal_print_hex32(total_memory);
    terminal_print_string("\r\n");

    terminal_print_string("Hello World\r\n");

    while (1);
}

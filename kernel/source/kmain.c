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
    pic_remap();
    idt_init();
    E820_init();
    terminal_print_string("Hello World\r\n");

    while (1);
}

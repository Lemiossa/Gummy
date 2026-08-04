/*
 * kmain.c
 * Created by Matheus Leme Da Silva
 */
#include <types.h>
#include <terminal.h>
#include <gdt.h>
#include <idt.h>

void kmain()
{
    gdt_init(); 
    terminal_init();
    idt_init();
    terminal_print_string("Hello World\r\n");

    while (1);
}

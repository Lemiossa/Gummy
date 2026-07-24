/*
 * kmain.c
 * Created by Matheus Leme Da Silva
 */
#include <types.h>
#include <terminal.h>

void kmain()
{
    terminal_init();
    terminal_print_string("Hello World\r\n");

    while (1);
}

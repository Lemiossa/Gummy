/*
 * e820.c
 * Created by Matheus Leme da Silva
 * */
#include <types.h>
#include <terminal.h>
#include <e820.h>

uint16_t E820_entry_count;
E820Entry *E820_entries;
uint32_t total_memory;

// Get memory map
void E820_init(void)
{
    E820_entry_count = (*(uint16_t *)E820_ADDRESS);
    E820_entries = (E820Entry *)(E820_ADDRESS + 2);
    terminal_print_string("E820 Entry Count: ");
    terminal_print_hex16(E820_entry_count); 
    terminal_print_string("\r\n");
    total_memory = 0;

    for (uint16_t i = 0; i < E820_entry_count; i++) {
        terminal_print_string("[");
        terminal_print_hex16(i);
        terminal_print_string("] Base: 0x");
        terminal_print_hex64(E820_entries[i].base);
        
        terminal_print_string(" | Length: 0x");
        terminal_print_hex64(E820_entries[i].length);
        
        terminal_print_string(" | Type: ");
        terminal_print_hex32(E820_entries[i].type);
        terminal_print_string("\r\n");
        total_memory += E820_entries[i].length;
    }
    
    terminal_print_string("Total memory: 0x");
    terminal_print_hex32(total_memory);
    terminal_print_string("\r\n");
    terminal_print_string("E820 initialized\r\n");
}


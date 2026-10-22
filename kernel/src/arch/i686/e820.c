/*
 * e820.c
 * Criado por Matheus Leme da Silva
 * */
#include <types.h>
#include <terminal.h>
#include <e820.h>
#include <debug.h>

uint16_t E820_entry_count;
e820_entry_t *E820_entries;
uint32_t total_memory;

// Obtem o mapa de memoria
void E820_init(void)
{
    E820_entry_count = (*(uint16_t *)E820_ADDRESS);
    E820_entries = (e820_entry_t *)(E820_ADDRESS + 2);
    for (uint16_t i = 0; i < E820_entry_count; i++)
    {
        e820_entry_t entry = E820_entries[i];

        debug_log_string("E820", "Entrada 0x");
        debug_log_hex16(i);
        debug_print_string(": base: 0x");
        debug_log_hex64(entry.base);
        debug_print_string(", length: 0x");
        debug_log_hex64(entry.length);
        debug_print_string(", type: 0x");
        debug_log_hex32(entry.type);
        debug_print_string("\r\n");
    }
}


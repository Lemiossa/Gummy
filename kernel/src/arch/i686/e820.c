/*
 * e820.c
 * Created by Matheus Leme da Silva
 * */
#include <types.h>
#include <terminal.h>
#include <e820.h>

uint16_t E820_entry_count;
e820_entry_t *E820_entries;
uint32_t total_memory;

// Get memory map
void E820_init(void)
{
    E820_entry_count = (*(uint16_t *)E820_ADDRESS);
    E820_entries = (e820_entry_t *)(E820_ADDRESS + 2);
}


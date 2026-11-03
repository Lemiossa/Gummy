/*
 * e820.c
 * Criado por Matheus Leme da Silva
 * */
#include <debug.h>
#include <e820.h>
#include <terminal.h>
#include <types.h>

uint16_t E820_entry_count;
e820_entry_t *E820_entries;
uint32_t total_memory;

// Obtem o mapa de memoria
void E820_init(void) {
	E820_entry_count = (*(uint16_t *)E820_ADDRESS);
	E820_entries = (e820_entry_t *)(E820_ADDRESS + 2);
	for (uint16_t i = 0; i < E820_entry_count; i++) {
		e820_entry_t entry = E820_entries[i];
		printk("e820[%hu]: 0x%016llX-0x%016llX: %u\r\n", i, entry.base,
			   (uint64_t)(entry.base + entry.length), entry.type);
	}
}

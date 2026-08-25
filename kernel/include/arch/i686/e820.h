#ifndef E820_H
#define E820_H
#include <types.h>

#define E820_ADDRESS  0xC0000500

typedef struct 
{
    uint64_t base;
    uint64_t length;
    uint32_t type;
    uint32_t acpi_extended;
} __attribute__((packed)) E820Entry;

extern uint32_t total_memory;
extern uint16_t E820_entry_count;
extern E820Entry *E820_entries;

// Get memory map
void E820_init(void);

#endif // E820_H

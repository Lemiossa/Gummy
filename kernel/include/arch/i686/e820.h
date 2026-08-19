#ifndef E820_H
#define E820_H
#include <types.h>

#define E820_ADDRESS  0x500

typedef struct 
{
    uint64_t base;
    uint64_t length;
    uint32_t type;
    uint32_t acpi_extended;
} __attribute__((packed)) E820Entry;

extern uint32_t total_memory;

// Get memory map
void E820_init(void);

#endif // E820_H

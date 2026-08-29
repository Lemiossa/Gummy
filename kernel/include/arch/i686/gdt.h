#ifndef GDT_H
#define GDT_H
#include <types.h>

typedef struct 
{
    uint16_t size;
    uint32_t offset;
} __attribute__((packed)) gdtr_t;

typedef struct 
{
    uint16_t limit_low;
    uint16_t base_low;
    uint8_t base_mid;
    uint8_t access;
    uint8_t flags_and_limit_high;
    uint8_t base_high;
} __attribute__((packed)) gdt_entry_t;

#define GDT_ENTRIES 8

// Sets a GDT entry
void gdt_set_entry(uint16_t index, uint32_t base, uint32_t limit, uint8_t access, uint8_t flags);
// Initializes the basic GDT
void gdt_init(void);

#endif // GDT_H

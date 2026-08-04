#ifndef IDT_H
#define IDT_H
#include <types.h>

typedef struct 
{
    uint16_t size;
    uint32_t offset;
} __attribute__((packed)) IDTR;

typedef struct 
{
    uint16_t offset_low;
    uint16_t selector;
    uint8_t reserved;
    uint8_t attributes;
    uint16_t offset_high;
} __attribute__((packed)) IDTEntry;

typedef struct 
{
    uint32_t gs, fs, es, ds;
    uint32_t esi, edi, ebp, edx, ecx, ebx, eax;
    uint32_t int_num;
    uint32_t error_code;
    uint32_t eip;
    uint32_t cs;
    uint32_t eflags;
} __attribute__((packed)) interrupt_context;

#define IDT_ENTRIES 256
#define IDT_INTERRUPT_GATE 0x8E
#define IDT_TRAP_GATE 0x8F
#define IDT_TASK_GATE 0x85

void idt_init(void);

#endif // IDT_H

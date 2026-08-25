#ifndef IO_H
#define IO_H
#include <types.h>

void outb(uint16_t port, uint8_t value);
uint8_t inb(uint16_t port);
void outw(uint16_t port, uint16_t value);
uint16_t inw(uint16_t port);
void outl(uint16_t port, uint32_t value);
uint32_t inl(uint16_t port);
void io_wait(void);

static inline void disable_interrupts(void)
{
    __asm__ volatile ("cli");
}

static inline void enable_interrupts(void)
{
    __asm__ volatile ("sti");
}

static inline uint32_t read_cr0(void) 
{
    uint32_t value;

    __asm__ volatile (
        "mov %%cr0, %0"
        : "=r"(value)
    );

    return value;
}


static inline uint32_t read_cr2(void) 
{
    uint32_t value;

    __asm__ volatile (
        "mov %%cr2, %0"
        : "=r"(value)
    );

    return value;
}


static inline uint32_t read_cr3(void) 
{
    uint32_t value;

    __asm__ volatile (
        "mov %%cr3, %0"
        : "=r"(value)
    );

    return value;
}

#endif // IO_H

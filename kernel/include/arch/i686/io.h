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

// Disable interrupts (cli)
static inline void disable_interrupts(void)
{
    __asm__ volatile ("cli");
}

// Enable interrupts (sti)
static inline void enable_interrupts(void)
{
    __asm__ volatile ("sti");
}

// Read the value of control register CR0
static inline uint32_t read_cr0(void) 
{
    uint32_t value;

    __asm__ volatile (
        "mov %%cr0, %0"
        : "=r"(value)
    );

    return value;
}

// Write a value to control register CR0
static inline void write_cr0(uint32_t value)
{
    __asm__ volatile (
        "mov %0, %%cr0"
        :
        : "r"(value)
    );
}

// Read the value of control register CR2
static inline uint32_t read_cr2(void) 
{
    uint32_t value;

    __asm__ volatile (
        "mov %%cr2, %0"
        : "=r"(value)
    );

    return value;
}

// Write a value to control register CR2
static inline void write_cr2(uint32_t value)
{
    __asm__ volatile (
        "mov %0, %%cr2"
        :
        : "r"(value)
    );
}

// Read the value of control register CR3
static inline uint32_t read_cr3(void) 
{
    uint32_t value;

    __asm__ volatile (
        "mov %%cr3, %0"
        : "=r"(value)
    );

    return value;
}

// Write a value to control register CR3
static inline void write_cr3(uint32_t value)
{
    __asm__ volatile (
        "mov %0, %%cr3"
        :
        : "r"(value)
    );
}

#endif // IO_H

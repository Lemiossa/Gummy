/*
 * pit.c
 * Created by Matheus Leme da Silva
 * */
#include <io.h>
#include <types.h>
#include <pit.h>
#include <pic.h>

#define PIT_CMD 0x43

// Set pit frequency
void pit_set_frequency(uint16_t channel, uint16_t frequency, uint8_t mode)
{
    if (channel > 2 || frequency == 0)
        return;

    uint32_t divisor = (uint32_t)PIT_BASE_FREQUENCY / frequency;

    if (divisor == 0 || divisor > 0xFFFF)
        return;

    if (channel == 0)
        pic_irq_set_mask(0);

    uint8_t command = (channel << 6) |
                      0b00110000 |
                      (mode & 0b00001110);
    uint16_t port = channel + 0x40;
    
    outb(PIT_CMD, command);
    outb(port, divisor & 0xFF);
    outb(port, (divisor >> 8) & 0xFF);

    if (channel == 0)
        pic_irq_clear_mask(0);
}

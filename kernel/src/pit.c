/*
 * pit.c
 * Criado por Matheus Leme da Silva
 * */
#include <debug.h>
#include <io.h>
#include <pic.h>
#include <pit.h>
#include <types.h>

#define PIT_CMD 0x43

// Define a frequencia do PIT
void pit_set_frequency(uint16_t channel, uint16_t frequency, uint8_t mode) {
	if (channel > 2 || frequency == 0)
		return;

	printk("Definindo PIT[%hu]: freq=%u hz, modo=0x%02hhX\r\n", channel,
		   frequency, mode);

	uint32_t divisor = (uint32_t)PIT_BASE_FREQUENCY / frequency;

	if (divisor == 0 || divisor > 0xFFFF)
		return;

	if (channel == 0)
		pic_irq_set_mask(0);

	uint8_t command = (channel << 6) | 0b00110000 | (mode & 0b00001110);
	uint16_t port = channel + 0x40;

	outb(PIT_CMD, command);
	outb(port, divisor & 0xFF);
	outb(port, (divisor >> 8) & 0xFF);

	if (channel == 0)
		pic_irq_clear_mask(0);
}

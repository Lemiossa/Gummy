/*
 * debug.c
 * Criado por Matheus Leme da Silva
 * */
#include <serial.h>
#include <terminal.h>
#include <utils.h>
#include <vsnprintf.h>

#define DEBUG_SERIAL_PORT COM1

// Inicializa o debug
void debug_init(void) {
	if (serial_init(DEBUG_SERIAL_PORT, 9600))
		terminal_print_string(
			"Falha ao inicializar a porta serial de debug\r\n");
}

// Imprime uma string no debug
void debug_print_string(const char *s) {
	terminal_print_string(s);
	while (*s)
		write_serial(DEBUG_SERIAL_PORT, *s++);
}

// Imprime uma string formatada no terminal e no serial
// Retorna o número de caracteres escritos
int printk(const char *format, ...) {
	va_list arg;
	va_start(arg, format);
	char buffer[256];
	int ret = vsnprintf(buffer, sizeof(buffer), format, arg);
	debug_print_string(buffer);
	va_end(arg);
	return ret;
}

// Imprime codigo
void debug_dump_code(uintptr_t eip, uint32_t count) {
	const volatile uint8_t *p = (const volatile uint8_t *)eip;

	printk("Bytes em 0x%016llX: ", (uint64_t)eip);

	for (uint32_t i = 0; i < count; i++)
		printk("%02hhX ", p[i]);

	printk("\r\n");
}

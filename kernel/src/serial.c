/*
 * serial.c
 * Criado por Matheus Leme da Silva
 * https://wiki.osdev.org/Serial_Ports
 * */
#include <io.h>
#include <serial.h>
#include <types.h>

// Inicializa a porta serial
// Retorna 0 em caso de sucesso, 1 em caso de falha
int serial_init(uint16_t port, int baudrate) {
	if (baudrate <= 0)
		return 1;

	// Verifica se a porta e valida
	if (port != COM1 && port != COM2 && port != COM3 && port != COM4)
		return 1;

	// Habilita DLAB
	outb(port + 3, 0x80);

	// Define a taxa de transmissao
	uint16_t divisor = COM_BASE_FREQ / baudrate;

	outb(port + 0, divisor & 0xFF);		   // Define o byte baixo do divisor
	outb(port + 1, (divisor >> 8) & 0xFF); // Define o byte alto do divisor

	// Desabilita DLAB e define o formato de dados (8 bits, sem paridade, 1 bit
	// de parada)
	outb(port + 3, 0x03);

	// Habilita a FIFO, limpa-a, com limiar de 14 bytes
	outb(port + 2, 0xC7);

	// Habilita IRQs, define RTS/DSR
	outb(port + 4, 0x0B);

	// Habilita o loopback
	outb(port + 4, 0x1E);

	// Envia byte de teste
	outb(port + 0, 0xAE);

	if (inb(port + 0) != 0xAE)
		return 1;

	// Operacao normal
	outb(port + 4, 0x0F);

	// Se a serial nao estiver com defeito, define o modo de operacao normal
	outb(port + 4, 0x0F);
	return 0;
}

// Verifica se a fila FIFO de transmissao esta vazia
int is_transmit_fifo_empty(uint16_t port) { return inb(port + 5) & 0x20; }

// Escreve um byte na porta serial
void write_serial(uint16_t port, char a) {
	while (is_transmit_fifo_empty(port) == 0)
		;
	outb(port, a);
}

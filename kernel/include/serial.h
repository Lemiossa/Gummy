#ifndef SERIAL_H
#define SERIAL_H
#include <types.h>

#define COM1 0x3F8
#define COM2 0x2F8
#define COM3 0x3E8
#define COM4 0x2E8
#define COM_BASE_FREQ 115200

// Inicializa a porta serial
// Retorna 0 em caso de sucesso, 1 em caso de falha
int serial_init(uint16_t port, int baudrate);
// Escreve um byte na porta serial
void write_serial(uint16_t port, char a);

#endif // SERIAL_H

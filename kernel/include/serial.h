#ifndef SERIAL_H
#define SERIAL_H
#include <types.h>

#define COM1          0x3F8
#define COM2          0x2F8
#define COM3          0x3E8
#define COM4          0x2E8
#define COM_BASE_FREQ 115200

// Initialize the serial port
// Return 0 on success, 1 on failure
int serial_init(uint16_t port, int baudrate);
// Write a byte to the serial port
void write_serial(uint16_t port, char a);

#endif // SERIAL_H

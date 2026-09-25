/*
 * serial.c
 * Created by Matheus Leme da Silva
 * https://wiki.osdev.org/Serial_Ports
 * */
#include <serial.h>
#include <io.h>
#include <types.h>

// Initialize the serial port
// Return 0 on success, 1 on failure
int serial_init(uint16_t port, int baudrate)
{
    if (baudrate <= 0)
        return 1;

    // Verify if the port is valid
    if (port != COM1 && port != COM2 && port != COM3 && port != COM4)
        return 1;

    // Enable DLAB 
    outb(port + 3, 0x80);

    // Set baud rate
    uint16_t divisor = COM_BASE_FREQ / baudrate;

    outb(port + 0, divisor & 0xFF); // Set low byte of divisor
    outb(port + 1, (divisor >> 8) & 0xFF); // Set high byte of divisor

    // Disable DLAB and set data format (8 bits, no parity, 1 stop bit)
    outb(port + 3, 0x03);

    // Enable FIFO, clear them, with 14-byte threshold
    outb(port + 2, 0xC7);

    // Enable IRQs, set RTS/DSR
    outb(port + 4, 0x0B);

    // Enable Loopback
    outb(port + 4, 0x1E);

    // Send test byte
    outb(port + 0, 0xAE);

    if (inb(port + 0) != 0xAE)
        return 1;

    // Normal operation
    outb(port + 4, 0x0F);

    // If serial is not faulty, set it in normal operation mode
    outb(port + 4, 0x0F);
    return 0;
}

// Check if the transmit FIFO queue is empty
int is_transmit_fifo_empty(uint16_t port)
{
    return inb(port + 5) & 0x20;
}

// Write a byte to the serial port
void write_serial(uint16_t port, char a)
{
    while (is_transmit_fifo_empty(port) == 0);
    outb(port, a);
}



/*
 * debug.c
 * Created by Matheus Leme da Silva
 * */
#include <terminal.h>
#include <serial.h>
#include <utils.h>

#define DEBUG_SERIAL_PORT COM1

// Initialize the debug
void debug_init(void)
{
    if (serial_init(DEBUG_SERIAL_PORT, 9600))
        terminal_print_string("Failed to initialize debug serial port\r\n");
}

// Prints a string on debug
void debug_print_string(const char *s)
{
    terminal_print_string(s);
    while (*s)
        write_serial(DEBUG_SERIAL_PORT, *s++);
}

// Prints a log string
void debug_log_string(const char *section, const char *s)
{
    debug_print_string("[");
    debug_print_string(section);
    debug_print_string("]: ");
    debug_print_string(s);
}

// Prints a hex byte
void debug_log_hex8(uint8_t b)
{
    char str[3];
    BYTE_TO_HEX(b, str);
    debug_print_string(str);
}

// Prints a hex word
void debug_log_hex16(uint16_t w)
{
    debug_log_hex8((w >> 8) & 0xFF);
    debug_log_hex8(w & 0xFF);
}

// Prints a hex dword
void debug_log_hex32(uint32_t dw)
{
    debug_log_hex16((dw >> 16) & 0xFFFF);
    debug_log_hex16(dw & 0xFFFF);
}

// Prints a hex qword
void debug_log_hex64(uint64_t qw)
{
    debug_log_hex32((qw >> 32) & 0xFFFFFFFF);
    debug_log_hex32(qw & 0xFFFFFFFF);
}

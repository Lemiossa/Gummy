#ifndef TERMINAL_H
#define TERMINAL_H
#include <types.h>

#define TERMINAL_WIDTH 80
#define TERMINAL_HEIGHT 25

// Initializes the terminal system
void terminal_init(void);
// Prints a char in the terminal and updates cursor position.
void terminal_putchar(char c);
// Prints a string on the terminal
void terminal_print_string(const char *s);
// Print a hex byte
void terminal_print_hex8(uint8_t b);
// Print a hex word
void terminal_print_hex16(uint16_t w);
// Print a hex dword
void terminal_print_hex32(uint32_t dw);
// Print a hex qword
void terminal_print_hex64(uint64_t qw);

#endif // TERMINAL_H

#ifndef DEBUG_H
#define DEBUG_H
#include <types.h>

// Initialize the debug
void debug_init(void);
// Prints a string on debug
void debug_print_string(const char *s);
// Prints a log string
void debug_log_string(const char *section, const char *s);
// Prints a hex byte
void debug_log_hex8(uint8_t b);
// Prints a hex word
void debug_log_hex16(uint16_t w);
// Prints a hex dword
void debug_log_hex32(uint32_t dw);
// Prints a hex qword
void debug_log_hex64(uint64_t qw);

#endif // DEBUG_H

#ifndef DEBUG_H
#define DEBUG_H
#include <types.h>

// Inicializa o debug
void debug_init(void);
// Imprime uma string no debug
void debug_print_string(const char *s);
// Imprime uma string de log
void debug_log_string(const char *section, const char *s);
// Imprime um byte em hexadecimal
void debug_log_hex8(uint8_t b);
// Imprime uma word em hexadecimal
void debug_log_hex16(uint16_t w);
// Imprime uma dword em hexadecimal
void debug_log_hex32(uint32_t dw);
// Imprime uma qword em hexadecimal
void debug_log_hex64(uint64_t qw);
// Imprime codigo
void debug_dump_code(uintptr_t eip, uint32_t count);

#endif // DEBUG_H

#ifndef DEBUG_H
#define DEBUG_H
#include <types.h>

// Inicializa o debug
void debug_init(void);
// Imprime uma string no debug
void debug_print_string(const char *s);
// Imprime uma string de log
void debug_log_string(const char *section, const char *s);
// Imprime uma string formatada no terminal e no serial
// Retorna o número de caracteres escritos
int printk(const char *format, ...);
// Imprime codigo
void debug_dump_code(uintptr_t eip, uint32_t count);

#endif // DEBUG_H

#ifndef TERMINAL_H
#define TERMINAL_H
#include <types.h>

#define TERMINAL_WIDTH 80
#define TERMINAL_HEIGHT 25

// Inicializa o sistema de terminal
void terminal_init(void);
// Imprime um caractere no terminal e atualiza a posicao do cursor.
void terminal_putchar(char c);
// Imprime uma string no terminal
void terminal_print_string(const char *s);
// Imprime um byte em hexadecimal
void terminal_print_hex8(uint8_t b);
// Imprime uma word em hexadecimal
void terminal_print_hex16(uint16_t w);
// Imprime uma dword em hexadecimal
void terminal_print_hex32(uint32_t dw);
// Imprime uma qword em hexadecimal
void terminal_print_hex64(uint64_t qw);

#endif // TERMINAL_H

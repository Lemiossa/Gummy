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

#endif // TERMINAL_H

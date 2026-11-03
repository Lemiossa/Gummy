#ifndef VSNPRINTF_H
#define VSNPRINTF_H
#include <types.h>

// Libera a string formatada em s com tamanho definido por n.
int vsnprintf(char *s, size_t n, const char *format, va_list arg);

#endif // VSNPRINTF_H

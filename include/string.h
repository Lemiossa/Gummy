#ifndef STRING_H
#define STRING_H
#include <types.h>

// Copia n bytes de src para dst
void memcpy(void *dst, const void *src, size_t n);
// Preenche n bytes com o valor c em dst
void memset(void *dst, int c, size_t n);

#endif // STRING_H

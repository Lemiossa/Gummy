#ifndef STRING_H
#define STRING_H
#include <types.h>

// He copies n bytes from src to dst
void memcpy(void *dst, const void *src, size_t n);
// Sets n bytes with c value in dst
void memset(void *dst, int c, size_t n);

#endif // STRING_H

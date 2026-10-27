/*
 * string.c
 * Criado por Matheus Leme da Silva
 * */
#include <string.h>
#include <types.h>

// Copia n bytes de src para dst
void memcpy(void *dst, const void *src, size_t n) {
	if (!dst || !src)
		return;

	uint8_t *from = (uint8_t *)src;
	uint8_t *to = (uint8_t *)dst;

	for (size_t i = 0; i < n; i++)
		to[i] = from[i];
}

// Preenche n bytes com o valor c em dst
void memset(void *dst, int c, size_t n) {
	if (!dst)
		return;

	uint8_t b = (uint8_t)c;

	uint8_t *p = (uint8_t *)dst;
	for (size_t i = 0; i < n; i++)
		p[i] = b;
}

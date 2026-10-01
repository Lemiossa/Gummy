/*
 * string.c
 * Created by Matheus Leme da Silva
 * */
#include <types.h>
#include <string.h>

// He copies n bytes from src to dst
void memcpy(void *dst, const void *src, size_t n)
{
    if (!dst || !src)
        return;

    uint8_t *from = (uint8_t *)src;
    uint8_t *to = (uint8_t *)dst;

    for (size_t i = 0; i < n; i++)
        to[i] = from[i];
}

// Sets n bytes with c value in dst
void memset(void *dst, int c, size_t n)
{
    if (!dst)
        return;

    uint8_t b = (uint8_t)c;

    uint8_t *p = (uint8_t *)dst;
    for (size_t i = 0; i < n; i++)
        p[i] = b;
}

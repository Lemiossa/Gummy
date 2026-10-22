#ifndef BITMAP_H
#define BITMAP_H
#include <types.h>

// Define um bit
static inline void bitmap_set_bit(uint8_t *bmp, uint64_t bit)
{
    if (!bmp) return;
    bmp[bit / 8] |= (uint8_t)(1 << (bit % 8));
}

// Retorna o estado de um bit
static inline int bitmap_test_bit(const uint8_t *bmp, uint64_t bit)
{
    if (!bmp) return 0;
    return (bmp[bit / 8] & (uint8_t)(1 << (bit % 8))) != 0;
}

// Limpa um bit
static inline void bitmap_clear_bit(uint8_t *bmp, uint64_t bit)
{
    if (!bmp) return;
    bmp[bit / 8] &= ~(uint8_t)(1 << (bit % 8));
}

// Encontra um bit livre em um bitmap
static inline uint64_t bitmap_find_free_bit(const uint8_t *bmp, uint64_t bits)
{
    if (!bmp || bits == 0)
        return 0;

    uint64_t bytes = ALIGN_UP(bits, 8) / 8;

    for (uint64_t i = 0; i < bytes; i++)
    {
        if (bmp[i] == 0xFF)
            continue;

        for (uint64_t bit = 0; bit < 8; bit++)
        {
                uint64_t index = i * 8 + bit;

            if (index >= bits)

                return 0;

            if (!(bmp[i] & (uint8_t)(1 << bit)))
                return index;
        }
    }

    return 0;
}

#endif // BITMAP_H

#ifndef BITMAP_H
#define BITMAP_H
#include <types.h>

// Set a bit
static inline void bitmap_set_bit(uint8_t *bmp, uint32_t bit)
{
    if (!bmp) return;
    bmp[bit / 8] |= (uint8_t)(1 << (bit % 8));
}

// Return a bit state
static inline int bitmap_test_bit(const uint8_t *bmp, uint32_t bit)
{
    if (!bmp) return 0;
    return (bmp[bit / 8] & (uint8_t)(1 << (bit % 8))) != 0;
}

// Clears a bit
static inline void bitmap_clear_bit(uint8_t *bmp, uint32_t bit)
{
    if (!bmp) return;
    bmp[bit / 8] &= ~(uint8_t)(1 << (bit % 8));
}

#endif // BITMAP_H

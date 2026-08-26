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

// Find a free bit in a bitmap
static inline int32_t bitmap_find_free_bit(const uint8_t *bmp, uint32_t size)
{
    if (!bmp) return -1;
    for (uint32_t i = 0; i < size; i++) {
        if (!bitmap_test_bit(bmp, i)) {
            return (int32_t)i;
        }
    }

    return -1; // No free bit found
}

#endif // BITMAP_H

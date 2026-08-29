#ifndef PIT_H
#define PIT_H

#include <types.h>

#define PIT_RATE_GENERATOR        0b00000100
#define PIT_SQUARE_WAVE_GENERATOR 0b00000110

#define PIT0    0
#define PIT1    1
#define PIT2    2

#define PIT_BASE_FREQUENCY 1193182

// Set pit frequency
void pit_set_frequency(uint16_t channel, uint16_t frequency, uint8_t mode);

#endif // PIT_H

#ifndef TIMER_H
#define TIMER_H

#include <types.h>

// Initializes the timer
void timer_init(uint16_t frequency);
// Return the timer ticks
uint32_t timer_get_ticks(void);

#endif // TIMER_H

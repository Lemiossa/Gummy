#ifndef SCHED_H
#define SCHED_H

#include <types.h>

// Initializes the scheduler with the given frequency in Hz
void sched_init(uint16_t frequency);
// Return the sched ticks
uint32_t sched_get_ticks(void);

#endif // SCHED_H

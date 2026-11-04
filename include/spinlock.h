#ifndef SPINLOCK_H
#define SPINLOCK_H

#include <types.h>

typedef struct {
	volatile uint32_t locked;
} spinlock_t;

#define SPINLOCK_INIT {0}

void spinlock(spinlock_t *l);
void spinunlock(spinlock_t *l);

#endif // SPINLOCK_H

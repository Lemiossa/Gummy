#ifndef LOCK_H
#define LOCK_H

#include <types.h>

typedef struct {
	volatile uint32_t locked;
} lock_t;

#define LOCK_INIT {0}

void lock(lock_t *l);
void unlock(lock_t *l);

#endif

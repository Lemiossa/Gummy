/*
 * spinlock.c
 * Criado por Matheus Leme da Silva
 * */
#include <spinlock.h>

void spinlock(spinlock_t *l) {
	while (__sync_lock_test_and_set(&l->locked, 1)) {
		while (l->locked) {
			__asm__ volatile("pause");
		}
	}
}

void spinunlock(spinlock_t *l) { __sync_lock_release(&l->locked); }

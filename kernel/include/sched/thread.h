#ifndef THREAD_H
#define THREAD_H

#include <idt.h>
#include <queue.h>
#include <types.h>

typedef enum {
	THREAD_RUNNING = 0,
	THREAD_READY,
	THREAD_BLOCKED,
	THREAD_ZOMBIE,
	THREAD_SLEEPING,
	THREAD_FREE,
} thread_state_t;

#define USER_STACK_PAGES 16
#define USER_STACK_TOP 0xBFFFF000
#define KERNEL_STACK_PAGES 1

typedef struct thread {
	queue_node_t node;
	uintptr_t stack, sp;
	uintptr_t stack0, sp0;
	thread_state_t state;
	int32_t exit_code;
	uint32_t wake_tick;
	pid_t pid;
} thread_t;

extern thread_t *current_thread;

extern queue_t ready_queue;
extern queue_t zombie_queue;
extern queue_t sleep_queue;

// Cria uma nova thread no processo
// Retorna o ponteiro pra thread(não aloca)
thread_t *sched_create_thread(uintptr_t loc, pid_t pid);
// destroi uma thread
// tira ela de qualquer fila que esteja
void sched_destroy_thread(thread_t *thread);
// seta uma thread como ready
void sched_ready(thread_t *thread);
// seta uma thread como zombie
void sched_zombie(thread_t *thread);
// seta uma thread como sleep
void sched_sleep(thread_t *thread);
// Retorna o ponteiro pra thread atual
thread_t *sched_get_current_thread(void);
// Sai da thread atual e seta o exit code dela
void sched_exit_current_thread(interrupt_context_t *ctx, int32_t status);
// Bota a thread atual em sleep
void sched_thread_sleep(interrupt_context_t *ctx, uint32_t wake_tick);

#define KERNEL_STACK_SIZE (KERNEL_STACK_PAGES * PAGE_SIZE)
#define USER_STACK_SIZE (USER_STACK_PAGES * PAGE_SIZE)

#endif // THREAD_H

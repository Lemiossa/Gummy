#ifndef SCHED_H
#define SCHED_H

#include <idt.h>
#include <ipc.h>
#include <pmm.h>
#include <queue.h>
#include <types.h>

#define USER_STACK_PAGES 16
#define KERNEL_STACK_PAGES 1
#define THREAD_PER_PROCESS 8
#define USER_STACK_TOP 0xBFFFF000

typedef struct thread thread_t;
typedef struct process process_t;

typedef enum {
	THREAD_RUNNING = 0,
	THREAD_READY = 1,
	THREAD_BLOCKED = 2,
	THREAD_ZOMBIE = 3,
	THREAD_SLEEPING =4,
	THREAD_FREE = 5
} thread_state_t;

struct thread {
	queue_node_t node;
	uintptr_t stack, sp;
	uintptr_t stack0, sp0;
	process_t *process;
	thread_state_t state;
	int32_t exit_code;
	uint32_t wake_tick;
};

struct process {
	mailbox_t mailbox;
	thread_t threads[THREAD_PER_PROCESS];
	process_t *prev;
	process_t *next;
	uintptr_t cr3;
	uint32_t pid;
	uint8_t num_threads;
};

// Threads ===

// Cria uma nova thread no processo
// Retorna o ponteiro pra thread(não aloca)
thread_t *sched_create_thread(uintptr_t loc, process_t *process);
// destroi uma thread
// tira ela de qualquer fila que esteja
void sched_destroy_thread(thread_t *thread);
// seta uma thread como ready
void sched_ready(thread_t *thread);
// seta uma thread como blocked
void sched_blocked(thread_t *thread);
// seta uma thread como zombie
void sched_zombie(thread_t *thread);
void sched_sleep(thread_t *thread);
// Retorna o ponteiro pra thread atual
thread_t *sched_get_current_thread(void);
// Sai da thread atual e seta o exit code dela
void sched_exit_current_thread(interrupt_context_t *ctx, int32_t status);
// Bota a thread atual em sleep
void sched_thread_sleep(interrupt_context_t *ctx, uint32_t wake_tick);

// Process ===

// cria um novo processo
// retorna um ponteiro para o processo
process_t *sched_create_process(void);
// destroi um processo e suas threads
void sched_destroy_process(process_t *proc);
// destroi um processo e suas threads
void sched_destroy_process(process_t *proc);
// Retorna o PID da thread rodando atualmente
uint32_t sched_get_current_pid(void);
// Retorna o ponteiro pro processo atual rodando
process_t *sched_get_current_process(void);
// Procura um processo pelo PID.
// Retorna o ponteiro para ele, nulo se erro.
process_t *get_process(uint32_t pid);

// Main ===

// Inicializa o escalonador com a frequencia informada em Hz
// Retorna !0 se ocorrer um erro
int sched_init(uint16_t frequency);
// Retorna os ticks do escalonador
uint32_t sched_get_ticks(void);
// Retorna o número de milisegundos por tick
uint32_t sched_get_ms_per_tick(void);

#define KERNEL_STACK_SIZE (KERNEL_STACK_PAGES * PAGE_SIZE)
#define USER_STACK_SIZE (USER_STACK_PAGES * PAGE_SIZE)

#endif // SCHED_H

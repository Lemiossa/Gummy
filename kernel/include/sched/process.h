#ifndef PROCESS_H
#define PROCESS_H

#include <ipc.h>
#include <ring_buffer.h>
#include <sched/cap.h>
#include <sched/thread.h>
#include <types.h>

#define THREAD_PER_PROCESS 8
#define CAP_PER_PROCESS 16

typedef enum {
	PROCESS_NORMAL = 0,
	PROCESS_DYING,
} process_state_t;

typedef struct process {
	mailbox_t mailbox;
	thread_t threads[THREAD_PER_PROCESS];
	cap_t caps[CAP_PER_PROCESS];
	uint32_t num_threads;
	struct process *prev;
	struct process *next;
	struct process *parent;
	uintptr_t cr3;
	process_state_t state;
	pid_t pid;
} process_t;

extern process_t *first_process;
extern process_t idle_process;
extern uint32_t current_pid;

// cria um novo processo
// retorna um ponteiro para o processo
process_t *sched_create_process(void);
// destroi um processo e suas threads
void sched_destroy_process(process_t *proc);
// Mata o processo atual com segurança
void sched_destroy_current_process(void);
// Retorna o PID da thread rodando atualmente
pid_t sched_get_current_pid(void);
// Retorna o PPID da thread rodando atualmente
pid_t sched_get_current_ppid(void);
// Retorna o ponteiro pro processo atual rodando
process_t *sched_get_current_process(void);
// Procura um processo pelo PID.
// Retorna o ponteiro para ele, nulo se erro.
process_t *sched_get_process(pid_t pid);

#endif // PROCESS_H

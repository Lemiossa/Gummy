#ifndef SCHED_H
#define SCHED_H

#include <types.h>
#include <queue.h>

#define KERNEL_STACK_SIZE 4096
#define THREAD_PER_PROCESS 8

typedef struct thread thread_t;
typedef struct process process_t;

struct thread
{
    queue_node_t node;
    uintptr_t stack, sp;
    uintptr_t stack0, sp0;
    process_t *process;
};

struct process
{
    thread_t threads[THREAD_PER_PROCESS];
    uintptr_t cr3;
    uint32_t pid;
    uint8_t num_threads;
};

// Cria um novo processo vazio
process_t *sched_create_process(void);
// Cria uma nova thread no processo
// Retorna um indice da thread no processo
thread_t *sched_create_thread(uintptr_t loc, process_t *process);

// TODO: Cria um novo processo

// Inicializa o escalonador com a frequencia informada em Hz
// Retorna !0 se ocorrer um erro
int sched_init(uint16_t frequency);
// Retorna os ticks do escalonador
uint32_t sched_get_ticks(void);

#endif // SCHED_H

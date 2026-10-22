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

// Creates a new empty process
process_t *sched_create_process(void);
// Creates a new thread in the process
// Returns an index of the thread in process
thread_t *sched_create_thread(uintptr_t loc, process_t *process);

// TODO: Spawns a new process

// Initializes the scheduler with the given frequency in Hz
// Return !0 if an error occours
int sched_init(uint16_t frequency);
// Return the sched ticks
uint32_t sched_get_ticks(void);

#endif // SCHED_H

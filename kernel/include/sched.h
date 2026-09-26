#ifndef SCHED_H
#define SCHED_H

#include <types.h>
#define KERNEL_STACK_SIZE 4096

enum thread_state 
{
    RUNNING,
    READY,
    BLOCKED,
};

struct thread
{
    uintptr_t stack;
    uintptr_t kstack;
    enum thread_state state;
    struct process *process;
    struct thread *prev;
    struct thread *next;
};

struct process
{
    uint32_t pid;
    uintptr_t cr3;
    struct thread *thread; // Main thread
    struct process *prev;
    struct process *next;
};

// Initializes the scheduler with the given frequency in Hz
// Return !0 if an error occours
int sched_init(uint16_t frequency);
// Return the sched ticks
uint32_t sched_get_ticks(void);

#endif // SCHED_H

/*
 * sched.c
 * Created by Matheus Leme da Silva
 * */
#include <pmm.h>
#include <vmm.h>
#include <types.h>
#include <sched.h>
#include <pic.h>
#include <idt.h>
#include <pit.h>
#include <heap.h>
#include <debug.h>
#include <queue.h>

volatile uint32_t ticks = 0;
uint16_t timer_frequency = 0;
uint32_t ms_per_tick = 0;

process_t idle_process;
thread_t *current_thread = NULL;
uint32_t current_pid = 0;
static queue_t ready_queue;
static queue_t blocked_queue;
static queue_t zombie_queue;

// Return the context pointer in a stack
static inline interrupt_context_t *sched_get_context(uintptr_t stack_top)
{
    return (interrupt_context_t *)(stack_top - sizeof(interrupt_context_t));
}

// Switches the context of CPU
void switch_context(thread_t *new)
{
    if (!current_thread || !new)
        return;

    current_thread = new;
    restore_context(new->sp0);
}

// Sched handler
static void sched_handler(interrupt_context_t *ctx)
{
    ticks++;
    pic_send_eoi(0);

    if (queue_empty(&ready_queue))
        return;

    interrupt_context_t *cur_ctx = sched_get_context(current_thread->sp0);
    *cur_ctx = *ctx;

    queue_node_t *n = queue_pop(&ready_queue);
    thread_t *new_thread = (thread_t *)CONTAINER_OF(n, thread_t, node);
    queue_push(&ready_queue, &current_thread->node);
    if (new_thread == current_thread)
        return;

    switch_context(new_thread);
}

// Return the sched ticks
uint32_t sched_get_ticks(void)
{
    return ticks;
}

// Initializes the scheduler with the given frequency in Hz
// Return !0 if an error occours
int sched_init(uint16_t frequency)
{
    if (frequency <= 18)
        frequency = 100;

    timer_frequency = frequency;
    ms_per_tick = 1000 / timer_frequency;
    idt_set_handler(32, sched_handler);
    pit_set_frequency(0, timer_frequency, PIT_SQUARE_WAVE_GENERATOR);

    idle_process.pid = current_pid++;
    idle_process.cr3 = kernel_cr3;
    idle_process.num_threads = 1;

    queue_init(&ready_queue);
    queue_init(&blocked_queue);
    queue_init(&zombie_queue);

    queue_push(&ready_queue, &idle_process.threads[0].node);
    current_thread = &idle_process.threads[0];

    uint8_t *stack0 = (uint8_t *)heap_alloc(KERNEL_STACK_SIZE);
    if (!stack0)
        return -1;
    uintptr_t sp0 = (uintptr_t)(stack0 + KERNEL_STACK_SIZE);
    current_thread->sp0 = sp0;

    return 0;
}

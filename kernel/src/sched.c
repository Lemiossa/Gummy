/*
 * sched.c
 * Created by Matheus Leme da Silva
 * */
#include <vmm.h>
#include <types.h>
#include <sched.h>
#include <pic.h>
#include <idt.h>
#include <pit.h>
#include <heap.h>
#include <debug.h>

volatile uint32_t ticks = 0;
uint16_t timer_frequency = 0;
uint32_t ms_per_tick = 0;

uint32_t current_pid = 0;
struct process *first_process = NULL;
struct thread *first_thread = NULL;

// Sched handler
static void sched_handler(interrupt_context_t *ctx)
{
    (void)ctx;
    ticks++;
    pic_send_eoi(0);
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

    debug_log_string("SCHED", "Creating first process...\r\n");
    first_process = (struct process *)heap_alloc(sizeof(*first_process));
    if (!first_process)
    {
        debug_log_string("SCHED", "Failed to alloc first process!\r\n");
        return 1;
    }
    first_process->cr3 = kernel_cr3;
    first_process->pid = current_pid++;
    first_process->prev = NULL;
    first_process->next = NULL;

    debug_log_string("SCHED", "Creating first thread...\r\n");
    first_thread = (struct thread *)heap_alloc(sizeof(*first_thread));
    if (!first_thread)
    {
        debug_log_string("SCHED", "Failed to alloc first thread!\r\n");
        heap_free(first_process);
        return 1;
    }
    debug_log_string("SCHED", "Created first thread!\r\n");

    uint8_t *kernel_stack = heap_alloc(KERNEL_STACK_SIZE);
    if (!kernel_stack)
    {
        debug_log_string("SCHED", "Failed to alloc memory for first thread kstack!\r\n");
        heap_free(first_thread);
        heap_free(first_process);
        return 1;
    }

    first_thread->kstack = (uintptr_t)kernel_stack + KERNEL_STACK_SIZE;
    first_thread->stack = 0;
    first_thread->prev = NULL;
    first_thread->next = NULL;
    first_thread->state = READY;

    first_process->thread = first_thread;

    debug_log_string("SCHED", "Created first process!\r\n");

    return 0;
}

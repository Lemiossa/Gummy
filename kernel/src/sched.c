/*
 * sched.c
 * criado por matheus leme da silva
 * */
#include <tss.h>
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
#include <io.h>

volatile uint32_t ticks = 0;
uint16_t timer_frequency = 0;
uint32_t ms_per_tick = 0;

process_t idle_process;
thread_t *current_thread = NULL;
uint32_t current_pid = 0;
static queue_t ready_queue;
static queue_t blocked_queue;
static queue_t zombie_queue;

// troca o contexto da CPU
void switch_context(thread_t *new)
{
    if (!current_thread || !new)
        return;

    // falha critica
    if (!new->process)
    {
        debug_log_string("sched", "switch_context: falha ao trocar o contexto: new->process == null;\r\n");
        debug_log_string("sched", "switch_context: sistema parado\r\n");
        disable_interrupts();
        halt_cpu();
    }

    current_thread = new;

    if (new != &idle_process.threads[0])
        tss_set_sp0(new->stack0 + KERNEL_STACK_SIZE, 0x10);

    write_cr3(new->process->cr3);

    restore_context(current_thread->sp0);
}

// rotina do escalonador
static void sched_handler(interrupt_context_t *ctx)
{
    ticks++;
    pic_send_eoi(0);

    if (queue_empty(&ready_queue))
        return;

    current_thread->sp0 = (uintptr_t)ctx;

    queue_node_t *n = queue_pop(&ready_queue);
    thread_t *new_thread = (thread_t *)CONTAINER_OF(n, thread_t, node);
    queue_push(&ready_queue, &current_thread->node);
    if (new_thread == current_thread)
        return;

    switch_context(new_thread);
}

// retorna os ticks do escalonador
uint32_t sched_get_ticks(void)
{
    return ticks;
}

// inicializa o escalonador com a frequencia informada em hz
// retorna !0 se ocorrer um erro
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

    current_thread = &idle_process.threads[0];
    current_thread->process = &idle_process;

    return 0;
}

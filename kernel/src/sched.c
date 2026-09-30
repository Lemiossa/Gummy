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

volatile uint32_t ticks = 0;
uint16_t timer_frequency = 0;
uint32_t ms_per_tick = 0;

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

    return 0;
}

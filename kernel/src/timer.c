/*
 * timer.c
 * Created by Matheus Leme da Silva
 * */
#include <pic.h>
#include <types.h>
#include <idt.h>
#include <pit.h>

volatile uint32_t ticks = 0;
uint16_t timer_frequency = 0;
uint32_t ms_per_tick = 0;

// Timer handler
static void timer_handler(interrupt_context_t *ctx)
{
    (void)ctx;
    ticks++;
    pic_send_eoi(0);
}

// Return the timer ticks
uint32_t timer_get_ticks(void)
{
    return ticks;
}

// Initializes the timer
void timer_init(uint16_t frequency)
{
    if (frequency <= 18)
        frequency = 100;

    timer_frequency = frequency;
    ms_per_tick = 1000 / timer_frequency;
    idt_set_handler(32, timer_handler);
    pit_set_frequency(0, timer_frequency, PIT_SQUARE_WAVE_GENERATOR);
}

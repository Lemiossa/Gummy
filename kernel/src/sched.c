/*
 * sched.c
 * criado por matheus leme da silva
 * */
#include <debug.h>
#include <heap.h>
#include <idt.h>
#include <io.h>
#include <pic.h>
#include <pit.h>
#include <pmm.h>
#include <queue.h>
#include <sched.h>
#include <tss.h>
#include <types.h>
#include <vmm.h>

volatile uint32_t ticks = 0;
uint16_t timer_frequency = 0;
uint32_t ms_per_tick = 0;

extern process_t idle_process;
extern thread_t *current_thread;
extern queue_t ready_queue;
extern queue_t blocked_queue;
extern queue_t zombie_queue;
extern uint32_t current_pid;
extern process_t *first_process;

// troca o contexto da CPU
void switch_context(thread_t *new) {
	if (!current_thread || !new) {
		debug_log_string("SCHED",
						 "switch_context: current_thread ou new nulo\r\n");
		return;
	}

	// falha critica
	if (!new->process) {
		debug_log_string("SCHED", "switch_context: falha ao trocar o contexto: "
								  "new->process == null;\r\n");
		debug_log_string("SCHED", "switch_context: sistema parado\r\n");
		disable_interrupts();
		halt_cpu();
	}

	current_thread = new;

	if (new != &idle_process.threads[0])
		tss_set_sp0(new->stack0 + KERNEL_STACK_SIZE, 0x10);

	write_cr3(new->process->cr3);

	restore_context(current_thread->sp0);
}

// Escalonador
void schedule(interrupt_context_t *ctx) {
	if (queue_empty(&ready_queue))
		return;

	current_thread->sp0 = (uintptr_t)ctx;

	queue_node_t *n = queue_pop(&ready_queue);
	thread_t *new_thread = (thread_t *)CONTAINER_OF(n, thread_t, node);
	if (sched_thread_state(current_thread) == 3)
		queue_push(&ready_queue, &current_thread->node);
	if (new_thread == current_thread)
		return;

	switch_context(new_thread);
}

// Rotina do timer
static void timer_handler(interrupt_context_t *ctx) {
	ticks++;
	pic_send_eoi(0);
	schedule(ctx);
}

// retorna os ticks do escalonador
uint32_t sched_get_ticks(void) { return ticks; }

// inicializa o escalonador com a frequencia informada em hz
// retorna !0 se ocorrer um erro
int sched_init(uint16_t frequency) {
	debug_log_string("SCHED", "Inicializando escalonador...\r\n");

	if (frequency <= 18)
		frequency = 100;

	timer_frequency = frequency;
	ms_per_tick = 1000 / timer_frequency;
	debug_log_string("SCHED", "Frequencia do timer: 0x");
	debug_log_hex16(frequency);
	debug_print_string(" Hz\r\n");

	idt_set_handler(32, timer_handler);
	pit_set_frequency(0, timer_frequency, PIT_SQUARE_WAVE_GENERATOR);

	idle_process.pid = current_pid++;
	idle_process.cr3 = kernel_cr3;
	idle_process.num_threads = 1;

	queue_init(&ready_queue);
	queue_init(&blocked_queue);
	queue_init(&zombie_queue);

	current_thread = &idle_process.threads[0];
	current_thread->process = &idle_process;

	idle_process.prev = NULL;
	idle_process.next = NULL;
	first_process = &idle_process;

	debug_log_string("SCHED", "Processo idle criado com PID 0x");
	debug_log_hex32(idle_process.pid);
	debug_print_string("\r\n");
	debug_log_string("SCHED", "Escalonador inicializado\r\n");

	return 0;
}

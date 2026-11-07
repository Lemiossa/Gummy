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
#include <sched/process.h>
#include <sched/sched.h>
#include <sched/thread.h>
#include <tss.h>
#include <types.h>
#include <vmm.h>

volatile uint32_t ticks = 0;
uint16_t timer_frequency = 0;
uint32_t ms_per_tick = 0;

// troca o contexto da CPU
void switch_context(thread_t *new) {
	if (!current_thread || !new) {
		printk("switch_context: current_thread ou new nulo\r\n");
		return;
	}

	process_t *proc = sched_get_process(new->pid);

	// falha critica
	if (!proc) {
		printk("switch_context: falha ao trocar o contexto: "
			   "new->process == null;\r\n");
		printk("switch_context: sistema parado\r\n");
		disable_interrupts();
		halt_cpu();
	}

	current_thread = new;

	if (new != &idle_process.threads[0])
		tss_set_sp0(new->stack0 + KERNEL_STACK_SIZE, 0x10);

	write_cr3(proc->cr3);

	current_thread->state = THREAD_RUNNING;

	restore_context(current_thread->sp0);
}

// Escalonador
// Não define o contexto de ctx for nulo
void schedule(interrupt_context_t *ctx) {
	if (queue_empty(&ready_queue))
		return;

	if (ctx)
		current_thread->sp0 = (uintptr_t)ctx;

	if (current_thread->state == THREAD_RUNNING)
		queue_push(&ready_queue, &current_thread->node);

	while (1) {
		queue_node_t *n = queue_pop(&ready_queue);
		thread_t *new_thread = (thread_t *)CONTAINER_OF(n, thread_t, node);
		if (new_thread == current_thread)
			return;

		process_t *proc = sched_get_process(new_thread->pid);
		if (!proc)
			return;

		if (proc->state == PROCESS_DYING)
			return; // Mais tempo de execução pra tarefa atual até que um
					// processo normal seja encontrado

		switch_context(new_thread);
	}
}

// Rotina do timer
static void timer_handler(interrupt_context_t *ctx) {
	ticks++;
	pic_send_eoi(0);

	queue_node_t *n = sleep_queue.head.next;
	while (n) {
		queue_node_t *next = n->next; // guarda antes de remover
		thread_t *t = CONTAINER_OF(n, thread_t, node);
		if (ticks >= t->wake_tick)
			sched_ready(t);
		n = next;
	}

	schedule(ctx);
}

// retorna os ticks do escalonador
uint32_t sched_get_ticks(void) { return ticks; }

// Retorna o número de milisegundos por tick
uint32_t sched_get_ms_per_tick(void) { return ms_per_tick; }

// inicializa o escalonador com a frequencia informada em hz
// retorna !0 se ocorrer um erro
int sched_init(uint16_t frequency) {
	printk("Inicializando escalonador...\r\n");

	if (frequency <= 18)
		frequency = 100;

	timer_frequency = frequency;
	ms_per_tick = 1000 / timer_frequency;

	idt_set_handler(32, timer_handler);
	pit_set_frequency(0, timer_frequency, PIT_SQUARE_WAVE_GENERATOR);

	idle_process.pid = current_pid++;
	idle_process.cr3 = kernel_cr3;

	queue_init(&ready_queue);
	queue_init(&zombie_queue);
	queue_init(&sleep_queue);

	current_thread = &idle_process.threads[0];
	current_thread->pid = idle_process.pid;

	idle_process.prev = NULL;
	idle_process.next = NULL;
	idle_process.parent = NULL;
	first_process = &idle_process;

	printk("Processo idle criado com PID %u\r\n", idle_process.pid);
	printk("Escalonador inicializado\r\n");

	idt_set_handler(0x81, schedule);
	idt_set_dpl(0x81, 3);

	return 0;
}

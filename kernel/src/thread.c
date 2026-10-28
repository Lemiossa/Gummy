/*
 * thread.c
 * Criado por Matheus Leme da Silva
 * */
#include <debug.h>
#include <heap.h>
#include <io.h>
#include <queue.h>
#include <sched.h>
#include <string.h>
#include <vmm.h>

extern process_t idle_process;
extern void schedule(interrupt_context_t *ctx);

thread_t *current_thread = NULL;
queue_t ready_queue;
queue_t blocked_queue;
queue_t zombie_queue;

// Retorna o estado de uma thread
//     0: ready
//     1: blocked
//     2: zombie
//     3: running
//     4: free
//     -1: Não possivel identificar
int sched_thread_state(thread_t *t) {
	if (!t)
		return -1;

	if (!t->process)
		return 4;

	if (t == current_thread)
		return 3; // Atual rodando

	if (!t->node.q)
		return -1;

	uintptr_t ptr = (uintptr_t)t->node.q;
	if (ptr == (uintptr_t)&ready_queue)
		return 0;

	else if (ptr == (uintptr_t)&blocked_queue)
		return 1;

	else if (ptr == (uintptr_t)&zombie_queue)
		return 2;

	return -1;
}

// seta uma thread como ready
void sched_ready(thread_t *thread) {
	if (!thread)
		return;

	uintptr_t flags = read_flags();
	disable_interrupts();
	queue_remove(&thread->node);
	queue_push(&ready_queue, &thread->node);
	write_flags(flags);
}

// seta uma thread como blocked
void sched_blocked(thread_t *thread) {
	if (!thread)
		return;

	uintptr_t flags = read_flags();
	disable_interrupts();
	queue_remove(&thread->node);
	queue_push(&blocked_queue, &thread->node);
	write_flags(flags);
}

// seta uma thread como zombie
void sched_zombie(thread_t *thread) {
	if (!thread)
		return;

	uintptr_t flags = read_flags();
	disable_interrupts();
	queue_remove(&thread->node);
	queue_push(&zombie_queue, &thread->node);
	write_flags(flags);
}

// destroi uma thread
// tira ela de qualquer fila que esteja
void sched_destroy_thread(thread_t *thread) {
	if (!thread)
		return;

	if (!thread->process)
		return; // Ja esta livre

	debug_log_string("SCHED", "Destruindo thread do processo PID 0x");
	debug_log_hex32(thread->process->pid);
	debug_print_string("\r\n");

	if (thread == current_thread) {
		debug_log_string("SCHED",
						 "Aviso: nao e possivel destruir thread atual\r\n");
		return;
	}

	uintptr_t flags = read_flags();
	disable_interrupts();

	if (thread->stack)
		vmm_free_pages_in(thread->process->cr3, USER_STACK_PAGES,
						  (void *)thread->stack);

	if (thread->stack0)
		heap_free((void *)thread->stack0);

	queue_remove(&thread->node);
	thread->process->num_threads--;
	memset(thread, 0, sizeof(*thread));
	write_flags(flags);

	debug_log_string("SCHED", "Thread destruida\r\n");
}

// cria uma thread
// retorna o ponteiro pra thread(não aloca)
// loc precisa estar mapeado com USER em proc->cr3 antes da primeira execução
thread_t *sched_create_thread(uintptr_t loc, process_t *proc) {
	if (!proc || !loc) {
		debug_log_string("SCHED",
						 "sched_create_thread: parametros invalidos\r\n");
		return NULL;
	}

	debug_log_string("SCHED", "Criando thread no processo PID 0x");
	debug_log_hex32(proc->pid);
	debug_print_string(", entry=0x");
	debug_log_hex32((uint32_t)loc);
	debug_print_string("\r\n");

	if (proc->num_threads >= THREAD_PER_PROCESS) {
		debug_log_string(
			"SCHED", "Falha ao criar thread: limite de threads atingido\r\n");
		return NULL;
	}

	int thread_idx = -1;
	for (int i = 0; i < THREAD_PER_PROCESS; i++) {
		if (!proc->threads[i].process) {
			thread_idx = i;
			break;
		}
	}

	if (thread_idx == -1)
		return NULL;

	thread_t *t = &proc->threads[thread_idx];
	memset(t, 0, sizeof(*t));

	uintptr_t stack0 = (uintptr_t)heap_alloc(KERNEL_STACK_SIZE);
	if (!stack0)
		return NULL;

	// USER_STACK_TOP - i * (USER_STACK_SIZE + PAGE_SIZE)
	uintptr_t sp = USER_STACK_TOP - thread_idx * (USER_STACK_SIZE + PAGE_SIZE);
	uintptr_t stack = sp - USER_STACK_SIZE;
	if (!vmm_alloc_pages_region_in(
			proc->cr3, USER_STACK_PAGES,
			VMM_FLAGS_PRESENT | VMM_FLAGS_RW | VMM_FLAGS_USER, stack, sp)) {
		heap_free((void *)stack0);
		return NULL;
	}

	uintptr_t sp0 = (stack0 + KERNEL_STACK_SIZE) - sizeof(interrupt_context_t);
	memset((void *)stack0, 0, KERNEL_STACK_SIZE);

	uintptr_t flags = read_flags();
	disable_interrupts();

	interrupt_context_t *ctx = (interrupt_context_t *)sp0;
	ctx->eax = 0;
	ctx->ebx = 0;
	ctx->ecx = 0;
	ctx->edx = 0;
	ctx->ebp = 0;
	ctx->edi = 0;
	ctx->esi = 0;
	ctx->cs = 0x1B;
	ctx->ds = 0x23;
	ctx->es = 0x23;
	ctx->fs = 0x23;
	ctx->gs = 0x23;
	ctx->ss = 0x23;
	ctx->eip = loc;
	ctx->esp = sp;
	ctx->eflags = 0x202;
	ctx->error_code = 0;
	ctx->int_num = 0;

	t->process = proc;
	t->sp = sp;
	t->sp0 = sp0;
	t->stack = stack;
	t->stack0 = stack0;

	proc->num_threads++;
	write_flags(flags);

	debug_log_string("SCHED", "Thread criada com sucesso (PID 0x");
	debug_log_hex32(proc->pid);
	debug_print_string(")\r\n");

	return t;
}

// Sai da thread atual e seta o exit code dela
void sched_exit_current_thread(interrupt_context_t *ctx, int32_t status) {
	if (current_thread->process == &idle_process) {
		debug_log_string("SCHED",
						 "Tentativa de sair do idle interrompida.\r\n");
		return;
	}

	uintptr_t flags = read_flags();
	disable_interrupts();

	thread_t *t = current_thread;
	t->exit_code = status;
	sched_zombie(t);

	schedule(ctx);

	write_flags(flags);
	for (;;)
		halt_cpu();
}

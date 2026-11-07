/*
 * thread.c
 * Criado por Matheus Leme da Silva
 * */
#include <debug.h>
#include <heap.h>
#include <idt.h>
#include <io.h>
#include <queue.h>
#include <sched/process.h>
#include <sched/sched.h>
#include <sched/thread.h>
#include <string.h>
#include <types.h>
#include <vmm.h>

extern void schedule(interrupt_context_t *ctx);

thread_t *current_thread = NULL;
queue_t ready_queue;
queue_t zombie_queue;
queue_t sleep_queue;

// Retorna o ponteiro pra thread atual
thread_t *sched_get_current_thread(void) { return current_thread; }

// seta uma thread como ready
void sched_ready(thread_t *thread) {
	if (!thread)
		return;

	flags_t flags = read_flags();
	disable_interrupts();
	queue_remove(&thread->node);
	queue_push(&ready_queue, &thread->node);
	thread->state = THREAD_READY;
	write_flags(flags);
}

// seta uma thread como zombie
void sched_zombie(thread_t *thread) {
	if (!thread)
		return;

	flags_t flags = read_flags();
	disable_interrupts();
	queue_remove(&thread->node);
	queue_push(&zombie_queue, &thread->node);
	thread->state = THREAD_ZOMBIE;
	write_flags(flags);
}

// seta uma thread como sleep
void sched_sleep(thread_t *thread) {
	if (!thread)
		return;

	flags_t flags = read_flags();
	disable_interrupts();
	queue_remove(&thread->node);
	queue_push(&sleep_queue, &thread->node);
	thread->state = THREAD_SLEEPING;
	write_flags(flags);
}

// destroi uma thread
// tira ela de qualquer fila que esteja
void sched_destroy_thread(thread_t *thread) {
	if (!thread)
		return;

	if (thread->state == THREAD_FREE)
		return; // Ja esta livre

	process_t *proc = sched_get_process(thread->pid);
	if (!proc)
		return;

	if (thread == current_thread) {
		printk("Aviso: nao e possivel destruir thread atual\r\n");
		return;
	}

	printk("Destruindo thread do processo PID %u\r\n", proc->pid);

	flags_t flags = read_flags();
	disable_interrupts();

	if (thread->stack)
		vmm_free_pages_in(proc->cr3, USER_STACK_PAGES, (void *)thread->stack);

	if (thread->stack0)
		heap_free((void *)thread->stack0);

	queue_remove(&thread->node);
	proc->num_threads--;
	thread->state = THREAD_FREE;
	write_flags(flags);

	printk("Thread destruida\r\n");
}

// cria uma thread
// retorna o ponteiro pra thread(não aloca)
// loc precisa estar mapeado com USER em proc->cr3 antes da primeira execução
thread_t *sched_create_thread(uintptr_t loc, pid_t pid) {
	if (!loc || pid < 0)
		return NULL;

	process_t *proc = sched_get_process(pid);
	if (!proc)
		return NULL;

	printk("Criando thread no processo PID %u, entry=%p\r\n", proc->pid, loc);

	if (proc->num_threads >= THREAD_PER_PROCESS) {
		printk("Falha ao criar thread: limite de threads atingido\r\n");
		return NULL;
	}

	int thread_idx = -1;
	for (int i = 0; i < THREAD_PER_PROCESS; i++) {
		if (proc->threads[i].state == THREAD_FREE) {
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

	uintptr_t sp = USER_STACK_TOP - thread_idx * (USER_STACK_SIZE + PAGE_SIZE);
	uintptr_t stack = sp - USER_STACK_SIZE;
	if (proc != &idle_process) {
		// USER_STACK_TOP - i * (USER_STACK_SIZE + PAGE_SIZE)
		if (!vmm_alloc_pages_region_in(
				proc->cr3, USER_STACK_PAGES,
				VMM_FLAGS_PRESENT | VMM_FLAGS_RW | VMM_FLAGS_USER, stack, sp)) {
			heap_free((void *)stack0);
			return NULL;
		}
	}

	uintptr_t sp0 = (stack0 + KERNEL_STACK_SIZE) - sizeof(interrupt_context_t);
	memset((void *)stack0, 0, KERNEL_STACK_SIZE);

	flags_t flags = read_flags();
	disable_interrupts();

	interrupt_context_t *ctx = (interrupt_context_t *)sp0;
	ctx->eax = 0;
	ctx->ebx = 0;
	ctx->ecx = 0;
	ctx->edx = 0;
	ctx->ebp = 0;
	ctx->edi = 0;
	ctx->esi = 0;
	if (proc != &idle_process) {
		ctx->cs = 0x1B;
		ctx->ds = 0x23;
		ctx->es = 0x23;
		ctx->fs = 0x23;
		ctx->gs = 0x23;
		ctx->ss = 0x23;
		ctx->esp = sp;
	} else {
		ctx->cs = 0x08;
		ctx->ds = 0x10;
		ctx->es = 0x10;
		ctx->fs = 0x10;
		ctx->gs = 0x10;
		ctx->ss = 0x10;
		ctx->esp = 0;
	}

	ctx->eip = loc;
	ctx->eflags = 0x202;
	ctx->error_code = 0;
	ctx->int_num = 0;

	t->pid = proc->pid;
	if (proc != &idle_process) {
		t->sp = sp;
		t->stack = stack;
	}
	t->sp0 = sp0;
	t->stack0 = stack0;

	proc->num_threads++;
	write_flags(flags);

	printk("Thread criada com sucesso (PID %u)\r\n", proc->pid);

	return t;
}

// Sai da thread atual e seta o exit code dela
void sched_exit_current_thread(interrupt_context_t *ctx, int32_t status) {
	if (sched_get_current_process() == &idle_process) {
		printk("Tentativa de sair do idle interrompida.\r\n");
		return;
	}

	flags_t flags = read_flags();
	disable_interrupts();

	thread_t *t = current_thread;
	t->exit_code = status;
	sched_zombie(t);

	schedule(ctx);

	write_flags(flags);
	for (;;)
		halt_cpu();
}

// Bota a thread atual em sleep
void sched_thread_sleep(interrupt_context_t *ctx, uint32_t wake_tick) {
	if (!current_thread || wake_tick <= sched_get_ticks())
		return;

	if (current_thread == &idle_process.threads[0])
		return;

	flags_t flags = read_flags();
	disable_interrupts();

	current_thread->wake_tick = wake_tick;
	sched_sleep(current_thread);
	schedule(ctx);
	write_flags(flags);
}

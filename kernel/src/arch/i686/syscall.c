/*
 * syscall.c
 * Criado por Matheus Leme da Silva
 * */
#include <heap.h>
#include <idt.h>
#include <io.h>
#include <sched.h>
#include <string.h>
#include <syscall.h>
#include <types.h>
#include <vmm.h>

extern void schedule(interrupt_context_t *ctx);

uint32_t sys_exit_impl(interrupt_context_t *ctx);
uint32_t sys_getpid_impl(interrupt_context_t *ctx);
uint32_t sys_getppid_impl(interrupt_context_t *ctx);
uint32_t sys_sleep_impl(interrupt_context_t *ctx);
uint32_t sys_nthread_impl(interrupt_context_t *ctx);
uint32_t sys_nprocess_impl(interrupt_context_t *ctx);

void syscall_handler(interrupt_context_t *ctx) {
	uint32_t ret = 0;
	switch (ctx->eax) {
	case SYS_EXIT:
		ret = sys_exit_impl(ctx);
		break;
	case SYS_GETPID:
		ret = sys_getpid_impl(ctx);
		break;
	case SYS_GETPPID:
		ret = sys_getppid_impl(ctx);
		break;
	case SYS_SLEEP:
		ret = sys_sleep_impl(ctx);
		break;
	case SYS_NTHREAD:
		ret = sys_nthread_impl(ctx);
		break;
	case SYS_NPROCESS:
		ret = sys_nprocess_impl(ctx);
		break;
	default:
		ret = -1;
		break;
	}
	ctx->eax = (uint32_t)ret;
}

// Inicializa as syscalls
void syscall_init(void) {
	idt_set_handler(0x80, syscall_handler);
	idt_set_dpl(0x80, 3);
}

// Cria um novo processo com uma thread inicial
// Copia n bytes de entry para o processo como thread inicial
uint32_t sys_nprocess_impl(interrupt_context_t *ctx) {
	const void *entry = (void *)ctx->ebx;
	uint32_t n = ctx->ecx;

	if (!entry || n == 0)
		return 0;

	void *data = heap_alloc(n);
	if (!data)
		return 0;

	memcpy(data, entry, n);

	process_t *p = sched_create_process();
	if (!p) {
		heap_free(data);
		return 0;
	}

	uint32_t pages = ALIGN_UP(n, PAGE_SIZE) / PAGE_SIZE;

	if (!vmm_alloc_pages_region_in(
			p->cr3, pages, VMM_FLAGS_PRESENT | VMM_FLAGS_RW | VMM_FLAGS_USER,
			0x400000, 0x400000 + pages * PAGE_SIZE)) {
		heap_free(data);
		sched_destroy_process(p);
		return 0;
	}

	thread_t *t = sched_create_thread(0x400000, p);
	if (!t) {
		vmm_free_pages_in(p->cr3, pages, (void *)0x400000);
		heap_free(data);
		sched_destroy_process(p);
		return 0;
	}

	uintptr_t flags = read_flags();
	disable_interrupts();

	uintptr_t old_cr3 = read_cr3();
	write_cr3(p->cr3);

	memcpy((void *)0x400000, data, n);

	write_cr3(old_cr3);
	write_flags(flags);

	heap_free(data);

	sched_ready(t);

	return p->pid;
}

uint32_t sys_exit_impl(interrupt_context_t *ctx) {
	sched_exit_current_thread(ctx, (int32_t)ctx->ebx);
	return 0;
}

uint32_t sys_getpid_impl(interrupt_context_t *ctx) {
	(void)ctx;
	return (uint32_t)sched_get_current_pid();
}

uint32_t sys_getppid_impl(interrupt_context_t *ctx) {
	(void)ctx;
	return (uint32_t)sched_get_current_ppid();
}

uint32_t sys_sleep_impl(interrupt_context_t *ctx) {
	sched_thread_sleep(ctx, sched_get_ticks() +
								(ctx->ebx / sched_get_ms_per_tick()));
	return 0;
}

uint32_t sys_nthread_impl(interrupt_context_t *ctx) {
	process_t *current_process = sched_get_current_process();
	if (!current_process)
		return (uint32_t)-1;
	uintptr_t entry = (uintptr_t)ctx->ebx;
	thread_t *t = sched_create_thread(entry, current_process);
	if (!t)
		return (uint32_t)-1;
	sched_ready(t);
	return 0;
}

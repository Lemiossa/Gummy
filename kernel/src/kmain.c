/*
 * kmain.c
 * Criado por Matheus Leme Da Silva
 */
#include <debug.h>
#include <e820.h>
#include <exception.h>
#include <gdt.h>
#include <heap.h>
#include <idt.h>
#include <io.h>
#include <pic.h>
#include <pmm.h>
#include <sched.h>
#include <string.h>
#include <syscall.h>
#include <terminal.h>
#include <tss.h>
#include <types.h>
#include <vmm.h>

// Cria um processo com uma thread inicial
// program: Endereço no CR3 ATUAL, será copiado para o cr3 do processo
// size: tamanho de program
// Retorna o endereço do processo, NULL caso algum erro ocorra
process_t *spawn(const void *program, size_t size) {
	if (!program || size == 0)
		return NULL;

	uintptr_t flags = read_flags();
	disable_interrupts();

	process_t *proc = sched_create_process();
	if (!proc) {
		write_flags(flags);
		return NULL;
	}

	const uint8_t *p = (const uint8_t *)program;

	uint8_t *data = heap_alloc(size);
	if (!data) {
		sched_destroy_process(proc);
		write_flags(flags);
		return NULL;
	}
	memcpy(data, p, size);

	size_t pages = ALIGN_UP(size, PAGE_SIZE) / PAGE_SIZE;
	void *addr = vmm_alloc_pages_region_in(
		proc->cr3, pages, VMM_FLAGS_PRESENT | VMM_FLAGS_RW | VMM_FLAGS_USER,
		0x400000,
		0x400000 + pages * PAGE_SIZE); // Como o cr3 está com esse mapeamento
									   // limpo, é certo de que vai funcionar
	if (!addr) {
		sched_destroy_process(proc);
		heap_free(data);
		write_flags(flags);
		return NULL;
	}

	// Copiar os dados com segurança
	uintptr_t cr3 = read_cr3();
	write_cr3(proc->cr3);

	// Como data foi copiada para o heap do kernel e spawn() é executado em
	// ring0, ela fica acessivel de qualquer cr3(não é destruido por
	// vmm_destroy())
	memcpy(addr, data, size);

	write_cr3(cr3);

	heap_free(data);

	thread_t *t = sched_create_thread((uintptr_t)addr, proc);
	if (!t) {
		vmm_free_pages_in(proc->cr3, pages, addr);
		sched_destroy_process(proc);

		write_flags(flags);
		return NULL;
	}

	sched_ready(t);

	write_flags(flags);
	return proc;
}

void syscall_handler(interrupt_context_t *ctx) {
	switch (ctx->eax) {
	case SYS_EXIT:
		sched_exit_current_thread(ctx, (int32_t)ctx->ebx);
		break;
	case SYS_GETPID:
		ctx->eax = sched_get_current_pid();
		break;
	default:
		ctx->eax = (uint32_t)-1;
		break;
	}
}

// Inicializa as syscalls
void syscall_init(void) {
	idt_set_handler(0x80, syscall_handler);
	idt_set_dpl(0x80, 3);
}

void kmain(void) {
	disable_interrupts();
	debug_init();

	debug_log_string("KMAIN", "Inicializando GDT...\r\n");
	gdt_init();
	debug_log_string("KMAIN", "GDT inicializado!\r\n");

	debug_log_string("KMAIN", "Inicializando TSS...\r\n");
	tss_init();
	debug_log_string("KMAIN", "TSS inicializado!\r\n");

	debug_log_string("KMAIN", "Inicializando terminal...\r\n");
	terminal_init();
	debug_log_string("KMAIN", "Terminal inicializado!\r\n");

	debug_log_string("KMAIN", "Inicializando IDT...\r\n");
	idt_init();
	debug_log_string("KMAIN", "IDT inicializado!\r\n");

	debug_log_string("KMAIN", "Remapeando PIC...\r\n");
	pic_remap();
	debug_log_string("KMAIN", "PIC remapeado!\r\n");

	debug_log_string("KMAIN", "Inicializando excecoes...\r\n");
	exception_init();
	debug_log_string("KMAIN", "Excecoes inicializadas!\r\n");

	debug_log_string("KMAIN", "Inicializando E820...\r\n");
	E820_init();
	debug_log_string("KMAIN", "E820 inicializado!\r\n");

	debug_log_string("KMAIN", "Inicializando PMM...\r\n");
	pmm_init();
	debug_log_string("KMAIN", "PMM inicializado!\r\n");

	debug_log_string("KMAIN", "Inicializando VMM...\r\n");
	vmm_init();
	debug_log_string("KMAIN", "VMM inicializado!\r\n");

	debug_log_string("KMAIN", "Inicializando heap...\r\n");
	heap_init();
	debug_log_string("KMAIN", "Heap inicializado!\r\n");

	debug_log_string("KMAIN", "Inicializando escalonador...\r\n");
	if (sched_init(100)) {
		debug_log_string("KMAIN", "Falha ao inicializar o escalonador!\r\n");
		goto halt;
	}
	debug_log_string("KMAIN", "Escalonador inicializado!\r\n");

	terminal_print_string(NAME);
	terminal_print_string(" v");
	terminal_print_string(VERSION);
	terminal_print_string("\r\n");

	syscall_init();

	process_t *p = spawn((void *)0xC0050000, 0x1000);
	enable_interrupts();

	// TODO: Reaper: Libera as threads zumbís ou os processos que não tem mais
	// threads
	while (1) {
	}

	for (;;)
		halt_cpu();
halt:
	debug_log_string("KMAIN", "Sistema parado\r\n");
	disable_interrupts();
	halt_cpu();
}

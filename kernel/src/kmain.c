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
#include <ipc.h>
#include <pic.h>
#include <pit.h>
#include <pmm.h>
#include <queue.h>
#include <ring_buffer.h>
#include <sched.h>
#include <syscall.h>
#include <terminal.h>
#include <tss.h>
#include <types.h>
#include <vmm.h>

// Thread de debug do heap
// Imprime um dump do heap a cada 30 segundos
void heap_debug_thread(void) {
	while (1) {
		heap_print();
		sys_sleep(30000);
	}
	sys_exit(0);
}

// Reaper de processos
// Mata todo e qualquer processo em estado dying
void reaper_thread(void) {
	while (1) {
		for (process_t *p = first_process; p;) {
			process_t *next = p->next;
			if (p->state == PROCESS_DYING)
				sched_destroy_process(p);
			p = next;
		}
		sys_sleep(5000);
	}
	sys_exit(0);
}

// Processo de teste, executa uma divisão por zero forcada
void test_process(void) {
	volatile int a = 1;
	volatile int b = 0;
	volatile int c = a / b;
	(void)c;
	sys_exit(0);
}

void kmain(void) {
	disable_interrupts();
	debug_init();
	gdt_init();
	tss_init();
	terminal_init();
	idt_init();
	pic_remap();
	exception_init();
	E820_init();
	pmm_init();
	vmm_init();
	heap_init();
	if (sched_init(100)) {
		debug_log_string("KMAIN", "Falha ao inicializar o escalonador!\r\n");
		goto halt;
	}
	syscall_init();
	enable_interrupts();

	sys_nthread(heap_debug_thread);
	sys_nprocess(test_process, 512);
	sys_nthread(reaper_thread);

	for (;;)
		halt_cpu();
halt:
	debug_log_string("KMAIN", "Sistema parado\r\n");
	disable_interrupts();
	halt_cpu();
}

/*
 * kmain.c
 * Criado por Matheus Leme Da Silva
 */
#include <initrd.h>
#include <io.h>
#include <queue.h>
#include <ring_buffer.h>
#include <string.h>
#include <types.h>

#include <e820.h>
#include <gdt.h>
#include <heap.h>
#include <pmm.h>
#include <vmm.h>

#include <debug.h>
#include <terminal.h>

#include <ipc.h>
#include <sched/process.h>
#include <sched/sched.h>
#include <tss.h>

#include <exception.h>
#include <idt.h>
#include <pic.h>
#include <pit.h>
#include <syscall.h>

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

// Spawner de processos


const char *initpath = "/init.sys";
uintptr_t initrd_loc = 0xC0050000;

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
		printk("Falha ao inicializar o escalonador!\r\n");
		goto halt;
	}
	syscall_init();
	enable_interrupts();

	sys_nthread(reaper_thread);

	initrd_t initrd;
	initrd_create(&initrd, (void *)initrd_loc);

	if (initrd_check(&initrd)) {
		printk("Falha ao carregar initrd!\r\n");
		goto halt;
	}

	const initrd_entry_t *init = initrd_find_entry(&initrd, initpath);
	if (!init) {
		printk("Falha ao carregar init!\r\n");
		printk("Entrada no initrd: '%s'\r\n", initpath);
		goto halt;
	}

	size_t len = initrd_get_len(init);
	printk("Encontrado '%s'\r\n", initpath);
	printk("Tamanho: %u b\r\n", len);
	const void *data = initrd_get_data(&initrd, init);
	sys_nprocess(data, len);

	for (;;)
		halt_cpu();
halt:
	printk("Sistema parado\r\n");
	disable_interrupts();
	halt_cpu();
}

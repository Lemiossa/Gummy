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
#include <string.h>
#include <syscall.h>
#include <terminal.h>
#include <tss.h>
#include <types.h>
#include <vmm.h>
#include <initrd.h>

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

// Imprime todas as entradas de um initrd 
void initrd_print(const initrd_t *initrd) {
	if (initrd_check(initrd)) return;

	for (size_t i = 0; i < initrd->header->entry_count; i++) {
		const initrd_entry_t *entry = initrd_get_entry(initrd, i);
		if (!entry) continue;
		const char *name = (const char *)((uintptr_t)entry + sizeof(initrd_entry_t));
		printk("entry %u: %s\r\n", i, name);
	}
}

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

	sys_nthread(heap_debug_thread);
	sys_nthread(reaper_thread);

	initrd_t initrd;
	initrd_create(&initrd, (void *)initrd_loc);

	printk("Header: %p\r\n", initrd.header);
	printk("Magic: %08x\r\n", initrd.header->magic);
	printk("Expected: %08x\r\n", INITRD_MAGIC);
	printk("Version: %u\r\n", initrd.header->version);
	if (!initrd_check(&initrd)) {
		printk("Initrd detectado\r\n");
		printk("Quantidade de entradas: %u\r\n", initrd.header->entry_count);
		printk("Data offset: %u\r\n", initrd.header->data_offset);

		initrd_print(&initrd);

		const initrd_entry_t *init = initrd_find_entry(&initrd, initpath);
		if (init) {
			size_t len = initrd_get_len(init);
			printk("Encontrado '%s'\r\n", initpath);
			printk("Tamanho: %u b\r\n", len);
			const void *data = initrd_get_data(&initrd, init);
			debug_dump_code((uintptr_t)data, len);
		}
	}

	for (;;)
		halt_cpu();
halt:
	printk("Sistema parado\r\n");
	disable_interrupts();
	halt_cpu();
}

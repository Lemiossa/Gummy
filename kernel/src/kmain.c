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

#include <vfs.h>

const char *initpath = "/init.sys";
uintptr_t initrd_loc = 0xC0050000;

// RAMFS
typedef enum ramfs_node_type {
	RAMFS_FILE,
	RAMFS_DIR
} ramfs_node_type_t;

typedef struct ramfs_node {
	char *name;
	size_t name_len;
	ramfs_node_type_t type;
	void *data;
	size_t data_len;
	struct ramfs_node *parent;
	struct ramfs_node *children;
	struct ramfs_node *next;
} ramfs_node_t;

typedef struct ramfs {
	ramfs_node_t *root;
} ramfs_t;

// Close do ramfs
int ramfs_close(void *ctx, handle_t *h) {
	if (!ctx || !h) return -VFS_ERR_INVALID;
	heap_free(h); // Arquivo se mantem, só o handle que não
	return VFS_ERR_OK;
}

// Open do ramfs
// Só aceita PATH começando com / 
int ramfs_open(void *ctx, const char *path, handle_t **h) {
	if (!ctx || !path || !h || path[0] != '/') return -VFS_ERR_INVALID;
	// /boot/config
	const char *p = (const char *)(uintptr_t)(path + 1);
}

// inicializa ramfs
// retorna 0 se sucesso
int ramfs_init(void) {
	fs_t *fs = heap_alloc(sizeof(*fs));
	if (!fs) return 1;

	ops_t *ops = heap_alloc(sizeof(*ops));
	if (!ops) {
		heap_free(fs);
		return 1;
	}

	memcpy(fs->name, "ramfs", 5);
	fs->ops->close = ramfs_close;
	fs->ops->open = ramfs_open;

	return 0;
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
		printk("Falha ao inicializar o escalonador!\r\n");
		goto halt;
	}
	syscall_init();
	enable_interrupts();

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

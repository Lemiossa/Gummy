/*
 * heap.c
 * Criado por Matheus Leme da Silva
 * */
#include <debug.h>
#include <heap.h>
#include <pmm.h>
#include <terminal.h>
#include <types.h>
#include <vmm.h>

typedef struct heap_block {
	size_t size;  // em bytes
	uint8_t used; // 1 se usado, 0 se livre
	struct heap_block *prev;
	struct heap_block *next;
} heap_block_t;

heap_block_t *heap_start = NULL;

// Inicializa o heap
void heap_init(void) {
	uintptr_t region_start = HEAP_VIRTUAL_ADDRESS;
	uintptr_t region_end =
		HEAP_VIRTUAL_ADDRESS + HEAP_INITIAL_PAGES * PAGE_SIZE;
	if ((uintptr_t)region_end >= 0xFFC00000) {
		printk("Falha na inicializacao: region_end excede 0xFFC00000\r\n");
		return;
	}

	heap_start = (heap_block_t *)vmm_alloc_pages_region(
		HEAP_INITIAL_PAGES, VMM_FLAGS_RW | VMM_FLAGS_PRESENT, region_start,
		region_end);
	if (!heap_start) {
		printk("Falha na inicializacao: vmm_alloc_pages retornou NULL\r\n");
		return;
	}

	printk("vaddr: 0x%016llX, paginas iniciais: 0x%08X\r\n",
		   (uint64_t)HEAP_VIRTUAL_ADDRESS, (uint32_t)HEAP_INITIAL_PAGES);

	size_t region_size = HEAP_INITIAL_PAGES * PAGE_SIZE;
	heap_start->size = region_size - sizeof(heap_block_t);
	heap_start->used = 0;
	heap_start->prev = NULL;
	heap_start->next = NULL;
}

// Expande o heap em n paginas
// Retorna o novo bloco em caso de sucesso, NULL caso contrario
void *heap_expand(size_t n) {
	if (!heap_start || n == 0)
		return NULL;

	heap_block_t *b = heap_start;
	while (b->next)
		b = b->next;
	uintptr_t region_start = ((uintptr_t)b + sizeof(heap_block_t) + b->size);
	uintptr_t region_end = ((uintptr_t)region_start + n * PAGE_SIZE);
	if (region_end >= 0xFFC00000)
		return NULL;

	heap_block_t *new_block = (heap_block_t *)vmm_alloc_pages_region(
		n, VMM_FLAGS_RW | VMM_FLAGS_PRESENT, region_start, region_end);
	if (!new_block)
		return NULL;

	new_block->size = n * PAGE_SIZE - sizeof(heap_block_t);
	new_block->used = 0;
	new_block->prev = b;
	new_block->next = NULL;
	b->next = new_block;

	printk("Heap expandido em %u paginas, novo bloco em 0x%016llX\r\n",
		   (uint32_t)n, (uint64_t)(uintptr_t)new_block);

	return new_block;
}

// Mescla blocos livres adjacentes
// O bloco atual deve estar livre
void heap_merge_free_blocks(heap_block_t *b) {
	if (!b || b->used)
		return;

	// Mescla o bloco anterior
	if (b->prev && !b->prev->used) {
		b->prev->size += b->size + sizeof(heap_block_t);
		b->prev->next = b->next;
		if (b->next)
			b->next->prev = b->prev;
		b = b->prev;
	}

	// Mescla o proximo bloco
	if (b->next && !b->next->used) {
		b->size += b->next->size + sizeof(heap_block_t);
		b->next = b->next->next;
		if (b->next)
			b->next->prev = b;
	}
}

// Divide o bloco do heap para o tamanho especificado
// O bloco atual deve estar livre
void heap_split_block(heap_block_t *b, size_t size) {
	if (!b || b->used || b->size <= size)
		return;

	size_t new_size = b->size - size - sizeof(heap_block_t);
	if (new_size < HEAP_SPLIT_BLOCK_MIN_SIZE)
		return;

	heap_block_t *new =
		(heap_block_t *)((uintptr_t)b + size + sizeof(heap_block_t));

	new->size = new_size;
	new->used = 0;
	new->prev = b;
	new->next = b->next;

	if (b->next)
		b->next->prev = new;

	b->size = size;
	b->next = new;
}

// Aloca um bloco de memoria com o tamanho informado
void *heap_alloc(size_t size) {
	if (size == 0)
		return NULL;

	size = ALIGN_UP(size, sizeof(uintptr_t));

	printk("Alocando %llu b\r\n", (uint64_t)size);

	heap_block_t *b = heap_start;
	while (b) {
		if (!b->used && b->size >= size) {
			heap_split_block(b, size);
			b->used = 1;

			return (void *)((uintptr_t)b + sizeof(heap_block_t));
		}

		if (!b->next)
			break;
		b = b->next;
	}

	heap_block_t *new = heap_expand(
		ALIGN_UP(size + sizeof(heap_block_t), PAGE_SIZE) / PAGE_SIZE);

	if (!new)
		return NULL;

	new->used = 1;

	return (void *)((uintptr_t)new + sizeof(heap_block_t));
}

// Libera um bloco de memoria alocado anteriormente
void heap_free(void *ptr) {
	if (!ptr)
		return;

	heap_block_t *b = heap_start;
	while (b) {
		if ((void *)((uintptr_t)b + sizeof(heap_block_t)) == ptr) {
			b->used = 0;
			break;
		}
		b = b->next;
	}

	printk("Bloco liberado em 0x%016llX\r\n", (uint64_t)(uintptr_t)b);

	heap_merge_free_blocks(b);
}

// Imprime o estado atual do heap (para fins de debug)
void heap_print(void) {
	if (!heap_start) {
		printk("Heap nao inicializado\r\n");
		return;
	}

	uint32_t blocks = 0, used_bytes = 0, free_bytes = 0;

	for (heap_block_t *b = heap_start; b; b = b->next) {
		blocks++;
		if (b->used)
			used_bytes += b->size;
		else {
			free_bytes += b->size;
		}
	}

	printk("blocos=%u usado=%u b livre=%u b\r\n", blocks, used_bytes,
		   free_bytes);
}

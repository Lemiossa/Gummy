#ifndef PMM_H
#define PMM_H
#include <types.h>

#define PAGE_SIZE 4096

// Alloc a page of physical memory
uintptr_t pmm_alloc_page(void);
// Free a page of physical memory
void pmm_free_page(uintptr_t page);
// Initialize the physical memory manager
void pmm_init();

#endif // PMM_H

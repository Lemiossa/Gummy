#ifndef PMM_H
#define PMM_H

#define PAGE_SIZE 4096

// Alloc a page of physical memory
void *pmm_alloc_page();
// Free a page of physical memory
void pmm_free_page(void *page);
// Initialize the physical memory manager
void pmm_init();

#endif // PMM_H

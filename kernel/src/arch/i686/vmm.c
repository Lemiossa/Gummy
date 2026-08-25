/*
 * vmm.c
 * Created by Matheus Leme da Silva
 * */
#include <io.h>
#include <terminal.h>
#include <types.h>

typedef struct 
{
    uint32_t present    : 1;
    uint32_t rw         : 1;
    uint32_t user       : 1;
    uint32_t pwt        : 1;
    uint32_t pcd        : 1;
    uint32_t accessed   : 1;
    uint32_t reserved   : 1;
    uint32_t page_size  : 1;
    uint32_t global     : 1;
    uint32_t ignored    : 3;
    uint32_t address    : 20;
} PDE;

typedef struct 
{
    uint32_t present    : 1;
    uint32_t rw         : 1;
    uint32_t user       : 1;
    uint32_t pwt        : 1;
    uint32_t pcd        : 1;
    uint32_t accessed   : 1;
    uint32_t dirty      : 1;
    uint32_t pat        : 1;
    uint32_t global     : 1;
    uint32_t ignored    : 3;
    uint32_t address    : 20;
} PTE;

_Static_assert(sizeof(PDE) == 4, "PDE must be 4 bytes");
_Static_assert(sizeof(PTE) == 4, "PTE must be 4 bytes");

static inline PDE *get_pde(uint32_t virt)
{
    return &((PDE *)0xFFFFF000)[virt >> 22]; // Get the PDE for the virtual address
}


static inline PTE *get_pte(uint32_t virt)
{
    PDE *pde = get_pde(virt);
    if (!pde->present) 
        return NULL; // Page directory entry not present
    
    PTE *pt = (PTE *)(0xFFC00000 + ((virt >> 22) * 0x1000)); // Get the page table address
    return &pt[(virt >> 12) & 0x3FF]; // Get the PTE for the virtual address
}

// Initialize the virtual memory manager
void vmm_init() 
{
    terminal_print_string("VMM initialized\r\n");
}

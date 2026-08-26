/*
 * vmm.c
 * Created by Matheus Leme da Silva
 * */
#include <io.h>
#include <terminal.h>
#include <types.h>
#include <pmm.h>

// https://wiki.osdev.org/X86_Paging

// PDE Bits
#define PDE_PRESENT   (1 << 0)
#define PDE_RW        (1 << 1)
#define PDE_USER      (1 << 2)
#define PDE_PWT       (1 << 3)
#define PDE_PCD       (1 << 4)
#define PDE_ACCESSED  (1 << 5)
#define PDE_RESERVED  (1 << 6)
#define PDE_PAGE_SIZE (1 << 7)
#define PDE_GLOBAL    (1 << 8)

// PTE Bits
#define PTE_PRESENT   (1 << 0)
#define PTE_RW        (1 << 1)
#define PTE_USER      (1 << 2)
#define PTE_PWT       (1 << 3)
#define PTE_PCD       (1 << 4)
#define PTE_ACCESSED  (1 << 5)
#define PTE_DIRTY     (1 << 6)
#define PTE_PAT       (1 << 7)
#define PTE_GLOBAL    (1 << 8)

// invlpg
static inline void invlpg(uint32_t addr)
{
    __asm__ volatile("invlpg (%0)" ::"r"(addr) : "memory");
}

// Return the page directory entry for a given virtual address
static inline uint32_t get_pde_index(uint32_t virt)
{
    // According to OSDev wiki:
    // "the most significant 10 bits (bits 22-31) specify the index of the page directory entry"
    return virt >> 22; // Get the PDE index from the virtual address
}

// Return the page table entry for a given virtual address
static inline uint32_t get_pte_index(uint32_t virt)
{
    // According to OSDev wiki:
    // "the next 10 bits (bits 12-21) specify the index of the page table entry"
    return (virt >> 12) & 0x3FF;
}

// Return the page directory entry for a given virtual address
static inline uint32_t *get_pde(uint32_t virt)
{
    return &((uint32_t *)0xFFFFF000)[get_pde_index(virt)]; // Get the PDE for the virtual address
}

// Return the page table
static inline uint32_t *get_pt(uint32_t virt)
{
    uint32_t *pde = get_pde(virt);
    if (!(*pde & PDE_PRESENT)) 
        return NULL; // Page directory entry not present
    
    return (uint32_t *)(0xFFC00000 + (get_pde_index(virt) * 0x1000)); // Get the page table address
}

// Return the page table entry for a given virtual address
static inline uint32_t *get_pte(uint32_t virt)
{
    uint32_t *pde = get_pde(virt);
    if (!(*pde & PDE_PRESENT)) 
        return NULL; // Page directory entry not present
    
    uint32_t *pt = get_pt(virt);
    return &pt[get_pte_index(virt)]; // Get the PTE for the virtual address
}

// Map a virtual address to a physical address
// Return !0 if an error occours
int vmm_map(uint32_t virt, uint32_t phys, uint32_t flags)
{
    uint32_t *pde = get_pde(virt);
    if (!(*pde & PDE_PRESENT)) 
    {
        // Allocate a new page table
        uint32_t pt_phys = (uint32_t)pmm_alloc_page();
        if (!pt_phys)
            return -1; // Failed to allocate a new page table

        *pde = pt_phys | PDE_PRESENT | PDE_RW | PDE_USER; // Set the PDE to point to the new page table

        // Zero PT
        uint32_t *pt = get_pt(virt);
        for (int i = 0; i < 1024; i++) 
            pt[i] = 0; // Clear the PTE
    }

    uint32_t *pte = get_pte(virt);
    if (pte) 
        *pte = phys | flags; // Set the PTE to point to the physical address

    invlpg(virt); // Invalidate the TLB entry for the virtual address
    return 0;
}

// Unmap a virtual address
// Return !0 if an error occours
int vmm_unmap(uint32_t virt)
{
    uint32_t *pte = get_pte(virt);
    if (!pte || !(*pte & PTE_PRESENT))
        return -1; // PTE not present

    *pte = 0; // Clear the PTE
    invlpg(virt); // Invalidate the TLB entry for the virtual address
    return 0;
}

// Initialize the virtual memory manager
void vmm_init() 
{
    terminal_print_string("VMM initialized\r\n");
}

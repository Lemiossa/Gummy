/*
 * vmm.c
 * Created by Matheus Leme da Silva
 * */
#include <io.h>
#include <terminal.h>
#include <types.h>
#include <pmm.h>
#include <vmm.h>

// https://wiki.osdev.org/X86_Paging

uint32_t kernel_cr3 = 0;

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
    if (!(*pde & VMM_FLAGS_PRESENT)) 
        return NULL; // Page directory entry not present
    
    return (uint32_t *)(0xFFC00000 + (get_pde_index(virt) * 0x1000)); // Get the page table address
}

// Return the page table entry for a given virtual address
static inline uint32_t *get_pte(uint32_t virt)
{
    uint32_t *pde = get_pde(virt);
    if (!(*pde & VMM_FLAGS_PRESENT)) 
        return NULL; // Page directory entry not present
    
    uint32_t *pt = get_pt(virt);
    return &pt[get_pte_index(virt)]; // Get the PTE for the virtual address
}

// Map a virtual address to a physical address
// Return !0 if an error occours
int vmm_map(void *virt, void *phys, uint32_t flags)
{
    uint32_t *pde = get_pde((uint32_t)virt);
    if (!(*pde & VMM_FLAGS_PRESENT)) 
    {
        // Allocate a new page table
        uint32_t pt_phys = (uint32_t)pmm_alloc_page();
        if (!pt_phys)
            return -1; // Failed to allocate a new page table

        *pde = pt_phys | flags; // Set the PDE to point to the new page table

        // Zero PT
        uint32_t *pt = get_pt((uint32_t)virt);
        for (int i = 0; i < 1024; i++) 
            pt[i] = 0; // Clear the PTE
    }

    uint32_t *pte = get_pte((uint32_t)virt);
    if (pte) 
        *pte = (uint32_t)phys | flags; // Set the PTE to point to the physical address

    invlpg((uint32_t)virt); // Invalidate the TLB entry for the virtual address
    return 0;
}

// Unmap a virtual address
// Return !0 if an error occours
int vmm_unmap(void *virt)
{
    uint32_t *pte = get_pte((uint32_t)virt);
    if (!pte || !(*pte & VMM_FLAGS_PRESENT))
        return -1; // PTE not present

    *pte = 0; // Clear the PTE
    invlpg((uint32_t)virt); // Invalidate the TLB entry for the virtual address
    return 0;
}

// Alloc n pages in specific region
// Return NULL if an error occours
// Map all the pages and return the first virtual address
void *vmm_alloc_pages(uint32_t n, void *region_start, void *region_end, uint32_t flags)
{
    if (n == 0)
        return NULL; // Invalid number of pages

    uint32_t start_page = ALIGN_UP((uint32_t)region_start, PAGE_SIZE);
    uint32_t end_page = ALIGN_DOWN((uint32_t)region_end, PAGE_SIZE); 

    uint32_t consecutive_pages = 0;
    uint32_t first_page = 0;

    for (uint32_t page = start_page; page < end_page; page += PAGE_SIZE)
    {
        uint32_t *pte = get_pte(page);

        if (!pte || !(*pte & VMM_FLAGS_PRESENT)) // Free page found
        {
            if (consecutive_pages == 0) 
                first_page = page;

            consecutive_pages++;
        }
        else
            consecutive_pages = 0; // Reset if a used page is found

        if (consecutive_pages == n)  
            goto found;
    }

    return NULL; // No suitable region found

found:
    for (uint32_t page = first_page; page < first_page + n * PAGE_SIZE; page += PAGE_SIZE)
    {
        void *phys = pmm_alloc_page();
        if (!phys) 
        {
            // Rollback if allocation fails
            for (uint32_t rollback_page = first_page; rollback_page < page; rollback_page += PAGE_SIZE)
                vmm_unmap((void *)rollback_page);
            return NULL;
        }

        if (vmm_map((void *)page, phys, flags) != 0) 
        {
            // Rollback if mapping fails
            pmm_free_page(phys);
            for (uint32_t rollback_page = first_page; rollback_page < page; rollback_page += PAGE_SIZE)
                vmm_unmap((void *)rollback_page);
            return NULL;
        }
    }

    return (void *)first_page; // Return the first virtual address of the allocated pages
}

// free n pages starting from a virtual address
// return !0 if an error occours
int vmm_free_pages(void *virt, uint32_t n)
{
    if (n == 0)
        return -1;

    uint32_t start = (uint32_t)virt;

    for (uint32_t i = 0; i < n; i++)
    {
        uint32_t page = start + i * PAGE_SIZE;

        uint32_t *pte = get_pte(page);
        if (!pte || !(*pte & VMM_FLAGS_PRESENT))
            return -1;

        void *phys = (void *)(*pte & 0xFFFFF000);

        *pte = 0;
        invlpg(page);

        pmm_free_page(phys);
    }

    return 0;
}

// Initialize the virtual memory manager
void vmm_init(void) 
{
    kernel_cr3 = read_cr3();

    // Unmap the first MiB
    uint32_t *pde = get_pde(0);
    *pde = 0;

    for (uint32_t addr = 0; addr < 0x100000; addr += PAGE_SIZE)
        invlpg(addr);

    terminal_print_string("initialized\r\n");
}

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
static inline void invlpg(uintptr_t addr)
{
    __asm__ volatile("invlpg (%0)" ::"r"(addr) : "memory");
}

// Return the page directory entry for a given virtual address
static inline uint32_t get_pde_index(uintptr_t virt)
{
    // According to OSDev wiki:
    // "the most significant 10 bits (bits 22-31) specify the index of the page directory entry"
    return virt >> 22; // Get the PDE index from the virtual address
}

// Return the page table entry for a given virtual address
static inline uint32_t get_pte_index(uintptr_t virt)
{
    // According to OSDev wiki:
    // "the next 10 bits (bits 12-21) specify the index of the page table entry"
    return (virt >> 12) & 0x3FF;
}

// Return the page directory entry for a given virtual address
static inline uint32_t *get_pde(uintptr_t virt)
{
    return &((uint32_t *)0xFFFFF000)[get_pde_index(virt)]; // Get the PDE for the virtual address
}

// Return the page table
static inline uint32_t *get_pt(uintptr_t virt)
{
    uint32_t *pde = get_pde(virt);
    if (!(*pde & VMM_FLAGS_PRESENT)) 
        return NULL; // Page directory entry not present
    
    return (uint32_t *)(0xFFC00000 + (get_pde_index(virt) * 0x1000)); // Get the page table address
}

// Return the page table entry for a given virtual address
static inline uint32_t *get_pte(uintptr_t virt)
{
    uint32_t *pde = get_pde(virt);
    if (!(*pde & VMM_FLAGS_PRESENT)) 
        return NULL; // Page directory entry not present
    
    uint32_t *pt = get_pt(virt);
    return &pt[get_pte_index(virt)]; // Get the PTE for the virtual address
}

// Get the physical address of an address
static inline uint32_t get_physical_address(uintptr_t virt)
{
    uint32_t *pte = get_pte(virt);
    if (!pte || !(*pte & VMM_FLAGS_PRESENT)) 
        return 0; // Page table entry not present
    
    return (*pte & 0xFFFFF000) | (virt & 0xFFF); // Get the physical address
}


// Map a virtual address to a physical address
// Return !0 if an error occours
int vmm_map(uintptr_t virt, uintptr_t phys, uint32_t flags)
{
    uint32_t *pde = get_pde(virt);
    if (!(*pde & VMM_FLAGS_PRESENT)) 
    {
        // Allocate a new page table
        uintptr_t pt_phys = pmm_alloc_page();
        if (!pt_phys)
            return -1; // Failed to allocate a new page table

        *pde = pt_phys | flags | VMM_FLAGS_PRESENT; // Set the PDE to point to the new page table

        // Zero PT
        uint32_t *pt = get_pt(virt);
        for (int i = 0; i < 1024; i++) 
            pt[i] = 0; // Clear the PTE
    }

    uint32_t *pte = get_pte(virt);
    if (pte) 
        *pte = phys | flags | VMM_FLAGS_PRESENT; // Set the PTE to point to the physical address

    invlpg(virt); // Invalidate the TLB entry for the virtual address
    return 0;
}

// Unmap a virtual address
// Return !0 if an error occours
int vmm_unmap(uintptr_t virt)
{
    uint32_t *pte = get_pte(virt);
    if (!pte || !(*pte & VMM_FLAGS_PRESENT))
        return -1; // PTE not present

    *pte = 0; // Clear the PTE
    invlpg(virt); // Invalidate the TLB entry for the virtual address
    return 0;
}

// Alloc n pages in specific region
// Return NULL if an error occours
// Map all the pages and return the first virtual address
void *vmm_alloc_pages_region(uint32_t n, uint32_t flags, uintptr_t region_start)
{
    if (n == 0)
        return NULL; // Invalid number of pages
    
    region_start = ALIGN_UP(region_start, PAGE_SIZE);

    uint32_t consecutive_pages = 0;
    uintptr_t first_page = 0;

    for (uintptr_t page = region_start; page < 0xFFC00000; page += PAGE_SIZE)
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
    for (uintptr_t page = first_page; page < first_page + n * PAGE_SIZE; page += PAGE_SIZE)
    {
        uintptr_t phys = pmm_alloc_page();
        if (phys == 0) 
        {
            // Rollback if allocation fails
            for (uintptr_t rollback_page = first_page; rollback_page < page; rollback_page += PAGE_SIZE)
                vmm_unmap(rollback_page);
            return NULL;
        }

        if (vmm_map(page, phys, flags) != 0)
        {
            // Rollback if mapping fails
            pmm_free_page(phys);
            for (uintptr_t rollback_page = first_page; rollback_page < page; rollback_page += PAGE_SIZE)
                vmm_unmap(rollback_page);
            return NULL;
        }
    }

    return (void *)first_page; // Return the first virtual address of the allocated pages
}

// Alloc n pages in the entire virtual address space
// Return NULL if an error occours
void *vmm_alloc_pages(uint32_t n, uint32_t flags)
{
    return vmm_alloc_pages_region(n, flags, 0x00000000); // Search the entire virtual address space
}

// free n pages starting from a virtual address
// return !0 if an error occours
int vmm_free_pages(uint32_t n, void *virt)
{
    if (n == 0)
        return -1;

    uintptr_t start = (uintptr_t)virt;

    for (uint32_t i = 0; i < n; i++)
    {
        uint32_t page = (uint32_t)start + i * PAGE_SIZE;

        uint32_t *pte = get_pte(page);
        if (!pte || !(*pte & VMM_FLAGS_PRESENT))
            return -1;

        uintptr_t phys = (uintptr_t)(*pte & 0xFFFFF000);

        *pte = 0;
        invlpg(page);

        pmm_free_page(phys);
    }

    return 0;
}

// Clone the current page directory and return the new CR3 value
uintptr_t vmm_clone(void)
{
    uint32_t new_cr3 = (uint32_t)vmm_alloc_pages(1, VMM_FLAGS_PRESENT | VMM_FLAGS_RW); // Allocate a new page directory
    if (!new_cr3)
        return 0; // Failed to allocate a new page directory
    uint32_t new_cr3_phys = get_physical_address(new_cr3);

    // Copy the kernel space mappings (higher half)
    uint32_t *new_pd = (uint32_t *)new_cr3;
    uint32_t *old_pd = (uint32_t *)0xFFFFF000;
    for (int i = 0; i < 1024; i++) 
        new_pd[i] = 0; 

    for (int i = 768; i < 1024; i++)
        new_pd[i] = old_pd[i];

    new_pd[1023] = new_cr3_phys | VMM_FLAGS_PRESENT | VMM_FLAGS_RW; 

    vmm_unmap((uintptr_t)new_cr3);

    return new_cr3_phys;
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
}

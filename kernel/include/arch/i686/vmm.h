#ifndef VMM_H
#define VMM_H
#include <types.h>

// Map a virtual address to a physical address
// Return !0 if an error occours
int vmm_map(uint32_t virt, uint32_t phys, uint32_t flags);
// Unmap a virtual address
// Return !0 if an error occours
int vmm_unmap(uint32_t virt);
// Initialize the virtual memory manager
void vmm_init();

#endif // VMM_H

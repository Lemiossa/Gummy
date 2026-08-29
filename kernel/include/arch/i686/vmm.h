#ifndef VMM_H
#define VMM_H
#include <types.h>

// Flags Bits
#define VMM_FLAGS_PRESENT   (1 << 0)
#define VMM_FLAGS_RW        (1 << 1)
#define VMM_FLAGS_USER      (1 << 2)
#define VMM_FLAGS_PWT       (1 << 3)
#define VMM_FLAGS_PCD       (1 << 4)
#define VMM_FLAGS_ACCESSED  (1 << 5)
#define VMM_FLAGS_RESERVED  (1 << 6)
#define VMM_FLAGS_PAGE_SIZE (1 << 7)
#define VMM_FLAGS_GLOBAL    (1 << 8)

// Map a virtual address to a physical address
// Return !0 if an error occours
int vmm_map(void *virt, void *phys, uint32_t flags);
// Unmap a virtual address
// Return !0 if an error occours
int vmm_unmap(void *virt);
// Initialize the virtual memory manager
void vmm_init();

#endif // VMM_H

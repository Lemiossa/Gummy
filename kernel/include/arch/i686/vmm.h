#ifndef VMM_H
#define VMM_H
#include <types.h>

// Bits das flags
#define VMM_FLAGS_PRESENT (1 << 0)
#define VMM_FLAGS_RW (1 << 1)
#define VMM_FLAGS_USER (1 << 2)
#define VMM_FLAGS_PWT (1 << 3)
#define VMM_FLAGS_PCD (1 << 4)
#define VMM_FLAGS_ACCESSED (1 << 5)
#define VMM_FLAGS_RESERVED (1 << 6)
#define VMM_FLAGS_PAGE_SIZE (1 << 7)
#define VMM_FLAGS_GLOBAL (1 << 8)

extern uintptr_t kernel_cr3;

// Mapeia um endereco virtual para um endereco fisico
// Retorna !0 se ocorrer um erro
int vmm_map(uintptr_t virt, uintptr_t phys, uint32_t flags);
// Desmapeia um endereco virtual
// Retorna !0 se ocorrer um erro
int vmm_unmap(uintptr_t virt);
// Aloca n paginas em uma regiao especifica
// Retorna NULL se ocorrer um erro
// Mapeia todas as paginas e retorna o primeiro endereco virtual
void *vmm_alloc_pages_region(uint32_t n, uint32_t flags, uintptr_t region_start,
							 uintptr_t region_end);
// Aloca n paginas em todo o espaco de enderecos virtuais
// Retorna NULL se ocorrer um erro
void *vmm_alloc_pages(uint32_t n, uint32_t flags);
// Libera n paginas a partir de um endereco virtual
// Retorna !0 se ocorrer um erro
int vmm_free_pages(uint32_t n, void *virt);
// Clona o diretorio de paginas atual e retorna o novo valor de CR3
uintptr_t vmm_clone(void);
// Mapeia um endereco virtual para um endereco fisico num address space
// específico Retorna !0 se ocorrer um erro
int vmm_map_in(uintptr_t cr3, uintptr_t virt, uintptr_t phys, uint32_t flags);
// Desmapeia um endereco virtual em um address space específico
// Retorna !0 se ocorrer um erro
int vmm_unmap_in(uintptr_t cr3, uintptr_t virt);
// Aloca n paginas em uma regiao especifica num address space especifico
// Retorna NULL se ocorrer um erro
// Mapeia todas as paginas e retorna o primeiro endereco virtual
void *vmm_alloc_pages_region_in(uintptr_t cr3, uint32_t n, uint32_t flags,
								uintptr_t region_start, uintptr_t region_end);
// Aloca n paginas em todo o espaco de enderecos virtuais num address space
// especifico Retorna NULL se ocorrer um erro
void *vmm_alloc_pages_in(uintptr_t cr3, uint32_t n, uint32_t flags);
// Libera n paginas a partir de um endereco virtual num address space especifico
// Retorna !0 se ocorrer um erro
int vmm_free_pages_in(uintptr_t cr3, uint32_t n, void *virt);
// Destroi tudo do PDE 0 a 767 num address space específico
// Nao libera o endereco fisico do diretorio de paginas
void vmm_destroy(uintptr_t cr3);
// Inicializa o gerenciador de memoria virtual
void vmm_init(void);

#endif // VMM_H

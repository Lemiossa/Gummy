/*
 * vmm.c
 * Criado por Matheus Leme da Silva
 * */
#include <debug.h>
#include <io.h>
#include <pmm.h>
#include <string.h>
#include <terminal.h>
#include <types.h>
#include <vmm.h>

// https://wiki.osdev.org/X86_Paging

uintptr_t kernel_cr3 = 0;

// invlpg
static inline void invlpg(uintptr_t addr) {
	__asm__ volatile("invlpg (%0)" ::"r"(addr) : "memory");
}

// Retorna a entrada do diretorio de paginas para um endereco virtual
static inline uint32_t get_pde_index(uintptr_t virt) {
	// De acordo com a wiki do OSDev:
	// "os 10 bits mais significativos (bits 22-31) especificam o indice da
	// entrada do diretorio de paginas"
	return virt >> 22; // Obtem o indice da PDE a partir do endereco virtual
}

// Retorna a entrada da tabela de paginas para um endereco virtual
static inline uint32_t get_pte_index(uintptr_t virt) {
	// De acordo com a wiki do OSDev:
	// "os 10 bits seguintes (bits 12-21) especificam o indice da entrada da
	// tabela de paginas"
	return (virt >> 12) & 0x3FF;
}

// Retorna a entrada do diretorio de paginas para um endereco virtual
static inline uint32_t *get_pde(uintptr_t virt) {
	return &((uint32_t *)0xFFFFF000)[get_pde_index(
		virt)]; // Obtem a PDE para o endereco virtual
}

// Retorna a tabela de paginas
static inline uint32_t *get_pt(uintptr_t virt) {
	uint32_t *pde = get_pde(virt);
	if (!(*pde & VMM_FLAGS_PRESENT))
		return NULL; // Entrada do diretorio de paginas nao presente

	return (uint32_t *)(0xFFC00000 +
						(get_pde_index(virt) *
						 0x1000)); // Obtem o endereco da tabela de paginas
}

// Retorna a entrada da tabela de paginas para um endereco virtual
static inline uint32_t *get_pte(uintptr_t virt) {
	uint32_t *pde = get_pde(virt);
	if (!(*pde & VMM_FLAGS_PRESENT))
		return NULL; // Entrada do diretorio de paginas nao presente

	uint32_t *pt = get_pt(virt);
	return &pt[get_pte_index(virt)]; // Obtem a PTE para o endereco virtual
}

// Obtem o endereco fisico de um endereco
static inline uint32_t get_physical_address(uintptr_t virt) {
	uint32_t *pte = get_pte(virt);
	if (!pte || !(*pte & VMM_FLAGS_PRESENT))
		return 0; // Entrada da tabela de paginas nao presente

	return (*pte & 0xFFFFF000) | (virt & 0xFFF); // Obtem o endereco fisico
}

// Mapeia um endereco virtual para um endereco fisico
// Retorna !0 se ocorrer um erro
int vmm_map(uintptr_t virt, uintptr_t phys, uint32_t flags) {
	uint32_t *pde = get_pde(virt);
	if (!(*pde & VMM_FLAGS_PRESENT)) {
		debug_log_string("VMM", "Criando uma nova tabela de paginas.\r\n");

		// Aloca uma nova tabela de paginas
		uintptr_t pt_phys = pmm_alloc_page();
		if (!pt_phys)
			return -1; // Falha ao alocar uma nova tabela de paginas

		*pde = pt_phys | flags |
			   VMM_FLAGS_PRESENT; // Define a PDE para apontar para a nova
								  // tabela de paginas

		// Zera a PT
		uint32_t *pt = get_pt(virt);
		for (int i = 0; i < 1024; i++)
			pt[i] = 0; // Limpa a PTE
	}

	uint32_t *pte = get_pte(virt);
	if (pte)
		*pte = phys | flags | VMM_FLAGS_PRESENT; // Define a PTE para apontar
												 // para o endereco fisico

	invlpg(virt); // Invalida a entrada da TLB para o endereco virtual
	return 0;
}

// Desmapeia um endereco virtual
// Retorna !0 se ocorrer um erro
int vmm_unmap(uintptr_t virt) {
	uint32_t *pte = get_pte(virt);
	if (!pte || !(*pte & VMM_FLAGS_PRESENT))
		return -1; // PTE nao presente

	*pte = 0;	  // Limpa a PTE
	invlpg(virt); // Invalida a entrada da TLB para o endereco virtual

	// Verificar se podemos liberar a PT
	uint32_t *pt = get_pt(virt);
	int present = 0;
	for (int i = 0; i < 1024; i++) {
		if (pt[i] & VMM_FLAGS_PRESENT)
			present++;
	}

	if (present == 0 && virt < 0xC0000000) {
		uint32_t *pde = get_pde(virt);
		uintptr_t pt_phys = (uintptr_t)*pde & 0xFFFFF000;
		pmm_free_page(pt_phys);

		*pde = 0;
	}

	return 0;
}

// Aloca n paginas em uma regiao especifica
// Retorna NULL se ocorrer um erro
// Mapeia todas as paginas e retorna o primeiro endereco virtual
void *vmm_alloc_pages_region(uint32_t n, uint32_t flags, uintptr_t region_start,
							 uintptr_t region_end) {
	if (n == 0)
		return NULL; // Numero de paginas invalido

	region_start = ALIGN_UP(region_start, PAGE_SIZE);
	region_end = ALIGN_DOWN(region_end, PAGE_SIZE);

	if (region_end < region_start + n * PAGE_SIZE)
		return NULL;

	uint32_t consecutive_pages = 0;
	uintptr_t first_page = 0;

	for (uintptr_t page = region_start; page < region_end; page += PAGE_SIZE) {
		uint32_t *pte = get_pte(page);

		if (!pte || !(*pte & VMM_FLAGS_PRESENT)) // Pagina livre encontrada
		{
			if (consecutive_pages == 0)
				first_page = page;

			consecutive_pages++;
		} else
			consecutive_pages = 0; // Zera se uma pagina usada for encontrada

		if (consecutive_pages == n)
			goto found;
	}

	debug_log_string("VMM", "Nenhuma regiao adequada encontrada.\r\n");
	return NULL; // Nenhuma regiao adequada encontrada

found:
	for (uintptr_t page = first_page; page < first_page + n * PAGE_SIZE;
		 page += PAGE_SIZE) {
		uintptr_t phys = pmm_alloc_page();
		if (phys == 0) {
			debug_log_string("VMM", "Falha ao alocar pagina fisica.\r\n");
			// Desfaz se a alocacao falhar
			for (uintptr_t rollback_page = first_page; rollback_page < page;
				 rollback_page += PAGE_SIZE)
				vmm_unmap(rollback_page);
			return NULL;
		}

		if (vmm_map(page, phys, flags) != 0) {
			debug_log_string("VMM", "Falha ao mapear phys -> virt.\r\n");
			// Desfaz se o mapeamento falhar
			pmm_free_page(phys);
			for (uintptr_t rollback_page = first_page; rollback_page < page;
				 rollback_page += PAGE_SIZE)
				vmm_unmap(rollback_page);
			return NULL;
		}
	}

	debug_log_string("VMM", "Alocadas 0x");
	debug_log_hex32(n);
	debug_print_string(" paginas.\r\n");

	return (void *)
		first_page; // Retorna o primeiro endereco virtual das paginas alocadas
}

// Aloca n paginas em todo o espaco de enderecos virtuais
// Retorna NULL se ocorrer um erro
void *vmm_alloc_pages(uint32_t n, uint32_t flags) {
	return vmm_alloc_pages_region(
		n, flags, 0x00001000,
		0xFFC00000); // Pesquisa todo o espaco de enderecos virtuais
}

// Libera n paginas a partir de um endereco virtual
// Retorna !0 se ocorrer um erro
int vmm_free_pages(uint32_t n, void *virt) {
	if (n == 0)
		return -1;

	uintptr_t start = (uintptr_t)virt;

	for (uint32_t i = 0; i < n; i++) {
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

// Clona o diretorio de paginas atual e retorna o novo valor de CR3
uintptr_t vmm_clone(void) {
	uint32_t new_cr3 = (uint32_t)vmm_alloc_pages(
		1,
		VMM_FLAGS_PRESENT | VMM_FLAGS_RW); // Aloca um novo diretorio de paginas
	if (!new_cr3)
		return 0; // Falha ao alocar um novo diretorio de paginas
	uint32_t new_cr3_phys = get_physical_address(new_cr3);

	// Copia os mapeamentos do espaco do kernel (metade superior)
	uint32_t *new_pd = (uint32_t *)new_cr3;
	uint32_t *old_pd = (uint32_t *)0xFFFFF000;
	memset(new_pd, 0, 1024 * sizeof(uint32_t));

	for (int i = 768; i < 1024; i++)
		new_pd[i] = old_pd[i];

	new_pd[1023] = new_cr3_phys | VMM_FLAGS_PRESENT | VMM_FLAGS_RW;

	vmm_unmap((uintptr_t)new_cr3);

	return new_cr3_phys;
}

// Mapeia um endereco virtual para um endereco fisico num address space
// específico Retorna !0 se ocorrer um erro
int vmm_map_in(uintptr_t cr3, uintptr_t virt, uintptr_t phys, uint32_t flags) {
	uintptr_t cpu_flags = read_flags();
	disable_interrupts();
	uintptr_t old_cr3 = read_cr3();
	write_cr3(cr3);

	if (vmm_map(virt, phys, flags)) {
		if (old_cr3 != cr3)
			write_cr3(old_cr3);
		write_flags(cpu_flags);
		return 1;
	}

	if (old_cr3 != cr3)
		write_cr3(old_cr3);
	write_flags(cpu_flags);
	return 0;
}

// Desmapeia um endereco virtual em um address space específico
// Retorna !0 se ocorrer um erro
int vmm_unmap_in(uintptr_t cr3, uintptr_t virt) {
	uintptr_t cpu_flags = read_flags();
	disable_interrupts();
	uintptr_t old_cr3 = read_cr3();
	write_cr3(cr3);

	if (vmm_unmap(virt)) {
		if (old_cr3 != cr3)
			write_cr3(old_cr3);
		write_flags(cpu_flags);
		return 1;
	}

	if (old_cr3 != cr3)
		write_cr3(old_cr3);
	write_flags(cpu_flags);
	return 0;
}

// Destroi tudo do PDE 0 a 767 num address space específico
// Nao libera o endereco fisico do diretorio de paginas
void vmm_destroy(uintptr_t cr3) {
	if (!cr3 || cr3 == read_cr3())
		return;

	uintptr_t cpu_flags = read_flags();
	disable_interrupts();
	uintptr_t old_cr3 = read_cr3();
	write_cr3(cr3);

	for (uint32_t i = 0; i < 768; i++) {
		uintptr_t base = i * 0x400000;
		uint32_t *pde = get_pde(base);
		if (!(*pde & VMM_FLAGS_PRESENT))
			continue;
		uint32_t *pt = get_pt(base);
		uintptr_t pt_phys = *pde & 0xFFFFF000;
		for (uint32_t j = 0; j < 1024; j++) {
			if (pt[j] & VMM_FLAGS_PRESENT) {
				pmm_free_page(pt[j] & 0xFFFFF000);
				pt[j] = 0;
			}
		}
		pmm_free_page(pt_phys);
		*pde = 0;
	}

	write_cr3(old_cr3);
	write_flags(cpu_flags);
}

// Aloca n paginas em uma regiao especifica num address space especifico
// Retorna NULL se ocorrer um erro
// Mapeia todas as paginas e retorna o primeiro endereco virtual
void *vmm_alloc_pages_region_in(uintptr_t cr3, uint32_t n, uint32_t flags,
								uintptr_t region_start, uintptr_t region_end) {
	uintptr_t cpu_flags = read_flags();
	disable_interrupts();
	uintptr_t old_cr3 = read_cr3();
	write_cr3(cr3);

	void *addr = vmm_alloc_pages_region(n, flags, region_start, region_end);
	if (!addr) {
		if (old_cr3 != cr3)
			write_cr3(old_cr3);
		write_flags(cpu_flags);
		return NULL;
	}

	if (old_cr3 != cr3)
		write_cr3(old_cr3);
	write_flags(cpu_flags);
	return addr;
}

// Aloca n paginas em todo o espaco de enderecos virtuais num address space
// especifico Retorna NULL se ocorrer um erro
void *vmm_alloc_pages_in(uintptr_t cr3, uint32_t n, uint32_t flags) {
	uintptr_t cpu_flags = read_flags();
	disable_interrupts();
	uintptr_t old_cr3 = read_cr3();
	write_cr3(cr3);

	void *addr = vmm_alloc_pages(n, flags);
	if (!addr) {
		if (old_cr3 != cr3)
			write_cr3(old_cr3);
		write_flags(cpu_flags);
		return NULL;
	}

	if (old_cr3 != cr3)
		write_cr3(old_cr3);
	write_flags(cpu_flags);
	return addr;
}

// Libera n paginas a partir de um endereco virtual num address space especifico
// Retorna !0 se ocorrer um erro
int vmm_free_pages_in(uintptr_t cr3, uint32_t n, void *virt) {
	uintptr_t cpu_flags = read_flags();
	disable_interrupts();
	uintptr_t old_cr3 = read_cr3();
	write_cr3(cr3);

	if (vmm_free_pages(n, virt)) {
		if (old_cr3 != cr3)
			write_cr3(old_cr3);
		write_flags(cpu_flags);
		return 1;
	}

	if (old_cr3 != cr3)
		write_cr3(old_cr3);
	write_flags(cpu_flags);
	return 0;
}

// Inicializa o gerenciador de memoria virtual
void vmm_init(void) {
	kernel_cr3 = read_cr3();

	// Desmapeia o primeiro MiB
	uint32_t *pde = get_pde(0);
	*pde = 0;

	debug_log_string("VMM", "CR3 do kernel: 0x");
	debug_log_hex32(kernel_cr3);
	debug_print_string("\r\n");

	for (uint32_t addr = 0; addr < 0x100000; addr += PAGE_SIZE)
		invlpg(addr);
}

#ifndef PMM_H
#define PMM_H
#include <types.h>

#define PAGE_SIZE 4096

// Aloca uma pagina de memoria fisica
uintptr_t pmm_alloc_page(void);
// Libera uma pagina de memoria fisica
void pmm_free_page(uintptr_t page);
// Inicializa o gerenciador de memoria fisica
void pmm_init(void);

#endif // PMM_H

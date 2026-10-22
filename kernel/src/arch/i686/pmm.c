/*
 * pmm.c
 * Criado por Matheus Leme da Silva
 * */
#include <types.h>
#include <terminal.h>
#include <bitmap.h>
#include <e820.h>
#include <pmm.h>
#include <debug.h>
#include <string.h>

extern uint8_t *__kernel_start; // Inicio do kernel na memoria
extern uint8_t *__kernel_end; // Fim do kernel na memoria
#define BITMAP_LOCATION ((uint32_t)&__kernel_end) // Localizacao do bitmap na memoria

uint8_t *bitmap = NULL; // Ponteiro para o bitmap
uint32_t bitmap_bits = 0; // tamanho do bitmap em bits
uint32_t bitmap_bytes = 0; // tamanho do bitmap em bytes
uint32_t phys_top = 0;
uint32_t usable_mem = 0;

// Aloca uma pagina de memoria fisica
uintptr_t pmm_alloc_page(void)
{
    if (bitmap == NULL || bitmap_bits == 0)
    {
        debug_log_string("PMM", "Tentativa de alocar uma pagina fisica sem inicializar o PMM.\r\n");
        return 0;
    }

    uint32_t page = bitmap_find_free_bit(bitmap, bitmap_bits);
    if (page == 0)
    {
        debug_log_string("PMM", "Nao ha paginas livres disponiveis.\r\n");
        return 0; // Nao ha paginas livres disponiveis
    }

    bitmap_set_bit(bitmap, page); // Marca a pagina como usada

    debug_log_string("PMM", "Pagina alocada 0x");
    debug_log_hex32(page);
    debug_print_string(".\r\n");

    return (uintptr_t)(page * PAGE_SIZE);
}

// Libera uma pagina de memoria fisica
void pmm_free_page(uintptr_t page)
{
    if (bitmap == NULL || bitmap_bits == 0)
    {
        debug_log_string("PMM", "Tentativa de liberar uma pagina fisica sem inicializar o PMM.\r\n");
        return;
    }

    bitmap_clear_bit(bitmap, (page / PAGE_SIZE));
}

// Inicializa o gerenciador de memoria fisica
void pmm_init(void)
{
    bitmap = (uint8_t *)BITMAP_LOCATION;

    for (int i = 0; i < E820_entry_count; i++)
    {
        e820_entry_t entry = E820_entries[i];
        if (entry.base >= 0xFFFFFFFF) // Ignora entradas acima de 4GB
            continue;

        uint32_t end = MIN(entry.base + entry.length, 0xFFFFFFFF);
        phys_top = (uint32_t)MAX(phys_top, end);

        if (entry.type == 1) // Memoria utilizavel
            usable_mem += end - entry.base;
    }

    bitmap_bits = phys_top / PAGE_SIZE;
    bitmap_bytes = ALIGN_UP(bitmap_bits, 8) / 8;

    memset(bitmap, 0xFF, bitmap_bytes);

    for (int i = 0; i < E820_entry_count; i++)
    {
        e820_entry_t *entry = &E820_entries[i];

        if (entry->type != 1)
            continue;

        if (entry->base >= 0xFFFFFFFF) // Ignora entradas acima de 4GB
            continue;

        uint32_t end = MIN(entry->base + entry->length, 0xFFFFFFFF);
        uint32_t start_page = ALIGN_UP(entry->base, PAGE_SIZE) / PAGE_SIZE;
        uint32_t end_page = ALIGN_DOWN(end, PAGE_SIZE) / PAGE_SIZE;

        for (uint32_t page = start_page; page < end_page; page++)
            bitmap_clear_bit(bitmap, page); // Marca como livre
    }

    // Marca a memoria do kernel como usada
    // NOTA: os simbolos do kernel sao enderecos virtuais da metade superior (0xC0xxxxxx).
    // O bitmap rastreia paginas *fisicas*, entao converte virt -> phys.
    uint32_t kstart_virt = (uint32_t)&__kernel_start;
    uint32_t kend_virt = (uint32_t)&__kernel_end + bitmap_bytes;
    uint32_t kernel_start_phys = kstart_virt - 0xC0000000;
    uint32_t kernel_end_phys = kend_virt - 0xC0000000;
    uint32_t kernel_start_page = ALIGN_DOWN(kernel_start_phys, PAGE_SIZE) / PAGE_SIZE;
    uint32_t kernel_end_page = ALIGN_UP(kernel_end_phys, PAGE_SIZE) / PAGE_SIZE;
    for (uint32_t page = kernel_start_page; page < kernel_end_page && page < bitmap_bits; page++)
        bitmap_set_bit(bitmap, page);

    // Marca a tabela E820 como usada
    // A tabela E820 fica sempre em < 0x10000
    // 64K / 4K = 16 paginas
    for (uint32_t page = 0; page < 16; page++)
        bitmap_set_bit(bitmap, page);
    
    debug_log_string("PMM", "Memoria utilizavel: 0x");
    debug_log_hex32(usable_mem);
    debug_print_string("\r\n");
}

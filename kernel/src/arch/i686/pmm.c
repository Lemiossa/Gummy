/*
 * pmm.c
 * Created by Matheus Leme da Silva
 * */
#include <types.h>
#include <terminal.h>
#include <bitmap.h>
#include <e820.h>
#include <pmm.h>
#include <debug.h>

extern uint8_t *__kernel_start; // Start of the kernel in memory
extern uint8_t *__kernel_end; // End of the kernel in memory
#define BITMAP_LOCATION ((uint32_t)&__kernel_end) // Location of the bitmap in memory

uint8_t *bitmap = NULL; // Pointer to the bitmap
uint32_t bitmap_bits = 0; // size of bitmap in bits
uint32_t bitmap_bytes = 0; // size of bitmap in bytes
uint32_t phys_top = 0;
uint32_t usable_mem = 0;

// Alloc a page of physical memory
uintptr_t pmm_alloc_page(void)
{
    if (bitmap == NULL || bitmap_bits == 0)
       return 0;

    uint32_t page = bitmap_find_free_bit(bitmap, bitmap_bits);
    if (page == 0)
        return 0; // No free pages available

    bitmap_set_bit(bitmap, page); // Mark the page as used
    return (uintptr_t)(page * PAGE_SIZE);
}

// Free a page of physical memory
void pmm_free_page(uintptr_t page)
{
    if (bitmap == NULL || bitmap_bits == 0)
        return;

    bitmap_clear_bit(bitmap, (page / PAGE_SIZE));
}

// Initialize the physical memory manager
void pmm_init(void)
{
    bitmap = (uint8_t *)BITMAP_LOCATION;

    for (int i = 0; i < E820_entry_count; i++)
    {
        e820_entry_t entry = E820_entries[i];
        if (entry.base >= 0xFFFFFFFF) // Skip entries above 4GB
            continue;

        uint32_t end = MIN(entry.base + entry.length, 0xFFFFFFFF);
        phys_top = (uint32_t)MAX(phys_top, end);

        if (entry.type == 1) // Usable memory
            usable_mem += end - entry.base;
    }

    bitmap_bits = phys_top / PAGE_SIZE;
    bitmap_bytes = ALIGN_UP(bitmap_bits, 8) / 8;

    for (uint32_t i = 0; i < bitmap_bytes; i++)
        bitmap[i] = 0xFF; // Mark all pages as used initially

    for (int i = 0; i < E820_entry_count; i++)
    {
        e820_entry_t *entry = &E820_entries[i];

        if (entry->type != 1)
            continue;

        if (entry->base >= 0xFFFFFFFF) // Skip entries above 4GB
            continue;

        uint32_t end = MIN(entry->base + entry->length, 0xFFFFFFFF);
        uint32_t start_page = ALIGN_UP(entry->base, PAGE_SIZE) / PAGE_SIZE;
        uint32_t end_page = ALIGN_DOWN(end, PAGE_SIZE) / PAGE_SIZE;

        for (uint32_t page = start_page; page < end_page; page++)
            bitmap_clear_bit(bitmap, page); // Mark as free
    }

    // Mark the kernel memory as used
    // NOTE: kernel symbols are higher-half virtual addresses (0xC0xxxxxx).
    // The bitmap tracks *physical* pages, so convert virt -> phys.
    uint32_t kstart_virt = (uint32_t)&__kernel_start;
    uint32_t kend_virt = (uint32_t)&__kernel_end + bitmap_bytes;
    uint32_t kernel_start_phys = kstart_virt - 0xC0000000;
    uint32_t kernel_end_phys = kend_virt - 0xC0000000;
    uint32_t kernel_start_page = ALIGN_DOWN(kernel_start_phys, PAGE_SIZE) / PAGE_SIZE;
    uint32_t kernel_end_page = ALIGN_UP(kernel_end_phys, PAGE_SIZE) / PAGE_SIZE;
    for (uint32_t page = kernel_start_page; page < kernel_end_page && page < bitmap_bits; page++)
        bitmap_set_bit(bitmap, page);

    // Mark E820 table as used
    // E820 table is located at < 0x10000 always
    // 64K / 4K = 16 pages
    for (uint32_t page = 0; page < 16; page++)
        bitmap_set_bit(bitmap, page);
    
    debug_log_string("PMM", "Usable memory: 0x");
    debug_log_hex32(usable_mem);
    debug_print_string("\r\n");
}

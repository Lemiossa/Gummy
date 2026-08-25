/*
 * pmm.c
 * Created by Matheus Leme da Silva
 * */
#include <types.h>
#include <terminal.h>
#include <bitmap.h>
#include <e820.h>
#include <pmm.h>

extern uint8_t *__kernel_start; // Start of the kernel in memory
extern uint8_t *__kernel_end; // End of the kernel in memory
#define BITMAP_LOCATION ((uint32_t)&__kernel_end) // Location of the bitmap in memory

uint8_t *bitmap;
uint32_t bitmap_size_in_bits = 0; // size of bitmap in bits
uint32_t bitmap_size_in_bytes = 0; // size of bitmap in bytes

// Alloc a page of physical memory
void *pmm_alloc_page()
{
    if (bitmap == NULL || bitmap_size_in_bits == 0)
        return NULL;

    for (uint32_t i = 0; i < bitmap_size_in_bits; i++)
    {
        if (!bitmap_test_bit(bitmap, i))
        {
            bitmap_set_bit(bitmap, i);
            return (void *)(i * PAGE_SIZE);
        }
    }

    return NULL; // No free pages available
}

// Free a page of physical memory
void pmm_free_page(void *page)
{
    if (bitmap == NULL || bitmap_size_in_bits == 0)
        return;

    bitmap_clear_bit(bitmap, ((uint32_t)page) / PAGE_SIZE);
}

// Initialize the physical memory manager
void pmm_init()
{
    bitmap = (uint8_t *)BITMAP_LOCATION;
    bitmap_size_in_bits = total_memory / PAGE_SIZE; 
    bitmap_size_in_bytes = ALIGN_UP(bitmap_size_in_bits, 8) / 8; 

    for (int i = 0; i < E820_entry_count; i++)
    {
        E820Entry *entry = &E820_entries[i];
        if (entry->type == 1) 
        {
            uint32_t start_page = entry->base / PAGE_SIZE;
            uint32_t end_page = (entry->base + entry->length) / PAGE_SIZE;

            for (uint32_t page = start_page; page < end_page; page++)
                bitmap_clear_bit(bitmap, page); // Mark as free
        }
        else
        {
            uint32_t start_page = entry->base / PAGE_SIZE;
            uint32_t end_page = (entry->base + entry->length) / PAGE_SIZE;

            for (uint32_t page = start_page; page < end_page; page++)
                bitmap_set_bit(bitmap, page); // Mark as used
        }
    }

    // Mark the bitmap itself as used
    uint32_t bitmap_pages = ALIGN_UP(bitmap_size_in_bytes, PAGE_SIZE) / PAGE_SIZE; 
    uint32_t bitmap_start_page = BITMAP_LOCATION / PAGE_SIZE;
    uint32_t bitmap_end_page = bitmap_start_page + bitmap_pages;
    for (uint32_t page = bitmap_start_page; page < bitmap_end_page; page++)
        bitmap_set_bit(bitmap, page);

    // Mark the kernel memory as used
    uint32_t kernel_start_page = (uint32_t)&__kernel_start / PAGE_SIZE;
    uint32_t kernel_end_page = (uint32_t)&__kernel_end / PAGE_SIZE;
    for (uint32_t page = kernel_start_page; page < kernel_end_page; page++)
        bitmap_set_bit(bitmap, page);

    // Mark E820 table as used
    // E820 table is located at < 0x10000 always
    // 64K / 4K = 16 pages
    for (uint32_t page = 0; page < 16; page++)
        bitmap_set_bit(bitmap, page);

    terminal_print_string("PMM initialized\r\n");
}

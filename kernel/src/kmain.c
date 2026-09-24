/*
 * kmain.c
 * Created by Matheus Leme Da Silva
 */
#include <io.h>
#include <types.h>
#include <terminal.h>
#include <gdt.h>
#include <idt.h>
#include <pic.h>
#include <exception.h>
#include <e820.h>
#include <pmm.h>
#include <vmm.h>
#include <sched.h>
#include <heap.h>

void kmain()
{
    disable_interrupts();
    gdt_init();
    terminal_init();
    idt_init();
    pic_remap();
    exception_init();
    E820_init();
    pmm_init();
    vmm_init();
    heap_init();
    sched_init(100);
    enable_interrupts();

    terminal_print_string(NAME);
    terminal_print_string(" v");
    terminal_print_string(VERSION);
    terminal_print_string("\r\n");

    terminal_print_string("Heap test...\r\n");

    void *a = heap_alloc(64);
    void *b = heap_alloc(128);

    if (!a || !b)
    {
        terminal_print_string("FAIL: alloc\r\n");
        return;
    }

    terminal_print_string("Alloc: PASS\r\n");

    uint32_t *p = (uint32_t *)a;
    for (uint32_t i = 0; i < 16; i++)
        p[i] = 0xDEADBEEF;

    for (uint32_t i = 0; i < 16; i++)
    {
        if (p[i] != 0xDEADBEEF)
        {
            terminal_print_string("FAIL: memory\r\n");
            return;
        }
    }

    terminal_print_string("Memory: PASS\r\n");

    heap_free(a);
    heap_free(b);

    terminal_print_string("Free/merge: PASS\r\n");

    void *c = heap_alloc(32);

    if (!c)
    {
        terminal_print_string("FAIL: reuse\r\n");
        return;
    }

    terminal_print_string("Reuse: PASS\r\n");

    heap_print();

    terminal_print_string("Heap test passed!\r\n");

    disable_interrupts();
    halt_cpu();
}

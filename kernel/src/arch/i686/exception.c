/*
 * exception.c
 * Created by Matheus Leme da Silva
 * */
#include "io.h"
#include <terminal.h>
#include <idt.h>
#include <types.h>

static const char *exception_names[32] = {
    [0]  = "Division Error",
    [1]  = "Debug",
    [2]  = "Non-Maskable Interrupt",
    [3]  = "Breakpoint",
    [4]  = "Overflow",
    [5]  = "BOUND Range Exceeded",
    [6]  = "Invalid Opcode",
    [7]  = "Device Not Available",
    [8]  = "Double Fault",
    [9]  = "Coprocessor Segment Overrun",
    [10] = "Invalid TSS",
    [11] = "Segment Not Present",
    [12] = "Stack-Segment Fault",
    [13] = "General Protection Fault",
    [14] = "Page Fault",
    [15] = "Reserved",
    [16] = "x87 Floating-Point Exception",
    [17] = "Alignment Check",
    [18] = "Machine Check",
    [19] = "SIMD Floating-Point Exception",
    [20] = "Virtualization Exception",
    [21] = "Control Protection Exception",
    [22] = "Reserved",
    [23] = "Reserved",
    [24] = "Reserved",
    [25] = "Reserved",
    [26] = "Reserved",
    [27] = "Reserved",
    [28] = "Hypervisor Injection Exception",
    [29] = "VMM Communication Exception",
    [30] = "Security Exception",
    [31] = "Reserved",
};

// Handles exceptions
static void exception_handler(interrupt_context_t *ctx)
{
    terminal_print_string("\r\n\n*** CPU EXCEPTION ***\r\n");

    terminal_print_string("Exception: ");
    terminal_print_string(exception_names[ctx->int_num]);
    terminal_print_string("\r\n  INT: 0x");
    terminal_print_hex32(ctx->int_num);
    terminal_print_string("\r\n  EIP: 0x");
    terminal_print_hex32(ctx->eip);

    if (ctx->int_num == 14 ) // Page Fault
    {
        uint32_t cr2 = read_cr2();
        terminal_print_string("\r\n  CR2: 0x");
        terminal_print_hex32(cr2);
    }

    terminal_print_string("\r\n\nSystem halted.\r\n");

    for (;;)
    {
        disable_interrupts();
        halt_cpu();
    }
}

// Initializes exceptions
void exception_init(void)
{
    for (int i = 0; i < 32; i++)
        idt_set_handler(i, exception_handler);
}

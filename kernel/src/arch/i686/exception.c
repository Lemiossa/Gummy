/*
 * exception.c
 * Criado por Matheus Leme da Silva
 * */
#include <debug.h>
#include <idt.h>
#include <io.h>
#include <sched/process.h>
#include <terminal.h>
#include <types.h>

static const char *exception_names[32] = {
	[0] = "Division Error",
	[1] = "Debug",
	[2] = "Non-Maskable Interrupt",
	[3] = "Breakpoint",
	[4] = "Overflow",
	[5] = "BOUND Range Exceeded",
	[6] = "Invalid Opcode",
	[7] = "Device Not Available",
	[8] = "Double Fault",
	[9] = "Coprocessor Segment Overrun",
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

// Trata excecoes
static void exception_handler(interrupt_context_t *ctx) {
	int from_user = (ctx->cs & 3) == 3;

	printk("%s!\r\n", exception_names[ctx->int_num]);
	printk("    INT: %u\r\n", ctx->int_num);
	printk("    EIP: 0x%08X\r\n", ctx->eip);

	if (ctx->int_num == 14) { // Page fault
		uint32_t cr2 = read_cr2();
		printk("    CR2: 0x%08X\r\n", cr2);
	}

	debug_dump_code((uintptr_t)ctx->eip, 16);
	if (from_user) {
		sched_destroy_current_process();
		return;
	}

	printk("Sistema parado!\r\n");

	for (;;) {
		disable_interrupts();
		halt_cpu();
	}
}

// Inicializa as excecoes
void exception_init(void) {
	for (int i = 0; i < 32; i++)
		idt_set_handler(i, exception_handler);
}

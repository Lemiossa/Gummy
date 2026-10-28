/*
 * process.c
 * Criado por Matheus Leme da Silva
 * */
#include "ipc.h"
#include "queue.h"
#include "ring_buffer.h"
#include <debug.h>
#include <heap.h>
#include <io.h>
#include <sched.h>
#include <string.h>
#include <types.h>
#include <vmm.h>

process_t idle_process;
uint32_t current_pid = 0;
process_t *first_process = NULL;
extern thread_t *current_thread;

// Procura um processo pelo PID.
// Retorna o ponteiro para ele, nulo se erro.
process_t *get_process(uint32_t pid) {
	process_t *process = first_process;
	do {
		if (process->pid == pid)
			return process;

		process = process->next;
	} while (process->next);
	return NULL;
}

// Retorna o ponteiro pro processo atual rodando
process_t *sched_get_current_process(void) {
	if (!current_thread || !current_thread->process)
		return NULL;
	return current_thread->process;
}

// cria um novo processo
// retorna um ponteiro para o processo
process_t *sched_create_process(void) {
	debug_log_string("SCHED", "Criando processo...\r\n");

	process_t *proc = (process_t *)heap_alloc(sizeof(process_t));
	if (!proc) {
		debug_log_string("SCHED", "Falha ao alocar memoria para processo\r\n");
		return NULL;
	}
	memset(proc, 0, sizeof(*proc));

	proc->cr3 = vmm_clone();
	if (!proc->cr3) {
		debug_log_string("SCHED", "Falha ao clonar tabela de paginas\r\n");
		heap_free(proc);
		return NULL;
	}

	proc->num_threads = 0;
	proc->pid = current_pid++;

	debug_log_string("SCHED", "Processo criado com PID 0x");
	debug_log_hex32(proc->pid);
	debug_print_string("\r\n");

	ring_buffer_init(&proc->mailbox.ring_buffer, (void *)proc->mailbox.data, sizeof(ipc_message_t), IPC_QUEUE_SIZE);
	queue_init(&proc->mailbox.waiters);

	proc->next = first_process;
	first_process->prev = proc;
	first_process = proc;

	return proc;
}

// destroi um processo e suas threads
void sched_destroy_process(process_t *proc) {
	if (!proc)
		return;

	debug_log_string("SCHED", "Destruindo processo PID 0x");
	debug_log_hex32(proc->pid);
	debug_print_string("\r\n");

	if (read_cr3() == proc->cr3) {
		debug_log_string("SCHED",
						 "Nao e possivel destruir processo em execucao\r\n");
		return;
	}

	for (uint8_t i = 0; i < THREAD_PER_PROCESS; i++)
		sched_destroy_thread(&proc->threads[i]);

	vmm_destroy(proc->cr3);

	if (proc->cr3)
		pmm_free_page(proc->cr3);

	if (proc->prev)
		proc->prev->next = proc->next;

	if (proc->next)
		proc->next->prev = proc->prev;

	heap_free(proc);

	debug_log_string("SCHED", "Processo destruido\r\n");
}

// Retorna o PID da thread rodando atualmente
uint32_t sched_get_current_pid(void) {
	if (!current_thread || !current_thread->process)
		return 0;

	return current_thread->process->pid;
}

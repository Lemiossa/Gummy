/*
 * process.c
 * Criado por Matheus Leme da Silva
 * */
#include "sched/cap.h"
#include <debug.h>
#include <heap.h>
#include <io.h>
#include <ipc.h>
#include <pmm.h>
#include <queue.h>
#include <ring_buffer.h>
#include <sched/process.h>
#include <sched/thread.h>
#include <string.h>
#include <syscall.h>
#include <types.h>
#include <vmm.h>

process_t idle_process;
uint32_t current_pid = 0;
process_t *first_process = NULL;
extern thread_t *current_thread;

// Procura um processo pelo PID.
// Retorna o ponteiro para ele, nulo se erro.
process_t *sched_get_process(pid_t pid) {
	if (pid < 0)
		return NULL;

	process_t *process = first_process;
	while (process) {
		if (process->pid == pid)
			return process;
		process = process->next;
	}
	return NULL;
}

// Retorna o ponteiro pro processo atual rodando
process_t *sched_get_current_process(void) {
	if (!current_thread || current_thread->pid < 0)
		return NULL;
	return sched_get_process(current_thread->pid);
}

// cria um novo processo
// retorna um ponteiro para o processo
process_t *sched_create_process(void) {
	printk("Criando processo...\r\n");

	process_t *proc = (process_t *)heap_alloc(sizeof(process_t));
	if (!proc) {
		printk("Falha ao alocar memoria para processo\r\n");
		return NULL;
	}
	memset(proc, 0, sizeof(*proc));

	proc->cr3 = vmm_clone();
	if (!proc->cr3) {
		printk("Falha ao clonar tabela de paginas\r\n");
		heap_free(proc);
		return NULL;
	}

	proc->pid = current_pid++;
	proc->parent = sched_get_current_process();

	for (int i = 0; i < THREAD_PER_PROCESS; i++)
		proc->threads[i].state = THREAD_FREE;

	ring_buffer_init(&proc->mailbox.ring_buffer, (void *)proc->mailbox.data,
					 sizeof(ipc_message_t), IPC_QUEUE_SIZE);
	queue_init(&proc->mailbox.waiters);

	proc->next = first_process;
	if (first_process)
		first_process->prev = proc;
	first_process = proc;

	printk("Processo criado com PID %u\r\n", proc->pid);

	return proc;
}

// destroi um processo e suas threads
void sched_destroy_process(process_t *proc) {
	if (!proc)
		return;

	printk("Destruindo processo PID %u\r\n", proc->pid);

	if (read_cr3() == proc->cr3) {
		printk("Nao e possivel destruir processo em execucao\r\n");
		return;
	}

	// Reparentar os filhos
	process_t *p = first_process;
	while (p) {
		if (p->parent == proc) {
			p->parent = proc->parent;
		}
		p = p->next;
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

	if (first_process == proc)
		first_process = proc->next;

	heap_free(proc);

	printk("Processo destruido\r\n");
}

// Mata o processo atual com segurança
void sched_destroy_current_process(void) {
	process_t *proc = sched_get_current_process();
	if (!proc)
		return;

	flags_t flags = read_flags();
	disable_interrupts();

	for (int i = 0; i < THREAD_PER_PROCESS; i++)
		queue_remove(&proc->threads[i]
						  .node); // Remove a thread de qualquer fila que esteja

	proc->state = PROCESS_DYING;

	write_flags(flags);
	sys_yield(); // int $0x81 -> troca de thread instantaneamente
}

// Retorna o PID da thread rodando atualmente
pid_t sched_get_current_pid(void) {
	if (!current_thread)
		return -1;

	return current_thread->pid;
}

// Retorna o PPID da thread rodando atualmente
pid_t sched_get_current_ppid(void) {
	if (!current_thread)
		return 0;

	process_t *cur_proc = sched_get_current_process();
	if (!cur_proc || !cur_proc->parent)
		return -1;

	return cur_proc->parent->pid;
}

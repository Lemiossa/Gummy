/*
 * ipc.c
 * Criado por Matheus Leme da Silva
 * */
#include <debug.h>
#include <idt.h>
#include <io.h>
#include <ipc.h>
#include <queue.h>
#include <sched/process.h>
#include <sched/sched.h>
#include <string.h>
#include <syscall.h>
#include <types.h>

extern void schedule(interrupt_context_t *ctx);

// Envia uma mensagem pra um processo
// Usa a thread atual
// Retorna !0 se houver erro
int ipc_send(uint32_t pid, uint32_t type, const void *data, uint32_t size) {
	if (!data || !size || size > IPC_MSG_MAX)
		return 1;

	process_t *p = sched_get_process(pid);
	if (!p)
		return 1;

	if (p->state == PROCESS_DYING)
		return 1;

	ipc_message_t msg;
	memcpy(msg.data, data, size);
	msg.size = size;
	msg.sender_pid = sched_get_current_pid();
	msg.type = type;

	if (ring_buffer_push(&p->mailbox.ring_buffer, &msg))
		return 1;

	if (queue_empty(&p->mailbox.waiters))
		return 0;

	queue_node_t *n = queue_pop(&p->mailbox.waiters);
	if (!n)
		return 1;

	thread_t *t = (thread_t *)CONTAINER_OF(n, thread_t, node);
	sched_ready(t);

	return 0;
}

// Recebe uma mensagem
// Por enquanto, sempre bloqueia a thread que está esperando
// Retorna !0 se houver erro
int ipc_receive(uint32_t *sender_pid, void *buffer, uint32_t size) {
	if (!sender_pid || !buffer || size == 0 || size > IPC_MSG_MAX)
		return 1;

	process_t *p = sched_get_current_process();
	if (!p)
		return 1;

	if (ring_buffer_empty(&p->mailbox.ring_buffer)) {
		thread_t *t = sched_get_current_thread();

		flags_t flags = read_flags();
		disable_interrupts();
		t->state = THREAD_BLOCKED;
		queue_remove(&t->node);
		queue_push(&p->mailbox.waiters, &t->node);
		write_flags(flags);
		sys_yield();
	}

	ipc_message_t msg;

	if (ring_buffer_pop(&p->mailbox.ring_buffer, &msg))
		return 1;

	*sender_pid = msg.sender_pid;
	uint32_t copy_size = MIN(size, msg.size);
	memcpy(buffer, msg.data, copy_size);

	return 0;
}

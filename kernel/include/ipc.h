#ifndef IPC_H
#define IPC_H

#include <idt.h>
#include <queue.h>
#include <ring_buffer.h>
#include <types.h>

#define IPC_QUEUE_SIZE 16
#define IPC_MSG_MAX 64

typedef struct ipc_message {
	uint32_t sender_pid;
	uint32_t type;
	uint32_t size;
	uint8_t data[IPC_MSG_MAX];
} ipc_message_t;

typedef struct mailbox {
	ipc_message_t data[IPC_QUEUE_SIZE];
	ring_buffer_t ring_buffer;
	queue_t waiters;
} mailbox_t;

// Envia uma mensagem pra um processo
int ipc_send(uint32_t pid, uint32_t type, const void *data, uint32_t size);
// Recebe uma mensagem
// Por enquanto, sempre bloqueia a thread que está esperando
// Retorna !0 se houver erro
int ipc_receive(uint32_t *sender_pid, void *buffer, uint32_t size);

#endif // IPC_H

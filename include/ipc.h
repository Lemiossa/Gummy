#ifndef IPC_H
#define IPC_H

#include <queue.h>
#include <types.h>
#include <ring_buffer.h>

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
int ipc_send(uint32_t pid, const void *data, size_t size);
// Recebe uma mensagem
// Pode bloquear ou não bloquear dependendo das flags IPC do processo
int ipc_receive(uint32_t *sender_pid, void *buffer, size_t size);

#endif // IPC_H

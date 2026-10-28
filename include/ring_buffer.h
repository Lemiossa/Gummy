#ifndef RING_BUFFER_H
#define RING_BUFFER_H
#include <types.h>

typedef struct ring_buffer {
	uint8_t *buf;	  // armazenamento (fornecido por quem usa)
	size_t elem_size; // tamanho de cada slot
	size_t capacity;  // numero de slots
	size_t head;	  // leitura (mais antigo)
	size_t tail;	  // escrita (proxima posicao livre)
	size_t count;
} ring_buffer_t;

// Inicializa um ring buffer
void ring_buffer_init(ring_buffer_t *r, void *storage, size_t elem_size,
					  size_t capacity);
// Coloca um elemento num ring buffer
// Retorna !0 se o buffer está cheio
int ring_buffer_push(ring_buffer_t *r, const void *elem);
// Retira um elemento de um ring buffer
// Retorna !0 se o buffer está vazio
int ring_buffer_pop(ring_buffer_t *r, void *out);
// Lê sem tirar do buffer
// Retorna !0 se o buffer está vazio
int ring_buffer_peek(ring_buffer_t *r, void *out);
// Retorna 1 se o buffer está cheio
int ring_buffer_full(const ring_buffer_t *r);
// Retorna 1 se o buffer está vazio
int ring_buffer_empty(const ring_buffer_t *r);

#endif // RING_BUFFER_H

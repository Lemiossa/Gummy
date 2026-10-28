/*
 * ring_buffer.c
 * Criado por Matheus Leme da Silva
 * */
#include <ring_buffer.h>
#include <string.h>
#include <types.h>

// Inicializa um ring buffer
void ring_buffer_init(ring_buffer_t *r, void *storage, size_t elem_size,
					  size_t capacity) {
	if (!r || !storage)
		return;

	r->capacity = capacity;
	r->elem_size = elem_size;
	r->head = 0;
	r->tail = 0;
	r->count = 0;
	r->buf = storage;
}

// Coloca um elemento num ring buffer
// Retorna !0 se o buffer está cheio
int ring_buffer_push(ring_buffer_t *r, const void *elem) {
	if (!r || !elem)
		return 1;
	if (ring_buffer_full(r))
		return 1;
	memcpy(r->buf + r->tail * r->elem_size, elem, r->elem_size);
	r->tail = (r->tail + 1) % r->capacity;
	r->count++;
	return 0;
}

// Retira um elemento de um ring buffer
// Retorna !0 se o buffer está vazio
int ring_buffer_pop(ring_buffer_t *r, void *out) {
	if (ring_buffer_peek(r, out))
		return 1;
	r->head = (r->head + 1) % r->capacity;
	r->count--;
	return 0;
}

// Lê sem tirar do buffer
// Retorna !0 se o buffer está vazio
int ring_buffer_peek(ring_buffer_t *r, void *out) {
	if (!r || !out)
		return 1;
	if (ring_buffer_empty(r))
		return 1;
	memcpy(out, r->buf + r->head * r->elem_size, r->elem_size);
	return 0;
}

// Retorna 1 se o buffer está cheio
int ring_buffer_full(const ring_buffer_t *r) {
	if (!r)
		return 1; // Trata como cheio
	return r->count >= r->capacity;
}

// Retorna 1 se o buffer está vazio
int ring_buffer_empty(const ring_buffer_t *r) {
	if (!r)
		return 1; // Trata como vazio
	return r->count == 0;
}

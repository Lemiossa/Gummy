#ifndef QUEUE_H
#define QUEUE_H
#include <types.h>

typedef struct queue_node queue_node_t;
typedef struct queue queue_t;

struct queue_node
{
    queue_node_t *prev;
    queue_node_t *next;
};

struct queue 
{
    queue_node_t head;  // Sentinela
                        // head.prev = final
                        // head.next = inicio
    size_t size;
};

// Inicializa uma fila
void queue_init(queue_t *q);
// Adiciona um no ao final da fila.
void queue_push(queue_t *q, queue_node_t *node);
// Remove e retorna o no na frente da fila.
queue_node_t *queue_pop(queue_t *q);
// Retorna diferente de zero se a fila estiver vazia.
int queue_empty(queue_t *q);
// Remove um no especifico da fila.
void queue_remove(queue_t *q, queue_node_t *node);
// Retorna o tamanho da fila
size_t queue_size(queue_t *q);

#endif // QUEUE_H

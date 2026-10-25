/*
 * queue.c
 * Criado por Matheus Leme da Silva
 * */
#include <types.h>
#include <queue.h>

// Inicializa uma fila
void queue_init(queue_t *q)
{
    if (!q)
        return;

    q->head.prev = NULL;
    q->head.next = NULL;
    q->size = 0;
}

// Adiciona um no ao final da fila.
void queue_push(queue_t *q, queue_node_t *node)
{
    if (!q || !node)
        return;

    node->prev = q->head.prev;
    node->next = NULL;

    if (q->head.prev)
        q->head.prev->next = node;
    else
        q->head.next = node;

    node->q = q;

    q->head.prev = node;
    q->size++;
}

// Remove e retorna o no na frente da fila.
queue_node_t *queue_pop(queue_t *q)
{
    if (!q || !q->head.next)
        return NULL;

    queue_node_t *node = q->head.next;
    node->q = NULL;
    q->head.next = node->next;

    if (node->next)
        node->next->prev = NULL;
    else
        q->head.prev = NULL;

    q->size--;
    return node;
}

// Retorna diferente de zero se a fila estiver vazia.
int queue_empty(queue_t *q)
{
    if (!q)
        return 1;

    return q->head.next == NULL;
}

// Remove um no especifico da fila.
void queue_remove(queue_node_t *node)
{
    if (!node->q || !node)
        return;

    if (node->prev)
        node->prev->next = node->next;
    else
        node->q->head.next = node->next;

    if (node->next)
        node->next->prev = node->prev;
    else
        node->q->head.prev = node->prev;

    node->prev = NULL;
    node->next = NULL;
    node->q->size--;
    node->q = NULL;
}

// Retorna o tamanho da fila
size_t queue_size(queue_t *q)
{
    if (!q)
        return 0;

    return q->size;
}

/*
 * queue.c
 * Created by Matheus Leme da Silva
 * */
#include <types.h>
#include <queue.h>

// Initializes a queue
void queue_init(queue_t *q)
{
    if (!q)
        return;

    q->head.prev = NULL;
    q->head.next = NULL;
}

// Adds a node to the back of the queue.
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

    q->head.prev = node;
}

// Removes and returns the node at the front.
queue_node_t *queue_pop(queue_t *q)
{
    if (!q || !q->head.next)
        return NULL;

    queue_node_t *node = q->head.next;
    q->head.next = node->next;

    if (node->next)
        node->next->prev = NULL;
    else
        q->head.prev = NULL;

    return node;
}

// Returns non-zero if the queue is empty.
int queue_empty(queue_t *q)
{
    if (!q)
        return 1;

    return q->head.next == NULL;
}

// Removes a specific node from the queue.
void queue_remove(queue_t *q, queue_node_t *node)
{
    if (!q || !node)
        return;

    if (node->prev)
        node->prev->next = node->next;
    else
        q->head.next = node->next;

    if (node->next)
        node->next->prev = node->prev;
    else
        q->head.prev = node->prev;

    node->prev = NULL;
    node->next = NULL;
}

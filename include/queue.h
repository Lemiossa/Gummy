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
    queue_node_t head;  // Sentinel
                        // head.prev = back
                        // head.next = front
    size_t size;
};

// Initializes a queue
void queue_init(queue_t *q);
// Adds a node to the back of the queue.
void queue_push(queue_t *q, queue_node_t *node);
// Removes and returns the node at the front.
queue_node_t *queue_pop(queue_t *q);
// Returns non-zero if the queue is empty.
int queue_empty(queue_t *q);
// Removes a specific node from the queue.
void queue_remove(queue_t *q, queue_node_t *node);
// Returns the size of queue
size_t queue_size(queue_t *q);

#endif // QUEUE_H

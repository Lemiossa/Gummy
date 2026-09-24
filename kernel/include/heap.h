#ifndef HEAP_H
#define HEAP_H
#include <types.h>

#define HEAP_VIRTUAL_ADDRESS      0xE0000000
#define HEAP_INITIAL_PAGES        2
#define HEAP_SPLIT_BLOCK_MIN_SIZE 32

// Initializes the heap
void heap_init(void);
// Allocates a block of memory of the given size
void *heap_alloc(size_t size);
// Frees a previously allocated block of memory
void heap_free(void *ptr);
// Prints the current state of the heap (for debugging purposes)
void heap_print(void);

#endif // HEAP_H

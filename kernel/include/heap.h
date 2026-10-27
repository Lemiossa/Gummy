#ifndef HEAP_H
#define HEAP_H
#include <types.h>

#define HEAP_VIRTUAL_ADDRESS 0xE0000000
#define HEAP_INITIAL_PAGES 24
#define HEAP_SPLIT_BLOCK_MIN_SIZE 32

// Inicializa o heap
void heap_init(void);
// Aloca um bloco de memoria com o tamanho informado
void *heap_alloc(size_t size);
// Libera um bloco de memoria alocado anteriormente
void heap_free(void *ptr);
// Imprime o estado atual do heap (para fins de debug)
void heap_print(void);

#endif // HEAP_H

#ifndef INITRD_H
#define INITRD_H
#include <types.h>

#define INITRD_MAGIC 0x47554D4D

typedef struct initrd_header {
	uint32_t magic;
	uint32_t version;
	uint32_t entry_count;
	uint32_t data_offset;
} __attribute__((packed)) initrd_header_t;

typedef struct initrd_entry {
	uint32_t type;
	uint32_t permissions;
	uint32_t name_size;
	uint32_t offset;
	uint32_t size;
} __attribute__((packed)) initrd_entry_t;

typedef struct initrd {
	const void *base;
	const initrd_header_t *header;
	const initrd_entry_t *entries;
	const void *data;
} initrd_t;

// Cria um initrd
void initrd_create(initrd_t *out, const void *data);
// Valida um initrd
// Retorna !0 se for inválido
int initrd_check(const initrd_t *initrd);
// Retorna uma entrada específica no initrd
const initrd_entry_t *initrd_get_entry(const initrd_t *initrd, size_t n);
// Procura uma entrada específica no initrd pelo nome
const initrd_entry_t *initrd_find_entry(const initrd_t *initrd, const char *path);
// Retorna o tamanho do conteúdo de uma entrada no initrd
size_t initrd_get_len(const initrd_entry_t *entry);
// Retorna um ponteiro para o conteúdo de uma entrada no initrd
const void *initrd_get_data(const initrd_t *initrd, const initrd_entry_t *entry);

#endif // INITRD_H

/*
 * initrd.c
 * Criado por Matheus Leme da Silva
 * */
#include <initrd.h>
#include <string.h>

// Cria um initrd
void initrd_create(initrd_t *out, const void *data) {
	if (!out || !data)
		return;

	out->base = data;
	out->header = (const initrd_header_t *)data;
	out->entries =
		(const initrd_entry_t *)((uintptr_t)data + sizeof(initrd_header_t));
	out->data = (const void *)((uintptr_t)data + out->header->data_offset);
}

// Valida um initrd
// Retorna !0 se for inválido
int initrd_check(const initrd_t *initrd) {
	if (!initrd || !initrd->header || !initrd->entries)
		return 1;
	return !(initrd->header->magic == INITRD_MAGIC);
}

// Retorna uma entrada específica no initrd
const initrd_entry_t *initrd_get_entry(const initrd_t *initrd, size_t n) {
	if (initrd_check(initrd))
		return NULL;

	if (n >= initrd->header->entry_count)
		return NULL;

	const initrd_entry_t *entry = initrd->entries;
	for (size_t i = 0; i < n; i++) {
		entry = (const initrd_entry_t *)((uintptr_t)entry + entry->name_size +
										 sizeof(initrd_entry_t));
	}

	return entry;
}

// Procura uma entrada específica no initrd pelo nome
const initrd_entry_t *initrd_find_entry(const initrd_t *initrd, const char *path) {
	if (initrd_check(initrd) || !path)
		return NULL;

	size_t len = strlen(path);
	if (len == 0)
		return NULL;

	for (size_t i = 0; i < initrd->header->entry_count; i++) {
		const initrd_entry_t *entry = initrd_get_entry(initrd, i);
		if (!entry)
			continue; // Por ora, continue
		if (entry->name_size != (uint32_t)len + 1)
			continue; // Evitar ficar comparando paths com tamanhos diferentes
		const char *name =
			(const char *)((uintptr_t)entry + sizeof(initrd_entry_t));
		if (memcmp(name, path, len) == 0)
			return entry;
	}

	return NULL;
}

// Retorna o tamanho do conteúdo de uma entrada no initrd
size_t initrd_get_len(const initrd_entry_t *entry) {
	if (!entry) return 0;
	return (size_t)entry->size;
}

// Retorna um ponteiro para o conteúdo de uma entrada no initrd
const void *initrd_get_data(const initrd_t *initrd, const initrd_entry_t *entry) {
	if (initrd_check(initrd) || !entry) return NULL;
	return (const void *)((uintptr_t)initrd->base + (uintptr_t)entry->offset);
}


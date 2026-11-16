/*
 * vfs.c
 * Criado por Matheus Leme da Silva
 * */
#include <vfs.h>
#include <string.h>

fs_t filesystems[VFS_FILESYSTEMS] = {0};
int num_filesystems = 0;
vol_t volumes[VFS_VOLUMES] = {0};
int num_volumes = 0;

// Procura um filesystem pelo nome
fs_t *vfs_find_fs(const char *name) {
	if (!name || strlen(name) >= VFS_FILESYSTEM_NAME_LEN)
		return NULL;

	for (int i = 0; i < num_filesystems; i++) {
		fs_t *fs = &filesystems[i];
		if (fs->name[0] == 0) break; // Se não tem nome, é um filesystem inválido
		if (strcmp(fs->name, name) == 0) 
			return fs;
	}

	return NULL;
}

// Procura um volume pelo nome
vol_t *vfs_find_vol(const char *name) {
	if (!name || strlen(name) >= VFS_VOLUME_NAME_LEN)
		return NULL;

	for (int i = 0; i < num_volumes; i++) {
		vol_t *vol = &volumes[i];
		if (vol->name[0] == 0) break; // Se não tem nome, é um volume inválido
		if (strcmp(vol->name, name) == 0) 
			return vol;
	}

	return NULL;
}

// Verifica se um filesystem é válido 
// Retorna 1 se o fs é válido
static inline int vfs_check_fs(const fs_t *fs) {
	if (fs->name[0] == 0) return 0;
	if (!fs->mount || !fs->unmount || !fs->open 
			|| !fs->read || !fs->close)
		return 0;

	return 1;
}

// Registra um filesystem no vfs
// Retorna o índice dele na lista, -1 em caso de erro
int vfs_registry_fs(fs_t fs) {
	// Verificar todos os ponteiros do vfs
	if (num_filesystems >= VFS_FILESYSTEMS)
		return -1;

	if (!vfs_check_fs(&fs))
		return -1;

	int index = num_filesystems++;
	filesystems[index] = fs;

	return index;
}

// Abre um arquivo 
file_t *vfs_open(const char *path, int *err) {
	if (!path) return NULL;

	const char *p = path;
	char name[VFS_VOLUME_NAME_LEN];

	for (int i = 0; i < VFS_VOLUME_NAME_LEN; i++) {
		if (*p == ':') break;
		if (i == VFS_VOLUME_NAME_LEN) 
			return NULL; // Ultrapassou o número de caracteres do nome do volume

		name[i] = *p++;
	}

	name[7] = 0;
	p++; // p == index(':') + 1

	vol_t *vol = vfs_find_vol(name);
	if (!vol) return NULL;
	if (!vfs_check_fs(vol->fs))
		return NULL;

	file_t *f = NULL;

	int ret = vol->fs->open(vol->ctx, p, &f);
	if (err) *err = ret;

	return f;
}


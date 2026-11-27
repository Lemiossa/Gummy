/*
 * vfs.c
 * Criado por Matheus Leme da Silva
 * */
#include <stddef.h>
#include <stdint.h>
#include <string.h>
#include <vfs.h>

fs_t filesystems[VFS_FILESYSTEMS] = {0};
int num_filesystems = 0;
vol_t volumes[VFS_VOLUMES] = {0};
int num_volumes = 0;

// Procura um handlesystem pelo nome
fs_t *vfs_find_fs(const char *name) {
	if (!name || strlen(name) >= VFS_FILESYSTEM_NAME_LEN)
		return NULL;

	for (int i = 0; i < num_filesystems; i++) {
		fs_t *fs = &filesystems[i];
		if (fs->name[0] == 0)
			break; // Se não tem nome, é um handlesystem inválido
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
		if (vol->name[0] == 0)
			break; // Se não tem nome, é um volume inválido
		if (strcmp(vol->name, name) == 0)
			return vol;
	}

	return NULL;
}

// Verifica se um handlesystem é válido
// Retorna 1 se o fs é válido
static inline int vfs_check_fs(const fs_t *fs) {
	if (!fs)
		return 0;
	if (fs->name[0] == 0)
		return 0;
	if (!fs->ops)
		return 0;

	return 1;
}

// Registra um handlesystem no vfs
// Retorna o índice dele na lista, -1 em caso de erro
int vfs_registry_fs(fs_t fs) {
	// Verificar todos os ponteiros do vfs
	if (num_filesystems >= VFS_FILESYSTEMS)
		return -1;

	if (!vfs_check_fs(&fs))
		return -1;

	if (vfs_find_fs(fs.name))
		return -1;

	int index = num_filesystems++;
	filesystems[index] = fs;

	return index;
}

// Monta um sistema de arquivos
int vfs_mount(const char *volname, const char *fsname, const void *source) {
	if (!volname || !source || strlen(volname) >= VFS_VOLUME_NAME_LEN ||
		volname[0] == 0)
		return -VFS_ERR_INVALID;
	if (vfs_find_vol(volname))
		return -VFS_ERR_NAME_USED;
	if (num_volumes >= VFS_VOLUMES)
		return -VFS_ERR_NOT_ENOUGH_SPACE;

	vol_t *vol = &volumes[num_volumes];

	fs_t *fs = vfs_find_fs(fsname);
	if (!fs)
		return -VFS_ERR_INVALID;
	if (!vfs_check_fs(fs))
		return -VFS_ERR_INVALID;
	if (!fs->ops->mount)
		return -VFS_ERR_OPERATION_NOT_FOUND;

	char name[VFS_VOLUME_NAME_LEN];

	for (int i = 0; i < VFS_VOLUME_NAME_LEN; i++) {
		if (volname[i] == ':' || volname[i] == 0) {
			name[i] = 0;
			break;
		}
		name[i] = volname[i];
	}

	void *ctx = NULL;

	int ret = fs->ops->mount(source, &ctx);
	if (ret != VFS_ERR_OK)
		return ret;

	if (!ctx)
		return -VFS_ERR_INVALID;

	vol->fs = fs;
	vol->ctx = ctx;
	memcpy(vol->name, name, VFS_VOLUME_NAME_LEN);
	num_volumes++;

	return ret;
}

// Abre um arquivo
handle_t *vfs_open(const char *path, int *err) {
	if (!path || path[0] == ':') {
		if (err)
			*err = -VFS_ERR_INVALID;
		return NULL;
	}

	const char *p = path;
	char name[VFS_VOLUME_NAME_LEN] = {0};
	char *colon = strchr(path, ':');
	if (!colon) {
		if (err) *err = -VFS_ERR_INVALID;
		return NULL;
	}

	size_t volname_len = (size_t)(colon - p);
	if (volname_len == 0 || volname_len >= VFS_VOLUME_NAME_LEN) {
		if (err) *err = -VFS_ERR_INVALID;
		return NULL;
	}
	strncpy(name,  p, volname_len);

	p = (const char *)(uintptr_t)(colon + 1);
	if (*p == 0) {
		if (err)
			*err = -VFS_ERR_INVALID;
		return NULL;
	}

	vol_t *vol = vfs_find_vol(name);
	if (!vol) {
		if (err)
			*err = -VFS_ERR_VOL_NOT_FOUND;
		return NULL;
	}
	if (!vfs_check_fs(vol->fs))
		return NULL;
	if (!vol->fs->ops->open) {
		if (err)
			*err = -VFS_ERR_OPERATION_NOT_FOUND;
		return NULL;
	}

	handle_t *h = NULL;

	int ret = vol->fs->ops->open(vol->ctx, p, &h);

	if (err)
		*err = ret;
	h->vol = vol;

	return h;
}

// Lê um arquivo/diretório
ssize_t vfs_read(handle_t *h, void *dst, size_t n) {
	if (!h || !dst || n == 0)
		return -VFS_ERR_INVALID;
	if (!h->vol)
		return -VFS_ERR_VOL_NOT_FOUND;
	if (!h->vol->fs)
		return -VFS_ERR_FS_NOT_FOUND;
	if (!h->vol->fs->ops)
		return -VFS_ERR_OPERATION_NOT_FOUND;
	if (!h->vol->fs->ops->read)
		return -VFS_ERR_OPERATION_NOT_FOUND;
	return h->vol->fs->ops->read(h->vol->ctx, h, dst, n);
}

// Escreve um arquivo
ssize_t vfs_write(handle_t *h, const void *src, size_t n) {
	if (!h || !src || n == 0)
		return -VFS_ERR_INVALID;
	if (!h->vol)
		return -VFS_ERR_VOL_NOT_FOUND;
	if (!h->vol->fs)
		return -VFS_ERR_FS_NOT_FOUND;
	if (!h->vol->fs->ops)
		return -VFS_ERR_OPERATION_NOT_FOUND;
	if (!h->vol->fs->ops->write)
		return -VFS_ERR_OPERATION_NOT_FOUND;
	return h->vol->fs->ops->write(h->vol->ctx, h, src, n);
}

// Cria um arquivo
int vfs_create(const char *path) {
	if (!path || path[0] == ':') {
		return -VFS_ERR_INVALID;
	}

	const char *p = path;
	char name[VFS_VOLUME_NAME_LEN];

	for (int i = 0; i < VFS_VOLUME_NAME_LEN; i++) {
		if (*p == ':') {
			name[i] = 0;
			break;
		}
		if (i == VFS_VOLUME_NAME_LEN - 1)
			return -VFS_ERR_INVALID; // Ultrapassou o número de caracteres do
									 // nome do volume sem encontrar ':'

		name[i] = *p++;
	}

	p++; // p == index(':') + 1
	if (*p == 0)
		return -VFS_ERR_INVALID;

	vol_t *vol = vfs_find_vol(name);
	if (!vol)
		return -VFS_ERR_VOL_NOT_FOUND;
	if (!vfs_check_fs(vol->fs))
		return -VFS_ERR_INVALID;

	if (!vol)
		return -VFS_ERR_VOL_NOT_FOUND;
	if (!vol->fs)
		return -VFS_ERR_FS_NOT_FOUND;
	if (!vol->fs->ops)
		return -VFS_ERR_OPERATION_NOT_FOUND;
	if (!vol->fs->ops->write)
		return -VFS_ERR_OPERATION_NOT_FOUND;

	return vol->fs->ops->create(vol->ctx, p);
}

// Fecha um arquivo
int vfs_close(handle_t *h) {
	if (!h)
		return -VFS_ERR_INVALID;
	if (!h->vol)
		return -VFS_ERR_VOL_NOT_FOUND;
	if (!h->vol->fs)
		return -VFS_ERR_FS_NOT_FOUND;
	if (!h->vol->fs->ops)
		return -VFS_ERR_OPERATION_NOT_FOUND;
	if (!h->vol->fs->ops->close)
		return -VFS_ERR_OPERATION_NOT_FOUND;
	return h->vol->fs->ops->close(h->vol->ctx, h);
}

// Pega stat de um arquivo
int vfs_stat(handle_t *h, stat_t *out) {
	if (!h || !out)
		return -VFS_ERR_INVALID;
	if (!h->vol)
		return -VFS_ERR_VOL_NOT_FOUND;
	if (!h->vol->fs)
		return -VFS_ERR_FS_NOT_FOUND;
	if (!h->vol->fs->ops)
		return -VFS_ERR_OPERATION_NOT_FOUND;
	if (!h->vol->fs->ops->stat)
		return -VFS_ERR_OPERATION_NOT_FOUND;
	return h->vol->fs->ops->stat(h->vol->ctx, h, out);
}

// Desmonta um volume
int vfs_unmount(const char *volname) {
	if (!volname || volname[0] == 0)
		return -VFS_ERR_INVALID;

	const char *colon = strchr(volname, ':');
	const char *end = (colon ? colon : strchr(volname, '\0'));
	size_t len = (size_t)((uintptr_t)end - (uintptr_t)volname);
	if (len >= VFS_VOLUME_NAME_LEN)
		return -VFS_ERR_INVALID;

	char name[VFS_VOLUME_NAME_LEN];
	strncpy(name, volname, VFS_VOLUME_NAME_LEN);
	vol_t *vol = vfs_find_vol(name);
	if (!vol)
		return -VFS_ERR_VOL_NOT_FOUND;
	if (!vol->fs)
		return -VFS_ERR_FS_NOT_FOUND;
	if (!vol->fs->ops || !vol->fs->ops->unmount)
		return -VFS_ERR_OPERATION_NOT_FOUND;

	return vol->fs->ops->unmount(vol->ctx);
}

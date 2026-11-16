#ifndef VFS_H
#define VFS_H
#include <types.h>

#define VFS_FILESYSTEM_NAME_LEN 8
#define VFS_VOLUME_NAME_LEN 8

#define VFS_VOLUMES 64
#define VFS_FILESYSTEMS 16

enum {
	VFS_ERR_OK = 0,
	VFS_ERR_INVALID,
	VFS_ERR_NOT_FOUND,
	VFS_ERR_BUSY,
	VFS_ERR_IO,
};

typedef struct file file_t;
typedef struct vol vol_t;
typedef struct fs fs_t;

// VFS
typedef struct file { 
	size_t offset;
	size_t size;
	void *ctx;
	vol_t *vol;
} file_t;

typedef struct fs {
	char name[VFS_FILESYSTEM_NAME_LEN];
	int (*mount)(const void *source, void **ctx); // Deve retornar um código de erro e definir o 
												  // ponteiro em *ctx(passado como void **ctx) 
												  // para o contexto de filesystem.
	int (*unmount)(void *ctx); // Deve liberar qualquer coisa do 
							   // filesystem e retornar o código de erro
	int (*open)(void *ctx, const char *path, file_t **out); // Deve retornar um código de erro 
															// *e definir (file *) em *out
															// *out = (file_t *)file;
	int (*read)(void *ctx, file_t *f, void *dst, size_t n, size_t *readed); // Deve retornar um código de erro
																			// Verificar dst, n e etc, deve escrever o
																			// número de bytes lidos em *readed
	int (*close)(void *ctx, file_t *f);
	// PARA TODOS OS CÓDIGOS DE ERRO, DEVE RETORNAR -ERRO. Ex: "return -VFS_ERR_NOT_FOUND;"
} fs_t;

typedef struct vol {
	char name[VFS_VOLUME_NAME_LEN]; // Isso é mais flexivel que indexado
									// No indexado poderia usar até 36 caracteres
									// com nome, isso permite coisas como
									// fd0:/config.cfg ao invés de A:/config.cfg
									// Também deve ser terminado com 0
	const fs_t *fs; // Um filesystem NUNCA deve ser modificado através do volume, deve ser modificado
					// apenas pela propria lista de filesystems
	void *ctx;
} vol_t;

// Procura um filesystem pelo nome
fs_t *vfs_find_fs(const char *name);
// Procura um volume pelo nome
vol_t *vfs_find_vol(const char *name);
// Registra um filesystem no vfs
// Retorna o índice dele na lista, -1 em caso de erro
int vfs_registry_fs(fs_t fs);

// Abre um arquivo 
file_t *vfs_open(const char *path, int *err);

#endif // VFS_H

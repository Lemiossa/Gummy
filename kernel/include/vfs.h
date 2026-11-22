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
	VFS_ERR_NAME_USED,
	VFS_ERR_NOT_ENOUGH_SPACE,
	VFS_ERR_VOL_NOT_FOUND,
	VFS_ERR_FS_NOT_FOUND,
};

typedef enum handle_type {
	VFS_HANDLE_FILE,
	VFS_HANDLE_DIR,
} handle_type_t;

typedef struct handle handle_t;
typedef struct vol vol_t;
typedef struct ops ops_t;
typedef struct fs fs_t;
typedef struct stat stat_t;

// VFS
struct handle {
	void *ctx;
	const vol_t *vol;
};

struct stat {
	size_t offset;
	size_t size;
};

struct ops {
	int (*mount)(const void *source,
				 void **ctx);  // Deve retornar um código de erro e definir o
							   // ponteiro em *ctx(passado como void **ctx)
							   // para o contexto de handlesystem.
	int (*unmount)(void *ctx); // Deve liberar qualquer coisa do
							   // handlesystem e retornar o código de erro
	int (*open)(void *ctx, const char *path,
				handle_t **out); // Deve retornar um código de erro
								 // *e definir (handle *) em *out
								 // *out = (handle_t *)handle;
	int (*create)(void *ctx,
				  const char *path); // Deve retornar o código de erro
	ssize_t (*read)(void *ctx, handle_t *h, void *dst,
					size_t n); // Deve retornar um código de erro negativo ou o
							   // número de bytes positivo
	ssize_t (*write)(void *ctx, handle_t *h, void *src,
					 size_t n); // Deve retornar um código de erro negativo ou o
								// número de bytes positivo
	int (*stat)(void *ctx,
				handle_t *h, stat_t *s); // Deve retornar um código de erro negativo
	int (*close)(void *ctx, handle_t *h);
	// PARA TODOS OS CÓDIGOS DE ERRO, DEVE RETORNAR -ERRO.
	// Ex: "return -VFS_ERR_NOT_FOUND;"
};

struct fs {
	char name[VFS_FILESYSTEM_NAME_LEN];
	ops_t *ops;
};

struct vol {
	char
		name[VFS_VOLUME_NAME_LEN]; // Isso é mais flexivel que indexado
								   // No indexado poderia usar até 36 caracteres
								   // com nome, isso permite coisas como
								   // fd0:/config.cfg ao invés de A:/config.cfg
								   // Também deve ser terminado com 0
	const fs_t
		*fs; // Um handlesystem NUNCA deve ser modificado através do volume,
			 // deve ser modificado apenas pela propria lista de handlesystems
	void *ctx;
};

// Procura um handlesystem pelo nome
fs_t *vfs_find_fs(const char *name);
// Procura um volume pelo nome
vol_t *vfs_find_vol(const char *name);
// Registra um handlesystem no vfs
// Retorna o índice dele na lista, -1 em caso de erro
int vfs_registry_fs(fs_t fs);

// Monta um sistema de arquivos
int vfs_mount(const char *volname, const char *fsname, const void *source);
// Abre um arquivo
handle_t *vfs_open(const char *path, int *err);
// Lê um arquivo/diretório
ssize_t vfs_read(handle_t *h, void *dst, size_t n);
// Escreve um arquivo
ssize_t vfs_write(handle_t *h, void *src, size_t n);
// Cria um arquivo
int vfs_create(const char *path);

#endif // VFS_H

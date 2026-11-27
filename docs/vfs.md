# VFS — Virtual File System

> **Status:** camada de despacho implementada; **nenhum filesystem real está registrado ou montado**. O RAMFS em `kmain.c` é um esqueleto inacabado e não é chamado.
> **Arquivos:** [`kernel/include/vfs.h`](../kernel/include/vfs.h), [`kernel/src/vfs.c`](../kernel/src/vfs.c), esqueleto de RAMFS em [`kernel/src/kmain.c`](../kernel/src/kmain.c).

## Visão geral

O VFS do Sedge é uma camada fina que associa **nomes de volume** (`vol:/caminho`) a um **filesystem** registrado, e delega operações para as callbacks desse filesystem. Não há cache, dentry, inode, permissões nem syscalls de arquivo. O objetivo atual é apenas estabelecer uma API única para futuros filesystems (RAMFS, FAT, etc.).

```mermaid
flowchart TD
    A[vfs_registry_fs\nfs_t com 8 callbacks] --> B[filesystems[16]]
    C[vfs_mount vol, fs, source] -->|ops.mount source, &ctx| D[vol_t em volumes[64]]
    E[vfs_open vol:/path] -->|find_vol → ops.open ctx, path| F[handle_t\nctx + offset + vol]
    F --> G[vfs_read / vfs_write / vfs_close]
    H[vfs_create vol:/path] -->|ops.create ctx, path| D
```

## Constantes

```c
#define VFS_FILESYSTEM_NAME_LEN 8
#define VFS_VOLUME_NAME_LEN    8
#define VFS_VOLUMES           64
#define VFS_FILESYSTEMS       16
```

Nomes de volume e filesystem são limitados a **7 caracteres + NUL**.

### Códigos de erro

| Constante | Valor | Significado |
|---|---:|---|
| `VFS_ERR_OK` | 0 | sucesso |
| `VFS_ERR_INVALID` | 1 | argumento inválido |
| `VFS_ERR_NOT_FOUND` | 2 | não encontrado |
| `VFS_ERR_BUSY` | 3 | ocupado |
| `VFS_ERR_IO` | 4 | erro de E/S |
| `VFS_ERR_NAME_USED` | 5 | nome duplicado |
| `VFS_ERR_NOT_ENOUGH_SPACE` | 6 | sem espaço no registro |
| `VFS_ERR_VOL_NOT_FOUND` | 7 | volume não encontrado |
| `VFS_ERR_FS_NOT_FOUND` | 8 | filesystem não encontrado |

> **Convenção do header:** *"PARA TODOS OS CÓDIGOS DE ERRO, DEVE RETORNAR -ERRO"*. Ou seja, as constantes são positivas, mas as APIs e as callbacks devem retornar o valor **negado** (por exemplo `-VFS_ERR_NOT_FOUND`).

## Estruturas

```c
typedef enum handle_type { VFS_HANDLE_FILE, VFS_HANDLE_DIR } handle_type_t;

struct handle {
    void          *ctx;      /* contexto privado do filesystem */
    size_t         offset;   /* posição atual — controlada pelo driver */
    const vol_t   *vol;      /* volume ao qual o handle pertence */
};

struct stat {
    size_t       size;
    const char  *name;
    size_t       name_len;
};

struct ops {
    int     (*mount)(const void *source, void **ctx);
    int     (*unmount)(void *ctx);
    int     (*open)(void *ctx, const char *path, handle_t **out);
    int     (*create)(void *ctx, const char *path);
    ssize_t (*read)(void *ctx, handle_t *h, void *dst, size_t n);
    ssize_t (*write)(void *ctx, handle_t *h, const void *src, size_t n);
    int     (*stat)(void *ctx, handle_t *h, stat_t *s);
    int     (*close)(void *ctx, handle_t *h);
};

struct fs {
    char  name[VFS_FILESYSTEM_NAME_LEN];
    ops_t *ops;
};

struct vol {
    char        name[VFS_VOLUME_NAME_LEN];
    const fs_t *fs;
    void       *ctx;
};
```

`handle_type_t` está declarado, mas `handle_t` **não** possui campo `type` — o VFS ainda não distingue arquivos de diretórios.

Estado global (em `vfs.c`): `filesystems[16]`, `volumes[64]`, `num_filesystems`, `num_volumes`.

## API pública

```c
fs_t     *vfs_find_fs(const char *name);
vol_t    *vfs_find_vol(const char *name);
int       vfs_registry_fs(fs_t fs);
int       vfs_mount(const char *volname, const char *fsname, const void *source);
handle_t *vfs_open(const char *path, int *err);
ssize_t   vfs_read(handle_t *h, void *dst, size_t n);
ssize_t   vfs_write(handle_t *h, const void *src, size_t n);
int       vfs_create(const char *path);
int       vfs_close(handle_t *h);
```

### Registro e montagem

- **`vfs_registry_fs(fs)`** recebe a estrutura **por valor**, valida o nome (não nulo, < 8 bytes), exige as **oito** callbacks não nulas (`vfs_check_fs`) e rejeita nomes duplicados. Retorna o índice em `filesystems[]` ou `-1`.
- **`vfs_mount(volname, fsname, source)`** valida o nome do volume, rejeita duplicatas e falta de espaço, localiza o filesystem, chama `ops->mount(source, &ctx)` e preenche `vol_t`. O nome é copiado até `':'` ou `'\0'`, permitindo chamar `vfs_mount("ram:", "ramfs", ...)`.
- **`vfs_find_fs` / `vfs_find_vol`** rejeitam nomes com `strlen >= 8` e comparam com `strcmp`.

### Abertura e operações

- **`vfs_open(path, err)`** exige o prefixo do volume: `vol:/caminho`. Extrai o nome antes de `':'`, acha o volume e chama `ops->open(vol->ctx, p, &h)` com `p` **após** o `':'` (sem o prefixo). Em seguida grava `*err = ret` e preenche `h->vol = vol`.
- **`vfs_read` / `vfs_write`** validam handle, buffer e `n > 0`, e delegam para `ops->read/write`. O VFS **não atualiza** `h->offset`: isso é responsabilidade do driver.
- **`vfs_close(h)`** delega para `ops->close`.
- **`vfs_create(path)`** também exige `vol:/caminho`, mas (diferente de `vfs_open`) passa o **path completo, com prefixo**, para `ops->create`. Há ainda a callback `ops->stat`, sem ponto de entrada público.

### Exemplo de uso (quando houver um FS registrado)

```c
fs_t fs = { .name = "ramfs", .ops = &ramfs_ops };
vfs_registry_fs(fs);
vfs_mount("ram", "ramfs", NULL);

int err;
handle_t *h = vfs_open("ram:/boot/config", &err);
if (!h) return -err;

char buf[64];
ssize_t n = vfs_read(h, buf, sizeof(buf));
vfs_close(h);
```

## RAMFS (em andamento)

`kmain.c` contém tipos e esqueleto para um filesystem em memória:

```c
typedef struct ramfs_node {
    char *name;
    size_t name_len;
    ramfs_node_type_t type;      /* RAMFS_FILE ou RAMFS_DIR */
    void *data;
    size_t data_len;
    struct ramfs_node *parent;
    struct ramfs_node *children;
    struct ramfs_node *next;
} ramfs_node_t;

typedef struct ramfs { ramfs_node_t *root; } ramfs_t;
```

Callbacks existentes: `ramfs_open()` (ainda sem corpo/retorno) e `ramfs_close()` (libera apenas o handle com `heap_free`). `ramfs_init()` aloca `fs_t` e `ops_t` no heap e preenche parcialmente os ponteiros, **mas nunca é chamada** por `kmain()`; mesmo que fosse, `fs->ops` não é atribuído (`ops` é vazado) e o FS não é registrado nem montado.

## Limitações conhecidas

1. `vfs_check_fs()` desreferencia `fs->ops` sem verificar se é nulo e exige 8 callbacks — um FS parcial (como o RAMFS atual) jamais passa na validação.
2. `vfs_open()` grava `h->vol` sem checar se `h` é nulo, após uma callback `open` que pode falhar.
3. Inconsistência de contrato: `vfs_open()` passa o caminho sem prefixo; `vfs_create()` passa com prefixo.
4. `vfs_mount()` não nega o código de erro de `ops->mount` e não desfaz o mount se `ctx` for nulo.
5. Não existem `vfs_stat()`, `vfs_unmount()` nem syscalls de VFS — `ops.stat` e `ops.unmount` estão inacessíveis ao usuário.
6. Nenhum filesystem funcional: não há volume montado no boot; o initrd é lido diretamente por `initrd_*` em `kmain`, sem passar pelo VFS (veja [initrd.md](initrd.md)).
7. `ramfs_close()` libera um handle sem saber se ele veio do heap do kernel.

## Ver também

- [Initrd](initrd.md) — origem de `/init.sys` no boot
- [Heap](memoria.md#heap-do-kernel) — alocação usada por handles e pelo RAMFS
- [Estado atual e pendências](estado-atual.md)

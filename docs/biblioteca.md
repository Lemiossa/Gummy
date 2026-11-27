# Biblioteca comum e tipos

> **Arquivos:** [`include/types.h`](../include/types.h), [`include/bitmap.h`](../include/bitmap.h), [`include/queue.h`](../include/queue.h), [`include/ring_buffer.h`](../include/ring_buffer.h), [`include/spinlock.h`](../include/spinlock.h), [`include/string.h`](../include/string.h), [`include/vsnprintf.h`](../include/vsnprintf.h), [`include/initrd.h`](../include/initrd.h) e implementações em [`lib/src/`](../lib/src/).
>
> O diretório `lib/` é compilado em `build/lib/global_lib.a` ([`lib/Makefile`](../lib/Makefile)) e linkado ao kernel, ao bootloader e ao `init`. Algumas APIs são `static inline` em headers (bitmap, tipos), portanto não possuem arquivo `.c` correspondente.

## Tipos e macros — `types.h`

| Grupo | Definições |
|---|---|
| Inteiros | `uint8_t`…`uint64_t`, `int8_t`…`int64_t`, `pid_t = int32_t`, `UINT*_MAX`, `INT*_MAX/MIN` |
| Por arquitetura | x86-64/AArch64: `uintptr_t`, `intptr_t`, `size_t`, `ssize_t`, `flags_t` de 64 bits; i386/ARM: 32 bits |
| Constante | `NULL`, `MIN`, `MAX`, `OFFSETOF`, `CONTAINER_OF(ptr, type, member)` |
| Alinhamento | `ALIGN_UP(x, a) (((x) + ((a) - 1)) & ~((a) - 1))`, `ALIGN_DOWN(x, a) ((x) & ~((a) - 1))` — `a` deve ser potência de 2 |
| Varargs | `va_list = __builtin_va_list` e macros `va_start`, `va_end`, `va_arg`, `va_copy` |

Arquitetura não suportada gera `#error "Arquitetura nao suportada"`.

## Bitmap — `bitmap.h` (header-only)

```c
static inline void     bitmap_set_bit(uint8_t *bmp, uint64_t bit);
static inline int      bitmap_test_bit(const uint8_t *bmp, uint64_t bit);
static inline void     bitmap_clear_bit(uint8_t *bmp, uint64_t bit);
static inline uint64_t bitmap_find_free_bit(const uint8_t *bmp, uint64_t bits);
```

Usado pelo [PMM](memoria.md#gerenciador-de-memória-física-pmm). `find_free_bit` otimiza bytes `0xFF` e testa bit a bit; retorna `0` tanto para "bit 0 livre" quanto para "nenhum livre" (o chamador deve tratar essa ambiguidade). `set/test/clear` não verificam limites.

## Fila — `queue.h` / `lib/src/queue.c`

```c
void          queue_init(queue_t *q);
void          queue_push(queue_t *q, queue_node_t *node);
queue_node_t *queue_pop(queue_t *q);
int           queue_empty(queue_t *q);
void          queue_remove(queue_node_t *node);
queue_node_t *queue_get(queue_t *q, size_t index);
size_t        queue_size(queue_t *q);
```

```c
struct queue_node { queue_node_t *prev, *next; queue_t *q; };
struct queue     { queue_node_t head; size_t size; };  /* lista circular com sentinela */
```

`queue_push()` **remove o nó da fila anterior** antes de inserir no fim — por isso o mesmo `queue_node_t` pode migrar entre `ready_queue`, `sleep_queue`, `zombie_queue` e `mailbox.waiters` (ver [escalonador.md](escalonador.md)). `queue_pop()` zera `node->q`. `queue_remove()` depende de `node->q` válido e, por um bug de ordem nos testes, não aceita `NULL`. Não há travamento interno: os chamadores usam `cli`.

## Ring buffer — `ring_buffer.h` / `lib/src/ring_buffer.c`

```c
typedef struct ring_buffer {
    uint8_t *buf;                 /* armazenamento externo */
    size_t elem_size, capacity, head, tail, count;
} ring_buffer_t;

void ring_buffer_init(ring_buffer_t *r, void *storage, size_t elem_size, size_t capacity);
int  ring_buffer_push(ring_buffer_t *r, const void *elem); /* 0 = ok */
int  ring_buffer_pop(ring_buffer_t *r, void *out);         /* 0 = ok */
int  ring_buffer_peek(ring_buffer_t *r, void *out);
int  ring_buffer_full(const ring_buffer_t *r);
int  ring_buffer_empty(const ring_buffer_t *r);
```

Cópia por elemento via `memcpy`, índices com módulo `capacity`, **sem sincronização**. Usado pelo mailbox de IPC: 16 mensagens de 76 bytes = 1216 bytes por processo ([ipc.md](ipc.md)).

## Spinlock — `spinlock.h` / `lib/src/spinlock.c`

```c
typedef struct { volatile uint32_t locked; } spinlock_t;
#define SPINLOCK_INIT {0}
void spinlock(spinlock_t *l);
void spinunlock(spinlock_t *l);
```

Implementado com `__sync_lock_test_and_set()` e `pause` da ISA x86 enquanto espera. Usado por `debug_print_string()`. Em sistema uniprocessor, chamadores que precisam excluir interrupções combinam `cli` + spinlock.

## String — `string.h` / `lib/src/string.c`

```c
void   memcpy(void *dst, const void *src, size_t n);
void   memset(void *dst, int c, size_t n);
int    memcmp(const void *s1, const void *s2, size_t n);
int    itoa(char *out, uint64_t base, uint64_t num, int signal, int upper, uint32_t zero_pad);
size_t strlen(const char *str);
int    strcmp(const char *s1, const char *s2);
int    strncmp(const char *s1, const char *s2, size_t n);
char  *strchr(const char *str, int ch);
void   strcpy(char *dst, const char *src);
void   strncpy(char *dst, const char *src, size_t n);
```

Observações:

- `itoa()` exige buffer de **66 bytes**, base entre 2 e 16, `num` em valor absoluto, e retorna a quantidade de caracteres escritos.
- `memcpy()`/`memset()` toleram ponteiros nulos; `memcmp()`, `strlen()`, `strcmp()` e `strncmp()` não.
- `strncpy()` só preenche o restante com `\0` se `src` terminar antes de `n`: se `strlen(src) >= n`, o destino **não fica terminado** (relevante para os nomes de volume do VFS).

## Formatação — `vsnprintf.h` / `lib/src/vsnprintf.c`

```c
int vsnprintf(char *s, size_t n, const char *format, va_list arg);
```

Suporta `%c`, `%s`, `%p`, `%d`, `%i`, `%u`, `%x`, `%X`, `%o`, `%%`, modificadores `h`/`hh`/`l`/`ll`, flag `0` e largura decimal. `NULL` em `%s` vira `(null)`. Retorna o total de caracteres que seriam escritos e sempre termina a string em `s[min(index, n-1)]` quando `n > 0`. Não suporta precisão, `+`, espaço, `#`, `%n` ou largura por `*`.

## Initrd — `initrd.h` / `lib/src/initrd.c`

```c
#define INITRD_MAGIC 0x47554D4D   /* 'M','M','U','G' em little-endian */

typedef struct initrd_header { uint32_t magic, version, entry_count, data_offset; } __attribute__((packed)) initrd_header_t;
typedef struct initrd_entry  { uint32_t type, permissions, name_size, offset, size; } __attribute__((packed)) initrd_entry_t;

typedef struct initrd {
    const void *base;
    const initrd_header_t *header;
    const initrd_entry_t *entries;
    const void *data;
} initrd_t;

void          initrd_create(initrd_t *out, const void *data);
int           initrd_check(const initrd_t *initrd);
const initrd_entry_t *initrd_get_entry(const initrd_t *initrd, size_t n);
const initrd_entry_t *initrd_find_entry(const initrd_t *initrd, const char *path);
size_t        initrd_get_len(const initrd_entry_t *entry);
const void   *initrd_get_data(const initrd_t *initrd, const initrd_entry_t *entry);
```

`initrd_find_entry()` exige `name_size == strlen(path) + 1` e compara com `memcmp` — a barra inicial do caminho faz parte do nome. A validação de `initrd_check()` cobre apenas ponteiros e magic: tamanhos e offsets não são conferidos. Formato detalhado em [initrd.md](initrd.md).

## Limitações resumidas

- `bitmap_find_free_bit()` ambíguo no retorno `0`.
- `queue_remove(NULL)` desreferencia `NULL` antes do teste.
- `strncpy()` não garante NUL terminal.
- `vsnprintf()` ignora vários especificadores e não limita a leitura de `%s`.
- Nenhuma estrutura da biblioteca possui travamento interno.
- `initrd_check()` confia em metadados potencialmente corrompidos; `initrd_find_entry()` é O(n²).

## Ver também

- [PMM](memoria.md#gerenciador-de-memória-física-pmm) — uso do bitmap
- [Escalonador](escalonador.md) — uso de filas
- [IPC](ipc.md) — uso do ring buffer e spinlocks
- [Debug](saida-e-debug.md) — uso de `vsnprintf` e spinlock
